import 'package:flutter_test/flutter_test.dart';
import 'package:grand_line/data/playback/playback_controller.dart';
import 'package:grand_line/features/player/player_model.dart';

void main() {
  const tracks = [
    PlaybackTrack(id: '1', title: 'Signs', language: 'en'),
    PlaybackTrack(id: '2', title: 'Full Subtitles', language: 'eng'),
    PlaybackTrack(id: '3', title: 'Japanese', language: 'ja'),
  ];

  test('matches ISO language codes first', () {
    expect(pickTrackForLanguage(tracks, 'eng')?.id, '1');
    expect(pickTrackForLanguage(tracks, 'jpn')?.id, '3');
  });

  test('falls back to title matching when no language tag fits', () {
    const untagged = [
      PlaybackTrack(id: '1', title: 'English (Full)'),
      PlaybackTrack(id: '2', title: 'Commentary'),
    ];
    expect(pickTrackForLanguage(untagged, 'eng')?.id, '1');
  });

  test('returns null when nothing matches, leaving the engine default', () {
    expect(pickTrackForLanguage(tracks, 'fra'), isNull);
    expect(pickTrackForLanguage(const [], 'eng'), isNull);
  });
}
