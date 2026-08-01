import 'dart:convert';

/// Parsed view of the vendored `assets/catalog/` snapshot
/// (ladyisatis/one-pace-metadata v2 exports, spec §2.2), merged into the
/// logical model: arcs, (arc, number)-keyed episodes, and CRC32-keyed MKV
/// download sources.
class CatalogSnapshot {
  const CatalogSnapshot({
    required this.arcs,
    required this.episodes,
    required this.downloadSources,
  });

  final List<SnapshotArc> arcs;
  final List<SnapshotEpisode> episodes;
  final List<SnapshotDownloadSource> downloadSources;

  /// [arcsJson]: `arcs.json` — `{en: [{part, saga, title, shortcode,
  /// description, mkvcode, episodes: [{episode, standard, extended}]}]}`.
  /// [episodesJson]: `episodes.min.json` — CRC32 → release detail.
  /// [descriptionsJson]: `descriptions.json` — `{en: [{arc, episode, title,
  /// description}]}`.
  factory CatalogSnapshot.parse({
    required String arcsJson,
    required String episodesJson,
    required String descriptionsJson,
  }) {
    final arcList = ((jsonDecode(arcsJson) as Map<String, dynamic>)['en'] as List)
        .cast<Map<String, dynamic>>();
    final byCrc = (jsonDecode(episodesJson) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as Map<String, dynamic>));
    final descriptions = ((jsonDecode(descriptionsJson) as Map<String, dynamic>)['en'] as List)
        .cast<Map<String, dynamic>>();

    final titles = <(int, int), Map<String, dynamic>>{
      for (final d in descriptions) (d['arc'] as int, d['episode'] as int): d,
    };

    final arcs = <SnapshotArc>[];
    final episodes = <SnapshotEpisode>[];
    final sources = <SnapshotDownloadSource>[];

    for (final arc in arcList) {
      final part = arc['part'] as int;
      arcs.add(SnapshotArc(
        part: part,
        saga: arc['saga'] as String? ?? '',
        title: arc['title'] as String? ?? '',
        shortcode: arc['shortcode'] as String? ?? '',
        description: arc['description'] as String? ?? '',
        mkvcode: arc['mkvcode'] as String? ?? '',
      ));

      for (final ep in (arc['episodes'] as List? ?? const []).cast<Map<String, dynamic>>()) {
        final number = int.tryParse(ep['episode'] as String? ?? '');
        if (number == null) continue;
        final standardCrc = _crcOrNull(ep['standard']);
        final extendedCrc = _crcOrNull(ep['extended']);
        final detail = byCrc[standardCrc] ?? byCrc[extendedCrc];
        final desc = titles[(part, number)];

        episodes.add(SnapshotEpisode(
          arcPart: part,
          number: number,
          title: _nonEmpty(desc?['title'] as String?),
          mangaChapters: _nonEmpty(detail?['manga_chapters'] as String?),
          animeEpisodes: _nonEmpty(detail?['anime_episodes'] as String?),
          released: DateTime.tryParse(detail?['released'] as String? ?? ''),
          durationSeconds: detail?['duration'] as int?,
        ));

        for (final (variant, crc) in [('standard', standardCrc), ('extended', extendedCrc)]) {
          final d = byCrc[crc];
          if (crc == null || d == null) continue;
          final file = d['file'] as Map<String, dynamic>? ?? const {};
          sources.add(SnapshotDownloadSource(
            arcPart: part,
            number: number,
            variant: variant,
            crc32: crc,
            fileName: _nonEmpty(file['name'] as String?),
            sizeBytes: parseHumanSize(file['size'] as String?),
          ));
        }
      }
    }

    return CatalogSnapshot(arcs: arcs, episodes: episodes, downloadSources: sources);
  }
}

class SnapshotArc {
  const SnapshotArc({
    required this.part,
    required this.saga,
    required this.title,
    required this.shortcode,
    required this.description,
    required this.mkvcode,
  });

  final int part;
  final String saga;
  final String title;
  final String shortcode;
  final String description;
  final String mkvcode;
}

class SnapshotEpisode {
  const SnapshotEpisode({
    required this.arcPart,
    required this.number,
    this.title,
    this.mangaChapters,
    this.animeEpisodes,
    this.released,
    this.durationSeconds,
  });

  final int arcPart;
  final int number;
  final String? title;
  final String? mangaChapters;
  final String? animeEpisodes;
  final DateTime? released;
  final int? durationSeconds;
}

class SnapshotDownloadSource {
  const SnapshotDownloadSource({
    required this.arcPart,
    required this.number,
    required this.variant,
    required this.crc32,
    this.fileName,
    this.sizeBytes,
  });

  final int arcPart;
  final int number;

  /// 'standard' or 'extended'.
  final String variant;
  final String crc32;
  final String? fileName;
  final int? sizeBytes;
}

String? _crcOrNull(Object? value) {
  final s = value as String?;
  return (s == null || s.isEmpty) ? null : s;
}

String? _nonEmpty(String? s) => (s == null || s.isEmpty) ? null : s;

/// Parses upstream human sizes like `"789.0 MiB"` / `"1.1 GiB"` to bytes.
int? parseHumanSize(String? size) {
  if (size == null) return null;
  final match = RegExp(r'^([\d.]+)\s*(B|KiB|MiB|GiB|TiB)$').firstMatch(size.trim());
  if (match == null) return null;
  final value = double.tryParse(match.group(1)!);
  if (value == null) return null;
  const multipliers = {'B': 1, 'KiB': 1024, 'MiB': 1048576, 'GiB': 1073741824, 'TiB': 1099511627776};
  return (value * multipliers[match.group(2)]!).round();
}
