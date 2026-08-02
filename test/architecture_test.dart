import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces the spec's layer and shim rules (spec §6.2–6.3):
///
/// - `features/` and `app/` may import `data/`, never the reverse.
/// - Engine packages never leak past their shim folder.
/// - Raw platform checks (`dart:io`) stay out of `features/` and `app/`.
void main() {
  final libDir = Directory('lib');
  late final Map<String, List<String>> importsByFile;

  setUpAll(() {
    importsByFile = {};
    final importPattern = RegExp("^import\\s+['\"]([^'\"]+)['\"]", multiLine: true);
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('.g.dart')) continue;
      final path = entity.path.replaceAll('\\', '/');
      importsByFile[path] = importPattern
          .allMatches(entity.readAsStringSync())
          .map((m) => m.group(1)!)
          .toList();
    }
  });

  test('data/ never imports features/ or app/', () {
    final violations = <String>[];
    final upwardRelative = RegExp(r'^(\.\./)+(features|app)/');
    for (final entry in importsByFile.entries) {
      if (!entry.key.startsWith('lib/data/')) continue;
      for (final import in entry.value) {
        if (import.startsWith('package:grand_line/features/') ||
            import.startsWith('package:grand_line/app/') ||
            upwardRelative.hasMatch(import)) {
          violations.add('${entry.key} imports $import');
        }
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('engine packages stay behind their shim folder', () {
    // package prefix -> the only lib/ locations allowed to import it
    const shims = <String, List<String>>{
      'package:media_kit': ['lib/data/playback/'],
      'package:background_downloader': ['lib/data/downloads/'],
      'package:supabase': ['lib/data/sync/'],
      'package:drift': ['lib/data/db/'],
      'package:window_manager': ['lib/main.dart', 'lib/data/platform/'],
      'package:url_launcher': ['lib/data/platform/'],
      'package:file_selector': ['lib/data/platform/'],
      'package:screen_brightness': ['lib/data/platform/'],
      'package:package_info_plus': ['lib/data/platform/'],
      'package:flutter_local_notifications': ['lib/data/notifications/'],
      'package:workmanager': ['lib/data/notifications/'],
    };
    final violations = <String>[];
    for (final entry in importsByFile.entries) {
      for (final import in entry.value) {
        for (final shim in shims.entries) {
          if (import.startsWith(shim.key) &&
              !shim.value.any(entry.key.startsWith)) {
            violations.add('${entry.key} imports $import');
          }
        }
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('features/ and app/ never touch dart:io', () {
    final violations = <String>[];
    for (final entry in importsByFile.entries) {
      if (!entry.key.startsWith('lib/features/') &&
          !entry.key.startsWith('lib/app/')) {
        continue;
      }
      if (entry.value.contains('dart:io')) {
        violations.add(entry.key);
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
