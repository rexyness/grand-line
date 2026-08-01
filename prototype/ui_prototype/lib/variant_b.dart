// PROTOTYPE — Variant B: "Library sidebar" (desktop-first dense library).
// Wide: persistent arc sidebar + dense episode table. Narrow: two-level list.
import 'package:flutter/material.dart';
import 'mock_data.dart';
import 'player.dart';

class VariantB extends StatefulWidget {
  const VariantB({super.key});
  static const label = 'Library sidebar';

  @override
  State<VariantB> createState() => _VariantBState();
}

class _VariantBState extends State<VariantB> {
  Arc selected = lastWatched.arc;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 700;
    if (wide) {
      return Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 280,
              child: _Sidebar(
                selected: selected,
                onSelect: (a) => setState(() => selected = a),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _EpisodePane(arc: selected)),
          ],
        ),
      );
    }
    // Narrow: arc list; tapping pushes the episode pane.
    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: _Sidebar(
        selected: null,
        onSelect: (a) => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => Scaffold(
                appBar: AppBar(title: Text(a.name)),
                body: _EpisodePane(arc: a)))),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selected, required this.onSelect});
  final Arc? selected;
  final ValueChanged<Arc> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            const Icon(Icons.sailing),
            const SizedBox(width: 8),
            const Text('GRAND LINE',
                style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w800)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          ]),
        ),
        // Continue watching mini-card
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          child: ListTile(
            leading: const Icon(Icons.play_circle_fill, size: 32),
            title: Text(
                '${lastWatched.arc.name} E${lastWatched.episode.number}',
                style: const TextStyle(fontSize: 14)),
            subtitle: Text(lastWatched.episode.remainingLabel,
                style: const TextStyle(fontSize: 12)),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PlayerScreen(item: lastWatched))),
          ),
        ),
        for (final saga in sagas) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(saga.toUpperCase(),
                style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    color: scheme.onSurfaceVariant)),
          ),
          for (final arc in arcsInSaga(saga))
            ListTile(
              dense: true,
              selected: arc == selected,
              leading: SizedBox(
                width: 28,
                height: 28,
                child: Stack(fit: StackFit.expand, children: [
                  CircularProgressIndicator(
                      value: arc.progress,
                      strokeWidth: 3,
                      backgroundColor: scheme.surfaceContainerHighest),
                  Center(
                      child: Text('${arc.episodes.length}',
                          style: const TextStyle(fontSize: 10))),
                ]),
              ),
              title: Text(arc.name, overflow: TextOverflow.ellipsis),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (arc.downloadedCount > 0)
                  const Icon(Icons.download_done, size: 14),
                if (arc.isNew)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(3)),
                    child: const Text('NEW', style: TextStyle(fontSize: 9)),
                  ),
              ]),
              onTap: () => onSelect(arc),
            ),
        ],
      ],
    );
  }
}

class _EpisodePane extends StatelessWidget {
  const _EpisodePane({required this.arc});
  final Arc arc;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 128,
              height: 72,
              clipBehavior: Clip.antiAlias,
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(12)),
              child: ArcImage(arc),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${arc.saga} Saga',
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                  Text(arc.name,
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                      '${arc.episodes.length} episodes · ${arc.watchedCount} watched · ${arc.downloadedCount} downloaded',
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(children: [
          FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.play_arrow),
              label: const Text('Resume')),
          const SizedBox(width: 8),
          OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_outlined),
              label: const Text('Download all')),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: '1080p',
            underline: const SizedBox.shrink(),
            items: [
              for (final q in qualities.skip(1))
                DropdownMenuItem(value: q, child: Text(q))
            ],
            onChanged: (_) {},
          ),
        ]),
        const Divider(height: 32),
        for (final ep in arc.episodes)
          InkWell(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PlayerScreen(item: PlayItem(arc, ep)))),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                SizedBox(
                    width: 32,
                    child: ep.watched
                        ? Icon(Icons.check_circle,
                            size: 18, color: scheme.primary)
                        : Text('${ep.number}',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: scheme.onSurfaceVariant))),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(ep.title,
                      style: TextStyle(
                          fontWeight:
                              ep.inProgress ? FontWeight.w700 : null)),
                ),
                Expanded(
                  flex: 2,
                  child: ep.inProgress
                      ? LinearProgressIndicator(value: ep.progress)
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 16),
                SizedBox(
                    width: 56,
                    child: Text('${ep.minutes} min',
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant))),
                IconButton(
                  icon: Icon(
                      switch (ep.download) {
                        DownloadState.done => Icons.download_done,
                        DownloadState.downloading => Icons.downloading,
                        DownloadState.none => Icons.download_outlined,
                      },
                      size: 18),
                  onPressed: () {},
                ),
              ]),
            ),
          ),
      ],
    );
  }
}
