import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grand_line/app/app.dart';
import 'package:grand_line/data/catalog/snapshot_seeder.dart';
import 'package:grand_line/data/db/database.dart';

void main() {
  testWidgets('app builds and renders the home carousel', (tester) async {
    // Seeding from bundled assets does real file I/O, which starves under the
    // widget test's fake-async zone — seed directly instead (drift's memory
    // executor completes via microtasks, which pump flushes fine).
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.catalogDao.upsertArc(
        part: 1, saga: 'East Blue', title: 'Romance Dawn', shortcode: 'RD');
    await db.catalogDao.upsertArc(
        part: 2, saga: 'East Blue', title: 'Orange Town', shortcode: 'OT');
    await db.catalogDao.upsertEpisode(arcPart: 1, number: 1);
    await db.catalogDao.upsertEpisode(arcPart: 1, number: 2);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          seededDatabaseProvider.overrideWith((ref) async => db),
        ],
        child: const GrandLineApp(),
      ),
    );
    // Let providers resolve and the backdrop cross-fade play out.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('GRAND LINE'), findsOneWidget);
    expect(find.text('Romance Dawn'), findsWidgets);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('E1'), findsOneWidget);

    // Focusing another arc swaps the info block.
    await tester.tap(find.text('Orange Town'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('0 episodes · 0 watched'), findsOneWidget);

    // Tear the tree down and flush drift's stream-close timers, or the
    // binding's pending-timer invariant fails the test.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
