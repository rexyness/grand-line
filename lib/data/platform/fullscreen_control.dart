import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

/// Shim over window_manager (desktop window fullscreen) and SystemChrome
/// (mobile landscape + immersive) for the player (issue #18). Failures are
/// swallowed: fullscreen is a nicety, never worth an error surface.
///
/// Player-mode chrome is ref-counted rather than tied to one widget: autoplay
/// -next replaces the player route, so the outgoing screen's dispose runs
/// *after* the incoming screen's init — restoring on plain dispose would drop
/// landscape/fullscreen mid-handoff. Only the last release restores.
class FullscreenControl {
  int _depth = 0;

  /// A player screen came up. First acquire locks landscape + hides system
  /// bars where [lockLandscape] says the platform wants it (mobile).
  Future<void> acquirePlayer({required bool lockLandscape}) async {
    _depth++;
    if (_depth != 1 || !lockLandscape) return;
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } catch (_) {}
  }

  /// A player screen went away. The last release restores system bars and
  /// orientation, and drops window fullscreen ([windowFullscreen], desktop) —
  /// leaving the player never strands the app fullscreen.
  Future<void> releasePlayer({
    required bool lockLandscape,
    required bool windowFullscreen,
  }) async {
    if (_depth == 0) return;
    _depth--;
    if (_depth != 0) return;
    if (lockLandscape) {
      try {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        // Empty list = defer to the OS default rotation behavior.
        await SystemChrome.setPreferredOrientations(const []);
      } catch (_) {}
    }
    if (windowFullscreen) {
      await setWindowFullscreen(false);
    }
  }

  /// Whether the desktop window is currently fullscreen. False on failure —
  /// callers only use this to seed toggle state.
  Future<bool> isWindowFullscreen() async {
    try {
      return await windowManager.isFullScreen();
    } catch (_) {
      return false;
    }
  }

  Future<void> setWindowFullscreen(bool value) async {
    try {
      await windowManager.setFullScreen(value);
    } catch (_) {}
  }
}

final fullscreenControlProvider =
    Provider<FullscreenControl>((ref) => FullscreenControl());
