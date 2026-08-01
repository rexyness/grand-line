import 'package:flutter_test/flutter_test.dart';
import 'package:grand_line/data/db/database.dart';
import 'package:grand_line/features/home/home_model.dart';
import 'package:grand_line/features/search/search_model.dart';

ArcView arcView(int part, String saga, String title, List<String?> episodeTitles) =>
    ArcView(
      arc: Arc(
        part: part,
        saga: saga,
        title: title,
        shortcode: 'A$part',
        description: '',
        mkvcode: '',
      ),
      episodes: [
        for (final (i, t) in episodeTitles.indexed)
          EpisodeView(
            episode: Episode(arcPart: part, number: i + 1, title: t),
            watched: false,
            positionMs: 0,
            downloaded: false,
          ),
      ],
      lastActivityMs: 0,
    );

void main() {
  final views = [
    arcView(1, 'East Blue', 'Romance Dawn', ['Roronoa Zoro', 'Morgan']),
    arcView(2, 'East Blue', 'Orange Town', ['Buggy the Clown']),
    arcView(31, 'Whole Cake Island', 'Whole Cake Island', ['Pudding']),
  ];

  test('empty query returns nothing', () {
    expect(searchCatalog(views, '  ').isEmpty, isTrue);
  });

  test('arcs match on title and saga', () {
    expect([for (final v in searchCatalog(views, 'orange').arcs) v.arc.part],
        [2]);
    expect(
        [for (final v in searchCatalog(views, 'east blue').arcs) v.arc.part],
        [1, 2]);
  });

  test('episodes match on their title, case-insensitively', () {
    final results = searchCatalog(views, 'zoro');
    expect(results.arcs, isEmpty);
    expect(results.episodes, hasLength(1));
    final (arc, episode) = results.episodes.single;
    expect(arc.arc.part, 1);
    expect(episode.number, 1);
  });

  test('E-number queries match episode numbers across arcs', () {
    final results = searchCatalog(views, 'E2');
    expect([for (final (a, e) in results.episodes) (a.arc.part, e.number)],
        [(1, 2)]);
    expect(searchCatalog(views, '1').episodes, hasLength(3),
        reason: 'bare number matches E1 in every arc');
  });

  test('results are capped', () {
    final many = [
      for (var part = 1; part <= 60; part++)
        arcView(part, 'Saga', 'Arc cap', ['Cap episode']),
    ];
    final results = searchCatalog(many, 'cap');
    expect(results.arcs, hasLength(searchArcLimit));
    expect(results.episodes, hasLength(searchEpisodeLimit));
  });
}
