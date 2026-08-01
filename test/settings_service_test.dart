import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grand_line/data/db/database.dart';
import 'package:grand_line/data/settings/settings_service.dart';

void main() {
  late AppDatabase db;
  late SettingsService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = SettingsService(db);
  });

  tearDown(() => db.close());

  test('defaults match the spec (§4.5, §7.4, §9.4)', () async {
    final s = await service.load();
    expect(s.streamQuality, kQualityAuto);
    expect(s.preferredQuality, 1080, reason: 'Auto resolves to 1080');
    expect(s.streamVariant, 'ensub');
    expect(s.subtitleLang, 'eng');
    expect(s.audioLang, 'jpn');
    expect(s.wifiOnly, isTrue);
    expect(s.autoDeleteWatched, isFalse);
    expect(s.downloadDir, isEmpty);
    expect(s.notifyNewEpisodes, isFalse);
  });

  test('writes round-trip and stream updates fire', () async {
    final updates = service.watch();
    await service.setStreamQuality('720');
    await service.setWifiOnly(false);
    await service.setAutoDeleteWatched(true);
    await service.setDownloadDir('D:/media');
    await service.setNotifyNewEpisodes(true);

    final s = await service.load();
    expect(s.streamQuality, '720');
    expect(s.preferredQuality, 720);
    expect(s.wifiOnly, isFalse);
    expect(s.autoDeleteWatched, isTrue);
    expect(s.downloadDir, 'D:/media');
    expect(s.notifyNewEpisodes, isTrue);

    final latest = await updates
        .firstWhere((s) => s.notifyNewEpisodes)
        .timeout(const Duration(seconds: 5));
    expect(latest.streamQuality, '720');
  });

  test('unknown stored values fall back rather than throw', () {
    final s = AppSettings.fromMap({
      SettingsService.streamQualityKey: 'weird',
      SettingsService.wifiOnlyKey: 'banana',
    });
    expect(s.preferredQuality, 1080);
    expect(s.wifiOnly, isTrue, reason: "only an explicit '0' disables it");
  });
}
