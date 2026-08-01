import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'backdrop_cache.g.dart';

/// Persistent disk cache for arc backdrops (spec §10.5): keyed on the catalog
/// row's URL, so images re-download only when the URL changes — bundled feel
/// after first launch, offline-friendly. On fetch failure callers fall back
/// to the painted placeholder; nothing is vendored.
class BackdropCache {
  BackdropCache(this._directory, {Future<List<int>?> Function(String url)? fetch})
      : _fetch = fetch ?? _httpFetch;

  final Directory _directory;
  final Future<List<int>?> Function(String url) _fetch;
  final _inFlight = <String, Future<File?>>{};

  /// The cached image for [url], downloading it on first sight.
  /// Returns null when the file is absent and the fetch fails (offline).
  Future<File?> fileFor(String url) {
    return _inFlight.putIfAbsent(url, () async {
      try {
        final file = File('${_directory.path}/${_keyFor(url)}.img');
        if (await file.exists()) return file;
        final bytes = await _fetch(url);
        if (bytes == null) return null;
        await _directory.create(recursive: true);
        final tmp = File('${file.path}.tmp');
        await tmp.writeAsBytes(bytes, flush: true);
        await tmp.rename(file.path);
        return file;
      } catch (_) {
        return null;
      } finally {
        unawaited(_inFlight.remove(url));
      }
    });
  }

  /// Deletes cached files whose URL is no longer in [liveUrls] (catalog
  /// rows changed their backdrop). Call after a catalog refresh.
  Future<void> prune(Iterable<String> liveUrls) async {
    if (!await _directory.exists()) return;
    final keep = liveUrls.map((u) => '${_keyFor(u)}.img').toSet();
    await for (final entity in _directory.list()) {
      if (entity is File &&
          entity.path.endsWith('.img') &&
          !keep.contains(entity.uri.pathSegments.last)) {
        try {
          await entity.delete();
        } catch (_) {}
      }
    }
  }

  static String _keyFor(String url) =>
      base64Url.encode(utf8.encode(url)).replaceAll('=', '');

  static Future<List<int>?> _httpFetch(String url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) return null;
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
      }
      return builder.takeBytes();
    } finally {
      client.close();
    }
  }
}

@Riverpod(keepAlive: true)
Future<BackdropCache> backdropCache(Ref ref) async {
  final support = await getApplicationSupportDirectory();
  return BackdropCache(Directory('${support.path}/backdrops'));
}
