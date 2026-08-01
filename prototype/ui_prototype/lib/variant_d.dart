// PROTOTYPE — Variant D: "Voyage timeline".
// One continuous scroll down the Grand Line: arcs as waypoints on a route
// line, big backdrop banners, episodes expand INLINE (no page navigation).
import 'package:flutter/material.dart';
import 'mock_data.dart';
import 'player.dart';

class VariantD extends StatefulWidget {
  const VariantD({super.key});
  static const label = 'Voyage timeline';

  @override
  State<VariantD> createState() => _VariantDState();
}

class _VariantDState extends State<VariantD> {
  Arc? expanded = lastWatched.arc;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final wide = MediaQuery.sizeOf(context).width >= 700;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Row(children: [
              const Icon(Icons.explore_outlined),
              const SizedBox(width: 8),
              const Text('THE VOYAGE',
                  style:
                      TextStyle(letterSpacing: 3, fontWeight: FontWeight.w800)),
              const Spacer(),
              // "You are here" jump chip
              ActionChip(
                avatar: const Icon(Icons.my_location, size: 16),
                label: Text(
                    '${lastWatched.arc.name} E${lastWatched.episode.number}'),
                onPressed: () =>
                    setState(() => expanded = lastWatched.arc),
              ),
            ]),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(
                horizontal: wide ? 80 : 12, vertical: 16),
            sliver: SliverList.list(children: [
              for (final (i, arc) in arcs.indexed) ...[
                _Waypoint(
                  arc: arc,
                  isFirstOfSaga: i == 0 || arcs[i - 1].saga != arc.saga,
                  isCurrent: arc == lastWatched.arc,
                  expanded: expanded == arc,
                  onTap: () => setState(
                      () => expanded = expanded == arc ? null : arc),
                ),
                if (i < arcs.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 19),
                    child: Container(
                      width: 3,
                      height: 24,
                      color: arc.watchedCount == arc.episodes.length
                          ? scheme.primary
                          : scheme.surfaceContainerHighest,
                    ),
                  ),
              ],
              const SizedBox(height: 96),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Waypoint extends StatelessWidget {
  const _Waypoint(
      {required this.arc,
      required this.isFirstOfSaga,
      required this.isCurrent,
      required this.expanded,
      required this.onTap});
  final Arc arc;
  final bool isFirstOfSaga;
  final bool isCurrent;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = arc.watchedCount == arc.episodes.length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (isFirstOfSaga)
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
          child: Text('◆  ${arc.saga.toUpperCase()} SAGA',
              style: TextStyle(
                  letterSpacing: 2,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: scheme.primary)),
        ),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Route node
        Padding(
          padding: const EdgeInsets.only(top: 28),
          child: Icon(
            done
                ? Icons.check_circle
                : (isCurrent ? Icons.sailing : Icons.circle_outlined),
            size: 40,
            color: done || isCurrent
                ? scheme.primary
                : scheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(children: [
            // Banner
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Container(
                height: expanded ? 160 : 96,
                clipBehavior: Clip.antiAlias,
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(16)),
                child: Stack(fit: StackFit.expand, children: [
                  ArcImage(arc, darken: 0.4),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(arc.name,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                            blurRadius: 6,
                                            color: Colors.black)
                                      ])),
                              Text(
                                  '${arc.watchedCount}/${arc.episodes.length} episodes'
                                  '${arc.downloadedCount > 0 ? ' · ${arc.downloadedCount} offline' : ''}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white
                                          .withValues(alpha: 0.85))),
                            ]),
                      ),
                      if (arc.isNew)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(6)),
                          child: const Text('NEW',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800)),
                        ),
                      Icon(
                          expanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: Colors.white),
                    ]),
                  ),
                  if (arc.progress > 0 && !done)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: LinearProgressIndicator(value: arc.progress),
                    ),
                ]),
              ),
            ),
            // Inline episode list
            if (expanded)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(children: [
                  for (final ep in arc.episodes)
                    ListTile(
                      dense: true,
                      leading: ep.watched
                          ? Icon(Icons.check_circle,
                              size: 18, color: scheme.primary)
                          : Icon(Icons.play_arrow,
                              size: 18,
                              color: ep.inProgress
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant),
                      title: Text(ep.title),
                      subtitle: ep.inProgress
                          ? LinearProgressIndicator(value: ep.progress)
                          : null,
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('${ep.minutes} min',
                            style: TextStyle(
                                fontSize: 11,
                                color: scheme.onSurfaceVariant)),
                        IconButton(
                          icon: Icon(
                              switch (ep.download) {
                                DownloadState.done => Icons.download_done,
                                DownloadState.downloading =>
                                  Icons.downloading,
                                DownloadState.none =>
                                  Icons.download_outlined,
                              },
                              size: 16),
                          onPressed: () {},
                        ),
                      ]),
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  PlayerScreen(item: PlayItem(arc, ep)))),
                    ),
                ]),
              ),
          ]),
        ),
      ]),
    ]);
  }
}
