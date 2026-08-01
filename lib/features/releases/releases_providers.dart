import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/catalog/snapshot_seeder.dart';
import '../../data/db/database.dart';
import '../home/home_providers.dart';
import 'releases_model.dart';

// Manual providers, like home_providers.dart (riverpod_generator can't
// express these stream providers).

final releasesStreamProvider = StreamProvider<List<ReleaseEntry>>((ref) async* {
  final db = await ref.watch(seededDatabaseProvider.future);
  yield* db.releasesDao.watchAll();
});

final sourcesStreamProvider = StreamProvider<List<Source>>((ref) async* {
  final db = await ref.watch(seededDatabaseProvider.future);
  yield* db.catalogDao.watchAllSources();
});

/// The assembled release list — recomputes whenever the feed or catalog
/// changes.
final releaseViewsProvider = FutureProvider<List<ReleaseView>>((ref) async {
  return buildReleaseViews(
    releases: await ref.watch(releasesStreamProvider.future),
    sources: await ref.watch(sourcesStreamProvider.future),
    episodes: await ref.watch(episodesStreamProvider.future),
    arcs: await ref.watch(arcsStreamProvider.future),
  );
});

/// Bell badge count. 0 while loading — the badge just stays hidden for the
/// first frames.
final unseenReleaseCountProvider = Provider<int>((ref) {
  final releases = ref.watch(releasesStreamProvider).value;
  return releases?.where((r) => r.seenAtMs == null).length ?? 0;
});

/// Arc parts that get an unseen-dot on the arc strip.
final unseenArcPartsProvider = Provider<Set<int>>((ref) {
  final views = ref.watch(releaseViewsProvider).value;
  return views == null ? const <int>{} : unseenArcParts(views);
});
