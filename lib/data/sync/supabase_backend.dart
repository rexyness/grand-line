import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../catalog/catalog_backend.dart';
import '../releases/releases_backend.dart';
import 'sync_backend.dart';

part 'supabase_backend.g.dart';

/// Backend configuration ships as build-time defines; with neither set the
/// app runs fully local-only off the vendored snapshot (spec §8.1). The anon
/// key is safe to embed publicly — RLS enforces everything (spec §3).
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

bool _initialized = false;

/// Call once from main before runApp. Sets up the shared client with
/// persistent auth sessions (spec §8.2: sessions persist per device); a
/// no-op in local-only builds without backend defines.
Future<void> initializeSupabase() async {
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) return;
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
  _initialized = true;
}

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

/// [ReleasesBackend] over Supabase PostgREST — a plain anon full read of the
/// world-readable `releases` table (spec §9.2).
class SupabaseReleasesBackend implements ReleasesBackend {
  SupabaseReleasesBackend(this._client);

  final SupabaseClient _client;

  @override
  Future<List<RemoteRelease>> fetchAll() async {
    final rows = await _client.from('releases').select();
    return [
      for (final r in rows.cast<Map<String, dynamic>>())
        RemoteRelease(
          infohash: r['infohash'] as String,
          title: r['title'] as String,
          pubDate: r['pub_date'] == null
              ? null
              : DateTime.parse(r['pub_date'] as String),
          variant: r['variant'] as String?,
          outdated: r['outdated'] as bool? ?? false,
          fileName: r['filename'] as String?,
          crc32: r['crc32'] as String?,
          magnet: r['magnet'] as String?,
          firstSeenAt: DateTime.parse(r['first_seen_at'] as String),
        ),
    ];
  }
}

/// [SyncBackend] over Supabase auth + the progress RPCs (spec §3.3/§8).
class SupabaseSyncBackend implements SyncBackend {
  SupabaseSyncBackend(this._client);

  final SupabaseClient _client;

  @override
  String? get userEmail => _client.auth.currentUser?.email;

  @override
  Stream<String?> get userEmailStream =>
      // onAuthStateChange replays the current session to new listeners;
      // distinct() drops the no-op tokenRefreshed emissions.
      _client.auth.onAuthStateChange
          .map((state) => state.session?.user.email)
          .distinct();

  @override
  Future<void> sendOtp(String email) => _wrapAuth(
      () => _client.auth.signInWithOtp(email: email, shouldCreateUser: true));

  @override
  Future<void> verifyOtp({required String email, required String code}) =>
      _wrapAuth(() => _client.auth
          .verifyOTP(type: OtpType.email, email: email, token: code));

  @override
  Future<void> signOut() => _wrapAuth(() => _client.auth.signOut());

  @override
  Future<void> pushProgress(List<RemoteProgress> rows) async {
    if (rows.isEmpty) return;
    await _client.rpc<void>('apply_progress_batch', params: {
      'p_rows': [
        for (final r in rows)
          {
            'arc_part': r.arcPart,
            'number': r.number,
            'position_ms': r.positionMs,
            'watched': r.watched,
            'updated_at': r.updatedAt.toUtc().toIso8601String(),
          },
      ],
    });
  }

  @override
  Future<List<RemoteProgress>> pullProgress() async {
    final rows = await _client.from('progress').select();
    return [
      for (final r in rows.cast<Map<String, dynamic>>())
        RemoteProgress(
          arcPart: r['arc_part'] as int,
          number: r['number'] as int,
          positionMs: (r['position_ms'] as num).toInt(),
          watched: r['watched'] as bool,
          updatedAt: DateTime.parse(r['updated_at'] as String),
        ),
    ];
  }

  /// Rethrows auth failures with their human-readable message so screens
  /// never see the engine package's exception types.
  Future<T> _wrapAuth<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthException catch (e) {
      throw SyncAuthException(e.message);
    }
  }
}

@Riverpod(keepAlive: true)
CatalogBackend? catalogBackend(Ref ref) {
  if (!_initialized) return null;
  return SupabaseCatalogBackend(Supabase.instance.client);
}

// Manual providers — build_runner needs `--force-jit` on this machine (the
// AOT build script trips over native build hooks); regenerating works, but
// new providers stay manual for uniformity with the stream providers that
// riverpod_generator can't express (see home_providers.dart).
final syncBackendProvider = Provider<SyncBackend?>((ref) {
  if (!_initialized) return null;
  return SupabaseSyncBackend(Supabase.instance.client);
});

final releasesBackendProvider = Provider<ReleasesBackend?>((ref) {
  if (!_initialized) return null;
  return SupabaseReleasesBackend(Supabase.instance.client);
});
