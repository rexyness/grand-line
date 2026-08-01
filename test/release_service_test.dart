import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grand_line/data/db/database.dart';
import 'package:grand_line/data/releases/release_service.dart';
import 'package:grand_line/data/releases/releases_backend.dart';

class FakeReleasesBackend implements ReleasesBackend {
  List<RemoteRelease> rows = [];
  int fetches = 0;

  @override
  Future<List<RemoteRelease>> fetchAll() async {
    fetches++;
    return rows;
  }
}

RemoteRelease remote(String infohash, {String? crc32, bool outdated = false}) =>
    RemoteRelease(
      infohash: infohash,
      title: 'Release $infohash',
      pubDate: DateTime.utc(2026, 7, 1),
      outdated: outdated,
      crc32: crc32,
      firstSeenAt: DateTime.utc(2026, 7, 1),
    );

void main() {
  late AppDatabase db;
  late FakeReleasesBackend backend;
  late ReleaseService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    backend = FakeReleasesBackend();
    service = ReleaseService(db, backend, checkThrottle: Duration.zero);
  });

  tearDown(() => db.close());

  Future<Map<String, ReleaseEntry>> local() async =>
      {for (final r in await db.releasesDao.all()) r.infohash: r};

  test('first check baselines the backlog as seen', () async {
    backend.rows = [remote('h1'), remote('h2')];
    expect(await service.check(), 0);
    final rows = await local();
    expect(rows, hasLength(2));
    expect(rows.values.every((r) => r.seenAtMs != null), isTrue);
  });

  test('rows arriving after the baseline land unseen', () async {
    backend.rows = [remote('h1')];
    await service.check();
    backend.rows = [remote('h1'), remote('h2')];
    expect(await service.check(), 1);
    final rows = await local();
    expect(rows['h1']!.seenAtMs, isNotNull);
    expect(rows['h2']!.seenAtMs, isNull);
  });

  test('refetches update feed fields but preserve seen state', () async {
    backend.rows = [remote('h1')];
    await service.check();
    backend.rows = [remote('h1', outdated: true), remote('h2')];
    await service.check();
    backend.rows = [remote('h1', outdated: true), remote('h2')];
    expect(await service.check(), 0, reason: 'h2 is already known');
    final rows = await local();
    expect(rows['h1']!.outdated, isTrue);
    expect(rows['h1']!.seenAtMs, isNotNull);
    expect(rows['h2']!.seenAtMs, isNull, reason: 'still unseen until marked');
  });

  test('checks are throttled', () async {
    final throttled =
        ReleaseService(db, backend, checkThrottle: const Duration(hours: 1));
    await throttled.check();
    await throttled.check();
    expect(backend.fetches, 1);
    await throttled.check(force: true);
    expect(backend.fetches, 2);
  });

  test('markAllSeen clears every unseen row', () async {
    backend.rows = [remote('h1')];
    await service.check();
    backend.rows = [remote('h1'), remote('h2'), remote('h3')];
    await service.check();
    await service.markAllSeen();
    final rows = await local();
    expect(rows.values.every((r) => r.seenAtMs != null), isTrue);
  });

  test('markEpisodeSeen joins case-insensitively via the MKV CRC32', () async {
    await db.catalogDao.upsertArc(
        part: 1, saga: 'S', title: 'Arc', shortcode: 'A1');
    await db.catalogDao.upsertEpisode(arcPart: 1, number: 3);
    await db.catalogDao.upsertSource(
        arcPart: 1,
        number: 3,
        kind: 'download',
        variant: 'standard',
        crc32: 'AAAA1111');

    backend.rows = [];
    await service.check(); // baseline
    backend.rows = [
      remote('h1', crc32: 'aaaa1111'),
      remote('h2', crc32: 'BBBB2222'),
    ];
    await service.check();

    await service.markEpisodeSeen(1, 3);
    final rows = await local();
    expect(rows['h1']!.seenAtMs, isNotNull);
    expect(rows['h2']!.seenAtMs, isNull);
  });

  test('local-only build (no backend) is a quiet no-op', () async {
    final localOnly = ReleaseService(db, null);
    expect(localOnly.available, isFalse);
    expect(await localOnly.check(), 0);
  });
}
