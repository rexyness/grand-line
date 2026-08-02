import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/platform/brightness_control.dart';
import '../../data/platform/platform_capabilities.dart';
import '../../data/playback/media_kit_controller.dart';
import '../../data/playback/playback_controller.dart';
import '../../data/releases/release_service.dart';
import '../../data/settings/settings_service.dart';
import '../home/home_model.dart';
import 'player_model.dart';

/// Full-screen player (spec §4.2 + the 2026-08-02 player-upgrade decisions):
/// seek bar with scrub timestamp, play/pause, ±10s, next episode, speed pill
/// (sticky) with hold-for-2×, pill menus for subtitles/audio (local MKV) or
/// quality/variant (stream), player-level volume (desktop slider + keys +
/// wheel, mobile swipe), mobile gesture zones (double-tap seek, brightness/
/// volume swipes), autoplay-next countdown, desktop keyboard shortcuts, and
/// progress checkpointing into the local DB.
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({
    super.key,
    required this.arc,
    required this.episodes,
    required this.index,
  });

  final ArcView arc;
  final List<EpisodeView> episodes;
  final int index;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  // Captured in initState: ref is unsafe to use once disposal has begun, and
  // dispose() needs the database for the final progress checkpoint.
  late final AppDatabase _db;
  PlaybackController? _controller;
  StreamSubscription<PlaybackSnapshot>? _subscription;
  PlaybackSnapshot _snapshot = const PlaybackSnapshot();
  PlaySource _source = const NoPlaySource();
  Timer? _checkpointTimer;
  Timer? _hideTimer;
  bool _controlsVisible = true;
  bool _watchedMarked = false;
  bool _prefsLoaded = false;
  bool _tracksApplied = false;
  int _preferredQuality = 1080;
  String _preferredVariant = 'ensub';
  String _subtitleLang = 'eng';
  String _audioLang = 'jpn';

  // Player-upgrade state.
  double _speed = 1.0;
  bool _holding2x = false;
  double _volume = 100;
  bool _muted = false;
  bool _autoplay = true;
  bool _completedHandled = false;
  int? _countdown; // non-null while the next-up card counts down
  Timer? _countdownTimer;
  bool _nextUnavailable = false;
  String? _flashText;
  Timer? _flashTimer;
  _DragAdjust? _dragAdjust; // live swipe indicator (mobile)
  double _dragStartDy = 0;
  double _dragStartValue = 0;
  double _brightness = 1.0;

  EpisodeView get _episode => widget.episodes[widget.index];
  bool get _hasNext => widget.index + 1 < widget.episodes.length;

  @override
  void initState() {
    super.initState();
    _db = ref.read(appDatabaseProvider);
    // Opening an episode clears its release badges (spec §9.3).
    unawaited(ref
        .read(releaseServiceProvider)
        .markEpisodeSeen(widget.arc.arc.part, _episode.number));
    _start();
  }

  Future<void> _start() async {
    // Settings seed the initial quality/variant/track preferences
    // (spec §4.5); in-session pill choices then override them.
    if (!_prefsLoaded) {
      _prefsLoaded = true;
      final settings = await ref.read(settingsServiceProvider).load();
      _preferredQuality = settings.preferredQuality;
      _preferredVariant = settings.streamVariant;
      _subtitleLang = settings.subtitleLang;
      _audioLang = settings.audioLang;
      _speed = settings.playbackSpeed;
      _volume = settings.playerVolume;
      _muted = settings.playerMuted;
      _autoplay = settings.autoplayNext;
    }
    final sources = await _db.catalogDao
        .sourcesForEpisode(widget.arc.arc.part, _episode.number);
    final downloads = await _db.downloadsDao.watchAll().first;
    final download = downloads
        .where((d) =>
            d.arcPart == widget.arc.arc.part && d.number == _episode.number)
        .firstOrNull;

    final source = choosePlaySource(
      sources: sources,
      download: download,
      preferredQuality: _preferredQuality,
      preferredVariant: _preferredVariant,
    );
    if (!mounted) return;
    setState(() => _source = source);
    if (source is NoPlaySource) return;

    final controller = ref.read(playbackControllerFactoryProvider)();
    _controller = controller;
    _subscription = controller.snapshots.listen((s) {
      if (!mounted) return;
      setState(() => _snapshot = s);
      _applyTrackPreferences(s, controller);
      _maybeMarkWatched(s);
      if (s.completed && !_completedHandled) {
        _completedHandled = true;
        unawaited(_onCompleted());
      }
    });

    final resume = _episode.inProgress
        ? Duration(milliseconds: _episode.positionMs)
        : null;
    final url = switch (source) {
      LocalPlaySource(:final filePath) => filePath,
      StreamPlaySource(:final url) => url,
      NoPlaySource() => throw StateError('unreachable'),
    };
    await controller.open(url, resumeAt: resume);
    // Sticky speed and volume apply to every episode (decisions Q2/Q4).
    await controller.setRate(_holding2x ? 2.0 : _speed);
    await controller.setVolume(_muted ? 0 : _volume);

    _checkpointTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _checkpoint());
    _scheduleHide();
  }

  Future<void> _checkpoint() async {
    final snapshot = _controller?.current;
    if (snapshot == null || snapshot.duration <= Duration.zero) return;
    await _db.progressDao.applyLww(
      arcPart: widget.arc.arc.part,
      number: _episode.number,
      positionMs: snapshot.position.inMilliseconds,
      watched: _watchedMarked || _episode.watched,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Applies the preferred subtitle/audio languages once the local MKV's
  /// embedded tracks appear (spec §4.5); manual pill choices afterwards win.
  void _applyTrackPreferences(PlaybackSnapshot s, PlaybackController controller) {
    if (_tracksApplied || _source is! LocalPlaySource) return;
    if (s.subtitleTracks.isEmpty && s.audioTracks.isEmpty) return;
    _tracksApplied = true;
    if (_subtitleLang == 'off') {
      unawaited(controller.setSubtitleTrack(null));
    } else if (pickTrackForLanguage(s.subtitleTracks, _subtitleLang)
        case final track?) {
      unawaited(controller.setSubtitleTrack(track.id));
    }
    if (pickTrackForLanguage(s.audioTracks, _audioLang) case final track?) {
      unawaited(controller.setAudioTrack(track.id));
    }
  }

  void _maybeMarkWatched(PlaybackSnapshot s) {
    if (_watchedMarked) return;
    if (crossesWatchedThreshold(s.position, s.duration)) {
      _watchedMarked = true;
      unawaited(_checkpoint());
    }
  }

  Future<void> _changeStream({int? quality, String? variant}) async {
    _preferredQuality = quality ?? _preferredQuality;
    _preferredVariant = variant ?? _preferredVariant;
    final position = _controller?.current.position;
    await _checkpoint();
    await _teardownController();
    if (!mounted) return;
    setState(() {
      _snapshot = PlaybackSnapshot(position: position ?? Duration.zero);
    });
    await _start();
    if (position != null && position > Duration.zero) {
      await _controller?.seek(position);
    }
  }

  Future<void> _teardownController() async {
    _checkpointTimer?.cancel();
    await _subscription?.cancel();
    _subscription = null;
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _showControls() {
    if (!_controlsVisible) setState(() => _controlsVisible = true);
    _scheduleHide();
  }

  void _openNext() {
    if (!_hasNext) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => PlayerScreen(
        arc: widget.arc,
        episodes: widget.episodes,
        index: widget.index + 1,
      ),
    ));
  }

  // ---- Player-upgrade behavior ----

  void _setSpeed(double speed) {
    setState(() => _speed = speed);
    if (!_holding2x) unawaited(_controller?.setRate(speed));
    unawaited(ref.read(settingsServiceProvider).setPlaybackSpeed(speed));
  }

  void _hold2x(bool held) {
    if (_holding2x == held) return;
    setState(() => _holding2x = held);
    unawaited(_controller?.setRate(held ? 2.0 : _speed));
  }

  void _setVolume(double volume, {bool persist = true}) {
    volume = volume.clamp(0, 100).toDouble();
    setState(() {
      _volume = volume;
      if (volume > 0) _muted = false;
    });
    unawaited(_controller?.setVolume(_muted ? 0 : volume));
    if (persist) {
      final settings = ref.read(settingsServiceProvider);
      unawaited(settings.setPlayerVolume(volume));
      unawaited(settings.setPlayerMuted(_muted));
    }
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    unawaited(_controller?.setVolume(_muted ? 0 : _volume));
    unawaited(ref.read(settingsServiceProvider).setPlayerMuted(_muted));
    _showControls();
  }

  void _flash(String text) {
    _flashTimer?.cancel();
    setState(() => _flashText = text);
    _flashTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _flashText = null);
    });
  }

  void _seekBy(Duration delta, {bool flash = false}) {
    final controller = _controller;
    if (controller == null) return;
    var target = controller.current.position + delta;
    if (target < Duration.zero) target = Duration.zero;
    unawaited(controller.seek(target));
    if (flash) {
      _flash(delta.isNegative ? '−10s' : '+10s');
    } else {
      _showControls();
    }
  }

  /// End of episode (decision Q5): countdown into the next episode when
  /// autoplay is on and the next episode has a playable source; an honest
  /// card when it doesn't.
  Future<void> _onCompleted() async {
    unawaited(_checkpoint());
    if (!_autoplay || !_hasNext) return;
    final next = widget.episodes[widget.index + 1];
    final sources = await _db.catalogDao
        .sourcesForEpisode(widget.arc.arc.part, next.number);
    final downloads = await _db.downloadsDao.watchAll().first;
    final download = downloads
        .where((d) =>
            d.arcPart == widget.arc.arc.part && d.number == next.number)
        .firstOrNull;
    final source = choosePlaySource(
      sources: sources,
      download: download,
      preferredQuality: _preferredQuality,
      preferredVariant: _preferredVariant,
    );
    if (!mounted) return;
    if (source is NoPlaySource) {
      setState(() => _nextUnavailable = true);
      return;
    }
    setState(() => _countdown = 5);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final remaining = (_countdown ?? 1) - 1;
      if (remaining <= 0) {
        timer.cancel();
        _openNext();
      } else {
        setState(() => _countdown = remaining);
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    setState(() => _countdown = null);
  }

  // Mobile gesture zones (decision Q3).

  void _onDoubleTapDown(TapDownDetails details, double width) {
    final dx = details.globalPosition.dx;
    if (dx < width / 3) {
      _seekBy(const Duration(seconds: -10), flash: true);
    } else if (dx > width * 2 / 3) {
      _seekBy(const Duration(seconds: 10), flash: true);
    }
  }

  Future<void> _onVerticalDragStart(
      DragStartDetails details, double width) async {
    final side = details.globalPosition.dx < width / 2
        ? _DragAdjust.brightness
        : _DragAdjust.volume;
    _dragStartDy = details.globalPosition.dy;
    if (side == _DragAdjust.brightness) {
      _brightness = await ref.read(brightnessControlProvider).current();
      _dragStartValue = _brightness;
    } else {
      _dragStartValue = _muted ? 0 : _volume;
    }
    if (mounted) setState(() => _dragAdjust = side);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details, double height) {
    final adjust = _dragAdjust;
    if (adjust == null) return;
    // A 70%-of-screen swipe spans the whole range.
    final fraction =
        (_dragStartDy - details.globalPosition.dy) / (height * 0.7);
    if (adjust == _DragAdjust.brightness) {
      _brightness = (_dragStartValue + fraction).clamp(0.0, 1.0);
      unawaited(ref.read(brightnessControlProvider).set(_brightness));
      setState(() {});
    } else {
      _setVolume(_dragStartValue + fraction * 100, persist: false);
    }
  }

  void _onVerticalDragEnd() {
    if (_dragAdjust == _DragAdjust.volume) {
      final settings = ref.read(settingsServiceProvider);
      unawaited(settings.setPlayerVolume(_volume));
      unawaited(settings.setPlayerMuted(_muted));
    }
    setState(() => _dragAdjust = null);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _checkpointTimer?.cancel();
    _countdownTimer?.cancel();
    _flashTimer?.cancel();
    final snapshot = _controller?.current;
    final arcPart = widget.arc.arc.part;
    final number = _episode.number;
    final watched = _watchedMarked || _episode.watched;
    if (snapshot != null && snapshot.duration > Duration.zero) {
      unawaited(_db.progressDao.applyLww(
        arcPart: arcPart,
        number: number,
        positionMs: snapshot.position.inMilliseconds,
        watched: watched,
        updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      ));
    }
    unawaited(_teardownController());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final capabilities = ref.watch(platformCapabilitiesProvider);
    final desktop = capabilities.hasWindowManagement;
    final size = MediaQuery.sizeOf(context);

    final body = MouseRegion(
      onHover: desktop ? (_) => _showControls() : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _controlsVisible
            ? setState(() => _controlsVisible = false)
            : _showControls(),
        // Mobile-only gesture zones; desktop keeps pointer/keyboard idioms.
        onDoubleTapDown:
            desktop ? null : (d) => _onDoubleTapDown(d, size.width),
        onDoubleTap: desktop ? null : () {},
        onLongPressStart: desktop ? null : (_) => _hold2x(true),
        onLongPressEnd: desktop ? null : (_) => _hold2x(false),
        onLongPressCancel: desktop ? null : () => _hold2x(false),
        onVerticalDragStart:
            desktop ? null : (d) => _onVerticalDragStart(d, size.width),
        onVerticalDragUpdate:
            desktop ? null : (d) => _onVerticalDragUpdate(d, size.height),
        onVerticalDragEnd: desktop ? null : (_) => _onVerticalDragEnd(),
        onVerticalDragCancel: desktop ? null : _onVerticalDragEnd,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: Colors.black,
              child: _controller?.buildVideoSurface() ?? const SizedBox(),
            ),
            if (_source is NoPlaySource)
              _Unavailable(onRetry: () => _start())
            else if (_snapshot.error != null)
              _Unavailable(message: _snapshot.error, onRetry: () => _start())
            else if (_snapshot.buffering)
              const Center(child: CircularProgressIndicator()),
            AnimatedOpacity(
              opacity: _controlsVisible ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_controlsVisible,
                child: _Controls(
                  arcTitle: widget.arc.arc.title,
                  episode: _episode,
                  snapshot: _snapshot,
                  source: _source,
                  hasNext: _hasNext,
                  desktop: desktop,
                  speed: _speed,
                  volume: _volume,
                  muted: _muted,
                  onPlayPause: () => _controller?.playOrPause(),
                  onSeek: (d) => _controller?.seek(d),
                  onSeekBy: _seekBy,
                  onNext: _openNext,
                  onSpeed: _setSpeed,
                  onVolume: _setVolume,
                  onMuteToggle: _toggleMute,
                  onSubtitle: (id) => _controller?.setSubtitleTrack(id),
                  onAudio: (id) => _controller?.setAudioTrack(id),
                  onQuality: (q) => _changeStream(quality: q),
                  onVariant: (v) => _changeStream(variant: v),
                  onBack: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            if (_holding2x)
              const _CenterBadge(text: '2×', icon: Icons.fast_forward)
            else if (_flashText != null)
              _CenterBadge(text: _flashText!),
            if (_dragAdjust case final adjust?)
              _AdjustIndicator(
                icon: adjust == _DragAdjust.brightness
                    ? Icons.brightness_6
                    : (_muted || _volume == 0
                        ? Icons.volume_off
                        : Icons.volume_up),
                fraction: adjust == _DragAdjust.brightness
                    ? _brightness
                    : (_muted ? 0 : _volume / 100),
              ),
            if (_countdown case final seconds?)
              _NextUpCard(
                episode: widget.episodes[widget.index + 1],
                seconds: seconds,
                onPlayNow: () {
                  _countdownTimer?.cancel();
                  _openNext();
                },
                onCancel: _cancelCountdown,
              )
            else if (_nextUnavailable)
              _NextUpCard.unavailable(
                onBack: () => Navigator.of(context).pop(),
              ),
          ],
        ),
      ),
    );

    if (!desktop) return Scaffold(backgroundColor: Colors.black, body: body);

    // Desktop keyboard shortcuts (spec §4.2 + decision Q4), behind
    // capability checks; the scroll wheel adjusts volume too.
    return Scaffold(
      backgroundColor: Colors.black,
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.space): () =>
              _controller?.playOrPause(),
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _seekBy(
              const Duration(seconds: -10)),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
              _seekBy(const Duration(seconds: 10)),
          const SingleActivator(LogicalKeyboardKey.arrowUp): () {
            _setVolume(_volume + 5);
            _showControls();
          },
          const SingleActivator(LogicalKeyboardKey.arrowDown): () {
            _setVolume(_volume - 5);
            _showControls();
          },
          const SingleActivator(LogicalKeyboardKey.keyM): _toggleMute,
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.of(context).pop(),
        },
        child: Focus(
          autofocus: true,
          child: Listener(
            onPointerSignal: (signal) {
              if (signal is PointerScrollEvent) {
                _setVolume(_volume + (signal.scrollDelta.dy < 0 ? 5 : -5));
                _showControls();
              }
            },
            child: body,
          ),
        ),
      ),
    );
  }
}

