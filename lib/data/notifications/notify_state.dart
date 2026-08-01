import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// The sliver of notification state shared with the background isolate as a
/// small JSON file — the Drift database stays single-isolate. `enabled`
/// mirrors the settings toggle (it also silences iOS's natively-scheduled
/// refresh, which Dart can't unregister); `watermark` is the newest release
/// `pub_date` either side has already surfaced, so the background poll never
/// re-notifies what the app has shown in-app.
class NotifyState {
  const NotifyState({this.enabled = false, this.watermark});

  final bool enabled;
  final DateTime? watermark;
}

Future<File> _stateFile() async {
  final dir = await getApplicationSupportDirectory();
  return File('${dir.path}${Platform.pathSeparator}notify_state.json');
}

Future<NotifyState> readNotifyState() async {
  try {
    final map =
        jsonDecode(await (await _stateFile()).readAsString()) as Map<String, dynamic>;
    return NotifyState(
      enabled: map['enabled'] == true,
      watermark: DateTime.tryParse(map['watermark'] as String? ?? ''),
    );
  } catch (_) {
    return const NotifyState();
  }
}

Future<void> writeNotifyState(NotifyState state) async {
  try {
    await (await _stateFile()).writeAsString(jsonEncode({
      'enabled': state.enabled,
      'watermark': state.watermark?.toUtc().toIso8601String(),
    }));
  } catch (_) {} // best-effort; a lost write means one redundant notification
}

/// Advances only the watermark, preserving `enabled`.
Future<void> advanceNotifyWatermark(DateTime? newest) async {
  if (newest == null) return;
  final current = await readNotifyState();
  final watermark = current.watermark;
  if (watermark != null && !newest.isAfter(watermark)) return;
  await writeNotifyState(
      NotifyState(enabled: current.enabled, watermark: newest));
}
