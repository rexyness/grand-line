import 'package:flutter_test/flutter_test.dart';
import 'package:grand_line/data/db/database.dart';
import 'package:grand_line/features/home/home_model.dart';

Arc arc(int part) => Arc(
      part: part,
      saga: 'East Blue',
      title: 'Arc $part',
      shortcode: 'A$part',
      description: '',
      mkvcode: '',
      backdropUrl: null,
    );

Episode episode(int part, int number) => Episode(
      arcPart: part,
      number: number,
      title: null,
      mangaChapters: null,
      animeEpisodes: null,
      released: null,
      durationSeconds: null,
    );

ProgressEntry progress(int part, int number,
        {int positionMs = 0, bool watched = false, int updatedAtMs = 1}) =>
    ProgressEntry(
      arcPart: part,
      number: number,
      positionMs: positionMs,
      watched: watched,
      updatedAtMs: updatedAtMs,
    );

void main() {
  test('resumeTarget prefers in-progress, then first unwatched', () {
    final views = buildArcViews(
      arcs: [arc(1)],
      episodes: [episode(1, 1), episode(1, 2), episode(1, 3)],
      progress: [
        progress(1, 1, watched: true),
        progress(1, 2, positionMs: 60000),
      ],
      downloads: [],
    );
    expect(views.single.resumeTarget!.number, 2);
    expect(views.single.started, true);
    expect(views.single.watchedCount, 1);

    final fresh = buildArcViews(
      arcs: [arc(1)],
      episodes: [episode(1, 1), episode(1, 2)],
      progress: [progress(1, 1, watched: true)],
      downloads: [],
    );
    expect(fresh.single.resumeTarget!.number, 2);

    final untouched = buildArcViews(
      arcs: [arc(1)],
      episodes: [episode(1, 1)],
      progress: [],
      downloads: [],
    );
    expect(untouched.single.resumeTarget!.number, 1);
    expect(untouched.single.started, false);
  });

  test('only complete downloads count as offline', () {
    final views = buildArcViews(
      arcs: [arc(1)],
      episodes: [episode(1, 1), episode(1, 2)],
      progress: [],
      downloads: [
        DownloadEntry(
            arcPart: 1, number: 1, status: 'complete', updatedAtMs: 1),
        DownloadEntry(arcPart: 1, number: 2, status: 'running', updatedAtMs: 1),
      ],
    );
    expect(views.single.downloadedCount, 1);
    expect(views.single.episodes[0].downloaded, true);
    expect(views.single.episodes[1].downloaded, false);
  });

  test('initialFocusPart: newest activity wins, else first non-special arc',
      () {
    final views = buildArcViews(
      arcs: [arc(0), arc(1), arc(2)],
      episodes: [episode(0, 1), episode(1, 1), episode(2, 1)],
      progress: [
        progress(1, 1, updatedAtMs: 100),
        progress(2, 1, updatedAtMs: 200),
      ],
      downloads: [],
    );
    expect(initialFocusPart(views), 2);

    final untouched = buildArcViews(
      arcs: [arc(0), arc(1), arc(2)],
      episodes: [],
      progress: [],
      downloads: [],
    );
    expect(initialFocusPart(untouched), 1, reason: 'skips Specials (part 0)');
  });
}
