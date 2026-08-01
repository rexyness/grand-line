import '../../data/db/database.dart';

/// Watched threshold: an episode counts as in-progress until the player
/// marks it watched (spec §4.2 wires the threshold; the model just reads it).
class EpisodeView {
  const EpisodeView({
    required this.episode,
    required this.watched,
    required this.positionMs,
    required this.downloaded,
  });

  final Episode episode;
  final bool watched;
  final int positionMs;
  final bool downloaded;

  int get number => episode.number;
  bool get inProgress => !watched && positionMs > 0;
}

class ArcView {
  const ArcView({
    required this.arc,
    required this.episodes,
    required this.lastActivityMs,
  });

  final Arc arc;
  final List<EpisodeView> episodes;

  /// Newest progress timestamp in this arc; drives the initial focus.
  final int lastActivityMs;

  int get watchedCount => episodes.where((e) => e.watched).length;
  int get downloadedCount => episodes.where((e) => e.downloaded).length;
  bool get started => episodes.any((e) => e.watched || e.inProgress);

  /// The episode Resume/Start plays: the newest in-progress episode, else
  /// the first unwatched, else the first.
  EpisodeView? get resumeTarget {
    if (episodes.isEmpty) return null;
    final inProgress = episodes.where((e) => e.inProgress).toList();
    if (inProgress.isNotEmpty) return inProgress.last;
    for (final e in episodes) {
      if (!e.watched) return e;
    }
    return episodes.first;
  }
}

/// Joins the four DB streams' latest values into the home view. Pure —
/// tested without a database.
List<ArcView> buildArcViews({
  required List<Arc> arcs,
  required List<Episode> episodes,
  required List<ProgressEntry> progress,
  required List<DownloadEntry> downloads,
}) {
  final progressByKey = <(int, int), ProgressEntry>{
    for (final p in progress) (p.arcPart, p.number): p,
  };
  final downloadedKeys = <(int, int)>{
    for (final d in downloads)
      if (d.status == 'complete') (d.arcPart, d.number),
  };

  final byArc = <int, List<EpisodeView>>{};
  for (final e in episodes) {
    final p = progressByKey[(e.arcPart, e.number)];
    (byArc[e.arcPart] ??= []).add(EpisodeView(
      episode: e,
      watched: p?.watched ?? false,
      positionMs: p?.positionMs ?? 0,
      downloaded: downloadedKeys.contains((e.arcPart, e.number)),
    ));
  }

  return [
    for (final arc in arcs)
      ArcView(
        arc: arc,
        episodes: byArc[arc.part] ?? const [],
        lastActivityMs: [
          0,
          for (final e in byArc[arc.part] ?? const <EpisodeView>[])
            if (progressByKey[(arc.part, e.number)] case final p?) p.updatedAtMs,
        ].reduce((a, b) => a > b ? a : b),
      ),
  ];
}

/// The arc the home screen should focus on launch: newest activity wins,
/// falling back to the first non-specials arc.
int initialFocusPart(List<ArcView> views) {
  if (views.isEmpty) return 0;
  ArcView? best;
  for (final v in views) {
    if (v.lastActivityMs > 0 &&
        (best == null || v.lastActivityMs > best.lastActivityMs)) {
      best = v;
    }
  }
  if (best != null) return best.arc.part;
  final nonSpecials = views.where((v) => v.arc.part != 0);
  return (nonSpecials.isEmpty ? views.first : nonSpecials.first).arc.part;
}
