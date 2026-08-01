import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'playback_controller.dart';

/// Must run once before the first [MediaKitPlaybackController] (called from
/// main()).
void initializePlaybackEngine() => MediaKit.ensureInitialized();

/// media_kit implementation, carrying the Android spike findings
/// (spike/ass_spike/RESULT.md):
/// - libass on, with the bundled Roboto fallback font (required on Android)
/// - `ao=audiotrack,opensles` before open — media_kit 1.2.6 hardcodes
///   opensles on physical devices, which yields no audio on some of them
class MediaKitPlaybackController implements PlaybackController {
  MediaKitPlaybackController()
      : _player = Player(
          configuration: const PlayerConfiguration(
            libass: true,
            libassAndroidFont: 'assets/fonts/Roboto-Regular.ttf',
            libassAndroidFontName: 'Roboto',
          ),
        ) {
    _controller = VideoController(_player);
    _wireStreams();
  }

  final Player _player;
  late final VideoController _controller;
  final _snapshots = StreamController<PlaybackSnapshot>.broadcast();
  final _subscriptions = <StreamSubscription<void>>[];
  var _current = const PlaybackSnapshot();

  @override
  Stream<PlaybackSnapshot> get snapshots => _snapshots.stream;

  @override
  PlaybackSnapshot get current => _current;

  void _wireStreams() {
    void push(PlaybackSnapshot next) {
      _current = next;
      if (!_snapshots.isClosed) _snapshots.add(next);
    }

    PlaybackSnapshot fromState() {
      final state = _player.state;
      final tracks = state.tracks;
      return PlaybackSnapshot(
        playing: state.playing,
        buffering: state.buffering,
        position: state.position,
        duration: state.duration,
        subtitleTracks: [
          for (final t in tracks.subtitle)
            if (t.id != 'auto' && t.id != 'no')
              PlaybackTrack(id: t.id, title: t.title, language: t.language),
        ],
        audioTracks: [
          for (final t in tracks.audio)
            if (t.id != 'auto' && t.id != 'no')
              PlaybackTrack(id: t.id, title: t.title, language: t.language),
        ],
        activeSubtitleId: switch (state.track.subtitle.id) {
          'auto' || 'no' => null,
          final id => id,
        },
        activeAudioId: state.track.audio.id,
        error: _current.error,
      );
    }

    for (final stream in <Stream<void>>[
      _player.stream.playing,
      _player.stream.buffering,
      _player.stream.position,
      _player.stream.duration,
      _player.stream.tracks,
      _player.stream.track,
    ]) {
      _subscriptions.add(stream.listen((_) => push(fromState())));
    }
    _subscriptions.add(_player.stream.error.listen((message) {
      _current = fromState();
      push(PlaybackSnapshot(
        playing: _current.playing,
        buffering: false,
        position: _current.position,
        duration: _current.duration,
        subtitleTracks: _current.subtitleTracks,
        audioTracks: _current.audioTracks,
        activeSubtitleId: _current.activeSubtitleId,
        activeAudioId: _current.activeAudioId,
        error: message,
      ));
    }));
  }

  @override
  Future<void> open(String url, {Duration? resumeAt}) async {
    if (Platform.isAndroid) {
      // Spike finding #1: hardcoded opensles → no audio on some devices.
      final platform = _player.platform;
      if (platform is NativePlayer) {
        await platform.setProperty('ao', 'audiotrack,opensles');
      }
    }
    await _player.open(Media(url));
    if (resumeAt != null && resumeAt > Duration.zero) {
      // Seeking is only reliable once the media is loaded; media_kit queues
      // it internally, but wait for a duration to be known for robustness.
      await _player.stream.duration
          .firstWhere((d) => d > Duration.zero)
          .timeout(const Duration(seconds: 30), onTimeout: () => Duration.zero);
      await _player.seek(resumeAt);
    }
  }

  @override
  Future<void> playOrPause() => _player.playOrPause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSubtitleTrack(String? id) async {
    if (id == null) {
      await _player.setSubtitleTrack(SubtitleTrack.no());
      return;
    }
    final track = _player.state.tracks.subtitle
        .where((t) => t.id == id)
        .firstOrNull;
    if (track != null) await _player.setSubtitleTrack(track);
  }

  @override
  Future<void> setAudioTrack(String id) async {
    final track =
        _player.state.tracks.audio.where((t) => t.id == id).firstOrNull;
    if (track != null) await _player.setAudioTrack(track);
  }

  @override
  Widget buildVideoSurface() =>
      Video(controller: _controller, controls: NoVideoControls);

  @override
  Future<void> dispose() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await _snapshots.close();
    await _player.dispose();
  }
}

/// Factory: the player screen constructs one controller per episode and owns
/// its lifecycle. Tests override this with a fake. Declared manually — no
/// codegen needed for a plain value.
final playbackControllerFactoryProvider =
    Provider<PlaybackController Function()>((ref) {
  return MediaKitPlaybackController.new;
});
