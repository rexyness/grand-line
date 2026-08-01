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

/// The one-time code (spec §4.6: 6 digits, matching the backend's OTP-length
/// setting — but accept up to 8 so a server-side config change degrades to a
/// wrong-code error instead of hard-blocking entry).
bool isValidOtpCode(String input) =>
    RegExp(r'^\d{6,8}$').hasMatch(input.trim());

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
