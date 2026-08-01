import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/platform/platform_capabilities.dart';
import '../../data/playback/media_kit_controller.dart';
import '../../data/playback/playback_controller.dart';
import '../../data/releases/release_service.dart';
import '../../data/settings/settings_service.dart';
import '../home/home_model.dart';
import 'player_model.dart';

/// Full-screen player (spec §4.2): seek bar, play/pause, next episode, pill
/// menus for subtitles/audio (local MKV) or quality/variant (stream), desktop
/// keyboard shortcuts, and progress checkpointing into the local DB.
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

  EpisodeView get _episode => widget.episodes[widget.index];

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
    if (widget.index + 1 >= widget.episodes.length) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => PlayerScreen(
        arc: widget.arc,
        episodes: widget.episodes,
        index: widget.index + 1,
      ),
    ));
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _checkpointTimer?.cancel();
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

    final body = MouseRegion(
      onHover: desktop ? (_) => _showControls() : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _controlsVisible
            ? setState(() => _controlsVisible = false)
            : _showControls(),
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
                  hasNext: widget.index + 1 < widget.episodes.length,
                  onPlayPause: () => _controller?.playOrPause(),
                  onSeek: (d) => _controller?.seek(d),
                  onNext: _openNext,
                  onSubtitle: (id) => _controller?.setSubtitleTrack(id),
                  onAudio: (id) => _controller?.setAudioTrack(id),
                  onQuality: (q) => _changeStream(quality: q),
                  onVariant: (v) => _changeStream(variant: v),
                  onBack: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (!desktop) return Scaffold(backgroundColor: Colors.black, body: body);

    // Desktop keyboard shortcuts (spec §4.2), behind capability checks.
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
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.of(context).pop(),
        },
        child: Focus(autofocus: true, child: body),
      ),
    );
  }

  void _seekBy(Duration delta) {
    final controller = _controller;
    if (controller == null) return;
    var target = controller.current.position + delta;
    if (target < Duration.zero) target = Duration.zero;
    unawaited(controller.seek(target));
    _showControls();
  }
}

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

class _Controls extends StatelessWidget {
  const _Controls({
    required this.arcTitle,
    required this.episode,
    required this.snapshot,
    required this.source,
    required this.hasNext,
    required this.onPlayPause,
    required this.onSeek,
    required this.onNext,
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
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onNext;
  final ValueChanged<String?> onSubtitle;
  final ValueChanged<String> onAudio;
  final ValueChanged<int> onQuality;
  final ValueChanged<String> onVariant;
  final VoidCallback onBack;

  String _fmt(Duration d) {
    final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final duration = snapshot.duration;
    final position = snapshot.position;
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
                onPressed: onBack,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '$arcTitle · E${episode.number}'
                  '${episode.episode.title != null ? ' — ${episode.episode.title}' : ''}',
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
                    child: Slider(
                      value: duration > Duration.zero
                          ? position.inMilliseconds
                              .clamp(0, duration.inMilliseconds)
                              .toDouble()
                          : 0,
                      max: duration > Duration.zero
                          ? duration.inMilliseconds.toDouble()
                          : 1,
                      onChanged: duration > Duration.zero
                          ? (v) => onSeek(Duration(milliseconds: v.round()))
                          : null,
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
                    iconSize: 32,
                    icon: Icon(
                        snapshot.playing ? Icons.pause : Icons.play_arrow),
                    onPressed: onPlayPause,
                  ),
                  IconButton(
                    color: Colors.white,
                    icon: const Icon(Icons.skip_next),
                    onPressed: hasNext ? onNext : null,
                  ),
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
    switch (source) {
      case StreamPlaySource(
          :final quality,
          :final variant,
          :final availableQualities,
          :final availableVariants
        ):
        return [
          if (availableVariants.length > 1)
            _PillMenu<String>(
              label: variant == 'dub' ? 'Dub' : 'Sub',
              values: availableVariants,
              display: (v) => v == 'dub' ? 'Dub' : v == 'ensub' ? 'En Sub' : v,
              selected: variant,
              onSelected: onVariant,
            ),
          if (availableQualities.isNotEmpty)
            _PillMenu<int>(
              label: '${quality}p',
              values: availableQualities,
              display: (q) => '${q}p',
              selected: quality,
              onSelected: onQuality,
            ),
        ];
      case LocalPlaySource():
        return [
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
              onSelected: (id) => onSubtitle(id == 'off' ? null : id),
            ),
          if (snapshot.audioTracks.length > 1)
            _PillMenu<String>(
              label: 'Audio',
              values: [for (final t in snapshot.audioTracks) t.id],
              display: (id) =>
                  snapshot.audioTracks.firstWhere((t) => t.id == id).label,
              selected: snapshot.activeAudioId,
              onSelected: onAudio,
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
