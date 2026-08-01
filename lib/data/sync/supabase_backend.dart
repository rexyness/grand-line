import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../catalog/catalog_backend.dart';

part 'supabase_backend.g.dart';

/// Backend configuration ships as build-time defines; with neither set the
/// app runs fully local-only off the vendored snapshot (spec §8.1). The anon
/// key is safe to embed publicly — RLS enforces everything (spec §3).
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

/// [CatalogBackend] over Supabase PostgREST — plain anon reads, no bespoke
/// API (spec §3.3).
class SupabaseCatalogBackend implements CatalogBackend {
  SupabaseCatalogBackend(this._client);

  final SupabaseClient _client;

  @override
  Future<List<RemoteArc>> arcsSince(DateTime? since) async {
    final rows = await _select('arcs', since);
    return [
      for (final r in rows)
        RemoteArc(
          part: r['part'] as int,
          saga: r['saga'] as String,
          title: r['title'] as String,
          shortcode: r['shortcode'] as String,
          description: r['description'] as String? ?? '',
          mkvcode: r['mkvcode'] as String? ?? '',
          backdropUrl: r['backdrop_url'] as String?,
          updatedAt: DateTime.parse(r['updated_at'] as String),
        ),
    ];
  }

  @override
  Future<List<RemoteEpisode>> episodesSince(DateTime? since) async {
    final rows = await _select('episodes', since);
    return [
      for (final r in rows)
        RemoteEpisode(
          arcPart: r['arc_part'] as int,
          number: r['number'] as int,
          title: r['title'] as String?,
          mangaChapters: r['manga_chapters'] as String?,
          animeEpisodes: r['anime_episodes'] as String?,
          released: r['released'] == null
              ? null
              : DateTime.parse(r['released'] as String),
          durationSeconds: r['duration_seconds'] as int?,
          updatedAt: DateTime.parse(r['updated_at'] as String),
        ),
    ];
  }

  @override
  Future<List<RemoteSource>> sourcesSince(DateTime? since) async {
    final rows = await _select('sources', since);
    return [
      for (final r in rows)
        RemoteSource(
          arcPart: r['arc_part'] as int,
          number: r['number'] as int,
          kind: r['kind'] as String,
          variant: r['variant'] as String,
          quality: r['quality'] as int? ?? 0,
          pixeldrainId: r['pixeldrain_id'] as String?,
          crc32: r['crc32'] as String?,
          fileName: r['file_name'] as String?,
          sizeBytes: (r['size_bytes'] as num?)?.toInt(),
          updatedAt: DateTime.parse(r['updated_at'] as String),
        ),
    ];
  }

  Future<List<Map<String, dynamic>>> _select(
      String table, DateTime? since) async {
    var query = _client.from(table).select();
    if (since != null) {
      query = query.gte('updated_at', since.toUtc().toIso8601String());
    }
    final rows = await query;
    return rows.cast<Map<String, dynamic>>();
  }
}

@Riverpod(keepAlive: true)
CatalogBackend? catalogBackend(Ref ref) {
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) return null;
  return SupabaseCatalogBackend(SupabaseClient(supabaseUrl, supabaseAnonKey));
}
