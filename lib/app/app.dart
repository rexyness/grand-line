import 'package:flutter/material.dart';

import '../features/home/home_screen.dart';
import 'theme.dart';

class GrandLineApp extends StatelessWidget {
  const GrandLineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'grand-line',
      theme: buildTheme(),
      home: const HomeScreen(),
    );
  }
}
