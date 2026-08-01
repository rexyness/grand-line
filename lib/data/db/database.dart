import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database.g.dart';

/// One Pace arcs, in voyage order (`part` 0 = Specials).
class Arcs extends Table {
  IntColumn get part => integer()();
  TextColumn get saga => text()();
  TextColumn get title => text()();
  TextColumn get shortcode => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get mkvcode => text().withDefault(const Constant(''))();

  /// Filled by catalog sync (spec §10.5); never vendored.
  TextColumn get backdropUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {part};
}

/// Logical episodes. Identity is (arc, number) — release CRC32s churn on
/// re-release and live on [Sources] rows instead, so progress survives
/// re-releases (spec §3.1).
class Episodes extends Table {
  IntColumn get arcPart => integer().references(Arcs, #part)();
  IntColumn get number => integer()();
  TextColumn get title => text().nullable()();
  TextColumn get mangaChapters => text().nullable()();
  TextColumn get animeEpisodes => text().nullable()();
  DateTimeColumn get released => dateTime().nullable()();
  IntColumn get durationSeconds => integer().nullable()();

  @override
  Set<Column> get primaryKey => {arcPart, number};
}

/// One row per obtainable file for an episode (spec §2.1):
/// - kind 'stream': hardsubbed MP4 per variant ('ensub'/'dub') and quality
///   (480/720/1080), Pixeldrain ID filled by catalog sync.
/// - kind 'download': canonical MKV per variant ('standard'/'extended'),
///   quality 0, CRC32-keyed, seeded from the vendored snapshot.
class Sources extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get arcPart => integer()();
  IntColumn get number => integer()();
  TextColumn get kind => text()();
  TextColumn get variant => text()();

  /// 480/720/1080 for streams; 0 (n/a) for downloads. Non-null so the
  /// uniqueness constraint holds (SQLite treats NULLs as distinct).
  IntColumn get quality => integer().withDefault(const Constant(0))();
  TextColumn get pixeldrainId => text().nullable()();
  TextColumn get crc32 => text().nullable()();
  TextColumn get fileName => text().nullable()();
  IntColumn get sizeBytes => integer().nullable()();
  IntColumn get updatedAtMs => integer().withDefault(const Constant(0))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {arcPart, number, kind, variant, quality},
      ];
}

/// Local watch progress; source of truth regardless of sign-in (spec §8.1).
/// `updatedAtMs` is the client-stamped LWW key mirrored by the server RPC.
class ProgressEntries extends Table {
  IntColumn get arcPart => integer()();
  IntColumn get number => integer()();
  IntColumn get positionMs => integer().withDefault(const Constant(0))();
  BoolColumn get watched => boolean().withDefault(const Constant(false))();
  IntColumn get updatedAtMs => integer()();

  @override
  Set<Column> get primaryKey => {arcPart, number};
}

/// Download registry, reconciled against background_downloader's own task DB
/// on every launch (spec §7.4).
class DownloadEntries extends Table {
  IntColumn get arcPart => integer()();
  IntColumn get number => integer()();
  IntColumn get sourceId => integer().nullable()();
  TextColumn get taskId => text().nullable()();

  /// queued | running | paused | complete | failed
  TextColumn get status => text().withDefault(const Constant('queued'))();
  TextColumn get filePath => text().nullable()();
  IntColumn get sizeBytes => integer().nullable()();
  IntColumn get updatedAtMs => integer()();

  @override
  Set<Column> get primaryKey => {arcPart, number};
}

/// Local mirror of the backend `releases` feed (spec §9). `seenAtMs` is the
/// per-item seen marker driving the bell badge and arc-strip dots — null
/// means unseen. Seen state is per-device and never synced (spec §9.5).
class ReleaseEntries extends Table {
  TextColumn get infohash => text()();
  TextColumn get title => text()();
  IntColumn get pubDateMs => integer().nullable()();
  TextColumn get variant => text().nullable()();
  BoolColumn get outdated => boolean().withDefault(const Constant(false))();
  TextColumn get fileName => text().nullable()();
  TextColumn get crc32 => text().nullable()();
  TextColumn get magnet => text().nullable()();
  IntColumn get firstSeenAtMs => integer()();
  IntColumn get seenAtMs => integer().nullable()();

