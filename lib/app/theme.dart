import 'package:flutter/material.dart';

/// Dark, near-black theme for the immersive full-bleed carousel home.
ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1B6FB5),
    brightness: Brightness.dark,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFF0A0E14),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
