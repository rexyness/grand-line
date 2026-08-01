import 'package:flutter_test/flutter_test.dart';
import 'package:grand_line/features/account/account_model.dart';

void main() {
  group('normalizeEmail', () {
    test('accepts and trims plausible addresses', () {
      expect(normalizeEmail('  nami@example.com '), 'nami@example.com');
      expect(normalizeEmail('a.b+tag@sub.domain.org'), 'a.b+tag@sub.domain.org');
    });

    test('rejects obvious typos', () {
      expect(normalizeEmail(''), isNull);
      expect(normalizeEmail('no-at-sign'), isNull);
      expect(normalizeEmail('@example.com'), isNull);
      expect(normalizeEmail('two@@example.com'), isNull);
      expect(normalizeEmail('nami@nodot'), isNull);
      expect(normalizeEmail('nami@ends.'), isNull);
    });
  });

  group('isValidOtpCode', () {
    test('exactly six digits', () {
      expect(isValidOtpCode('123456'), isTrue);
      expect(isValidOtpCode(' 123456 '), isTrue);
      expect(isValidOtpCode('12345'), isFalse);
      expect(isValidOtpCode('1234567'), isFalse);
      expect(isValidOtpCode('12345a'), isFalse);
    });
  });

  group('formatLastSync', () {
    final now = DateTime(2026, 8, 1, 12, 0);

    test('never synced', () {
      expect(formatLastSync(null, now), 'Not synced yet');
    });

    test('relative buckets', () {
      expect(formatLastSync(now.subtract(const Duration(seconds: 30)), now),
          'Last sync: just now');
      expect(formatLastSync(now.subtract(const Duration(minutes: 5)), now),
          'Last sync: 5 min ago');
      expect(formatLastSync(now.subtract(const Duration(hours: 1)), now),
          'Last sync: 1 hour ago');
      expect(formatLastSync(now.subtract(const Duration(hours: 3)), now),
          'Last sync: 3 hours ago');
    });

    test('older than a day shows the date', () {
      expect(formatLastSync(DateTime(2026, 7, 20, 9, 5), now),
          'Last sync: 2026-07-20 09:05');
    });
  });
}
