import 'package:flutter_test/flutter_test.dart';
import 'package:grand_line/data/notifications/background_check.dart';

void main() {
  final d1 = DateTime.utc(2026, 7, 1);
  final d2 = DateTime.utc(2026, 7, 15);
  final d3 = DateTime.utc(2026, 7, 29);

  test('freshReleaseCount counts rows strictly newer than the watermark', () {
    expect(freshReleaseCount([d1, d2, d3], d2), 1);
    expect(freshReleaseCount([d1, d2, d3], d3), 0,
        reason: 'the watermark row itself is not fresh');
    expect(freshReleaseCount([d1, d2, d3, null], d1), 2,
        reason: 'null pub_dates never count');
  });

  test('a null watermark counts everything dated', () {
    expect(freshReleaseCount([d1, d2, null], null), 2);
  });

  test('newestPubDate ignores nulls and empty input', () {
    expect(newestPubDate([d2, null, d3, d1]), d3);
    expect(newestPubDate(const []), isNull);
    expect(newestPubDate([null]), isNull);
  });
}
