import 'dart:async';

import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../notifications/notification_scheduler.dart';
import '../notifications/notify_state.dart';
import '../platform/platform_capabilities.dart';
import '../settings/settings_service.dart';
import '../sync/supabase_backend.dart';
import 'releases_backend.dart';

/// Keeps the local release feed fresh and tracks what this device has seen
/// (spec §9). Checks happen on launch, on foreground resume, and — while a
/// desktop app stays running — on a periodic timer; all of them funnel
/// through [check], which throttles itself. The in-app badge is the only
/// surface wired here; OS notification tiers arrive behind the settings
/// toggle (spec §9.4).
class ReleaseService {
  ReleaseService(
    this._db,
    this._backend, {
    this.checkThrottle = const Duration(minutes: 15),
    this.runningPollInterval = const Duration(hours: 8),
    this.onFresh,
  });

  static const _lastCheckKey = 'releases.lastCheckMs';
  static const _baselineKey = 'releases.baselined';

  final AppDatabase _db;
  final ReleasesBackend? _backend;
  final Duration checkThrottle;

  /// Spec §9.2's 6–12 h "while running" re-check cadence (desktop only).
  final Duration runningPollInterval;

  /// Fired when a *non-launch* check finds new rows — the launch check's
  /// news is already on screen as the bell badge. The desktop toast tier
  /// hangs off this (spec §9.4).
  final Future<void> Function(int freshCount)? onFresh;

  Timer? _pollTimer;
  AppLifecycleListener? _lifecycle;

  bool get available => _backend != null;

  /// Call once at startup. Fires the launch check and wires the resume +
  /// (on desktop) periodic re-checks. All checks are fire-and-forget and
  /// swallow errors — the app keeps serving the cached feed.
  void start({required bool desktopTimer}) {
    if (_backend == null) return;
    void tryCheck({required bool notify}) =>
        unawaited(check(notifyIfFresh: notify).catchError((Object _) => 0));
    tryCheck(notify: false); // launch news lands as the badge, not a toast
    _lifecycle = AppLifecycleListener(onResume: () => tryCheck(notify: true));
    if (desktopTimer) {
      _pollTimer = Timer.periodic(
          runningPollInterval, (_) => tryCheck(notify: true));
    }
  }

  void dispose() {
    _pollTimer?.cancel();
    _lifecycle?.dispose();
  }

  /// Fetches the feed and merges it into the local mirror. Rows already
  /// known keep their seen state; genuinely new rows land unseen — except
  /// on the very first check, which baselines the whole backlog as seen so
  /// a fresh install doesn't badge years of history. Returns the number of
  /// new unseen rows (0 on a quiet, throttled, or local-only check).
  Future<int> check({bool force = false, bool notifyIfFresh = false}) async {
    final backend = _backend;
    if (backend == null) return 0;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (!force) {
      final last =
          int.tryParse(await _db.catalogDao.getSyncValue(_lastCheckKey) ?? '');
      if (last != null && nowMs - last < checkThrottle.inMilliseconds) return 0;
    }

    final rows = await backend.fetchAll();
    final baselined = await _db.catalogDao.getSyncValue(_baselineKey) != null;
    final known = {for (final r in await _db.releasesDao.all()) r.infohash};

    var fresh = 0;
    await _db.catalogDao.runInTransaction(() async {
      for (final r in rows) {
        final isNew = !known.contains(r.infohash);
        if (isNew && baselined) fresh++;
        await _db.releasesDao.upsertFetched(
          infohash: r.infohash,
          title: r.title,
          pubDateMs: r.pubDate?.millisecondsSinceEpoch,
          variant: r.variant,
          outdated: r.outdated,
          fileName: r.fileName,
          crc32: r.crc32,
          magnet: r.magnet,
          firstSeenAtMs: r.firstSeenAt.millisecondsSinceEpoch,
          seenAtMs: baselined ? null : nowMs,
        );
      }
      await _db.catalogDao.setSyncValue(_baselineKey, '1');
      await _db.catalogDao.setSyncValue(_lastCheckKey, nowMs.toString());
    });

    // Whatever the app has ingested is on the bell badge now — the
    // background poll must never re-notify it (spec §9.4).
    await advanceNotifyWatermark(
        _newestPubDate(rows)?.toUtc());

    if (fresh > 0 && notifyIfFresh && onFresh != null) {
      await onFresh!(fresh);
    }
    return fresh;
  }

  DateTime? _newestPubDate(List<RemoteRelease> rows) {
    DateTime? newest;
    for (final r in rows) {
      final d = r.pubDate;
      if (d != null && (newest == null || d.isAfter(newest))) newest = d;
    }
    return newest;
  }

  /// Opening the release list clears every badge (spec §9.3).
  Future<void> markAllSeen() =>
      _db.releasesDao.markAllSeen(DateTime.now().millisecondsSinceEpoch);

  /// Opening an episode clears its releases' badges (spec §9.3). The join
  /// runs release CRC32 → the episode's MKV source rows.
  Future<void> markEpisodeSeen(int arcPart, int number) async {
    final sources = await _db.catalogDao.sourcesForEpisode(arcPart, number);
    final crc32s = {for (final s in sources) ?s.crc32};
    if (crc32s.isEmpty) return;
    await _db.releasesDao
        .markSeenByCrc32s(crc32s, DateTime.now().millisecondsSinceEpoch);
  }
}

// Manual providers — riverpod codegen stays out of stream-adjacent files
// (see home_providers.dart).

final releaseServiceProvider = Provider<ReleaseService>((ref) {
  final service = ReleaseService(
    ref.watch(appDatabaseProvider),
    ref.watch(releasesBackendProvider),
    // Desktop toast tier (spec §9.4): a running app's periodic/resume check
    // that finds news raises an OS toast — if the toggle is on. Settings are
    // read at fire time so a toggle flip needs no re-wiring.
    onFresh: (count) async {
      if (ref.read(platformCapabilitiesProvider).notificationStyle !=
          NotificationStyle.desktopToast) {
        return;
      }
      final settings = await ref.read(settingsServiceProvider).load();
      if (!settings.notifyNewEpisodes) return;
      await ref.read(notificationServiceProvider).showNewReleases(count);
    },
  );
  ref.onDispose(service.dispose);
  return service;
});

/// One-shot startup hookup, watched from the home screen like the other
/// init providers. Also syncs the background-poll registration with the
/// stored toggle.
final releasesInitProvider = FutureProvider<void>((ref) async {
  final desktop = ref.watch(platformCapabilitiesProvider).hasWindowManagement;
  ref.watch(releaseServiceProvider).start(desktopTimer: desktop);
  await ref.watch(notificationSchedulerProvider).ensureStarted();
});
