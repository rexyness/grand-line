import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../db/database.dart';
import '../sync/supabase_backend.dart';
import 'catalog_backend.dart';
import 'snapshot_seeder.dart';

part 'catalog_repository.g.dart';

/// Keeps the local catalog fresh from the backend (spec §6.4): refresh on
/// launch + manual pull-to-refresh, no background polling. With no backend
/// configured the app runs local-only off the vendored snapshot.
class CatalogRepository {
  CatalogRepository(this._db, this._backend);

  final AppDatabase _db;
  final CatalogBackend? _backend;

  static const _arcsCursor = 'catalog.arcs.watermark';
  static const _episodesCursor = 'catalog.episodes.watermark';
  static const _sourcesCursor = 'catalog.sources.watermark';

  /// Pulls rows changed since the stored per-table watermarks and advances
  /// them to the newest `updated_at` seen. Returns the number of rows applied
  /// (0 for a quiet refresh or when no backend is configured).
  Future<int> refresh() async {
    final backend = _backend;
    if (backend == null) return 0;
    final dao = _db.catalogDao;
    var applied = 0;

    final arcs = await backend.arcsSince(await _cursor(_arcsCursor));
    for (final arc in arcs) {
      await dao.upsertArc(
        part: arc.part,
        saga: arc.saga,
        title: arc.title,
        shortcode: arc.shortcode,
        description: arc.description,
        mkvcode: arc.mkvcode,
        backdropUrl: arc.backdropUrl,
      );
    }
    applied += arcs.length;
    await _advance(_arcsCursor, arcs.map((a) => a.updatedAt));

    final episodes = await backend.episodesSince(await _cursor(_episodesCursor));
    for (final ep in episodes) {
      await dao.upsertEpisode(
        arcPart: ep.arcPart,
        number: ep.number,
        title: ep.title,
        mangaChapters: ep.mangaChapters,
        animeEpisodes: ep.animeEpisodes,
        released: ep.released,
        durationSeconds: ep.durationSeconds,
      );
    }
    applied += episodes.length;
    await _advance(_episodesCursor, episodes.map((e) => e.updatedAt));

    final sources = await backend.sourcesSince(await _cursor(_sourcesCursor));
    for (final s in sources) {
      await dao.upsertSource(
        arcPart: s.arcPart,
        number: s.number,
        kind: s.kind,
        variant: s.variant,
        quality: s.quality,
        pixeldrainId: s.pixeldrainId,
        crc32: s.crc32,
        fileName: s.fileName,
        sizeBytes: s.sizeBytes,
        updatedAtMs: s.updatedAt.millisecondsSinceEpoch,
      );
    }
    applied += sources.length;
    await _advance(_sourcesCursor, sources.map((s) => s.updatedAt));

    return applied;
  }

  Future<DateTime?> _cursor(String key) async {
    final value = await _db.catalogDao.getSyncValue(key);
    return value == null ? null : DateTime.parse(value);
  }

  Future<void> _advance(String key, Iterable<DateTime> seen) async {
    if (seen.isEmpty) return;
    final max = seen.reduce((a, b) => a.isAfter(b) ? a : b);
    await _db.catalogDao.setSyncValue(key, max.toUtc().toIso8601String());
  }
}

@Riverpod(keepAlive: true)
Future<CatalogRepository> catalogRepository(Ref ref) async {
  final db = await ref.watch(seededDatabaseProvider.future);
  return CatalogRepository(db, ref.watch(catalogBackendProvider));
}
