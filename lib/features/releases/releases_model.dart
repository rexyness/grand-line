import '../../data/db/database.dart';

/// How a feed row relates to the catalog (decision in ticket 16): the first
/// release for an episode is a *new episode*; later infohashes for the same
/// episode are *updated releases*; rows whose CRC32 matches nothing in the
/// catalog can't deep-link and get a neutral label.
enum ReleaseKind { newEpisode, updatedRelease, unmatched }

class ReleaseView {
  const ReleaseView({
    required this.release,
    required this.kind,
    this.arc,
    this.episode,
  });

  final ReleaseEntry release;
  final ReleaseKind kind;
  final Arc? arc;
  final Episode? episode;

  bool get unseen => release.seenAtMs == null;

  /// Publication instant used for ordering and display.
  int get whenMs => release.pubDateMs ?? release.firstSeenAtMs;
}

/// Joins the release feed to the catalog, newest first. Pure — tested
/// without a database. The join runs release CRC32 → MKV source rows
/// (uppercased: the RSS and the snapshot don't agree on casing).
List<ReleaseView> buildReleaseViews({
  required List<ReleaseEntry> releases,
  required List<Source> sources,
  required List<Episode> episodes,
  required List<Arc> arcs,
}) {
  final episodeByCrc = <String, (int, int)>{
    for (final s in sources)
      if (s.crc32 case final c?) c.toUpperCase(): (s.arcPart, s.number),
  };
  final episodeByKey = <(int, int), Episode>{
    for (final e in episodes) (e.arcPart, e.number): e,
  };
  final arcByPart = <int, Arc>{for (final a in arcs) a.part: a};

  // Earliest release per episode = the episode's debut; everything after is
  // an update.
  final debutMsByKey = <(int, int), int>{};
  final keyByInfohash = <String, (int, int)>{};
  for (final r in releases) {
    final key = r.crc32 == null ? null : episodeByCrc[r.crc32!.toUpperCase()];
    if (key == null) continue;
    keyByInfohash[r.infohash] = key;
    final whenMs = r.pubDateMs ?? r.firstSeenAtMs;
    final debut = debutMsByKey[key];
    if (debut == null || whenMs < debut) debutMsByKey[key] = whenMs;
  }

  final views = [
    for (final r in releases)
      if (keyByInfohash[r.infohash] case final key?)
        ReleaseView(
          release: r,
          kind: (r.pubDateMs ?? r.firstSeenAtMs) > debutMsByKey[key]!
              ? ReleaseKind.updatedRelease
              : ReleaseKind.newEpisode,
          arc: arcByPart[key.$1],
          episode: episodeByKey[key],
        )
      else
        ReleaseView(release: r, kind: ReleaseKind.unmatched),
  ];
  views.sort((a, b) => b.whenMs.compareTo(a.whenMs));
  return views;
}

/// Arcs that should show an unseen-dot on the arc strip (spec §9.3).
Set<int> unseenArcParts(List<ReleaseView> views) => {
      for (final v in views)
        if (v.unseen && v.arc != null) v.arc!.part,
    };
