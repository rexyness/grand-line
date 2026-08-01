import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/pixeldrain.dart';
import '../db/database.dart';
import '../platform/platform_capabilities.dart';
import '../settings/settings_service.dart';

/// Picks the MKV to download for an episode (spec §7.2: MKV-only, no quality
/// picker): a 'download'-kind source with a resolved Pixeldrain ID, preferring
/// the 'standard' variant over 'extended'. Pure — tested without a downloader.
Source? chooseDownloadSource(List<Source> sources) {
  final candidates = sources
      .where((s) => s.kind == 'download' && s.pixeldrainId != null)
      .toList();
  if (candidates.isEmpty) return null;
  return candidates.firstWhere(
    (s) => s.variant == 'standard',
    orElse: () => candidates.first,
  );
}

/// App-owned shim over background_downloader (spec §7): 2-lane FIFO queue,
/// pause/resume/cancel, 3 auto-retries then a visible 'failed' state, and a
/// registry (the Drift downloads table) reconciled against the package's
/// persistent task database on every launch. Nothing outside `data/downloads/`
/// touches the engine package.
class DownloadService {
  DownloadService(this._db, this._settings);

  /// Spec §7.4: 2 fixed lanes, FIFO, no concurrency setting.
  static const lanes = 2;
  static const retries = 3;

  final AppDatabase _db;
  final SettingsService _settings;
  final FileDownloader _downloader = FileDownloader();
  StreamSubscription<TaskUpdate>? _subscription;
  StreamSubscription<AppSettings>? _settingsSub;
  StreamSubscription<List<ProgressEntry>>? _progressSub;
  AppSettings _current = const AppSettings();
  bool _wifiPreferenceApplies = false;

  final _progress = <(int, int), double>{};
  final _progressController =
      StreamController<Map<(int, int), double>>.broadcast();

  /// Per-episode progress (0..1) for tasks that are actively downloading.
  Map<(int, int), double> get progress => Map.unmodifiable(_progress);
  Stream<Map<(int, int), double>> get progressStream =>
      _progressController.stream;

  static String taskIdFor(int arcPart, int number) => 'ep-$arcPart-$number';

  static (int, int)? episodeKeyOf(String taskId) {
    final m = RegExp(r'^ep-(\d+)-(\d+)$').firstMatch(taskId);
    if (m == null) return null;
    return (int.parse(m.group(1)!), int.parse(m.group(2)!));
  }

  /// Call once at startup, before any other method: configures the 2-lane
  /// holding queue, wires status/progress updates, applies the stored
  /// settings (and follows their changes), recovers tasks that ran while
  /// the app was gone, and reconciles the registry (spec §7.4).
  ///
  /// [wifiPreferenceApplies] is the platform's `hasCellularToggle` — the
  /// Wi-Fi-only preference is meaningless where there is no cellular.
  Future<void> init({required bool wifiPreferenceApplies}) async {
    _wifiPreferenceApplies = wifiPreferenceApplies;
    await _downloader.configure(
        globalConfig: (Config.holdingQueue, (lanes, null, null)));
    _subscription = _downloader.updates.listen(_onUpdate);
    await _downloader.start();
    _current = await _settings.load();
    if (_wifiPreferenceApplies) await _applyWifi(_current.wifiOnly);
    _settingsSub = _settings.watch().listen(
        (s) => unawaited(_onSettings(s).catchError((Object _) {})));
    // skip(1) drops the initial snapshot; only real progress changes can
    // flip an episode to watched.
    _progressSub = _db.progressDao.watchAll().skip(1).listen((_) {
      if (_current.autoDeleteWatched) {
        unawaited(deleteWatchedDownloads().catchError((Object _) {}));
      }
    });
    await _reconcile();
    if (_current.autoDeleteWatched) await deleteWatchedDownloads();
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _settingsSub?.cancel();
    await _progressSub?.cancel();
    await _progressController.close();
  }

  Future<void> _onSettings(AppSettings s) async {
    final previous = _current;
    _current = s;
    if (_wifiPreferenceApplies && s.wifiOnly != previous.wifiOnly) {
      await _applyWifi(s.wifiOnly);
    }
    if (s.autoDeleteWatched && !previous.autoDeleteWatched) {
      await deleteWatchedDownloads();
    }
  }

  Future<void> _applyWifi(bool wifiOnly) => _downloader.requireWiFi(
      wifiOnly ? RequireWiFi.forAllTasks : RequireWiFi.asSetByTask);

