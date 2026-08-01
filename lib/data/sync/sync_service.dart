import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import 'supabase_backend.dart';
import 'sync_backend.dart';

/// Watch-progress sync orchestration (spec §8). The local Drift DB stays the
/// source of truth regardless of sign-in; syncing is strictly additive:
///
/// - Sign-in (including the first) triggers a full push — that *is* the
///   first-sign-in history upload (spec §8.1) — followed by a full pull.
/// - Local progress changes schedule a debounced background push.
/// - Pulls apply the most-recent-activity-wins rule locally, mirroring the
///   server RPC (spec §8.4).
///
/// Pulls are always full-table, never watermarked: `updated_at` is
/// client-stamped *activity* time, so a device that syncs after being
/// offline uploads rows stamped in the past — rows a newer-than-watermark
/// pull on another device would miss. The table is a few hundred rows at
/// most; correctness wins.
class SyncService {
  SyncService(
    this._db,
    this._backend, {
    this.pushDebounce = const Duration(seconds: 30),
  });

  static const lastSyncKey = 'sync.lastSyncMs';

  final AppDatabase _db;
  final SyncBackend? _backend;
  final Duration pushDebounce;

  Timer? _pushTimer;
  StreamSubscription<String?>? _authSub;
  StreamSubscription<List<ProgressEntry>>? _progressSub;
  String? _syncedEmail;

  /// False in local-only builds without backend defines; the account surface
  /// says so instead of offering sign-in.
  bool get available => _backend != null;

  String? get userEmail => _backend?.userEmail;

  Stream<String?> get userEmailStream =>
      _backend?.userEmailStream ?? Stream.value(null);

  Stream<DateTime?> watchLastSync() =>
      _db.catalogDao.watchSyncValue(lastSyncKey).map((value) {
        final ms = value == null ? null : int.tryParse(value);
        return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
      });

  /// Call once at startup. Wires the two background triggers: sync on
  /// sign-in (which also covers "signed in at launch" — the auth stream
  /// replays the current session), and a debounced push on local progress
  /// changes.
  void start() {
    final backend = _backend;
    if (backend == null) return;

    _authSub = backend.userEmailStream.listen((email) {
      final signedIn = email != null && email != _syncedEmail;
      _syncedEmail = email;
      if (signedIn) {
        unawaited(syncNow().catchError((Object _) => null));
      }
    });

    // skip(1) drops the initial table snapshot; only real changes push.
    // A pull that applies remote rows re-triggers this and pushes the same
    // state back once — harmless, the server RPC no-ops on equal-or-older
    // timestamps.
    _progressSub = _db.progressDao.watchAll().skip(1).listen((_) {
      if (backend.userEmail == null) return;
      _pushTimer?.cancel();
      _pushTimer = Timer(pushDebounce, () {
        unawaited(_push(backend).catchError((Object _) {}));
      });
    });
  }

  Future<void> dispose() async {
    _pushTimer?.cancel();
    await _authSub?.cancel();
    await _progressSub?.cancel();
  }

  Future<void> sendOtp(String email) async {
    final backend = _requireBackend();
    await backend.sendOtp(email);
  }

  /// On success the auth stream fires and [start]'s listener runs the
  /// first-sign-in upload + pull.
  Future<void> verifyOtp({required String email, required String code}) async {
    final backend = _requireBackend();
    await backend.verifyOtp(email: email, code: code);
  }

  /// Local data stays (spec §4.6); only the session goes.
  Future<void> signOut() async {
    final backend = _requireBackend();
    await backend.signOut();
  }

  /// Full push + full pull. Returns the completion time (also persisted for
  /// the account surface), or null when signed out / local-only.
  Future<DateTime?> syncNow() async {
    final backend = _backend;
    if (backend == null || backend.userEmail == null) return null;
    _pushTimer?.cancel();
    await _push(backend);
    await _pull(backend);
    final now = DateTime.now();
    await _db.catalogDao
        .setSyncValue(lastSyncKey, now.millisecondsSinceEpoch.toString());
    return now;
  }

  Future<void> _push(SyncBackend backend) async {
    final rows = await _db.progressDao.all();
    await backend.pushProgress([
      for (final r in rows)
        RemoteProgress(
          arcPart: r.arcPart,
          number: r.number,
          positionMs: r.positionMs,
          watched: r.watched,
          updatedAt:
              DateTime.fromMillisecondsSinceEpoch(r.updatedAtMs, isUtc: true),
        ),
    ]);
  }

  Future<void> _pull(SyncBackend backend) async {
    for (final r in await backend.pullProgress()) {
      await _db.progressDao.applyLww(
        arcPart: r.arcPart,
        number: r.number,
        positionMs: r.positionMs,
        watched: r.watched,
        updatedAtMs: r.updatedAt.toUtc().millisecondsSinceEpoch,
      );
    }
  }

  SyncBackend _requireBackend() {
    final backend = _backend;
    if (backend == null) {
      throw const SyncAuthException('Sync is not available in this build.');
    }
    return backend;
  }
}

// Manual providers — see the note in supabase_backend.dart (build_runner
// works with `--force-jit`; new providers stay manual for uniformity).

final syncServiceProvider = Provider<SyncService>((ref) {
  final service =
      SyncService(ref.watch(appDatabaseProvider), ref.watch(syncBackendProvider));
  ref.onDispose(service.dispose);
  return service;
});

/// One-shot startup hookup, watched from the home screen the same way as
/// the downloads init.
final syncInitProvider = Provider<void>((ref) {
  ref.watch(syncServiceProvider).start();
});

/// Signed-in email, or null. Loading only for the first frames.
final signedInEmailProvider = StreamProvider<String?>(
    (ref) => ref.watch(syncServiceProvider).userEmailStream);

final lastSyncProvider = StreamProvider<DateTime?>(
    (ref) => ref.watch(syncServiceProvider).watchLastSync());
