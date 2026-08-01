# Research: Flutter video playback stack for Windows/Linux/Android/iOS

Researched 2026-08-01 against primary sources (pub.dev, GitHub repos and issue trackers). Question: which Flutter playback approach can play One Pace content — remote/local MKV with embedded ASS soft subtitles, multiple audio/sub tracks — on Windows, Linux, Android, and iOS?

## Candidates

### 1. media_kit (libmpv-based)

- **What it is:** Cross-platform player built on libmpv via Dart FFI ("80%+ implementation in 100% Dart"). Supports Android, iOS, macOS, Windows, GNU/Linux, Web. MIT license, verified publisher media-kit.dev. ([pub.dev/packages/media_kit](https://pub.dev/packages/media_kit))
- **MKV + codecs:** libmpv bundles FFmpeg demuxers/decoders, so MKV plays on every native platform, including iOS — no reliance on AVPlayer's container support. Hardware-accelerated rendering "up to 4K/8K 60 FPS". ([pub.dev/packages/media_kit](https://pub.dev/packages/media_kit))
- **ASS subtitle rendering:** the *default* Flutter-widget subtitle path (`SubtitleView`) renders extracted text only and does **not** do styled ASS. Styled rendering requires `PlayerConfiguration(libass: true)`, which burns subtitles in via libass inside the native video output. Users report this "works perfectly on Windows", but on Android embedded ASS subs have failed to display even with the `libassAndroidFont` option (font must be supplied as an asset on Android). ([media-kit issue #945 "Definite answer on subtitle rendering"](https://github.com/media-kit/media-kit/issues/945), [issue #255](https://github.com/media-kit/media-kit/issues/255))
- **Graphic subtitle formats** (PGS/HDMV — not needed for One Pace but indicative): selectable but not rendered on any platform. ([issue #1371](https://github.com/media-kit/media-kit/issues/1371))
- **Track selection:** first-class — `player.state.tracks` enumerates embedded video/audio/subtitle tracks; `setAudioTrack` / `setSubtitleTrack` switch them, plus external subtitle URIs (SRT/WebVTT/ASS listed as supported formats). ([pub.dev/packages/media_kit](https://pub.dev/packages/media_kit))
- **Streaming:** libmpv/FFmpeg handle HTTP(S) progressive playback, seeking via range requests, and local files natively; media_kit accepts network URLs and file paths through the same `Media` API. ([pub.dev/packages/media_kit](https://pub.dev/packages/media_kit))
- **Binary size:** ships prebuilt libmpv+FFmpeg via `media_kit_libs_*` packages per platform — the heaviest option here (tens of MB per platform; "-video" and slimmer "-audio" variants exist). ([pub.dev/publishers/media-kit.dev/packages](https://pub.dev/publishers/media-kit.dev/packages))
- **Maintenance health (Aug 2026):** latest stable `media_kit 1.2.6` published ~Jan 2026 — a 7-month gap as of writing; the 1.2.2–1.2.6 cluster all landed within ~2 months around Dec 2025–Jan 2026. 1.8k stars, **324 open issues**, 15 open PRs. Active issue traffic into mid-2026, but release cadence is bursty and largely community-carried; bus factor is a real concern. ([pub.dev/packages/media_kit/versions](https://pub.dev/packages/media_kit/versions), [github.com/media-kit/media-kit](https://github.com/media-kit/media-kit), [releases](https://github.com/media-kit/media-kit/releases))

### 2. video_player (official) — alone

- **What it is:** Flutter's first-party plugin. v2.13.0 published mid-July 2026 by flutter.dev; excellent maintenance. Backends: ExoPlayer (Android), AVPlayer (iOS/macOS), browser (Web). ([pub.dev/packages/video_player](https://pub.dev/packages/video_player))
- **Fatal gaps for this project:**
  - **No Windows or Linux support at all.** ([pub.dev/packages/video_player](https://pub.dev/packages/video_player))
  - **iOS cannot play MKV** — AVPlayer does not support the container; MKV works only on the ExoPlayer side. ([flutter/flutter issue #32029](https://github.com/flutter/flutter/issues/32029))
  - **No embedded-subtitle or ASS rendering** — only external `ClosedCaptionFile` (SubRip/WebVTT) supplied by the app; no embedded audio/sub track selection API. ([pub.dev/packages/video_player](https://pub.dev/packages/video_player))
- Verdict: disqualified on its own. Only viable as an *interface* fronted by fvp (below).

### 3. fvp (libmdk-based, video_player-compatible)

- **What it is:** "A plugin for official Flutter Video Player to support all desktop and mobile platforms" — registers as the video_player implementation on Windows x64/arm64, Linux x64/arm64, macOS, iOS, Android, HarmonyOS; also offers its own richer backend Player API (decoder selection, media info, play-from-position, `setExternalSubtitle()`, etc.). BSD-3-Clause plugin. ([github.com/wang-bin/fvp](https://github.com/wang-bin/fvp), [pub.dev/packages/fvp](https://pub.dev/packages/fvp))
- **MKV + ASS:** FFmpeg-based demux/decode (MKV fine everywhere); ASS/SSA rendered via **libass**, "added to your app automatically for windows, macOS, ohos and android"; iOS requires manually adding `ass.framework`; Linux uses system libass. Hardware decoding on all platforms (D3D11, Metal, OpenGL/Vulkan). ([github.com/wang-bin/fvp](https://github.com/wang-bin/fvp))
- **Size:** "only about 10MB size increase per cpu architecture" — the lightest full-codec option. ([pub.dev/packages/fvp](https://pub.dev/packages/fvp))
- **Maintenance health (Aug 2026):** v0.37.3 published ~July 2026; frequent releases; 352 stars, 68 open issues; essentially a **single maintainer** (wang-bin, author of QtAV) — bus factor 1. ([pub.dev/packages/fvp](https://pub.dev/packages/fvp), [github.com/wang-bin/fvp](https://github.com/wang-bin/fvp))
- **The catch — closed-source core:** the underlying `libmdk` (mdk-sdk) is distributed as **prebuilt binaries with a tiered license**: free for open-source projects and Flutter users, commercial licenses otherwise, and outdated/unlicensed SDKs "may see a QR image in the last frame". For an open-source app this is usable but weakens auditability, reproducible builds, and Linux distro packaging. ([github.com/wang-bin/mdk-sdk](https://github.com/wang-bin/mdk-sdk))
- **API caveat:** through the standard video_player interface there is no embedded audio/subtitle track-selection API; switching tracks requires dropping to fvp's own backend Player/extension APIs, which are thinner-documented. ([pub.dev/packages/fvp](https://pub.dev/packages/fvp))

### 4. Other options (surveyed, not viable)

- **flutter_vlc_player** (libVLC, solid.software): v7.4.4 ~Oct 2025; **iOS and Android only** — no Windows/Linux, so it cannot be the single stack. ([pub.dev/packages/flutter_vlc_player](https://pub.dev/packages/flutter_vlc_player))
- **better_player / forks**: wraps ExoPlayer/AVPlayer, so it inherits video_player's iOS-MKV and desktop gaps (MKV-no-sound class issues on record: [betterplayer #410](https://github.com/jhomlala/betterplayer/issues/410)).

## Comparison table

| Criterion | media_kit (libmpv) | video_player alone | video_player + fvp (libmdk) | flutter_vlc_player |
|---|---|---|---|---|
| Windows | Yes | **No** | Yes (x64/arm64, incl. Win7) | **No** |
| Linux | Yes | **No** | Yes (x64/arm64) | **No** |
| Android | Yes | Yes (ExoPlayer) | Yes | Yes |
| iOS | Yes | Yes, but **no MKV** | Yes (manual ass.framework for subs) | Yes |
| MKV container | Yes (FFmpeg) everywhere | Android only | Yes (FFmpeg) everywhere | Yes (libVLC) |
| Styled ASS embedded subs | Via `libass: true`; solid on Windows, **reported broken on Android** | No | Yes via libass, auto-bundled (iOS manual step) | libVLC renders ASS |
| Audio/sub track selection API | First-class (`setAudioTrack`/`setSubtitleTrack`) | None (external captions only) | Not in video_player API; via fvp backend Player API | Yes |
| HTTP streaming + local file | Yes | Yes (formats permitting) | Yes | Yes |
| Hardware decoding | Yes | Yes | Yes (D3D11/Metal/OpenGL) | Yes |
| Binary size | Heaviest (bundled libmpv+FFmpeg, tens of MB) | Minimal | ~10 MB per arch | Moderate |
| License / source | MIT, fully open | BSD-3, open | Plugin BSD-3 open; **core libmdk closed-source prebuilt** | Open (libVLC LGPL) |
| Latest release (as of 2026-08) | 1.2.6, ~Jan 2026 | 2.13.0, ~Jul 2026 | 0.37.3, ~Jul 2026 | 7.4.4, ~Oct 2025 |
| Maintenance signal | 324 open issues, bursty releases, community-carried | First-party, excellent | Active, but single maintainer | Active-ish, mobile-only |

## Recommendation

**Primary: media_kit with `PlayerConfiguration(libass: true)`.** It is the only fully open-source stack that covers all four targets with MKV + styled ASS + first-class embedded track selection through one API — exactly the One Pace shape. Its risks are (a) release cadence has slowed (last stable ~Jan 2026) with a large open-issue backlog, and (b) the documented Android reports of embedded ASS not displaying under libass mode, which must be validated first.

**Concrete plan:**
1. Spike media_kit on all four platforms against a real One Pace MKV (embedded ASS, multiple sub/audio tracks), specifically verifying styled ASS on **Android** with `libass: true` + bundled font, both streamed over HTTP and from a local file.
2. If the Android ASS path fails and cannot be worked around, fall back to **video_player + fvp**: it demonstrably renders ASS via libass on all four targets at ~10 MB/arch and is actively maintained — accepting the closed-source libmdk core (free for open-source apps, but watermark-on-stale-SDK licensing and weaker auditability) and the need to use fvp's backend API for track switching.
3. Do **not** build on video_player alone (no Windows/Linux, no MKV on iOS, no ASS) or flutter_vlc_player (mobile-only).

Trade-off summary: media_kit = open-source purity + best subtitle/track API, at the cost of maintenance risk, larger binaries, and an Android-ASS question mark; fvp = leanest and most actively shipped, at the cost of a closed-source core and a thinner track-selection story.

## Sources

- https://pub.dev/packages/media_kit
- https://pub.dev/packages/media_kit/versions
- https://github.com/media-kit/media-kit
- https://github.com/media-kit/media-kit/releases
- https://github.com/media-kit/media-kit/issues/945
- https://github.com/media-kit/media-kit/issues/255
- https://github.com/media-kit/media-kit/issues/1371
- https://pub.dev/packages/video_player
- https://github.com/flutter/flutter/issues/32029
- https://pub.dev/packages/fvp
- https://github.com/wang-bin/fvp
- https://github.com/wang-bin/mdk-sdk
- https://pub.dev/packages/flutter_vlc_player
- https://github.com/jhomlala/betterplayer/issues/410
