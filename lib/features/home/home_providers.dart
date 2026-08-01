import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/catalog/catalog_repository.dart';
import '../../data/catalog/snapshot_seeder.dart';
import '../../data/db/database.dart';
import 'home_model.dart';

// Providers here are declared manually: riverpod_generator 3.0.3 (newest
// compatible with Dart 3.10) throws InvalidTypeException on this file's
// stream providers. Codegen remains in use in data/.

final arcsStreamProvider = StreamProvider<List<Arc>>((ref) async* {
  final db = await ref.watch(seededDatabaseProvider.future);
  yield* db.catalogDao.watchArcs();
});

final episodesStreamProvider = StreamProvider<List<Episode>>((ref) async* {
  final db = await ref.watch(seededDatabaseProvider.future);
  yield* db.catalogDao.watchAllEpisodes();
});

final progressStreamProvider =
    StreamProvider<List<ProgressEntry>>((ref) async* {
  final db = await ref.watch(seededDatabaseProvider.future);
  yield* db.progressDao.watchAll();
});

final downloadsStreamProvider =
    StreamProvider<List<DownloadEntry>>((ref) async* {
  final db = await ref.watch(seededDatabaseProvider.future);
  yield* db.downloadsDao.watchAll();
});

/// The assembled home view — recomputes whenever any underlying table
/// changes.
final arcViewsProvider = FutureProvider<List<ArcView>>((ref) async {
  return buildArcViews(
    arcs: await ref.watch(arcsStreamProvider.future),
    episodes: await ref.watch(episodesStreamProvider.future),
    progress: await ref.watch(progressStreamProvider.future),
    downloads: await ref.watch(downloadsStreamProvider.future),
  );
});

/// The focused arc `part`. Null until the user picks or the initial focus
/// (newest activity) is applied by the screen.
final focusedArcPartProvider =
    NotifierProvider<FocusedArcPart, int?>(FocusedArcPart.new);

class FocusedArcPart extends Notifier<int?> {
  @override
  int? build() => null;

  void focus(int part) => state = part;
}

/// Launch catalog refresh (spec §6.4): fire-and-forget once per app run;
/// re-invoked manually from the overflow menu. Errors are swallowed — the
/// app keeps serving the local catalog.
final launchRefreshProvider = FutureProvider<int>((ref) async {
  try {
    final repo = await ref.watch(catalogRepositoryProvider.future);
    return await repo.refresh();
  } catch (_) {
    return 0;
  }
});
