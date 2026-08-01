/// Pure logic for the account & sync surface (spec §4.6).
library;

/// Light-touch email check: enough to catch obvious typos before the
/// backend does the real validation. Returns the trimmed address, or null.
String? normalizeEmail(String input) {
  final email = input.trim();
  final at = email.indexOf('@');
  if (at < 1 || at != email.lastIndexOf('@')) return null;
  final domain = email.substring(at + 1);
  if (!domain.contains('.') || domain.startsWith('.') || domain.endsWith('.')) {
    return null;
  }
  return email;
}

/// The 6-digit one-time code (spec §4.6).
bool isValidOtpCode(String input) => RegExp(r'^\d{6}$').hasMatch(input.trim());

/// "Last sync" as the account card shows it.
String formatLastSync(DateTime? lastSync, DateTime now) {
  if (lastSync == null) return 'Not synced yet';
  final elapsed = now.difference(lastSync);
  if (elapsed < const Duration(minutes: 1)) return 'Last sync: just now';
  if (elapsed < const Duration(hours: 1)) {
    return 'Last sync: ${elapsed.inMinutes} min ago';
  }
  if (elapsed < const Duration(days: 1)) {
    final h = elapsed.inHours;
    return 'Last sync: $h hour${h == 1 ? '' : 's'} ago';
  }
  final local = lastSync.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return 'Last sync: ${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}
