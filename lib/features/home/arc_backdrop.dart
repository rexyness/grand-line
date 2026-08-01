import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/catalog/backdrop_cache.dart';

/// An arc backdrop image from the disk cache, with the GPL-safe painted
/// placeholder when no URL is known or the fetch fails (spec §10.5 —
/// nothing vendored).
class ArcBackdrop extends ConsumerWidget {
  const ArcBackdrop({super.key, required this.url, this.darken = 0});

  final String? url;
  final double darken;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = url;
    Widget placeholder() => const _PlaceholderBackdrop();

    Widget child;
    if (u == null) {
      child = placeholder();
    } else {
      final cache = ref.watch(backdropCacheProvider);
      child = switch (cache) {
        AsyncData(:final value) => FutureBuilder(
            future: value.fileFor(u),
            builder: (context, snapshot) {
              final file = snapshot.data;
              if (file == null) return placeholder();
              return Image.file(file, fit: BoxFit.cover);
            },
          ),
        _ => placeholder(),
      };
    }

    if (darken > 0) {
      child = ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.black.withValues(alpha: darken),
          BlendMode.darken,
        ),
        child: child,
      );
    }
    return child;
  }
}

/// Deep-ocean gradient standing in for missing artwork — original, shippable.
class _PlaceholderBackdrop extends StatelessWidget {
  const _PlaceholderBackdrop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF12263A), Color(0xFF0A0E14), Color(0xFF1B3A5C)],
        ),
      ),
    );
  }
}
