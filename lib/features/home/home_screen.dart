import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'arc_backdrop.dart';
import 'home_model.dart';
import 'home_providers.dart';

/// Immersive-carousel home (spec §4.1, prototype Variant E): full-bleed
/// backdrop of the focused arc, minimal top chrome, focused-arc info block,
/// episode chips, and the arc strip in voyage order.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(launchRefreshProvider);
    final views = ref.watch(arcViewsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: switch (views) {
        AsyncData(:final value) when value.isNotEmpty =>
          _HomeBody(views: value),
        AsyncError(:final error) => Center(
            child: Text(
              'Failed to load catalog: $error',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.views});

  final List<ArcView> views;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusedPart =
        ref.watch(focusedArcPartProvider) ?? initialFocusPart(views);
    final focused = views.firstWhere(
      (v) => v.arc.part == focusedPart,
      orElse: () => views.first,
    );
    final wide = MediaQuery.sizeOf(context).width >= 700;

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: ArcBackdrop(
            key: ValueKey(focused.arc.part),
            url: focused.arc.backdropUrl,
            darken: 0.45,
          ),
        ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopChrome(onRefresh: () => ref.invalidate(launchRefreshProvider)),
              const Spacer(),
              _ArcInfo(view: focused, wide: wide),
              const SizedBox(height: 16),
              _EpisodeChips(view: focused),
              const SizedBox(height: 12),
              _ArcStrip(
                views: views,
                focusedPart: focused.arc.part,
                wide: wide,
                onFocus: (part) =>
                    ref.read(focusedArcPartProvider.notifier).focus(part),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopChrome extends StatelessWidget {
  const _TopChrome({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          const Icon(Icons.sailing, color: Colors.white),
          const SizedBox(width: 8),
          const Text(
            'GRAND LINE',
            style: TextStyle(
              color: Colors.white,
              letterSpacing: 3,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          // Search, downloads, and the release bell arrive in later steps;
          // the slots exist so the chrome doesn't reflow.
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.search),
            tooltip: 'Search (coming soon)',
            onPressed: null,
          ),
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Downloads (coming soon)',
            onPressed: null,
          ),
          MenuAnchor(
            builder: (context, controller, _) => IconButton(
              color: Colors.white,
              icon: const Icon(Icons.more_vert),
              onPressed: () =>
                  controller.isOpen ? controller.close() : controller.open(),
            ),
            menuChildren: [
              MenuItemButton(
                leadingIcon: const Icon(Icons.refresh),
                onPressed: onRefresh,
                child: const Text('Refresh catalog'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArcInfo extends StatelessWidget {
  const _ArcInfo({required this.view, required this.wide});

  final ArcView view;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final arc = view.arc;
    final resume = view.resumeTarget;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${arc.saga} Saga'.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
          Text(
            arc.title,
            style: TextStyle(
              color: Colors.white,
              fontSize: wide ? 34 : 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${view.episodes.length} episodes · ${view.watchedCount} watched'
            '${view.downloadedCount > 0 ? ' · ${view.downloadedCount} offline' : ''}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.icon(
                onPressed: resume == null ? null : () => _play(context, resume),
                icon: const Icon(Icons.play_arrow),
                label: Text(view.started ? 'Resume' : 'Start'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                // Wired in the downloads step.
                onPressed: null,
                icon: const Icon(Icons.download_outlined, color: Colors.white),
                label: const Text(
                  'Download',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EpisodeChips extends StatelessWidget {
  const _EpisodeChips({required this.view});

  final ArcView view;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          for (final ep in view.episodes)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: ep.watched
                    ? const Icon(Icons.check, size: 14)
                    : ep.inProgress
                        ? const Icon(Icons.play_arrow, size: 14)
                        : null,
                label: Text('E${ep.number}'),
                backgroundColor: ep.inProgress
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                onPressed: () => _play(context, ep),
              ),
            ),
        ],
      ),
    );
  }
}

class _ArcStrip extends StatelessWidget {
  const _ArcStrip({
    required this.views,
    required this.focusedPart,
    required this.wide,
    required this.onFocus,
  });

  final List<ArcView> views;
  final int focusedPart;
  final bool wide;
  final ValueChanged<int> onFocus;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: wide ? 120 : 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: views.length,
        itemBuilder: (context, i) {
          final view = views[i];
          final focused = view.arc.part == focusedPart;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onFocus(view.arc.part),
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
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ArcBackdrop(
                      url: view.arc.backdropUrl,
                      darken: focused ? 0 : 0.5,
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(
                          view.arc.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The player arrives in the next implementation step; until then episode
/// taps are visible no-ops.
void _play(BuildContext context, EpisodeView episode) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Player coming soon — E${episode.number}'),
      duration: const Duration(seconds: 1),
    ),
  );
}
