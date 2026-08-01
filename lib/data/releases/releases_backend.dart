/// Read-side backend interface for the release feed (spec §9). Implemented
/// over Supabase PostgREST in `data/sync/`; faked in tests. Always a full
/// fetch — the table is a few hundred small rows and `outdated` flips in
/// place, which a watermark would miss.
abstract interface class ReleasesBackend {
  Future<List<RemoteRelease>> fetchAll();
}

class RemoteRelease {
  const RemoteRelease({
    required this.infohash,
    required this.title,
    required this.firstSeenAt,
    this.pubDate,
    this.variant,
    this.outdated = false,
    this.fileName,
    this.crc32,
    this.magnet,
  });

  final String infohash;
  final String title;
  final DateTime? pubDate;
  final String? variant;
  final bool outdated;
  final String? fileName;
  final String? crc32;
  final String? magnet;
  final DateTime firstSeenAt;
}
