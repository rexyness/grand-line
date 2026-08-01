import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/home_model.dart';
import '../home/home_providers.dart';
import '../player/player_screen.dart';
import 'search_model.dart';

/// Search overlay (spec §4.3): dims the home, text field on top,
/// live-filtered Arcs/Episodes groups. Tap an arc to focus it in the
/// carousel; tap an episode to play. Esc/back/barrier-tap dismisses.
Future<void> showSearchOverlay(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Search',
    barrierColor: Colors.black.withValues(alpha: 0.7),
    transitionDuration: const Duration(milliseconds: 150),
    transitionBuilder: (context, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
    pageBuilder: (context, _, _) => const _SearchOverlay(),
  );
}

class _SearchOverlay extends ConsumerStatefulWidget {
  const _SearchOverlay();

  @override
  ConsumerState<_SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends ConsumerState<_SearchOverlay> {
  String _query = '';

  void _focusArc(ArcView view) {
    ref.read(focusedArcPartProvider.notifier).focus(view.arc.part);
    Navigator.of(context).pop();
  }

  void _play(ArcView arc, EpisodeView episode) {
    final index = arc.episodes.indexWhere((e) => e.number == episode.number);
    if (index < 0) return;
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(MaterialPageRoute(
      builder: (_) =>
          PlayerScreen(arc: arc, episodes: arc.episodes, index: index),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final views = ref.watch(arcViewsProvider).value ?? const <ArcView>[];
    final results = searchCatalog(views, _query);

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    autofocus: true,
                    onChanged: (value) => setState(() => _query = value),
                    onSubmitted: (_) => _openFirstResult(results),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search arcs and episodes',
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: _query.trim().isEmpty
                        ? const SizedBox.shrink()
                        : results.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(24),
                                child: Text('No matches.',
                                    style: TextStyle(color: Colors.white70),
                                    textAlign: TextAlign.center),
                              )
                            : _ResultsList(
                                results: results,
                                onArc: _focusArc,
                                onEpisode: _play,
                              ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openFirstResult(SearchResults results) {
    if (results.episodes.isNotEmpty) {
      final (arc, episode) = results.episodes.first;
      _play(arc, episode);
    } else if (results.arcs.isNotEmpty) {
      _focusArc(results.arcs.first);
    }
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({
    required this.results,
    required this.onArc,
    required this.onEpisode,
  });

  final SearchResults results;
  final ValueChanged<ArcView> onArc;
  final void Function(ArcView, EpisodeView) onEpisode;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE6101014),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          if (results.arcs.isNotEmpty) const _GroupHeader('Arcs'),
          for (final v in results.arcs)
            ListTile(
              leading: const Icon(Icons.map_outlined, color: Colors.white70),
              title: Text(v.arc.title,
                  style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                  '${v.arc.saga} Saga · ${v.episodes.length} episodes',
                  style: const TextStyle(color: Colors.white54)),
              onTap: () => onArc(v),
            ),
          if (results.episodes.isNotEmpty) const _GroupHeader('Episodes'),
          for (final (arc, e) in results.episodes)
            ListTile(
              leading: Icon(
                e.watched
                    ? Icons.check_circle_outline
                    : e.inProgress
                        ? Icons.play_circle_outline
                        : Icons.circle_outlined,
                color: e.watched || e.inProgress
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white38,
              ),
              title: Text(
                'E${e.number}'
                '${e.episode.title != null && e.episode.title!.isNotEmpty ? ' · ${e.episode.title}' : ''}',
                style: const TextStyle(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(arc.arc.title,
                  style: const TextStyle(color: Colors.white54)),
              onTap: () => onEpisode(arc, e),
            ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 11,
          letterSpacing: 2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
