import 'package:flutter/widgets.dart';

/// A subtitle or audio track inside the playing media.
class PlaybackTrack {
  const PlaybackTrack({required this.id, this.title, this.language});

  final String id;
  final String? title;
  final String? language;

  String get label => [
        if (title != null && title!.isNotEmpty) title,
        if (language != null && language!.isNotEmpty) '($language)',
      ].join(' ').trim();
}

/// Immutable snapshot of the player state, emitted on every change.
class PlaybackSnapshot {
  const PlaybackSnapshot({
    this.playing = false,
    this.buffering = true,
    this.completed = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.subtitleTracks = const [],
    this.audioTracks = const [],
    this.activeSubtitleId,
    this.activeAudioId,
    this.error,
  });

  final bool playing;
  final bool buffering;

  /// True once the media has played to its natural end (drives autoplay-next).
  final bool completed;

  final Duration position;
  final Duration duration;
  final List<PlaybackTrack> subtitleTracks;
  final List<PlaybackTrack> audioTracks;
  final String? activeSubtitleId;
  final String? activeAudioId;
  final String? error;
}

/// App-owned playback abstraction (spec §5): the only surface the rest of
/// the app talks to. media_kit stays behind [PlaybackController] so an
/// engine swap is contained to data/playback/.
abstract interface class PlaybackController {
  Stream<PlaybackSnapshot> get snapshots;
  PlaybackSnapshot get current;

  /// Opens [url] (http stream or local file path) and starts playing,
  /// seeking to [resumeAt] once the media is ready.
  Future<void> open(String url, {Duration? resumeAt});

  Future<void> playOrPause();
  Future<void> seek(Duration position);

  /// Playback rate multiplier (1.0 = normal speed).
  Future<void> setRate(double rate);

  /// Player-level volume, 0–100. The app uses this on every platform rather
  /// than the OS media volume — one code path, no extra plugin.
  Future<void> setVolume(double volume);

  /// Pass null to disable subtitles.
  Future<void> setSubtitleTrack(String? id);
  Future<void> setAudioTrack(String id);

  /// The engine's video surface, embedded by the player screen.
  Widget buildVideoSurface();

  Future<void> dispose();
}
