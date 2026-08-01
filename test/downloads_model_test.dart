import 'package:flutter_test/flutter_test.dart';
import 'package:grand_line/data/db/database.dart';
import 'package:grand_line/data/downloads/download_service.dart';
import 'package:grand_line/features/downloads/downloads_model.dart';

DownloadEntry entry({
  required int arcPart,
  required int number,
  required String status,
  int? sizeBytes,
  int updatedAtMs = 0,
}) =>
    DownloadEntry(
      arcPart: arcPart,
      number: number,
      status: status,
      sizeBytes: sizeBytes,
      updatedAtMs: updatedAtMs,
    );

Arc arc(int part, String title) => Arc(
      part: part,
      saga: 'Saga',
      title: title,
      shortcode: 'a$part',
      description: '',
      mkvcode: '',
    );

Episode episode(int arcPart, int number, {String? title}) =>
    Episode(arcPart: arcPart, number: number, title: title);

Source source({
  required int id,
  required String kind,
  required String variant,
  String? pixeldrainId,
  int? sizeBytes,
}) =>
    Source(
      id: id,
      arcPart: 1,
      number: 1,
      kind: kind,
      variant: variant,
      quality: 0,
      pixeldrainId: pixeldrainId,
      sizeBytes: sizeBytes,
      updatedAtMs: 0,
    );

void main() {
  group('buildDownloadsView', () {
    test('splits queue from library and keeps queue FIFO by enqueue time', () {
      final view = buildDownloadsView(
        entries: [
          entry(arcPart: 1, number: 2, status: 'queued', updatedAtMs: 30),
          entry(arcPart: 1, number: 1, status: 'running', updatedAtMs: 10),
          entry(
              arcPart: 2,
              number: 1,
              status: 'complete',
              sizeBytes: 500,
              updatedAtMs: 20),
        ],
        arcs: [arc(1, 'Romance Dawn'), arc(2, 'Orange Town')],
        episodes: [
          episode(1, 1),
          episode(1, 2),
          episode(2, 1, title: 'Buggy'),
        ],
      );

      expect(view.queue.map((q) => q.entry.number), [1, 2]);
      expect(view.queue.first.isRunning, isTrue);
      expect(view.library.single.title, 'Orange Town');
      expect(view.library.single.items.single.label, 'Ep 1 · Buggy');
      expect(view.totalBytes, 500);
      expect(view.anythingRunning, isTrue);
    });

    test('groups library by arc in voyage order with summed sizes', () {
      final view = buildDownloadsView(
        entries: [
          entry(arcPart: 3, number: 1, status: 'complete', sizeBytes: 100),
          entry(arcPart: 1, number: 2, status: 'complete', sizeBytes: 200),
          entry(arcPart: 1, number: 1, status: 'complete', sizeBytes: 300),
        ],
        arcs: [arc(1, 'Romance Dawn'), arc(3, 'Syrup Village')],
        episodes: const [],
      );

      expect(view.library.map((a) => a.arcPart), [1, 3]);
      expect(view.library.first.items.map((i) => i.entry.number), [1, 2]);
      expect(view.library.first.totalBytes, 500);
      expect(view.totalBytes, 600);
    });
  });

  group('chooseDownloadSource', () {
    test('prefers the standard variant and requires a pixeldrain id', () {
      final chosen = chooseDownloadSource([
        source(id: 1, kind: 'stream', variant: 'ensub', pixeldrainId: 'x'),
        source(id: 2, kind: 'download', variant: 'extended', pixeldrainId: 'y'),
        source(id: 3, kind: 'download', variant: 'standard', pixeldrainId: 'z'),
        source(id: 4, kind: 'download', variant: 'standard'),
      ]);
      expect(chosen?.id, 3);
    });

    test('falls back to any downloadable variant, null when none', () {
      expect(
        chooseDownloadSource([
          source(id: 1, kind: 'download', variant: 'extended', pixeldrainId: 'y'),
        ])?.id,
        1,
      );
      expect(
        chooseDownloadSource([
          source(id: 1, kind: 'download', variant: 'standard'),
          source(id: 2, kind: 'stream', variant: 'ensub', pixeldrainId: 'x'),
        ]),
        isNull,
      );
    });
  });

  group('episode key round-trip', () {
    test('taskIdFor and episodeKeyOf invert each other', () {
      expect(DownloadService.episodeKeyOf(DownloadService.taskIdFor(12, 3)),
          (12, 3));
      expect(DownloadService.episodeKeyOf('not-a-task'), isNull);
    });
  });

  group('formatBytes', () {
    test('formats across magnitudes', () {
      expect(formatBytes(0), '—');
      expect(formatBytes(999), '999 B');
      expect(formatBytes(1500), '1.5 KB');
      expect(formatBytes(850 * 1000 * 1000), '850 MB');
      expect(formatBytes(1400 * 1000 * 1000), '1.4 GB');
    });
  });
}
