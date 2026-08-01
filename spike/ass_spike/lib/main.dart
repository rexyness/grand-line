import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
// ignore: implementation_imports
import 'package:media_kit/src/player/native/player/real.dart';
import 'package:media_kit_video/media_kit_video.dart';

// Spike: does media_kit (libmpv + libass) render One Pace styled ASS subs on
// Android, and does embedded track switching work?
// Stream under test: canonical MKV "[One Pace][132-135] Drum Island 02
// [1080p][42F9FF82].mkv" — HEVC, dual jpn/eng audio, multi-language ASS subs
// with font attachments (verified in docs/research/content-sources.md).
const kMkvUrl = 'https://pixeldrain.net/api/file/s79kDrd7';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const SpikeApp());
}

class SpikeApp extends StatefulWidget {
  const SpikeApp({super.key});

  @override
  State<SpikeApp> createState() => _SpikeAppState();
}

class _SpikeAppState extends State<SpikeApp> {
  late final Player player = Player(
    configuration: const PlayerConfiguration(
      libass: true,
      libassAndroidFont: 'assets/fonts/Roboto-Regular.ttf',
      libassAndroidFontName: 'Roboto',
      logLevel: MPVLogLevel.warn,
    ),
  );
  late final VideoController controller = VideoController(player);

  String status = 'opening...';

  @override
  void initState() {
    super.initState();
    player.stream.log.listen((e) => debugPrint('SPIKE mpv [${e.level}] ${e.text}'));
    player.stream.error.listen((e) => debugPrint('SPIKE error: $e'));
    player.stream.tracks.listen((t) {
      debugPrint('SPIKE subs: ${t.subtitle.map((s) => '${s.id}:${s.title ?? s.language}').join(' | ')}');
      debugPrint('SPIKE audio: ${t.audio.map((a) => '${a.id}:${a.title ?? a.language}').join(' | ')}');
      _refresh();
    });
    player.stream.track.listen((_) => _refresh());
    player.stream.playing.listen((_) => _refresh());
    _open();
  }

  Future<void> _open() async {
    // media_kit hardcodes ao=opensles on physical Android devices, which fails
    // on this OnePlus (SL Realize error 9, "no sound"). mpv's audiotrack AO is
    // mpv-android's default and the candidate fix — spike finding for the shim.
    await (player.platform as NativePlayer).setProperty('ao', 'audiotrack,opensles');
    await player.open(Media(kMkvUrl));
    // Jump into dialogue so subs are on screen.
    await player.stream.duration.firstWhere((d) => d > Duration.zero);
    await player.seek(const Duration(minutes: 3));
  }

  void _refresh() {
    if (!mounted) return;
    final t = player.state.track;
    setState(() {
      status =
          'sub=${t.subtitle.id}:${t.subtitle.title ?? t.subtitle.language ?? '-'}  '
          'audio=${t.audio.id}:${t.audio.title ?? t.audio.language ?? '-'}  '
          'playing=${player.state.playing}';
    });
  }

  List<SubtitleTrack> get _subs =>
      player.state.tracks.subtitle.where((s) => s.id != 'auto').toList();
  List<AudioTrack> get _audios =>
      player.state.tracks.audio.where((a) => !['auto', 'no'].contains(a.id)).toList();

  void _cycleSub() {
    final subs = _subs;
    if (subs.isEmpty) return;
    final i = subs.indexWhere((s) => s.id == player.state.track.subtitle.id);
    final next = subs[(i + 1) % subs.length];
    debugPrint('SPIKE switching sub -> ${next.id}:${next.title ?? next.language}');
    player.setSubtitleTrack(next);
  }

  void _cycleAudio() {
    final audios = _audios;
    if (audios.isEmpty) return;
    final i = audios.indexWhere((a) => a.id == player.state.track.audio.id);
    final next = audios[(i + 1) % audios.length];
    debugPrint('SPIKE switching audio -> ${next.id}:${next.title ?? next.language}');
    player.setAudioTrack(next);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            Expanded(
              child: Video(controller: controller, controls: NoVideoControls),
            ),
            Container(
              color: Colors.black,
              padding: const EdgeInsets.all(4),
              child: Text(status,
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 11)),
            ),
            Row(
              children: [
                _btn('CYCLE SUB', _cycleSub),
                _btn('CYCLE AUDIO', _cycleAudio),
                _btn('PAUSE/PLAY', () => player.playOrPause()),
                _btn('SEEK +30', () =>
                    player.seek(player.state.position + const Duration(seconds: 30))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(String label, VoidCallback onTap) => Expanded(
        child: SizedBox(
          height: 56,
          child: TextButton(
            onPressed: onTap,
            child: Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 11)),
          ),
        ),
      );

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }
}
