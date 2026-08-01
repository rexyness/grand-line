// PROTOTYPE — Variant E: "Immersive carousel" (console-dashboard style).
// Full-bleed backdrop of the focused arc; arcs as a horizontal card strip;
// episode chips for the focused arc along the bottom. Minimal chrome.
import 'package:flutter/material.dart';
import 'mock_data.dart';
import 'player.dart';

class VariantE extends StatefulWidget {
  const VariantE({super.key});
  static const label = 'Immersive carousel';

  @override
  State<VariantE> createState() => _VariantEState();
}

class _VariantEState extends State<VariantE> {
  late int focus = arcs.indexOf(lastWatched.arc);
  final controller = ScrollController();

  Arc get arc => arcs[focus];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 700;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(fit: StackFit.expand, children: [
        // Full-bleed backdrop of the focused arc.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: ArcImage(arc, key: ValueKey(arc.name), darken: 0.45),
        ),
        // Bottom-up scrim so the strip reads.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black87],
              stops: [0.35, 1],
            ),
          ),
        ),
        SafeArea(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(children: [
                const Icon(Icons.sailing, color: Colors.white),
                const SizedBox(width: 8),
                const Text('GRAND LINE',
                    style: TextStyle(
                        color: Colors.white,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(
                    color: Colors.white,
                    icon: const Icon(Icons.search),
                    onPressed: () {}),
                IconButton(
                    color: Colors.white,
                    icon: const Icon(Icons.download_outlined),
                    onPressed: () {}),
              ]),
            ),
            const Spacer(),
            // Focused-arc info block
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${arc.saga} Saga'.toUpperCase(),
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                            letterSpacing: 2)),
                    Row(children: [
                      Text(arc.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: wideTitle,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(width: 12),
                      if (arc.isNew)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(6)),
                          child: const Text('NEW',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w800)),
                        ),
                    ]),
                    const SizedBox(height: 6),
                    Text(
                        '${arc.episodes.length} episodes · ${arc.watchedCount} watched'
                        '${arc.downloadedCount > 0 ? ' · ${arc.downloadedCount} offline' : ''}',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13)),
                    const SizedBox(height: 12),
                    Row(children: [
                      FilledButton.icon(
                        onPressed: () => _play(context,
                            arc.episodes.firstWhere((e) => !e.watched,
                                orElse: () => arc.episodes.first)),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(arc.progress > 0 ? 'Resume' : 'Start'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.download_outlined,
                            color: Colors.white),
                        label: const Text('Download',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ]),
                  ]),
            ),
            const SizedBox(height: 16),
            // Episode chips for the focused arc
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  for (final ep in arc.episodes)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: ep.watched
                            ? const Icon(Icons.check, size: 14)
                            : (ep.inProgress
                                ? const Icon(Icons.play_arrow, size: 14)
                                : null),
                        label: Text('E${ep.number}'),
                        backgroundColor: ep.inProgress
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        onPressed: () => _play(context, ep),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Arc carousel strip
            SizedBox(
              height: wide ? 120 : 90,
              child: ListView.builder(
                controller: controller,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: arcs.length,
                itemBuilder: (context, i) {
                  final a = arcs[i];
                  final focused = i == focus;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => focus = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: focused ? (wide ? 190 : 140) : (wide ? 150 : 110),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: focused
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                        ),
                        child: Stack(fit: StackFit.expand, children: [
                          ArcImage(a, darken: focused ? 0 : 0.5),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Text(a.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      shadows: [
                                        Shadow(
                                            blurRadius: 4,
                                            color: Colors.black)
                                      ])),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 64), // keep clear of the switcher pill
          ]),
        ),
      ]),
    );
  }

  static const double wideTitle = 34;

  void _play(BuildContext context, Episode ep) =>
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PlayerScreen(item: PlayItem(arc, ep))));
}
