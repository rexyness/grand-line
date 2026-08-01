import 'dart:convert';
import 'dart:io';

import 'package:workmanager/workmanager.dart';

import 'notification_service.dart';
import 'notify_state.dart';

/// Task name registered with WorkManager on Android; iOS delivers the
/// AppDelegate-registered BGAppRefresh identifier instead — the dispatcher
/// treats every task as a release check, so both land here.
const releaseCheckTask = 'releaseCheck';

// The backend defines, re-read here rather than imported so the background
// isolate doesn't drag in the supabase package (which stays behind the
// data/sync shim anyway).
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

/// Entry point for the background isolate (spec §9.4: Android daily poll,
/// iOS best-effort BGAppRefresh). Never reports failure — a missed courtesy
/// poll must not trigger OS retry/backoff loops.
@pragma('vm:entry-point')
void notificationTaskDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await runBackgroundReleaseCheck();
    } catch (_) {}
    return true;
  });
}

/// Counts feed rows newer than [watermark]. Pure — tested directly.
int freshReleaseCount(Iterable<DateTime?> pubDates, DateTime? watermark) => [
      for (final d in pubDates)
        if (d != null && (watermark == null || d.isAfter(watermark))) d,
    ].length;

DateTime? newestPubDate(Iterable<DateTime?> pubDates) {
  DateTime? newest;
  for (final d in pubDates) {
    if (d != null && (newest == null || d.isAfter(newest))) newest = d;
  }
  return newest;
}

/// Fetches the newest release rows straight off PostgREST (no Drift — the
/// app's database stays single-isolate) and fires a local notification when
/// something is newer than the shared watermark.
Future<void> runBackgroundReleaseCheck() async {
  if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) return;
  final state = await readNotifyState();
  if (!state.enabled) return;

  final pubDates = await _fetchRecentPubDates();
  if (pubDates.isEmpty) return;
  final newest = newestPubDate(pubDates);

  if (state.watermark == null) {
    // First background run: baseline silently, like the in-app feed does.
    await advanceNotifyWatermark(newest);
    return;
  }

  final fresh = freshReleaseCount(pubDates, state.watermark);
  if (fresh == 0) return;
  await NotificationService().showNewReleases(fresh);
  await advanceNotifyWatermark(newest);
}

Future<List<DateTime?>> _fetchRecentPubDates() async {
  final uri = Uri.parse('$_supabaseUrl/rest/v1/releases'
      '?select=pub_date&order=pub_date.desc.nullslast&limit=50');
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    request.headers.set('apikey', _supabaseAnonKey);
    request.headers.set('Authorization', 'Bearer $_supabaseAnonKey');
    final response = await request.close();
    if (response.statusCode != 200) return const [];
    final body = await response.transform(utf8.decoder).join();
    return [
      for (final row in jsonDecode(body) as List)
        DateTime.tryParse((row as Map<String, dynamic>)['pub_date'] as String? ?? ''),
    ];
  } finally {
    client.close();
  }
}
