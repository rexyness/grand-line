import '../../data/catalog/pixeldrain.dart';
import '../../data/db/database.dart';

export '../../data/catalog/pixeldrain.dart' show pixeldrainFileUrl;

/// What the player should open for an episode (spec §4.2): a completed
/// download plays the local MKV (track pills, no quality pill); otherwise
/// the hardsub MP4 stream for the chosen variant/quality (quality + variant
/// pills, no track pills).
sealed class PlaySource {
  const PlaySource();
}

class LocalPlaySource extends PlaySource {
  const LocalPlaySource(this.filePath);

  final String filePath;
}

class StreamPlaySource extends PlaySource {
  const StreamPlaySource({
    required this.url,
    required this.variant,
    required this.quality,
    required this.availableQualities,
    required this.availableVariants,
  });

  final String url;
  final String variant;
  final int quality;
  final List<int> availableQualities;
  final List<String> availableVariants;
}

class NoPlaySource extends PlaySource {
  const NoPlaySource();
}

/// Picks what to play. [preferredQuality]/[preferredVariant] fall back to
/// the nearest available (spec default: 1080 En Sub).
PlaySource choosePlaySource({
  required List<Source> sources,
  DownloadEntry? download,
  int preferredQuality = 1080,
  String preferredVariant = 'ensub',
}) {
  if (download != null &&
      download.status == 'complete' &&
      download.filePath != null) {
    return LocalPlaySource(download.filePath!);
  }

  final streams = sources
      .where((s) => s.kind == 'stream' && s.pixeldrainId != null)
      .toList();
  if (streams.isEmpty) return const NoPlaySource();

  final variants = streams.map((s) => s.variant).toSet().toList()..sort();
  final variant =
      variants.contains(preferredVariant) ? preferredVariant : variants.first;

  final inVariant = streams.where((s) => s.variant == variant).toList();
  final qualities = inVariant.map((s) => s.quality).toSet().toList()..sort();
  final quality = qualities.contains(preferredQuality)
      ? preferredQuality
      : qualities.last; // nearest-best: highest available

  final chosen = inVariant.firstWhere(
      (s) => s.quality == quality && s.variant == variant);
  return StreamPlaySource(
    url: pixeldrainFileUrl(chosen.pixeldrainId!),
    variant: variant,
    quality: quality,
    availableQualities: qualities,
    availableVariants: variants,
  );
}

/// An episode is watched once playback crosses 90% (spec §4.2's threshold).
bool crossesWatchedThreshold(Duration position, Duration duration) {
  if (duration <= Duration.zero) return false;
  return position.inMilliseconds / duration.inMilliseconds >= 0.9;
}
