import '../home/home_model.dart';

class SearchResults {
  const SearchResults({this.arcs = const [], this.episodes = const []});

  final List<ArcView> arcs;
  final List<(ArcView, EpisodeView)> episodes;

  bool get isEmpty => arcs.isEmpty && episodes.isEmpty;
}

const searchArcLimit = 8;
const searchEpisodeLimit = 30;

/// Live-filters the catalog for the search overlay (spec §4.3). Local only.
/// Arcs match on title/saga; episodes on their title, their arc's title, or
/// an `E5`/`5`-style episode number. Pure — tested without a database.
SearchResults searchCatalog(List<ArcView> views, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const SearchResults();

  final number = int.tryParse(q.startsWith('e') ? q.substring(1) : q);

  final arcs = [
    for (final v in views)
      if (v.arc.title.toLowerCase().contains(q) ||
          v.arc.saga.toLowerCase().contains(q))
        v,
  ];

  final episodes = <(ArcView, EpisodeView)>[
    for (final v in views)
      for (final e in v.episodes)
        if ((e.episode.title?.toLowerCase().contains(q) ?? false) ||
            e.number == number)
          (v, e),
  ];

  return SearchResults(
    arcs: arcs.take(searchArcLimit).toList(),
    episodes: episodes.take(searchEpisodeLimit).toList(),
  );
}
