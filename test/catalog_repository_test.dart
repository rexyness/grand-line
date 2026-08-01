import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grand_line/data/catalog/catalog_backend.dart';
import 'package:grand_line/data/catalog/catalog_repository.dart';
import 'package:grand_line/data/db/database.dart';

class FakeBackend implements CatalogBackend {
  final arcs = <RemoteArc>[];
  final episodes = <RemoteEpisode>[];
  final sources = <RemoteSource>[];
  final requestedCursors = <DateTime?>[];

  @override
  Future<List<RemoteArc>> arcsSince(DateTime? since) async {
    requestedCursors.add(since);
    return arcs
        .where((a) => since == null || !a.updatedAt.isBefore(since))
        .toList();
  }

  @override
  Future<List<RemoteEpisode>> episodesSince(DateTime? since) async => episodes
      .where((e) => since == null || !e.updatedAt.isBefore(since))
      .toList();

  @override
  Future<List<RemoteSource>> sourcesSince(DateTime? since) async => sources
      .where((s) => since == null || !s.updatedAt.isBefore(since))
      .toList();
}

void main() {
  late AppDatabase db;
  late FakeBackend backend;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    backend = FakeBackend();
  });
  tearDown(() => db.close());

  final t1 = DateTime.utc(2026, 8, 1, 12);
  final t2 = DateTime.utc(2026, 8, 2, 12);

  RemoteArc arc(int part, DateTime at, {String? backdrop}) => RemoteArc(
        part: part,
        saga: 'East Blue',
        title: 'Arc $part',
        shortcode: 'A$part',
        description: '',
        mkvcode: '',
        backdropUrl: backdrop,
        updatedAt: at,
      );

  test('refresh applies rows and advances the watermark', () async {
    backend.arcs.add(arc(1, t1, backdrop: 'https://x/1.jpg'));
    backend.episodes.add(RemoteEpisode(arcPart: 1, number: 1, updatedAt: t1));
    backend.sources.add(RemoteSource(
      arcPart: 1,
      number: 1,
      kind: 'stream',
      variant: 'ensub',
      quality: 1080,
      pixeldrainId: 'abc',
      updatedAt: t1,
    ));

    final repo = CatalogRepository(db, backend);
    expect(await repo.refresh(), 3);
    expect(backend.requestedCursors, [null]);

    final arcs = await db.catalogDao.watchArcs().first;
    expect(arcs.single.backdropUrl, 'https://x/1.jpg');
    final sources = await db.catalogDao.sourcesForEpisode(1, 1);
    expect(sources.single.pixeldrainId, 'abc');

    // Second refresh sends the stored watermark; boundary row re-applies.
    expect(await repo.refresh(), 3);
    expect(backend.requestedCursors[1], t1);
  });

  test('newer rows update in place; null backdrop keeps the stored one',
      () async {
    backend.arcs.add(arc(1, t1, backdrop: 'https://x/1.jpg'));
    final repo = CatalogRepository(db, backend);
    await repo.refresh();

    backend.arcs
      ..clear()
      ..add(arc(1, t2));
    await repo.refresh();

    final arcs = await db.catalogDao.watchArcs().first;
    expect(arcs.single.backdropUrl, 'https://x/1.jpg');
  });

  test('no backend configured means a quiet no-op', () async {
    final repo = CatalogRepository(db, null);
    expect(await repo.refresh(), 0);
  });
}
