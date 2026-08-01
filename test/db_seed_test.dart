import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grand_line/data/catalog/snapshot.dart';
import 'package:grand_line/data/catalog/snapshot_seeder.dart';
import 'package:grand_line/data/db/database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<String> loadFromRepo(String path) => File(path).readAsString();

  group('snapshot seeding', () {
    test('seeds arcs, episodes, and MKV download sources from vendored assets',
        () async {
      await ensureSeeded(db, loadAsset: loadFromRepo);

      final arcs = await db.catalogDao.watchArcs().first;
      expect(arcs.length, greaterThanOrEqualTo(30));
      expect(arcs.first.part, 0);
      expect(arcs.map((a) => a.title), contains('Romance Dawn'));

      final romanceDawn = arcs.firstWhere((a) => a.title == 'Romance Dawn');
      final episodes =
          await db.catalogDao.watchEpisodesOfArc(romanceDawn.part).first;
      expect(episodes, isNotEmpty);

      final sources = await db.catalogDao
          .sourcesForEpisode(romanceDawn.part, episodes.first.number);
      expect(sources, isNotEmpty);
      final mkv = sources.firstWhere((s) => s.kind == 'download');
      expect(mkv.crc32, isNotNull);
      expect(mkv.variant, anyOf('standard', 'extended'));
    });

    test('is idempotent — second run does not duplicate', () async {
      await ensureSeeded(db, loadAsset: loadFromRepo);
      final before = await db.catalogDao.countArcs();
      await ensureSeeded(db, loadAsset: loadFromRepo);
      expect(await db.catalogDao.countArcs(), before);
    });
  });

  group('progress LWW', () {
    test('newer timestamp wins, older is ignored', () async {
      final dao = db.progressDao;
      await dao.applyLww(
          arcPart: 1, number: 1, positionMs: 1000, watched: false, updatedAtMs: 200);
      await dao.applyLww(
          arcPart: 1, number: 1, positionMs: 500, watched: true, updatedAtMs: 100);

      var row = await dao.get(1, 1);
      expect(row!.positionMs, 1000);
      expect(row.watched, false);

      await dao.applyLww(
          arcPart: 1, number: 1, positionMs: 0, watched: true, updatedAtMs: 300);
      row = await dao.get(1, 1);
      expect(row!.positionMs, 0);
      expect(row.watched, true);
    });
  });

  group('parseHumanSize', () {
    test('parses upstream size strings', () {
      expect(parseHumanSize('789.0 MiB'), (789.0 * 1048576).round());
      expect(parseHumanSize('1.1 GiB'), (1.1 * 1073741824).round());
      expect(parseHumanSize('512 B'), 512);
      expect(parseHumanSize('garbage'), isNull);
      expect(parseHumanSize(null), isNull);
    });
  });
}
