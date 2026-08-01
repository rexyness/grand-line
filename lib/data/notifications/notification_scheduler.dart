import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import '../platform/platform_capabilities.dart';
import '../settings/settings_service.dart';
import 'background_check.dart';
import 'notification_service.dart';
import 'notify_state.dart';

/// Owns the "Notify me about new episodes" toggle's plumbing (spec §9.4):
/// in-context permission requests, the Android daily WorkManager poll, and
/// the shared enabled/watermark state the background isolate reads. iOS's
/// BGAppRefresh is registered natively in the AppDelegate; the state file's
/// `enabled` flag is what actually silences it.
class NotificationScheduler {
  NotificationScheduler(this._settings, this._notifications, this._style);

  static const _uniqueName = 'grand-line-release-check';

  final SettingsService _settings;
  final NotificationService _notifications;
  final NotificationStyle _style;

  bool get _mobile => _style != NotificationStyle.desktopToast;

  /// Call once at startup: hands WorkManager the background entry point and
  /// re-syncs the shared state file with the stored setting.
  Future<void> ensureStarted() async {
    final enabled = (await _settings.load()).notifyNewEpisodes;
    if (_mobile) {
      await Workmanager().initialize(notificationTaskDispatcher);
      if (enabled && _style == NotificationStyle.androidLocal) {
        await _registerAndroidPoll();
      }
    }
    final state = await readNotifyState();
    if (state.enabled != enabled) {
      await writeNotifyState(
          NotifyState(enabled: enabled, watermark: state.watermark));
    }
  }

  /// Flips the toggle. Returns false when the OS denied the notification
  /// permission — the setting stays off and the caller should say so.
  Future<bool> setEnabled(bool enabled) async {
    if (enabled && !await _notifications.requestPermission()) {
      await _settings.setNotifyNewEpisodes(false);
      return false;
    }
    await _settings.setNotifyNewEpisodes(enabled);
    final state = await readNotifyState();
    await writeNotifyState(
        NotifyState(enabled: enabled, watermark: state.watermark));

    if (_style == NotificationStyle.androidLocal) {
      if (enabled) {
        await _registerAndroidPoll();
      } else {
        await Workmanager().cancelByUniqueName(_uniqueName);
      }
    }
    if (enabled && _style == NotificationStyle.desktopToast) {
      // Confirmation doubling as the unpackaged-toast smoke test.
      await _notifications.showEnabledConfirmation();
    }
    return true;
  }

  Future<void> _registerAndroidPoll() =>
      Workmanager().registerPeriodicTask(
        _uniqueName,
        releaseCheckTask,
        frequency: const Duration(hours: 24),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
}

// Manual providers — see the note in supabase_backend.dart.

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  return NotificationScheduler(
    ref.watch(settingsServiceProvider),
    ref.watch(notificationServiceProvider),
    ref.watch(platformCapabilitiesProvider).notificationStyle,
  );
});
