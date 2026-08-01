import '../../data/db/database.dart';

/// A queue row (anything not yet complete), joined with its catalog names.
class QueueItemView {
  const QueueItemView({required this.entry, this.arc, this.episode});

  final DownloadEntry entry;
  final Arc? arc;
  final Episode? episode;

  String get title =>
      '${arc?.title ?? 'Arc ${entry.arcPart}'} — ${episodeLabel(episode, entry.number)}';
  bool get isRunning => entry.status == 'running';
  bool get isPaused => entry.status == 'paused';
  bool get isQueued => entry.status == 'queued';
  bool get isFailed => entry.status == 'failed';
}

/// A downloaded episode in the library section.
class LibraryItemView {
  const LibraryItemView({required this.entry, this.episode});

  final DownloadEntry entry;
  final Episode? episode;

  String get label => episodeLabel(episode, entry.number);
  int get sizeBytes => entry.sizeBytes ?? 0;
}

/// Completed downloads of one arc, grouped for the library section.
class LibraryArcView {
  const LibraryArcView({this.arc, required this.arcPart, required this.items});

  final Arc? arc;
  final int arcPart;
  final List<LibraryItemView> items;

  String get title => arc?.title ?? 'Arc $arcPart';
  int get totalBytes => items.fold(0, (sum, i) => sum + i.sizeBytes);
}

/// The whole downloads manager view (spec §4.4): queue + library + readout.
class DownloadsView {
  const DownloadsView({required this.queue, required this.library});

  final List<QueueItemView> queue;
  final List<LibraryArcView> library;

  int get totalBytes => library.fold(0, (sum, a) => sum + a.totalBytes);
  bool get anythingRunning => queue.any((q) => q.isRunning);
}

String episodeLabel(Episode? episode, int number) {
  final title = episode?.title;
  return title == null || title.isEmpty ? 'Episode $number' : 'Ep $number · $title';
}

/// Joins the registry with the catalog. Pure — tested without a database.
/// Queue keeps FIFO order (oldest enqueue first); library follows voyage
/// order (arc part, then episode number).
DownloadsView buildDownloadsView({
  required List<DownloadEntry> entries,
  required List<Arc> arcs,
  required List<Episode> episodes,
}) {
  final arcByPart = {for (final a in arcs) a.part: a};
  final episodeByKey = {
    for (final e in episodes) (e.arcPart, e.number): e,
  };

  final queue = [
    for (final d in entries)
      if (d.status != 'complete')
        QueueItemView(
          entry: d,
          arc: arcByPart[d.arcPart],
          episode: episodeByKey[(d.arcPart, d.number)],
        ),
  ]..sort((a, b) => a.entry.updatedAtMs.compareTo(b.entry.updatedAtMs));

  final byArc = <int, List<LibraryItemView>>{};
  for (final d in entries) {
    if (d.status != 'complete') continue;
    (byArc[d.arcPart] ??= []).add(LibraryItemView(
      entry: d,
      episode: episodeByKey[(d.arcPart, d.number)],
    ));
  }
  final library = [
    for (final part in byArc.keys.toList()..sort())
      LibraryArcView(
        arc: arcByPart[part],
        arcPart: part,
        items: byArc[part]!
          ..sort((a, b) => a.entry.number.compareTo(b.entry.number)),
      ),
  ];

  return DownloadsView(queue: queue, library: library);
}

/// '1.4 GB', '850 MB', '12 KB' — sizes shown before committing and in the
/// storage readout (spec §7.2, §4.4).
String formatBytes(int bytes) {
  if (bytes <= 0) return '—';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1000 && unit < units.length - 1) {
    value /= 1000;
    unit++;
  }
  final text = value >= 100 || unit == 0
      ? value.round().toString()
      : value.toStringAsFixed(1);
  return '$text ${units[unit]}';
}
