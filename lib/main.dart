import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app.dart';
import 'data/platform/platform_capabilities.dart';
import 'data/playback/media_kit_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializePlaybackEngine();

  final capabilities = PlatformCapabilities.detect();
  if (capabilities.hasWindowManagement) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      title: 'grand-line',
      size: Size(1280, 720),
      minimumSize: Size(960, 540),
      center: true,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(
    ProviderScope(
      overrides: [
        platformCapabilitiesProvider.overrideWithValue(capabilities),
      ],
      child: const GrandLineApp(),
    ),
  );
}
