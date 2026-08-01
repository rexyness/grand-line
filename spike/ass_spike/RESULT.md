# Spike result: Android ASS rendering with media_kit — **GO**

Implementation step 0 from [spec §5](../../.scratch/app-spec/spec.md). Run 2026-08-01
against `media_kit 1.2.6` (pinned), `PlayerConfiguration(libass: true)`, streaming the
canonical One Pace MKV `[One Pace][132-135] Drum Island 02 [1080p][42F9FF82].mkv`
(HEVC, dual jpn/eng audio, 6 ASS sub tracks + font attachments) from
`https://pixeldrain.net/api/file/s79kDrd7`.

**Device: OnePlus 10 Pro (NE2213), Android/ColorOS, via wireless ADB.**

## Switch-trigger check (ticket 08): did NOT fire

- **Styled ASS renders correctly** — One Pace's own styled font (from the MKV's embedded
  font attachments) with outline, correct positioning, over HTTP streaming.
  Proof: `results/ass-english.png`, `results/ass-german.png`.
- **Track switching works** — `setSubtitleTrack` cycled English → Signs and Songs →
  German (visually confirmed, different language on screen); `setAudioTrack` switched
  Japanese ↔ English. All 6 sub + 2 audio tracks enumerated exactly as ffprobe reported.

**media_kit stays. video_player+fvp fallback not needed.**

## Findings the PlaybackController shim must carry

1. **Audio: override `ao=audiotrack,opensles`.** media_kit 1.2.6 hardcodes `ao=opensles`
   on physical Android devices (`real.dart:2408`); OpenSL ES `Realize()` fails on this
   device (error 9) → **no sound at all** with defaults. Setting
   `NativePlayer.setProperty('ao', 'audiotrack,opensles')` before `open()` fixes it
   (verified: AudioTrack session started, stereo 48 kHz). Needs the
   `package:media_kit/src/...` implementation import — acceptable inside the shim.
2. **`libassAndroidFont` + `libassAndroidFontName` are required** on Android alongside
   `libass: true` (fallback font, copied to files dir by media_kit). Roboto used here.
3. **hwdec falls back to software** — `hevc_mediacodec: Both surface and native_window
   are NULL` at open; 1080p HEVC software decode was smooth on this hardware. Revisit
   hwdec wiring later; not blocking.
4. **Android emulators cannot run the player** — mpv fails `Could not create EGL context
   for GLES 2.x+` under default, `-gpu host`, and `-gpu swiftshader_indirect` on the
   API-35 x86_64 image. Player work needs a physical device; the emulator remains fine
   for non-player UI.

## Reproduce

```
cd spike/ass_spike
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
# launch, wait ~10 s for the stream to open; buttons: CYCLE SUB / CYCLE AUDIO /
# PAUSE/PLAY / SEEK +30; track state in the green status line and `SPIKE` logcat lines.
```