  /// Spec §7.5's opt-in auto-delete: drops completed downloads of episodes
  /// the local progress table marks watched.
  Future<void> deleteWatchedDownloads() async {
    final watched = {
      for (final p in await _db.progressDao.all())
        if (p.watched) (p.arcPart, p.number),
    };
    if (watched.isEmpty) return;
    for (final row in await _db.downloadsDao.all()) {
      if (row.status == 'complete' &&
          watched.contains((row.arcPart, row.number))) {
        await delete(row.arcPart, row.number);
      }
    }
  }

  /// The downloadable sources for [numbers] of an arc that are not already
  /// downloaded or in the queue — the plan the UI confirms (with its total
  /// size) before committing (spec §7.2).
  Future<Map<int, Source>> planEpisodes(int arcPart, List<int> numbers) async {
    final existing = {
      for (final d in await _db.downloadsDao.all())
        if (d.arcPart == arcPart && d.status != 'failed') d.number,
    };
    final plan = <int, Source>{};
    for (final number in numbers) {
      if (existing.contains(number)) continue;
      final source = chooseDownloadSource(
          await _db.catalogDao.sourcesForEpisode(arcPart, number));
      if (source != null) plan[number] = source;
    }
    return plan;
  }

  /// Queues the canonical MKV for an episode. Returns false when the catalog
  /// has no downloadable source with a resolved Pixeldrain ID yet.
  Future<bool> enqueueEpisode(int arcPart, int number) async {
    final source = chooseDownloadSource(
        await _db.catalogDao.sourcesForEpisode(arcPart, number));
    if (source == null) return false;
    await enqueueSource(arcPart, number, source);
    return true;
  }

  Future<void> enqueueSource(int arcPart, int number, Source source) async {
    // Desktop download-folder setting (spec §4.5): absolute path via the
    // root base; empty keeps the app-private default. Applies to newly
    // queued tasks only.
    final customDir = _current.downloadDir;
    final task = DownloadTask(
      taskId: taskIdFor(arcPart, number),
      url: pixeldrainFileUrl(source.pixeldrainId!),
      filename: source.fileName ?? 'onepace-$arcPart-$number.mkv',
      baseDirectory: customDir.isEmpty
          ? BaseDirectory.applicationSupport
          : BaseDirectory.root,
      directory: customDir.isEmpty ? 'episodes' : customDir,
      updates: Updates.statusAndProgress,
      allowPause: true,
      retries: retries,
    );
    await _db.downloadsDao.upsert(
      arcPart: arcPart,
      number: number,
      sourceId: source.id,
      taskId: task.taskId,
      status: 'queued',
      sizeBytes: source.sizeBytes,
      updatedAtMs: _now(),
    );
    await _downloader.enqueue(task);
  }

  Future<void> pause(int arcPart, int number) async {
    final task = await _taskFor(arcPart, number);
    if (task != null) await _downloader.pause(task);
  }

  Future<void> resume(int arcPart, int number) async {
    final task = await _taskFor(arcPart, number);
    if (task != null) await _downloader.resume(task);
  }

  /// Global pause-all (spec §4.4): pauses every running task.
  Future<void> pauseAll() async {
    for (final row in await _db.downloadsDao.all()) {
      if (row.status == 'running') await pause(row.arcPart, row.number);
    }
  }

  Future<void> cancel(int arcPart, int number) async {
    await _downloader.cancelTaskWithId(taskIdFor(arcPart, number));
    await _db.downloadsDao.remove(arcPart, number);
  }

  /// Deletes a completed download's file (or cancels it if still active) and
  /// drops the registry row.
  Future<void> delete(int arcPart, int number) async {
    final row = await _db.downloadsDao.get(arcPart, number);
    if (row == null) return;
    if (row.status == 'complete') {
      final path = row.filePath;
      if (path != null) {
        try {
          await File(path).delete();
        } catch (_) {} // already gone — the row goes regardless
      }
      await _db.downloadsDao.remove(arcPart, number);
    } else {
      await cancel(arcPart, number);
    }
  }

  Future<void> deleteArc(int arcPart) async {
    for (final row in await _db.downloadsDao.all()) {
      if (row.arcPart == arcPart) await delete(row.arcPart, row.number);
    }
  }

  Future<void> deleteAll() async {
    for (final row in await _db.downloadsDao.all()) {
      await delete(row.arcPart, row.number);
    }
  }

  Future<DownloadTask?> _taskFor(int arcPart, int number) async {
    final record =
        await _downloader.database.recordForId(taskIdFor(arcPart, number));
    final task = record?.task;
    return task is DownloadTask ? task : null;
  }

