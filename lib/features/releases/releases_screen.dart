import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/releases/release_service.dart';
import '../home/home_providers.dart';
import '../player/player_screen.dart';
import 'releases_model.dart';
import 'releases_providers.dart';

/// Chronological release list behind the home bell (spec §9.3). Rows are
/// labeled *new episode* vs *updated release* and deep-link to the episode.
/// Opening the screen marks everything seen; the rows that were unseen at
/// open keep their highlight until the screen is left, so the news stays
/// visible while it's being read.
class ReleasesScreen extends ConsumerStatefulWidget {
  const ReleasesScreen({super.key});

  @override
  ConsumerState<ReleasesScreen> createState() => _ReleasesScreenState();
}

class _ReleasesScreenState extends ConsumerState<ReleasesScreen> {
  Set<String>? _unseenAtOpen;

  @override
  Widget build(BuildContext context) {
    final views = ref.watch(releaseViewsProvider).value;

    if (views != null && _unseenAtOpen == null) {
      _unseenAtOpen = {
        for (final v in views)
          if (v.unseen) v.release.infohash,
      };
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(releaseServiceProvider).markAllSeen();
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('New releases')),
      body: switch (views) {
        null => const Center(child: CircularProgressIndicator()),
        [] => const Center(
            child: Text('No releases yet.\n'
                'New One Pace episodes and updates will show up here.',
                textAlign: TextAlign.center),
          ),
        _ => ListView.builder(
            itemCount: views.length,
            itemBuilder: (context, i) => _ReleaseTile(
              view: views[i],
              highlighted:
                  _unseenAtOpen?.contains(views[i].release.infohash) ?? false,
            ),
          ),
      },
    );
  }
}

class _ReleaseTile extends ConsumerWidget {
  const _ReleaseTile({required this.view, required this.highlighted});

  final ReleaseView view;
  final bool highlighted;

  void _open(BuildContext context, WidgetRef ref) {
    final episode = view.episode;
    if (episode == null) return;
    final arcViews = ref.read(arcViewsProvider).value;
    if (arcViews == null) return;
    final arcView = arcViews
        .where((v) => v.arc.part == episode.arcPart)
        .firstOrNull;
    if (arcView == null) return;
    final index =
        arcView.episodes.indexWhere((e) => e.number == episode.number);
    if (index < 0) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PlayerScreen(
          arc: arcView, episodes: arcView.episodes, index: index),
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final release = view.release;
    final episode = view.episode;
    final when = DateTime.fromMillisecondsSinceEpoch(view.whenMs);

    final (label, icon) = switch (view.kind) {
      ReleaseKind.newEpisode => ('NEW EPISODE', Icons.fiber_new_outlined),
      ReleaseKind.updatedRelease => ('UPDATED', Icons.upgrade),
      ReleaseKind.unmatched => ('RELEASE', Icons.movie_outlined),
    };

    final variant = release.variant;
    final subtitle = [
      if (view.arc != null && episode != null)
        '${view.arc!.title} · E${episode.number}',
      _formatDate(when),
      if (variant != null && variant.isNotEmpty) variant,
      if (release.outdated) 'superseded',
    ].join(' · ');

    return ListTile(
      enabled: episode != null,
      tileColor:
          highlighted ? scheme.primaryContainer.withValues(alpha: 0.25) : null,
      leading: Icon(icon,
          color: view.kind == ReleaseKind.newEpisode ? scheme.primary : null),
      title: Text(
        (episode?.title != null && episode!.title!.isNotEmpty)
            ? episode.title!
            : release.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 1,
          fontWeight: FontWeight.w700,
          color: view.kind == ReleaseKind.newEpisode
              ? scheme.primary
              : scheme.onSurfaceVariant,
        ),
      ),
      onTap: episode == null ? null : () => _open(context, ref),
    );
  }
}

String _formatDate(DateTime when) {
  final now = DateTime.now();
  final days = DateTime(now.year, now.month, now.day)
      .difference(DateTime(when.year, when.month, when.day))
      .inDays;
  return switch (days) {
    0 => 'today',
    1 => 'yesterday',
    < 30 => '$days days ago',
    _ => '${when.year}-${when.month.toString().padLeft(2, '0')}'
        '-${when.day.toString().padLeft(2, '0')}',
  };
}
