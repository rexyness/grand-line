import 'package:flutter_test/flutter_test.dart';
import 'package:grand_line/data/db/database.dart';
import 'package:grand_line/features/player/player_model.dart';

Source source({
  required String kind,
  required String variant,
  int quality = 0,
  String? pixeldrainId,
}) =>
    Source(
      id: 0,
      arcPart: 1,
      number: 1,
      kind: kind,
      variant: variant,
      quality: quality,
      pixeldrainId: pixeldrainId,
      crc32: null,
      fileName: null,
      sizeBytes: null,
      updatedAtMs: 0,
    );

void main() {
  test('completed download wins over streaming', () {
    final result = choosePlaySource(
      sources: [
        source(kind: 'stream', variant: 'ensub', quality: 1080, pixeldrainId: 'a'),
      ],
      download: const DownloadEntry(
        arcPart: 1,
        number: 1,
        sourceId: null,
        taskId: null,
        status: 'complete',
        filePath: '/x/ep.mkv',
        sizeBytes: null,
        updatedAtMs: 1,
      ),
    );
    expect(result, isA<LocalPlaySource>());
    expect((result as LocalPlaySource).filePath, '/x/ep.mkv');
  });

  test('prefers 1080 ensub, falls back to best available', () {
    final full = choosePlaySource(sources: [
      source(kind: 'stream', variant: 'ensub', quality: 480, pixeldrainId: 'a'),
      source(kind: 'stream', variant: 'ensub', quality: 1080, pixeldrainId: 'b'),
      source(kind: 'stream', variant: 'dub', quality: 1080, pixeldrainId: 'c'),
    ]) as StreamPlaySource;
    expect(full.quality, 1080);
    expect(full.variant, 'ensub');
    expect(full.url, 'https://pixeldrain.net/api/file/b');
    expect(full.availableQualities, [480, 1080]);
    expect(full.availableVariants, ['dub', 'ensub']);

    final only720 = choosePlaySource(sources: [
      source(kind: 'stream', variant: 'ensub', quality: 720, pixeldrainId: 'a'),
    ]) as StreamPlaySource;
    expect(only720.quality, 720);
  });

  test('sources without pixeldrain ids are unplayable', () {
    final result = choosePlaySource(sources: [
      source(kind: 'stream', variant: 'ensub', quality: 1080),
      source(kind: 'download', variant: 'standard'),
    ]);
    expect(result, isA<NoPlaySource>());
  });

  test('watched threshold at 90%', () {
    const d = Duration(minutes: 20);
    expect(crossesWatchedThreshold(const Duration(minutes: 17), d), false);
    expect(crossesWatchedThreshold(const Duration(minutes: 18), d), true);
    expect(crossesWatchedThreshold(Duration.zero, Duration.zero), false);
  });
}
