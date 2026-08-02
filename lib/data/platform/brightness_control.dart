import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_brightness/screen_brightness.dart';

/// Shim over the screen_brightness plugin (player gesture on mobile). App-level
/// brightness only — the OS setting is never touched, and the override ends
/// with the app. Failures are swallowed: brightness is a nicety, never worth
/// an error surface.
class BrightnessControl {
  /// Current app brightness 0–1, or 1.0 where unsupported.
  Future<double> current() async {
    try {
      return await ScreenBrightness.instance.application;
    } catch (_) {
      return 1.0;
    }
  }

  Future<void> set(double value) async {
    try {
      await ScreenBrightness.instance
          .setApplicationScreenBrightness(value.clamp(0.0, 1.0));
    } catch (_) {}
  }
}

final brightnessControlProvider =
    Provider<BrightnessControl>((ref) => BrightnessControl());