  @override
  Set<Column> get primaryKey => {infohash};
}

/// Small key-value store for sync cursors/watermarks.
class SyncState extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    Arcs,
    Episodes,
    Sources,
    ProgressEntries,
    DownloadEntries,
    ReleaseEntries,
    SyncState,
  ],
  daos: [CatalogDao, ProgressDao, DownloadsDao, ReleasesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Opens the on-device database file.
  AppDatabase.open() : super(driftDatabase(name: 'grand_line'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.createTable(releaseEntries);
        },
      );
}

@DriftAccessor(tables: [Arcs, Episodes, Sources, SyncState])
class CatalogDao extends DatabaseAccessor<AppDatabase> with _$CatalogDaoMixin {
  CatalogDao(super.db);

  Future<String?> getSyncValue(String key) async {
    final row = await (select(syncState)..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setSyncValue(String key, String value) =>
      into(syncState).insertOnConflictUpdate(
          SyncStateCompanion.insert(key: key, value: value));

  Stream<String?> watchSyncValue(String key) =>
      (select(syncState)..where((s) => s.key.equals(key)))
          .watchSingleOrNull()
          .map((row) => row?.value);

  Stream<Map<String, String>> watchSyncValuesWithPrefix(String prefix) =>
      (select(syncState)..where((s) => s.key.like('$prefix%')))
          .watch()
          .map((rows) => {for (final r in rows) r.key: r.value});

  Future<int> countArcs() async {
    final row = await (selectOnly(arcs)..addColumns([arcs.part.count()])).getSingle();
    return row.read(arcs.part.count()) ?? 0;
  }

  /// A null [backdropUrl] means "unknown" and keeps any stored value.
  Future<void> upsertArc({
    required int part,
    required String saga,
    required String title,
    required String shortcode,
    String description = '',
    String mkvcode = '',
    String? backdropUrl,
  }) {
    return into(arcs).insertOnConflictUpdate(
      ArcsCompanion.insert(
        part: Value(part),
        saga: saga,
        title: title,
        shortcode: shortcode,
        description: Value(description),
        mkvcode: Value(mkvcode),
        backdropUrl: Value.absentIfNull(backdropUrl),
      ),
    );
  }

  Future<void> upsertEpisode({
    required int arcPart,
    required int number,
    String? title,
    String? mangaChapters,
    String? animeEpisodes,
    DateTime? released,
    int? durationSeconds,
  }) {
    return into(episodes).insertOnConflictUpdate(
      EpisodesCompanion.insert(
        arcPart: arcPart,
        number: number,
        title: Value(title),
        mangaChapters: Value(mangaChapters),
        animeEpisodes: Value(animeEpisodes),
        released: Value(released),
        durationSeconds: Value(durationSeconds),
      ),
    );
  }

  Future<void> upsertSource({
    required int arcPart,
    required int number,
    required String kind,
    required String variant,
    int quality = 0,
    String? pixeldrainId,
    String? crc32,
    String? fileName,
    int? sizeBytes,
    int updatedAtMs = 0,
  }) async {
    await into(sources).insert(
      SourcesCompanion.insert(
        arcPart: arcPart,
        number: number,
        kind: kind,
        variant: variant,
        quality: Value(quality),
        pixeldrainId: Value(pixeldrainId),
        crc32: Value(crc32),
        fileName: Value(fileName),
        sizeBytes: Value(sizeBytes),
        updatedAtMs: Value(updatedAtMs),
      ),
      onConflict: DoUpdate(
        (old) => SourcesCompanion(
          pixeldrainId: Value(pixeldrainId),
          crc32: Value(crc32),
          fileName: Value(fileName),
          sizeBytes: Value(sizeBytes),
          updatedAtMs: Value(updatedAtMs),
        ),
        target: [sources.arcPart, sources.number, sources.kind, sources.variant, sources.quality],
      ),
    );
  }

  /// Runs [action] atomically (used by the snapshot seeder).
  Future<T> runInTransaction<T>(Future<T> Function() action) => transaction(action);

  Stream<List<Arc>> watchArcs() =>
      (select(arcs)..orderBy([(a) => OrderingTerm.asc(a.part)])).watch();

  Stream<List<Episode>> watchAllEpisodes() => (select(episodes)
        ..orderBy([
          (e) => OrderingTerm.asc(e.arcPart),
          (e) => OrderingTerm.asc(e.number),
        ]))
      .watch();

  Stream<List<Episode>> watchEpisodesOfArc(int arcPart) => (select(episodes)
        ..where((e) => e.arcPart.equals(arcPart))
        ..orderBy([(e) => OrderingTerm.asc(e.number)]))
      .watch();

  Future<List<Source>> sourcesForEpisode(int arcPart, int number) => (select(sources)
        ..where((s) => s.arcPart.equals(arcPart) & s.number.equals(number)))
      .get();

  Stream<List<Source>> watchAllSources() => select(sources).watch();
}

@DriftAccessor(tables: [ProgressEntries])
class ProgressDao extends DatabaseAccessor<AppDatabase> with _$ProgressDaoMixin {
  ProgressDao(super.db);

  /// Most-recent-activity-wins apply (spec §8.4): the row is written iff the
  /// incoming client-stamped `updatedAtMs` is newer than the stored one.
  /// Mirrors the server RPC; idempotent and order-independent.
  Future<void> applyLww({
    required int arcPart,
    required int number,
    required int positionMs,
    required bool watched,
    required int updatedAtMs,
  }) async {
    // customInsert (not customStatement) so the write notifies the table's
    // watch streams — the home progress chips and the sync push trigger
    // both hang off watchAll().
    await customInsert(
      'INSERT INTO progress_entries (arc_part, number, position_ms, watched, updated_at_ms) '
      'VALUES (?, ?, ?, ?, ?) '
      'ON CONFLICT(arc_part, number) DO UPDATE SET '
      'position_ms = excluded.position_ms, watched = excluded.watched, '
      'updated_at_ms = excluded.updated_at_ms '
      'WHERE excluded.updated_at_ms > progress_entries.updated_at_ms',
      variables: [
        Variable(arcPart),
        Variable(number),
        Variable(positionMs),
        Variable(watched ? 1 : 0),
        Variable(updatedAtMs),
      ],
      updates: {progressEntries},
    );
  }

  Future<ProgressEntry?> get(int arcPart, int number) => (select(progressEntries)
        ..where((p) => p.arcPart.equals(arcPart) & p.number.equals(number)))
      .getSingleOrNull();

  Future<List<ProgressEntry>> all() => select(progressEntries).get();

  Stream<List<ProgressEntry>> watchAll() => select(progressEntries).watch();
}

@DriftAccessor(tables: [DownloadEntries])
class DownloadsDao extends DatabaseAccessor<AppDatabase> with _$DownloadsDaoMixin {
  DownloadsDao(super.db);

  Future<void> upsert({
    required int arcPart,
    required int number,
    int? sourceId,
    String? taskId,
    required String status,
    String? filePath,
    int? sizeBytes,
    required int updatedAtMs,
  }) {
    return into(downloadEntries).insertOnConflictUpdate(
      DownloadEntriesCompanion.insert(
        arcPart: arcPart,
        number: number,
        sourceId: Value(sourceId),
        taskId: Value(taskId),
        status: Value(status),
        filePath: Value(filePath),
        sizeBytes: Value(sizeBytes),
        updatedAtMs: updatedAtMs,
      ),
    );
  }

  /// Partial status update — unlike [upsert] it leaves the columns it isn't
  /// given untouched (so a status flip never nulls sourceId/taskId/filePath).
  Future<void> setStatus({
    required int arcPart,
    required int number,
    required String status,
    String? filePath,
    int? sizeBytes,
    required int updatedAtMs,
  }) {
    return (update(downloadEntries)
          ..where((d) => d.arcPart.equals(arcPart) & d.number.equals(number)))
        .write(DownloadEntriesCompanion(
      status: Value(status),
      filePath: filePath == null ? const Value.absent() : Value(filePath),
      sizeBytes: sizeBytes == null ? const Value.absent() : Value(sizeBytes),
      updatedAtMs: Value(updatedAtMs),
    ));
  }

  Future<DownloadEntry?> get(int arcPart, int number) => (select(downloadEntries)
        ..where((d) => d.arcPart.equals(arcPart) & d.number.equals(number)))
      .getSingleOrNull();

  Future<List<DownloadEntry>> all() => select(downloadEntries).get();

  Future<void> remove(int arcPart, int number) => (delete(downloadEntries)
        ..where((d) => d.arcPart.equals(arcPart) & d.number.equals(number)))
      .go();

  Stream<List<DownloadEntry>> watchAll() => select(downloadEntries).watch();
}

@DriftAccessor(tables: [ReleaseEntries])
class ReleasesDao extends DatabaseAccessor<AppDatabase> with _$ReleasesDaoMixin {
  ReleasesDao(super.db);

  /// Upsert from a backend fetch. On conflict the feed fields refresh but
  /// `seenAtMs` is left alone — seen state is local and survives refetches;
  /// [seenAtMs] only lands when the row is first inserted.
  Future<void> upsertFetched({
    required String infohash,
    required String title,
    int? pubDateMs,
    String? variant,
    bool outdated = false,
    String? fileName,
    String? crc32,
    String? magnet,
    required int firstSeenAtMs,
    int? seenAtMs,
  }) {
    return into(releaseEntries).insert(
      ReleaseEntriesCompanion.insert(
        infohash: infohash,
        title: title,
        pubDateMs: Value(pubDateMs),
        variant: Value(variant),
        outdated: Value(outdated),
        fileName: Value(fileName),
        crc32: Value(crc32),
        magnet: Value(magnet),
        firstSeenAtMs: firstSeenAtMs,
        seenAtMs: Value(seenAtMs),
      ),
      onConflict: DoUpdate(
        (old) => ReleaseEntriesCompanion(
          title: Value(title),
          pubDateMs: Value(pubDateMs),
          variant: Value(variant),
          outdated: Value(outdated),
          fileName: Value(fileName),
          crc32: Value(crc32),
          magnet: Value(magnet),
        ),
        target: [releaseEntries.infohash],
      ),
    );
  }

  Future<List<ReleaseEntry>> all() => select(releaseEntries).get();

  /// Newest first, by publication date with first-seen as tiebreak/fallback.
  Stream<List<ReleaseEntry>> watchAll() => (select(releaseEntries)
        ..orderBy([
          (r) => OrderingTerm.desc(
              coalesce([r.pubDateMs, r.firstSeenAtMs])),
          (r) => OrderingTerm.desc(r.firstSeenAtMs),
        ]))
      .watch();

  Future<void> markAllSeen(int nowMs) =>
      (update(releaseEntries)..where((r) => r.seenAtMs.isNull()))
          .write(ReleaseEntriesCompanion(seenAtMs: Value(nowMs)));

  /// CRC32s are compared uppercased — the RSS and the catalog snapshot don't
  /// agree on casing.
  Future<void> markSeenByCrc32s(Set<String> crc32s, int nowMs) {
    final upper = [for (final c in crc32s) c.toUpperCase()];
    return (update(releaseEntries)
          ..where((r) => r.seenAtMs.isNull() & r.crc32.upper().isIn(upper)))
        .write(ReleaseEntriesCompanion(seenAtMs: Value(nowMs)));
  }
}

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
}