enum _DragAdjust { brightness, volume }

class _Unavailable extends StatelessWidget {
  const _Unavailable({this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message ?? 'This episode is temporarily unavailable.',
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/// Momentary center feedback: ±10s double-tap flashes, hold-for-2× badge.
class _CenterBadge extends StatelessWidget {
  const _CenterBadge({required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
              ],
              Text(text,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slim overlay shown while a brightness/volume swipe is in progress.
class _AdjustIndicator extends StatelessWidget {
  const _AdjustIndicator({required this.icon, required this.fraction});

  final IconData icon;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  value: fraction.clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: Colors.white24,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 38,
                child: Text('${(fraction * 100).round()}%',
                    textAlign: TextAlign.end,
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// End-of-episode card (decision Q5): countdown into the next episode, or
/// the honest unavailable variant.
class _NextUpCard extends StatelessWidget {
  const _NextUpCard({
    required this.episode,
    required this.seconds,
    required this.onPlayNow,
    required this.onCancel,
  })  : unavailable = false,
        onBack = null;

  const _NextUpCard.unavailable({required this.onBack})
      : episode = null,
        seconds = 0,
        onPlayNow = null,
        onCancel = null,
        unavailable = true;

  final EpisodeView? episode;
  final int seconds;
  final VoidCallback? onPlayNow;
  final VoidCallback? onCancel;
  final VoidCallback? onBack;
  final bool unavailable;

  @override
  Widget build(BuildContext context) {
    final title = unavailable
        ? 'The next episode isn\'t available right now.'
        : 'Up next: E${episode!.number}'
            '${episode!.episode.title != null ? ' — ${episode!.episode.title}' : ''}';
    return Positioned(
      right: 24,
      bottom: 96,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xE6101418),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            if (!unavailable)
              Text('Playing in $seconds…',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              children: unavailable
                  ? [FilledButton(onPressed: onBack, child: const Text('Back'))]
                  : [
                      FilledButton(
                          onPressed: onPlayNow, child: const Text('Play now')),
                      const SizedBox(width: 8),
                      TextButton(
                          onPressed: onCancel, child: const Text('Cancel')),
                    ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Controls extends StatefulWidget {
  const _Controls({
    required this.arcTitle,
    required this.episode,
    required this.snapshot,
    required this.source,
    required this.hasNext,
    required this.desktop,
    required this.speed,
    required this.volume,
    required this.muted,
    required this.onPlayPause,
    required this.onSeek,
    required this.onSeekBy,
    required this.onNext,
    required this.onSpeed,
    required this.onVolume,
    required this.onMuteToggle,
    required this.onSubtitle,
    required this.onAudio,
    required this.onQuality,
    required this.onVariant,
    required this.onBack,
  });

  final String arcTitle;
  final EpisodeView episode;
  final PlaybackSnapshot snapshot;
  final PlaySource source;
  final bool hasNext;
  final bool desktop;
  final double speed;
  final double volume;
  final bool muted;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<Duration> onSeekBy;
  final VoidCallback onNext;
  final ValueChanged<double> onSpeed;
  final ValueChanged<double> onVolume;
  final VoidCallback onMuteToggle;
  final ValueChanged<String?> onSubtitle;
  final ValueChanged<String> onAudio;
  final ValueChanged<int> onQuality;
  final ValueChanged<String> onVariant;
  final VoidCallback onBack;

  @override
  State<_Controls> createState() => _ControlsState();
}

class _ControlsState extends State<_Controls> {
  /// Non-null while the user drags the seek bar; seeking happens on release
  /// (decision Q6), with a timestamp bubble tracking the thumb.
  double? _dragMs;

  String _fmt(Duration d) {
    final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final duration = snapshot.duration;
    final position = snapshot.position;
    final maxMs =
        duration > Duration.zero ? duration.inMilliseconds.toDouble() : 1.0;
    final sliderMs = _dragMs ??
        (duration > Duration.zero
            ? position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble()
            : 0.0);
    return Column(
      children: [
        // Top bar
        Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
          child: Row(
            children: [
              IconButton(
                color: Colors.white,
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${widget.arcTitle} · E${widget.episode.number}'
                  '${widget.episode.episode.title != null ? ' — ${widget.episode.episode.title}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Bottom bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(_fmt(position),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Scrub timestamp bubble tracks the thumb.
                        SizedBox(
                          height: 24,
                          child: _dragMs == null
                              ? null
                              : Align(
                                  alignment: Alignment(
                                      (sliderMs / maxMs) * 2 - 1, 0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.75),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _fmt(Duration(
                                          milliseconds: sliderMs.round())),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ),
                        ),
                        Slider(
                          value: sliderMs.clamp(0.0, maxMs),
                          max: maxMs,
                          onChangeStart: duration > Duration.zero
                              ? (v) => setState(() => _dragMs = v)
                              : null,
                          onChanged: duration > Duration.zero
                              ? (v) => setState(() => _dragMs = v)
                              : null,
                          onChangeEnd: duration > Duration.zero
                              ? (v) {
                                  setState(() => _dragMs = null);
                                  widget.onSeek(
                                      Duration(milliseconds: v.round()));
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                  Text(_fmt(duration),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    color: Colors.white,
                    icon: const Icon(Icons.replay_10),
                    onPressed: () =>
                        widget.onSeekBy(const Duration(seconds: -10)),
                  ),
                  IconButton(
                    color: Colors.white,
                    iconSize: 32,
                    icon: Icon(
                        snapshot.playing ? Icons.pause : Icons.play_arrow),
                    onPressed: widget.onPlayPause,
                  ),
                  IconButton(
                    color: Colors.white,
                    icon: const Icon(Icons.forward_10),
                    onPressed: () =>
                        widget.onSeekBy(const Duration(seconds: 10)),
                  ),
                  IconButton(
                    color: Colors.white,
                    icon: const Icon(Icons.skip_next),
                    onPressed: widget.hasNext ? widget.onNext : null,
                  ),
                  if (widget.desktop) ...[
                    IconButton(
                      color: Colors.white,
                      icon: Icon(widget.muted || widget.volume == 0
                          ? Icons.volume_off
                          : Icons.volume_up),
                      onPressed: widget.onMuteToggle,
                    ),
                    SizedBox(
                      width: 110,
                      child: Slider(
                        value: widget.muted ? 0 : widget.volume,
                        max: 100,
                        onChanged: widget.onVolume,
                      ),
                    ),
                  ],
                  const Spacer(),
                  ..._pills(context),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _pills(BuildContext context) {
    final snapshot = widget.snapshot;
    final speedPill = _PillMenu<double>(
      label: formatSpeed(widget.speed),
      values: kSpeedLadder,
      display: formatSpeed,
      selected: widget.speed,
      onSelected: widget.onSpeed,
    );
    switch (widget.source) {
      case StreamPlaySource(
          :final quality,
          :final variant,
          :final availableQualities,
          :final availableVariants
        ):
        return [
          speedPill,
          if (availableVariants.length > 1)
            _PillMenu<String>(
              label: variant == 'dub' ? 'Dub' : 'Sub',
              values: availableVariants,
              display: (v) => v == 'dub' ? 'Dub' : v == 'ensub' ? 'En Sub' : v,
              selected: variant,
              onSelected: widget.onVariant,
            ),
          if (availableQualities.isNotEmpty)
            _PillMenu<int>(
              label: '${quality}p',
              values: availableQualities,
              display: (q) => '${q}p',
              selected: quality,
              onSelected: widget.onQuality,
            ),
        ];
      case LocalPlaySource():
        return [
          speedPill,
          if (snapshot.subtitleTracks.isNotEmpty)
            // 'off' sentinel: PopupMenuButton drops null selections.
            _PillMenu<String>(
              label: 'Subs',
              values: ['off', ...snapshot.subtitleTracks.map((t) => t.id)],
              display: (id) => id == 'off'
                  ? 'Off'
                  : snapshot.subtitleTracks
                      .firstWhere((t) => t.id == id)
                      .label,
              selected: snapshot.activeSubtitleId ?? 'off',
              onSelected: (id) => widget.onSubtitle(id == 'off' ? null : id),
            ),
          if (snapshot.audioTracks.length > 1)
            _PillMenu<String>(
              label: 'Audio',
              values: [for (final t in snapshot.audioTracks) t.id],
              display: (id) =>
                  snapshot.audioTracks.firstWhere((t) => t.id == id).label,
              selected: snapshot.activeAudioId,
              onSelected: widget.onAudio,
            ),
        ];
      case NoPlaySource():
        return const [];
    }
  }
}

class _PillMenu<T> extends StatelessWidget {
  const _PillMenu({
    required this.label,
    required this.values,
    required this.display,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<T> values;
  final String Function(T) display;
  final T? selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: PopupMenuButton<T>(
        onSelected: onSelected,
        itemBuilder: (context) => [
          for (final v in values)
            PopupMenuItem<T>(
              value: v,
              child: Row(
                children: [
                  if (v == selected)
                    const Icon(Icons.check, size: 16)
                  else
                    const SizedBox(width: 16),
                  const SizedBox(width: 8),
                  Text(display(v)),
                ],
              ),
            ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(label, style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
