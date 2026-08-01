/// Read-side backend interface for catalog refresh (spec §6.4). Implemented
/// over Supabase PostgREST in `data/sync/`; faked in tests. All queries are
/// watermark-based: rows with `updated_at >= since` (inclusive — boundary
/// re-fetches are harmless because upserts are idempotent).
abstract interface class CatalogBackend {
  Future<List<RemoteArc>> arcsSince(DateTime? since);
  Future<List<RemoteEpisode>> episodesSince(DateTime? since);
  Future<List<RemoteSource>> sourcesSince(DateTime? since);
}

class RemoteArc {
  const RemoteArc({
    required this.part,
    required this.saga,
    required this.title,
    required this.shortcode,
    required this.description,
    required this.mkvcode,
    required this.updatedAt,
    this.backdropUrl,
  });

  final int part;
  final String saga;
  final String title;
  final String shortcode;
  final String description;
  final String mkvcode;
  final String? backdropUrl;
  final DateTime updatedAt;
}

class RemoteEpisode {
  const RemoteEpisode({
    required this.arcPart,
    required this.number,
    required this.updatedAt,
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
  final DateTime updatedAt;
}

class RemoteSource {
  const RemoteSource({
    required this.arcPart,
    required this.number,
    required this.kind,
    required this.variant,
    required this.quality,
    required this.updatedAt,
    this.pixeldrainId,
    this.crc32,
    this.fileName,
    this.sizeBytes,
  });

  final int arcPart;
  final int number;
  final String kind;
  final String variant;
  final int quality;
  final String? pixeldrainId;
  final String? crc32;
  final String? fileName;
  final int? sizeBytes;
  final DateTime updatedAt;
}