  Future<void> _onUpdate(TaskUpdate update) async {
    final key = episodeKeyOf(update.task.taskId);
    if (key == null) return;
    switch (update) {
      case TaskStatusUpdate():
        await _applyStatus(key, update.status, update.task);
      case TaskProgressUpdate():
        // Negative values are sentinel signals (failed/canceled/retry),
        // surfaced through status updates instead.
        if (update.progress >= 0) {
          _progress[key] = update.progress.clamp(0, 1);
          _emitProgress();
        }
    }
  }

  Future<void> _applyStatus((int, int) key, TaskStatus status, Task task) async {
    final (arcPart, number) = key;
    switch (status) {
      case TaskStatus.enqueued:
      case TaskStatus.waitingToRetry:
        await _setStatus(arcPart, number, 'queued');
      case TaskStatus.running:
        await _setStatus(arcPart, number, 'running');
      case TaskStatus.paused:
        _dropProgress(key);
        await _setStatus(arcPart, number, 'paused');
      case TaskStatus.complete:
        _dropProgress(key);
        await _markComplete(arcPart, number, task);
      case TaskStatus.failed:
      case TaskStatus.notFound:
        _dropProgress(key);
        await _setStatus(arcPart, number, 'failed');
      case TaskStatus.canceled:
        _dropProgress(key);
        await _db.downloadsDao.remove(arcPart, number);
    }
  }

  Future<void> _markComplete(int arcPart, int number, Task task) async {
    final path = await task.filePath();
    int? size;
    try {
      size = await File(path).length();
    } catch (_) {}
    await _db.downloadsDao.setStatus(
      arcPart: arcPart,
      number: number,
      status: 'complete',
      filePath: path,
      sizeBytes: size,
      updatedAtMs: _now(),
    );
  }

  /// Spec §7.4: the queue survives restarts in the package's persistent task
  /// DB; the registry is reconciled against it on every launch. Complete rows
  /// whose file vanished are dropped; rows the downloader no longer knows
  /// become 'failed — tap to retry'.
  Future<void> _reconcile() async {
    final records = await _downloader.database.allRecords();
    final byId = {for (final r in records) r.taskId: r};
    for (final row in await _db.downloadsDao.all()) {
      if (row.status == 'complete') {
        final path = row.filePath;
        if (path == null || !await File(path).exists()) {
          await _db.downloadsDao.remove(row.arcPart, row.number);
        }
        continue;
      }
      final record = row.taskId == null ? null : byId[row.taskId];
      if (record == null) {
        await _setStatus(row.arcPart, row.number, 'failed');
        continue;
      }
      switch (record.status) {
        case TaskStatus.enqueued:
        case TaskStatus.waitingToRetry:
          await _setStatus(row.arcPart, row.number, 'queued');
        case TaskStatus.running:
          await _setStatus(row.arcPart, row.number, 'running');
        case TaskStatus.paused:
          await _setStatus(row.arcPart, row.number, 'paused');
        case TaskStatus.complete:
          await _markComplete(row.arcPart, row.number, record.task);
        case TaskStatus.failed:
        case TaskStatus.notFound:
          await _setStatus(row.arcPart, row.number, 'failed');
        case TaskStatus.canceled:
          await _db.downloadsDao.remove(row.arcPart, row.number);
      }
    }
  }

  Future<void> _setStatus(int arcPart, int number, String status) =>
      _db.downloadsDao.setStatus(
        arcPart: arcPart,
        number: number,
        status: status,
        updatedAtMs: _now(),
      );

  void _dropProgress((int, int) key) {
    if (_progress.remove(key) != null) _emitProgress();
  }

  void _emitProgress() {
    if (!_progressController.isClosed) {
      _progressController.add(Map.unmodifiable(_progress));
    }
  }

  static int _now() => DateTime.now().millisecondsSinceEpoch;
}

// Manual providers — see the note in supabase_backend.dart.

final downloadServiceProvider = Provider<DownloadService>((ref) {
  final service = DownloadService(
      ref.watch(appDatabaseProvider), ref.watch(settingsServiceProvider));
  ref.onDispose(service.dispose);
  return service;
});

/// One-shot startup init, watched from the home screen the same way as the
/// launch catalog refresh.
final downloadsInitProvider = FutureProvider<void>((ref) async {
  final capabilities = ref.watch(platformCapabilitiesProvider);
  await ref
      .watch(downloadServiceProvider)
      .init(wifiPreferenceApplies: capabilities.hasCellularToggle);
});

/// Live progress per (arcPart, number), for queue rows' progress bars.
final downloadProgressProvider =
    StreamProvider<Map<(int, int), double>>((ref) async* {
  final service = ref.watch(downloadServiceProvider);
  yield service.progress;
  yield* service.progressStream;
});
