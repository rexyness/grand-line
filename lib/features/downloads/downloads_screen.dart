import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/downloads/download_service.dart';
import '../home/home_providers.dart';
import 'downloads_model.dart';

/// Downloads manager (spec §4.4): queue section (active/queued/paused/failed
/// items with per-item controls and global pause-all) and library section
/// (completed episodes grouped by arc with sizes and delete controls).
/// Compact widths stack the sections; expanded shows them side by side.
class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(downloadsStreamProvider).value ?? const [];
    final arcs = ref.watch(arcsStreamProvider).value ?? const [];
    final episodes = ref.watch(episodesStreamProvider).value ?? const [];
    final progress =
        ref.watch(downloadProgressProvider).value ?? const <(int, int), double>{};

    final view =
        buildDownloadsView(entries: entries, arcs: arcs, episodes: episodes);
    final wide = MediaQuery.sizeOf(context).width >= 900;

    final queueSection = _QueueSection(view: view, progress: progress);
    final librarySection = _LibrarySection(view: view);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        actions: [
          if (view.anythingRunning)
            IconButton(
              icon: const Icon(Icons.pause_circle_outline),
              tooltip: 'Pause all',
              onPressed: () =>
                  ref.read(downloadServiceProvider).pauseAll(),
            ),
        ],
      ),
      body: view.queue.isEmpty && view.library.isEmpty
          ? const Center(
              child: Text('Nothing downloaded yet.\n'
                  'Use Download on an arc to keep episodes offline.',
                  textAlign: TextAlign.center),
            )
          : wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: ListView(children: [queueSection])),
                    const VerticalDivider(width: 1),
                    Expanded(child: ListView(children: [librarySection])),
                  ],
                )
              : ListView(children: [queueSection, librarySection]),
    );
  }
}

class _QueueSection extends ConsumerWidget {
  const _QueueSection({required this.view, required this.progress});

  final DownloadsView view;
  final Map<(int, int), double> progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (view.queue.isEmpty) return const SizedBox.shrink();
    final service = ref.read(downloadServiceProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('Queue'),
        for (final item in view.queue)
          _QueueTile(
            item: item,
            progress: progress[(item.entry.arcPart, item.entry.number)],
            service: service,
          ),
      ],
    );
  }
}

class _QueueTile extends StatelessWidget {
  const _QueueTile({
    required this.item,
    required this.progress,
    required this.service,
  });

  final QueueItemView item;
  final double? progress;
  final DownloadService service;

  @override
  Widget build(BuildContext context) {
    final entry = item.entry;
    final size = entry.sizeBytes;
    final subtitle = switch (entry.status) {
      'running' => progress == null
          ? 'Downloading…'
          : 'Downloading · ${(progress! * 100).round()}%'
              '${size == null ? '' : ' of ${formatBytes(size)}'}',
      'paused' => 'Paused',
      'failed' => 'Failed — tap to retry',
      _ => 'Queued${size == null ? '' : ' · ${formatBytes(size)}'}',
    };

    return ListTile(
      onTap: item.isFailed
          ? () => service.enqueueEpisode(entry.arcPart, entry.number)
          : null,
      title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle,
              style: item.isFailed
                  ? TextStyle(color: Theme.of(context).colorScheme.error)
                  : null),
          if (item.isRunning) ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(value: progress),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.isRunning)
            IconButton(
              icon: const Icon(Icons.pause),
              tooltip: 'Pause',
              onPressed: () => service.pause(entry.arcPart, entry.number),
            ),
          if (item.isPaused)
            IconButton(
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Resume',
              onPressed: () => service.resume(entry.arcPart, entry.number),
            ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cancel',
            onPressed: () => service.cancel(entry.arcPart, entry.number),
          ),
        ],
      ),
    );
  }
}

class _LibrarySection extends ConsumerWidget {
  const _LibrarySection({required this.view});

  final DownloadsView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (view.library.isEmpty) return const SizedBox.shrink();
    final service = ref.read(downloadServiceProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          'Library · ${formatBytes(view.totalBytes)}',
          action: TextButton(
            onPressed: () => _confirm(
              context,
              'Delete all downloads?',
              'Every downloaded episode (${formatBytes(view.totalBytes)}) '
                  'will be removed from this device.',
              service.deleteAll,
            ),
            child: const Text('Delete all'),
          ),
        ),
        for (final arcView in view.library)
          ExpansionTile(
            title: Text(arcView.title),
            subtitle: Text(
                '${arcView.items.length} episodes · ${formatBytes(arcView.totalBytes)}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete arc',
              onPressed: () => _confirm(
                context,
                'Delete "${arcView.title}" downloads?',
                '${arcView.items.length} episodes '
                    '(${formatBytes(arcView.totalBytes)}) will be removed.',
                () => service.deleteArc(arcView.arcPart),
              ),
            ),
            children: [
              for (final item in arcView.items)
                ListTile(
                  dense: true,
                  title: Text(item.label,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(formatBytes(item.sizeBytes)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete episode',
                    onPressed: () =>
                        service.delete(item.entry.arcPart, item.entry.number),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          ?action,
        ],
      ),
    );
  }
}

Future<void> _confirm(
  BuildContext context,
  String title,
  String message,
  Future<void> Function() action,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed ?? false) await action();
}
