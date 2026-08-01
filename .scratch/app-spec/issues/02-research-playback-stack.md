# Research: Flutter video playback stack for Windows/Linux/Android/iOS

Type: research
Status: resolved

## Question

Which Flutter video playback approach can play One Pace content on all four targets (Windows, Linux, Android, iOS)? Compare at least `media_kit` (libmpv-based) and `video_player` (+ desktop implementations), noting any other credible options. Decisive criteria:

- MKV container support and **embedded ASS/SSA soft-subtitle rendering** (One Pace ships soft subs; correct styled rendering matters).
- Subtitle and audio track selection APIs (multiple languages, sub vs dub).
- Streaming a remote HTTP file (range requests / progressive playback) and playing a local downloaded file.
- Per-platform maturity: known issues on Windows, Linux, Android, iOS; binary size cost; hardware decoding.
- Maintenance health as of now (release cadence, open issues, bus factor).

## Answer

Full findings with per-claim sources: [docs/research/playback-stack.md](../../../docs/research/playback-stack.md).

- **Recommended: media_kit (libmpv) with `PlayerConfiguration(libass: true)`** — the only fully open-source stack covering all four targets with MKV, styled ASS, and first-class `setAudioTrack`/`setSubtitleTrack` APIs; HTTP streaming and local files both work via libmpv/FFmpeg. Risks: last stable release ~Jan 2026 with 324 open issues (community-carried maintenance), heaviest binaries, and GitHub reports that embedded ASS under libass mode fails on Android — must be spiked on a real One Pace MKV before committing.
- **Fallback: video_player + fvp (libmdk)** — actively maintained (v0.37.3, Jul 2026), renders ASS via libass on all four platforms (iOS needs manual ass.framework), ~10 MB/arch; but the libmdk core is closed-source prebuilt binaries (free for open-source use) and track switching requires fvp's backend API, not the video_player interface.
- **Ruled out:** video_player alone (no Windows/Linux, no MKV on iOS via AVPlayer, no ASS/embedded tracks) and flutter_vlc_player (Android/iOS only).
