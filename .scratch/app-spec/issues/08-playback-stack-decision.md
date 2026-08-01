# Decide: playback stack

Type: grilling
Status: resolved
Blocked by: 02, 07

## Question

Given the playback research and the chosen content sources (container/codec/subtitle reality), which player package does the app commit to across Windows, Linux, Android, and iOS? Lock: the package, how subtitle and audio track selection is exposed, how streaming vs local-file playback is handled, and any per-platform caveats the spec must carry (binary size, hardware decoding, known bugs).

## Answer

Decided with the user (grilled 2026-08-01):

1. **media_kit everywhere** — one engine (libmpv, `PlayerConfiguration(libass: true)`) for both MP4 streams and MKV downloads on all four platforms. Track menus use `setSubtitleTrack`/`setAudioTrack`. Rejected: hybrid video_player+media_kit (video_player lacks Windows/Linux, so the split only helps mobile at the cost of two integrations) and fvp-everywhere (closed-source libmdk core).
2. **Isolation as insurance** — all playback sits behind one app-owned `PlaybackController` abstraction; no media_kit types leak outside it, so a fallback swap stays contained to one module.
3. **Conditional commit** — the Android embedded-ASS risk (GitHub reports of libass-mode failures) is handled by mandating the spike as **implementation step 0**, with a written switch-trigger: if a current One Pace MKV's styled subs don't render correctly on Android or track switching fails, switch to **video_player + fvp** (designated fallback). Chosen over spiking before closing this ticket — accepted risk: if the spike fails, this decision and the subtitle UI wiring reopen post-spec.
4. **Spec caveats** — pin the media_kit version (maintenance is community-carried and has slowed); accept the binary-size cost (heaviest option); iOS/desktop packaging per media_kit docs.

## Addendum: step-0 spike result (2026-08-01) — GO, switch-trigger did not fire

The mandated Android ASS spike ran on a real device (OnePlus 10 Pro, NE2213) against a current One Pace MKV streamed from Pixeldrain: **styled ASS renders correctly** (embedded font attachments honored) and **track switching works** for all 6 subtitle + 2 audio tracks. **media_kit stays; the video_player+fvp fallback is not needed.** Full findings and proof screenshots: `spike/ass_spike/RESULT.md` on branch `spike/android-ass`.

Caveats for the shim discovered by the spike: media_kit's hardcoded `ao=opensles` produces **no audio** on this device — the shim must set `ao=audiotrack,opensles` before open; `libassAndroidFont`(+`Name`) is required alongside `libass: true`; hevc hwdec falls back to software (smooth at 1080p, revisit later); Android **emulators cannot create an EGL context for mpv at all** — player testing needs real hardware.
