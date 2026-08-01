import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grand_line/data/catalog/backdrop_cache.dart';

void main() {
  late Directory dir;
  late int fetches;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('backdrops');
    fetches = 0;
  });
  tearDown(() => dir.deleteSync(recursive: true));

  BackdropCache cache({bool fail = false}) => BackdropCache(
        dir,
        fetch: (url) async {
          fetches++;
          return fail ? null : [1, 2, 3];
        },
      );

  test('downloads once, then serves from disk', () async {
    final c = cache();
    final first = await c.fileFor('https://x/a.jpg');
    expect(first, isNotNull);
    expect(await first!.readAsBytes(), [1, 2, 3]);

    await c.fileFor('https://x/a.jpg');
    expect(fetches, 1);

    // A fresh instance (new launch) still hits disk, not the network.
    await cache().fileFor('https://x/a.jpg');
    expect(fetches, 1);
  });

  test('failed fetch returns null and retries next time', () async {
    final failing = cache(fail: true);
    expect(await failing.fileFor('https://x/a.jpg'), isNull);
    expect(await cache().fileFor('https://x/a.jpg'), isNotNull);
    expect(fetches, 2);
  });

  test('prune removes files for retired URLs only', () async {
    final c = cache();
    await c.fileFor('https://x/a.jpg');
    await c.fileFor('https://x/b.jpg');

    await c.prune(['https://x/b.jpg']);

    expect(await c.fileFor('https://x/b.jpg'), isNotNull);
    expect(fetches, 2, reason: 'b survived the prune');
    await c.fileFor('https://x/a.jpg');
    expect(fetches, 3, reason: 'a was pruned and re-fetched');
  });
}
