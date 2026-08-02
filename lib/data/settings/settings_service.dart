import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';

/// Streaming quality preference: 'auto' resolves to the best available
/// (spec §4.5: Auto→1080 default).
const kQualityAuto = 'auto';

/// Immutable snapshot of every local setting (spec §4.5). All settings are
/// per-device and never synced. Stored as `settings.*` keys in the Drift
/// key-value table — the notification decision names Drift for local
/// preferences, and one storage mechanism beats two.
class AppSettings {
  const AppSettings({
    this.streamQuality = kQualityAuto,
    this.streamVariant = 'ensub',
    this.subtitleLang = 'eng',
    this.audioLang = 'jpn',
    this.wifiOnly = true,
    this.autoDeleteWatched = false,
    this.downloadDir = '',
    this.notifyNewEpisodes = false,
    this.playbackSpeed = 1.0,
    this.playerVolume = 100,
    this.playerMuted = false,
    this.autoplayNext = true,
  });

  factory AppSettings.fromMap(Map<String, String> map) {
    final defaults = const AppSettings();
    return AppSettings(
      streamQuality: map[SettingsService.streamQualityKey] ??
          defaults.streamQuality,
      streamVariant: map[SettingsService.streamVariantKey] ??
          defaults.streamVariant,
      subtitleLang: map[SettingsService.subtitleLangKey] ??
          defaults.subtitleLang,
      audioLang: map[SettingsService.audioLangKey] ?? defaults.audioLang,
      wifiOnly: map[SettingsService.wifiOnlyKey] != '0',
      autoDeleteWatched: map[SettingsService.autoDeleteWatchedKey] == '1',
      downloadDir: map[SettingsService.downloadDirKey] ?? '',
      notifyNewEpisodes: map[SettingsService.notifyNewEpisodesKey] == '1',
      playbackSpeed:
          double.tryParse(map[SettingsService.playbackSpeedKey] ?? '') ??
              defaults.playbackSpeed,
      playerVolume:
          double.tryParse(map[SettingsService.playerVolumeKey] ?? '') ??
              defaults.playerVolume,
      playerMuted: map[SettingsService.playerMutedKey] == '1',
      autoplayNext: map[SettingsService.autoplayNextKey] != '0',
    );
  }

  /// 'auto' | '1080' | '720' | '480'.
  final String streamQuality;

  /// 'ensub' | 'dub'.
  final String streamVariant;

  /// Preferred MKV subtitle language: 'eng' | 'jpn' | 'off'.
  final String subtitleLang;

  /// Preferred MKV audio language: 'jpn' | 'eng'.
  final String audioLang;

  /// Mobile only (default ON); desktop ignores it.
  final bool wifiOnly;

  final bool autoDeleteWatched;

  /// Desktop only. Empty = the app-private default location. Applies to
  /// downloads queued after the change.
  final String downloadDir;

  /// The one OS-notification toggle (spec §9.4), default OFF.
  final bool notifyNewEpisodes;

  /// Sticky playback rate (player decision Q2): chosen once, applies to every
  /// episode until changed. Hold-for-2× never persists.
  final double playbackSpeed;

  /// Player-level volume 0–100 (player decision Q4), all platforms.
  final double playerVolume;

  final bool playerMuted;

  /// Autoplay-next countdown (player decision Q5), default ON.
  final bool autoplayNext;

  /// The player's initial quality: 'auto' picks the best available, which
  /// choosePlaySource expresses as preferring 1080.
  int get preferredQuality => switch (streamQuality) {
        '720' => 720,
        '480' => 480,
        _ => 1080,
      };
}

/// Read/write access to [AppSettings] over the Drift key-value store.
class SettingsService {
  SettingsService(this._db);

  static const _prefix = 'settings.';
  static const streamQualityKey = '${_prefix}streamQuality';
  static const streamVariantKey = '${_prefix}streamVariant';
  static const subtitleLangKey = '${_prefix}subtitleLang';
  static const audioLangKey = '${_prefix}audioLang';
  static const wifiOnlyKey = '${_prefix}wifiOnly';
  static const autoDeleteWatchedKey = '${_prefix}autoDeleteWatched';
  static const downloadDirKey = '${_prefix}downloadDir';
  static const notifyNewEpisodesKey = '${_prefix}notifyNewEpisodes';
  static const playbackSpeedKey = '${_prefix}playbackSpeed';
  static const playerVolumeKey = '${_prefix}playerVolume';
  static const playerMutedKey = '${_prefix}playerMuted';
  static const autoplayNextKey = '${_prefix}autoplayNext';

  final AppDatabase _db;

  Stream<AppSettings> watch() => _db.catalogDao
      .watchSyncValuesWithPrefix(_prefix)
      .map(AppSettings.fromMap);

  Future<AppSettings> load() async =>
      AppSettings.fromMap(await _db.catalogDao
          .watchSyncValuesWithPrefix(_prefix)
          .first);

  Future<void> setStreamQuality(String value) =>
      _set(streamQualityKey, value);
  Future<void> setStreamVariant(String value) =>
      _set(streamVariantKey, value);
  Future<void> setSubtitleLang(String value) => _set(subtitleLangKey, value);
  Future<void> setAudioLang(String value) => _set(audioLangKey, value);
  Future<void> setWifiOnly(bool value) => _setBool(wifiOnlyKey, value);
  Future<void> setAutoDeleteWatched(bool value) =>
      _setBool(autoDeleteWatchedKey, value);
  Future<void> setDownloadDir(String value) => _set(downloadDirKey, value);
  Future<void> setNotifyNewEpisodes(bool value) =>
      _setBool(notifyNewEpisodesKey, value);
  Future<void> setPlaybackSpeed(double value) =>
      _set(playbackSpeedKey, value.toString());
  Future<void> setPlayerVolume(double value) =>
      _set(playerVolumeKey, value.toString());
  Future<void> setPlayerMuted(bool value) => _setBool(playerMutedKey, value);
  Future<void> setAutoplayNext(bool value) =>
      _setBool(autoplayNextKey, value);

  Future<void> _set(String key, String value) =>
      _db.catalogDao.setSyncValue(key, value);

  Future<void> _setBool(String key, bool value) =>
      _set(key, value ? '1' : '0');
}

// Manual providers — see the note in supabase_backend.dart.

final settingsServiceProvider = Provider<SettingsService>(
    (ref) => SettingsService(ref.watch(appDatabaseProvider)));

/// Live settings snapshot. Defaults while the first read is in flight.
final settingsProvider = StreamProvider<AppSettings>(
    (ref) => ref.watch(settingsServiceProvider).watch());
