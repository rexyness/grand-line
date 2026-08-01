// PROTOTYPE — Variant A: "Shelf home" (streaming-service style).
// Vertical scroll of horizontal shelves; player is a pushed full-screen page.
import 'package:flutter/material.dart';
import 'mock_data.dart';
import 'player.dart';

class VariantA extends StatelessWidget {
  const VariantA({super.key});
  static const label = 'Shelf home';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Row(
              children: [
                const Icon(Icons.sailing),
                const SizedBox(width: 8),
                const Text('GRAND LINE',
                    style: TextStyle(letterSpacing: 3, fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.search), onPressed: () {}),
                IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {}),
                const CircleAvatar(radius: 14, child: Text('L')),
              ],
            ),
          ),
          _shelfTitle(context, 'Continue watching'),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 150,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final item in continueWatching)
                    _ResumeCard(item: item),
                ],
              ),
            ),
          ),
          for (final saga in sagas) ...[
            _shelfTitle(context, '$saga Saga'),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 170,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final arc in arcsInSaga(saga)) _ArcCard(arc: arc),
                  ],
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }

  Widget _shelfTitle(BuildContext context, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.item});
  final PlayItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PlayerScreen(item: item))),
        child: Container(
          width: 240,
          clipBehavior: Clip.antiAlias,
          decoration:
              BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Stack(fit: StackFit.expand, children: [
            ArcImage(item.arc, darken: 0.35),
            Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.play_circle_fill, size: 28),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${item.arc.name} E${item.episode.number}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text(item.episode.remainingLabel,
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              LinearProgressIndicator(value: item.episode.progress),
            ],
            ),
          ]),
        ),
      ),
    );
  }
}

class _ArcCard extends StatelessWidget {
  const _ArcCard({required this.arc});
  final Arc arc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => _ArcDetail(arc: arc))),
        child: SizedBox(
          width: 130,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 110,
                    width: 130,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12)),
                    child: ArcImage(arc),
                  ),
                  if (arc.isNew)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(4)),
                        child: const Text('NEW',
                            style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  if (arc.downloadedCount > 0)
                    const Positioned(
                        top: 6, right: 6, child: Icon(Icons.download_done, size: 16)),
                ],
              ),
              const SizedBox(height: 6),
              Text(arc.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('${arc.watchedCount}/${arc.episodes.length} watched',
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArcDetail extends StatelessWidget {
  const _ArcDetail({required this.arc});
  final Arc arc;

  @override
  Widget build(BuildContext context) {
    final color = arc.color(Brightness.dark);
    return Scaffold(
      appBar: AppBar(title: Text(arc.name)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          Container(
            height: 180,
            margin: const EdgeInsets.all(16),
            clipBehavior: Clip.antiAlias,
            decoration:
                BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child: Stack(fit: StackFit.expand, children: [
              ArcImage(arc, darken: 0.35),
              Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${arc.saga} Saga',
                      style: const TextStyle(fontSize: 12)),
                  Text(arc.name,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
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
                  ]),
                ],
              ),
              ),
            ]),
          ),
          for (final ep in arc.episodes)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.3),
                child: ep.watched
                    ? const Icon(Icons.check, size: 18)
                    : Text('${ep.number}'),
              ),
              title: Text(ep.title),
              subtitle: ep.inProgress
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: LinearProgressIndicator(value: ep.progress),
                    )
                  : Text('${ep.minutes} min'),
              trailing: Icon(switch (ep.download) {
                DownloadState.done => Icons.download_done,
                DownloadState.downloading => Icons.downloading,
                DownloadState.none => Icons.download_outlined,
              }),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PlayerScreen(item: PlayItem(arc, ep)))),
            ),
        ],
      ),
    );
  }
}
