import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'platform_capabilities.g.dart';

/// How (and whether) this device can surface OS-level release notifications.
enum NotificationStyle {
  /// Daily WorkManager poll + local notification (Android).
  androidLocal,

  /// Best-effort BGAppRefreshTask; iOS decides when sideloaded apps run.
  iosBestEffort,

  /// OS toast while the app is running (Windows/Linux).
  desktopToast,
}

/// Semantic capability flags for the current device.
///
/// Feature code branches on these flags, never on `Platform.isX` — raw
/// platform checks live only here and in `data/` adapters.
@immutable
class PlatformCapabilities {
  const PlatformCapabilities({
    required this.canChooseDownloadDir,
    required this.hasCellularToggle,
    required this.hasWindowManagement,
    required this.hasWindowFullscreen,
    required this.playerLocksLandscape,
    required this.notificationStyle,
  });

  /// Detects capabilities from the host platform. The only sanctioned
  /// `Platform.isX` branch point outside `data/` adapters.
  factory PlatformCapabilities.detect() {
    final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    return PlatformCapabilities(
      canChooseDownloadDir: isDesktop,
      hasCellularToggle: Platform.isAndroid || Platform.isIOS,
      hasWindowManagement: isDesktop,
      hasWindowFullscreen: isDesktop,
      playerLocksLandscape: Platform.isAndroid || Platform.isIOS,
      notificationStyle: Platform.isAndroid
          ? NotificationStyle.androidLocal
          : Platform.isIOS
              ? NotificationStyle.iosBestEffort
              : NotificationStyle.desktopToast,
    );
  }

  /// Desktop gets a "download folder" setting; mobile stays app-private.
  final bool canChooseDownloadDir;

  /// Mobile gets the "Wi-Fi only" download toggle.
  final bool hasCellularToggle;

  /// Desktop window sizing/title via window_manager.
  final bool hasWindowManagement;

  /// Desktop toggles true window fullscreen in the player (F / button /
  /// double-click, issue #18).
  final bool hasWindowFullscreen;

  /// Mobile locks landscape + hides system bars while the player is open —
  /// the player *is* the fullscreen there, so no toggle is shown.
  final bool playerLocksLandscape;

  final NotificationStyle notificationStyle;
}

@Riverpod(keepAlive: true)
PlatformCapabilities platformCapabilities(Ref ref) =>
    PlatformCapabilities.detect();
