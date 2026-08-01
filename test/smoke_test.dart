import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grand_line/app/app.dart';

void main() {
  testWidgets('app builds', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GrandLineApp()));
    expect(find.text('grand-line'), findsOneWidget);
  });
}
