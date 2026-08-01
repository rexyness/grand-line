import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// App-owned shim over flutter_local_notifications (spec §9.4); nothing
/// outside `data/notifications/` touches the engine package. Init failures
/// (e.g. flaky unpackaged-Windows toast registration — the research's known
/// caveat) degrade to no-ops: the in-app bell is always the baseline.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _windowsGuid = 'a1f862dd-4a40-4416-b8e3-79d1f25f2790';

  Future<void> init() async {
    if (_ready) return;
    try {
      await _plugin.initialize(
          settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          // Requested in context when the user flips the toggle, never at
          // first launch (spec §9.4).
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        linux: LinuxInitializationSettings(defaultActionName: 'Open'),
        windows: WindowsInitializationSettings(
          appName: 'grand-line',
          appUserModelId: 'Rexyness.GrandLine',
          guid: _windowsGuid,
        ),
      ));
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  /// Asks the OS for notification permission where one exists (Android 13+
  /// `POST_NOTIFICATIONS`, iOS alert permission); true on platforms without
  /// a runtime permission.
  Future<bool> requestPermission() async {
    await init();
    if (!_ready) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true) ?? false;
    }
    return true;
  }

  Future<void> showNewReleases(int count) => _show(
        'New One Pace ${count == 1 ? 'episode' : 'episodes'}',
        count == 1
            ? 'A new release is ready to watch.'
            : '$count new releases are ready to watch.',
      );

  /// Fired when the toggle turns on where toasts are the only tier — both a
  /// confirmation and the smoke test the research called for.
  Future<void> showEnabledConfirmation() => _show('Notifications on',
      "You'll hear about new episodes while the app is running.");

  Future<void> _show(String title, String body) async {
    await init();
    if (!_ready) return;
    try {
      await _plugin.show(
        id: 0,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'releases',
            'New releases',
            channelDescription: 'New One Pace episodes and updates',
          ),
        ),
      );
    } catch (_) {} // a lost toast is never worth a crash
  }
}
