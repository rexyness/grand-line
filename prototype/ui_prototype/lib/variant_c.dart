// PROTOTYPE — Variant C: "Player-first".
// The app OPENS into the resume screen; browsing is an overlay on the video.
import 'package:flutter/material.dart';
import 'mock_data.dart';

class VariantC extends StatefulWidget {
  const VariantC({super.key});
  static const label = 'Player-first';

  @override
  State<VariantC> createState() => _VariantCState();
}

class _VariantCState extends State<VariantC> {
  late PlayItem current = lastWatched;
  bool playing = false;
  bool browsing = false;
  String subtitle = 'English';
  String quality = 'Auto';

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 700;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // The video IS the home screen — arc backdrop stands in for it.
          ArcImage(current.arc, darken: playing ? 0.2 : 0.55),
          if (subtitle != 'Off' && playing)
            Align(
              alignment: const Alignment(0, 0.7),
              child: Text(
                "I'm gonna be King of the Pirates!",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                  shadows: const [Shadow(blurRadius: 8, color: Colors.black)],
                ),
              ),
            ),
          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent
                  ],
                ),
              ),
              child: Row(children: [
                const Icon(Icons.sailing, color: Colors.white),
                const SizedBox(width: 8),
                const Text('GRAND LINE',
                    style: TextStyle(
                        color: Colors.white,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w800)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() => browsing = !browsing),
                  icon: const Icon(Icons.video_library_outlined,
                      color: Colors.white),
                  label: const Text('Browse',
                      style: TextStyle(color: Colors.white)),
                ),
              ]),
            ),
          ),
          // Center: resume affordance
          if (!playing)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    iconSize: 88,
                    color: Colors.white,
                    icon: const Icon(Icons.play_circle_filled),
                    onPressed: () => setState(() => playing = true),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Resume ${current.arc.name} · Episode ${current.episode.number}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                  ),
                  Text(current.episode.remainingLabel,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7))),
                ],
              ),
            )
          else
            Center(
              child: IconButton(
                iconSize: 72,
                color: Colors.white.withValues(alpha: 0.85),
                icon: const Icon(Icons.pause_circle_filled),
                onPressed: () => setState(() => playing = false),
              ),
            ),
          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.transparent
                  ],
                ),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Slider(
                    value: current.episode.progress,
                    onChanged: (v) =>
                        setState(() => current.episode.progress = v)),
                Row(children: [
                  _chip(Icons.subtitles_outlined, subtitle, subtitleTracks,
                      (v) => setState(() => subtitle = v)),
                  const SizedBox(width: 8),
                  _chip(Icons.high_quality_outlined, quality, qualities,
                      (v) => setState(() => quality = v)),
                  const Spacer(),
                  IconButton(
                      color: Colors.white,
                      icon: const Icon(Icons.skip_next),
                      onPressed: () {}),
                ]),
              ]),
            ),
          ),
          // Browse overlay: side panel when wide, bottom sheet when narrow.
          if (browsing)
            wide
                ? Positioned(
                    top: 0,
                    right: 0,
                    bottom: 0,
                    width: 360,
                    child: _BrowsePanel(
                      onPick: _pick,
                      onClose: () => setState(() => browsing = false),
                    ),
                  )
                : Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: MediaQuery.sizeOf(context).height * 0.6,
                    child: _BrowsePanel(
                      onPick: _pick,
                      onClose: () => setState(() => browsing = false),
                    ),
                  ),
        ],
      ),
    );
  }

  void _pick(PlayItem item) =>
      setState(() {
        current = item;
        playing = true;
        browsing = false;
      });

  Widget _chip(IconData icon, String label, List<String> options,
      ValueChanged<String> onPick) {
    return PopupMenuButton<String>(
      onSelected: onPick,
      itemBuilder: (_) =>
          [for (final o in options) PopupMenuItem(value: o, child: Text(o))],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ]),
      ),
    );
  }
}

class _BrowsePanel extends StatelessWidget {
  const _BrowsePanel({required this.onPick, required this.onClose});
  final ValueChanged<PlayItem> onPick;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: 0.97),
      borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      child: Column(children: [
        ListTile(
          title: const Text('Up next / Browse',
              style: TextStyle(fontWeight: FontWeight.w700)),
          trailing:
              IconButton(icon: const Icon(Icons.close), onPressed: onClose),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              for (final saga in sagas)
                ExpansionTile(
                  title: Text('$saga Saga'),
                  initiallyExpanded: saga == lastWatched.arc.saga,
                  children: [
                    for (final arc in arcsInSaga(saga))
                      for (final ep in arc.episodes)
                        ListTile(
                          dense: true,
                          leading: ep.watched
                              ? Icon(Icons.check_circle,
                                  size: 16, color: scheme.primary)
                              : const Icon(Icons.play_arrow, size: 16),
                          title: Text('${arc.name} · ${ep.title}'),
                          subtitle: ep.inProgress
                              ? LinearProgressIndicator(value: ep.progress)
                              : null,
                          trailing: ep.download == DownloadState.done
                              ? const Icon(Icons.download_done, size: 14)
                              : null,
                          onTap: () => onPick(PlayItem(arc, ep)),
                        ),
                  ],
                ),
            ],
          ),
        ),
      ]),
    );
  }
}
