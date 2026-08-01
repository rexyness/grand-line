// PROTOTYPE — throwaway mock data. Wipe me. Not production code.
import 'package:flutter/material.dart';

enum DownloadState { none, downloading, done }

class Episode {
  Episode(this.number, this.title, this.minutes,
      {this.progress = 0, this.download = DownloadState.none});
  final int number;
  final String title;
  final int minutes;
  double progress; // 0..1
  DownloadState download;
  bool get watched => progress >= 0.97;
  bool get inProgress => progress > 0 && !watched;
  String get remainingLabel {
    final left = (minutes * (1 - progress)).round();
    return '$left min left';
  }
}

class Arc {
  Arc(this.saga, this.name, this.hue, this.episodes, {this.isNew = false});
  final String saga;
  final String name;
  final double hue;
  final List<Episode> episodes;
  final bool isNew;

  int get watchedCount => episodes.where((e) => e.watched).length;
  double get progress =>
      episodes.fold<double>(0, (s, e) => s + e.progress) / episodes.length;
  int get downloadedCount =>
      episodes.where((e) => e.download == DownloadState.done).length;
  Color color(Brightness b) => HSLColor.fromAHSL(1, hue, 0.55, 0.42).toColor();

  /// Official arc backdrop downloaded from onepace.net (see tools/ note).
  String get imagePath =>
      'assets/images/${name.toLowerCase().replaceAll('-', '').replaceAll(' ', '_')}.jpg';
}

/// Arc backdrop with a gradient fallback if the asset is missing.
class ArcImage extends StatelessWidget {
  const ArcImage(this.arc,
      {super.key, this.fit = BoxFit.cover, this.darken = 0.0});
  final Arc arc;
  final BoxFit fit;
  final double darken;

  @override
  Widget build(BuildContext context) {
    final img = Image.asset(
      arc.imagePath,
      fit: fit,
      errorBuilder: (_, _, _) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              arc.color(Brightness.dark),
              arc.color(Brightness.dark).withValues(alpha: 0.4),
            ],
          ),
        ),
      ),
    );
    if (darken == 0) return img;
    return Stack(
      fit: StackFit.expand,
      children: [
        img,
        ColoredBox(color: Colors.black.withValues(alpha: darken)),
      ],
    );
  }
}

List<Episode> _eps(int count, String prefix,
    {Map<int, double> progress = const {},
    Map<int, DownloadState> dl = const {}}) {
  return [
    for (var i = 1; i <= count; i++)
      Episode(i, '$prefix $i', 18 + (i * 7) % 21,
          progress: progress[i] ?? 0, download: dl[i] ?? DownloadState.none)
  ];
}

final arcs = <Arc>[
  Arc('East Blue', 'Romance Dawn', 24,
      _eps(3, 'Romance Dawn', progress: {1: 1, 2: 1, 3: 1})),
  Arc('East Blue', 'Orange Town', 36, _eps(2, 'Orange Town', progress: {1: 1, 2: 1})),
  Arc('East Blue', 'Syrup Village', 48,
      _eps(3, 'Syrup Village', progress: {1: 1, 2: 1, 3: 1})),
  Arc('East Blue', 'Baratie', 200,
      _eps(4, 'Baratie', progress: {1: 1, 2: 1, 3: 1, 4: 1},
          dl: {1: DownloadState.done, 2: DownloadState.done})),
  Arc('East Blue', 'Arlong Park', 210,
      _eps(4, 'Arlong Park', progress: {1: 1, 2: 0.55},
          dl: {2: DownloadState.done, 3: DownloadState.downloading})),
  Arc('East Blue', 'Loguetown', 260, _eps(2, 'Loguetown')),
  Arc('Alabasta', 'Reverse Mountain', 150, _eps(1, 'Reverse Mountain')),
  Arc('Alabasta', 'Whisky Peak', 90, _eps(2, 'Whisky Peak')),
  Arc('Alabasta', 'Little Garden', 110, _eps(2, 'Little Garden')),
  Arc('Alabasta', 'Drum Island', 190, _eps(3, 'Drum Island', progress: {1: 0.2})),
  Arc('Alabasta', 'Alabasta', 40, _eps(7, 'Alabasta')),
  Arc('Sky Island', 'Jaya', 28, _eps(3, 'Jaya')),
  Arc('Sky Island', 'Skypiea', 265, _eps(7, 'Skypiea')),
  Arc('Water 7', 'Water 7', 205, _eps(8, 'Water 7')),
  Arc('Water 7', 'Enies Lobby', 220, _eps(6, 'Enies Lobby')),
  Arc('Thriller Bark', 'Thriller Bark', 280, _eps(5, 'Thriller Bark')),
  Arc('Summit War', 'Sabaody Archipelago', 10, _eps(3, 'Sabaody')),
  Arc('Summit War', 'Marineford', 5, _eps(6, 'Marineford')),
  Arc('Fish-Man Island', 'Fish-Man Island', 175, _eps(5, 'Fish-Man Island')),
  Arc('Dressrosa', 'Punk Hazard', 130, _eps(5, 'Punk Hazard')),
  Arc('Dressrosa', 'Dressrosa', 340, _eps(9, 'Dressrosa')),
  Arc('Whole Cake Island', 'Zou', 95, _eps(3, 'Zou')),
  Arc('Whole Cake Island', 'Whole Cake Island', 320, _eps(8, 'Whole Cake')),
  Arc('Wano', 'Wano', 0, _eps(12, 'Wano'), isNew: true),
];

final sagas = {for (final a in arcs) a.saga}.toList();

List<Arc> arcsInSaga(String saga) => arcs.where((a) => a.saga == saga).toList();

class PlayItem {
  PlayItem(this.arc, this.episode);
  final Arc arc;
  final Episode episode;
}

/// Episodes mid-watch, most recent first (mock order).
final continueWatching = <PlayItem>[
  PlayItem(arcs[4], arcs[4].episodes[1]), // Arlong Park 2 @ 55%
  PlayItem(arcs[9], arcs[9].episodes[0]), // Drum Island 1 @ 20%
];

final lastWatched = continueWatching.first;

const qualities = ['Auto', '1080p', '720p', '480p'];
const subtitleTracks = ['Off', 'English', 'Español', 'Français', 'Deutsch', 'العربية'];
const audioTracks = ['Japanese', 'English (Dub)'];
