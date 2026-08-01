import 'package:flutter/services.dart' show rootBundle;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../db/database.dart';
import 'snapshot.dart';

part 'snapshot_seeder.g.dart';

/// Seeds an empty catalog from the vendored snapshot so first launch works
/// offline (spec §2.2). No-op when arcs already exist; catalog sync (step 6)
/// keeps the data fresh afterwards.
Future<void> ensureSeeded(
  AppDatabase db, {
  Future<String> Function(String path)? loadAsset,
}) async {
  final dao = db.catalogDao;
  if (await dao.countArcs() > 0) return;

  loadAsset ??= rootBundle.loadString;
  final snapshot = CatalogSnapshot.parse(
    arcsJson: await loadAsset('assets/catalog/arcs.json'),
    episodesJson: await loadAsset('assets/catalog/episodes.json'),
    descriptionsJson: await loadAsset('assets/catalog/descriptions.json'),
  );

  await dao.runInTransaction(() async {
    for (final arc in snapshot.arcs) {
      await dao.upsertArc(
        part: arc.part,
        saga: arc.saga,
        title: arc.title,
        shortcode: arc.shortcode,
        description: arc.description,
        mkvcode: arc.mkvcode,
      );
    }
    for (final ep in snapshot.episodes) {
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
    for (final source in snapshot.downloadSources) {
      await dao.upsertSource(
        arcPart: source.arcPart,
        number: source.number,
        kind: 'download',
        variant: source.variant,
        crc32: source.crc32,
        fileName: source.fileName,
        sizeBytes: source.sizeBytes,
      );
    }
  });
}

/// The app database, seeded. UI layers await this instead of [appDatabase].
@Riverpod(keepAlive: true)
Future<AppDatabase> seededDatabase(Ref ref) async {
  final db = ref.watch(appDatabaseProvider);
  await ensureSeeded(db);
  return db;
}
