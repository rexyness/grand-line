import 'package:flutter_test/flutter_test.dart';
import 'package:grand_line/data/db/database.dart';
import 'package:grand_line/features/releases/releases_model.dart';

Arc arc(int part, {String title = 'Arc'}) => Arc(
      part: part,
      saga: 'Saga',
      title: title,
      shortcode: 'A$part',
      description: '',
      mkvcode: '',
    );

Episode episode(int arcPart, int number) =>
    Episode(arcPart: arcPart, number: number, title: 'E$number title');

Source mkvSource(int arcPart, int number, String crc32) => Source(
      id: arcPart * 100 + number,
      arcPart: arcPart,
      number: number,
      kind: 'download',
      variant: 'standard',
      quality: 0,
      crc32: crc32,
      updatedAtMs: 0,
    );

ReleaseEntry release(
  String infohash, {
  String? crc32,
  int? pubDateMs,
  int firstSeenAtMs = 0,
  int? seenAtMs,
  bool outdated = false,
}) =>
    ReleaseEntry(
      infohash: infohash,
      title: 'One Pace release $infohash',
      pubDateMs: pubDateMs,
      outdated: outdated,
      crc32: crc32,
      firstSeenAtMs: firstSeenAtMs,
      seenAtMs: seenAtMs,
    );

void main() {
  final arcs = [arc(1), arc(2)];
  final episodes = [episode(1, 1), episode(1, 2), episode(2, 1)];
  final sources = [
    mkvSource(1, 1, 'AAAA1111'),
    mkvSource(1, 2, 'BBBB2222'),
    mkvSource(2, 1, 'CCCC3333'),
  ];

  test('labels the earliest release per episode as new, later as updated', () {
    final views = buildReleaseViews(
      releases: [
        release('h1', crc32: 'AAAA1111', pubDateMs: 100),
        release('h2', crc32: 'aaaa1111', pubDateMs: 200), // re-release, lowercase crc
        release('h3', crc32: 'BBBB2222', pubDateMs: 150),
      ],
      sources: sources,
      episodes: episodes,
      arcs: arcs,
    );

    // Newest first.
    expect([for (final v in views) v.release.infohash], ['h2', 'h3', 'h1']);
    final byHash = {for (final v in views) v.release.infohash: v};
    expect(byHash['h1']!.kind, ReleaseKind.newEpisode);
    expect(byHash['h2']!.kind, ReleaseKind.updatedRelease);
    expect(byHash['h3']!.kind, ReleaseKind.newEpisode);
    expect(byHash['h2']!.episode?.number, 1);
    expect(byHash['h2']!.arc?.part, 1);
  });

  test('rows without a catalog match are unmatched and unlinked', () {
    final views = buildReleaseViews(
      releases: [
        release('h1', crc32: 'ZZZZ9999', pubDateMs: 100),
        release('h2', pubDateMs: 200),
      ],
      sources: sources,
      episodes: episodes,
      arcs: arcs,
    );
    expect(views, hasLength(2));
    expect(views.every((v) => v.kind == ReleaseKind.unmatched), isTrue);
    expect(views.every((v) => v.episode == null && v.arc == null), isTrue);
  });

  test('falls back to firstSeenAt when the RSS row has no pub date', () {
    final views = buildReleaseViews(
      releases: [
        release('h1', crc32: 'AAAA1111', pubDateMs: null, firstSeenAtMs: 500),
        release('h2', crc32: 'BBBB2222', pubDateMs: 100),
      ],
      sources: sources,
      episodes: episodes,
      arcs: arcs,
    );
    expect([for (final v in views) v.release.infohash], ['h1', 'h2']);
    expect(views.first.whenMs, 500);
  });

  test('unseenArcParts collects arcs with unseen matched releases only', () {
    final views = buildReleaseViews(
      releases: [
        release('h1', crc32: 'AAAA1111', pubDateMs: 100), // unseen, arc 1
        release('h2', crc32: 'CCCC3333', pubDateMs: 100, seenAtMs: 1), // seen
        release('h3', crc32: 'ZZZZ9999', pubDateMs: 100), // unseen, unmatched
      ],
      sources: sources,
      episodes: episodes,
      arcs: arcs,
    );
    expect(unseenArcParts(views), {1});
  });
}
