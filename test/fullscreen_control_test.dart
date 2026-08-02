import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grand_line/data/platform/fullscreen_control.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late List<String> calls;

  setUp(() {
    calls = [];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform, (call) async {
      calls.add(call.method);
      return null;
    });
  });

  tearDown(() {
    binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('first acquire locks landscape immersive, last release restores',
      () async {
    final control = FullscreenControl();
    await control.acquirePlayer(lockLandscape: true);
    expect(calls, [
      'SystemChrome.setEnabledSystemUIMode',
      'SystemChrome.setPreferredOrientations',
    ]);

    calls.clear();
    await control.releasePlayer(
        lockLandscape: true, windowFullscreen: false);
    expect(calls, [
      'SystemChrome.setEnabledSystemUIMode',
      'SystemChrome.setPreferredOrientations',
    ]);
  });

  test('autoplay-next handoff (acquire before release) never restores',
      () async {
    final control = FullscreenControl();
    await control.acquirePlayer(lockLandscape: true);
    calls.clear();

    // pushReplacement: the incoming player acquires before the outgoing
    // player's dispose releases.
    await control.acquirePlayer(lockLandscape: true);
    await control.releasePlayer(
        lockLandscape: true, windowFullscreen: false);
    expect(calls, isEmpty, reason: 'chrome must survive the route handoff');

    await control.releasePlayer(
        lockLandscape: true, windowFullscreen: false);
    expect(calls, hasLength(2), reason: 'last release restores');
  });

  test('desktop (no landscape lock) never touches system chrome', () async {
    final control = FullscreenControl();
    await control.acquirePlayer(lockLandscape: false);
    await control.releasePlayer(
        lockLandscape: false, windowFullscreen: false);
    expect(calls, isEmpty);
  });

  test('over-release does not underflow the ref-count', () async {
    final control = FullscreenControl();
    await control.releasePlayer(
        lockLandscape: true, windowFullscreen: false);
    expect(calls, isEmpty, reason: 'stray release must not restore');
    await control.acquirePlayer(lockLandscape: true);
    expect(calls, hasLength(2),
        reason: 'a fresh acquire after a stray release still locks');
  });
}
