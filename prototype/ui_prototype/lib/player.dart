// PROTOTYPE — throwaway player screen shared by variants A and B.
import 'package:flutter/material.dart';
import 'mock_data.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.item});
  final PlayItem item;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool playing = true;
  bool controlsVisible = true;
  late double position = widget.item.episode.progress;
  String quality = 'Auto';
  String subtitle = 'English';
  String audio = 'Japanese';

  @override
  Widget build(BuildContext context) {
    final arc = widget.item.arc;
    final ep = widget.item.episode;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => controlsVisible = !controlsVisible),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fake video frame: the arc backdrop stands in for the video.
            ArcImage(arc, darken: playing ? 0.15 : 0.45),
            // Fake ASS subtitle line
            if (subtitle != 'Off')
              Align(
                alignment: const Alignment(0, 0.72),
                child: Text(
                  "I'm gonna be King of the Pirates!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                    shadows: const [
                      Shadow(blurRadius: 4, color: Colors.black),
                      Shadow(blurRadius: 12, color: Colors.black),
                    ],
                  ),
                ),
              ),
            if (controlsVisible) ...[
              // Top bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(4, 8, 12, 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      BackButton(
                          color: Colors.white,
                          onPressed: () => Navigator.of(context).maybePop()),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${arc.name} — Episode ${ep.number}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                            Text('${arc.saga} Saga · One Pace',
                                style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Download this episode',
                        color: Colors.white,
                        icon: Icon(ep.download == DownloadState.done
                            ? Icons.download_done
                            : Icons.download_outlined),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
              // Center play/pause
              Center(
                child: IconButton(
                  iconSize: 72,
                  color: Colors.white,
                  icon: Icon(playing
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled),
                  onPressed: () => setState(() => playing = !playing),
                ),
              ),
              // Bottom controls
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(_fmt(position * ep.minutes * 60),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12)),
                          Expanded(
                            child: Slider(
                              value: position,
                              onChanged: (v) => setState(() => position = v),
                            ),
                          ),
                          Text('${ep.minutes}:00',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12)),
                        ],
                      ),
                      Row(
                        children: [
                          _menuChip(Icons.subtitles_outlined, 'Subs: $subtitle',
                              subtitleTracks,
                              (v) => setState(() => subtitle = v)),
                          const SizedBox(width: 8),
                          _menuChip(Icons.audiotrack_outlined, audio,
                              audioTracks, (v) => setState(() => audio = v)),
                          const SizedBox(width: 8),
                          _menuChip(Icons.high_quality_outlined, quality,
                              qualities, (v) => setState(() => quality = v)),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.skip_next,
                                color: Colors.white),
                            label: const Text('Next episode',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _menuChip(IconData icon, String label, List<String> options,
      ValueChanged<String> onPick) {
    return PopupMenuButton<String>(
      onSelected: onPick,
      itemBuilder: (_) => [
        for (final o in options) PopupMenuItem(value: o, child: Text(o))
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  String _fmt(double seconds) {
    final s = seconds.round();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }
}
