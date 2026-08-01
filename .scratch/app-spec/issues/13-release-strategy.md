# Decide: release and distribution strategy

Type: grilling
Status: resolved
Blocked by: 05

## Question

Also settle (surfaced by the UI prototype): the chosen UI leans on One Pace's official arc backdrops — can they ship inside the public repo/app, or must the app fetch them at runtime from onepace.net (and with what caching)?

Given the CI research, how does grand-line actually reach users? Decide: which artifacts each release ships (APK, Windows zip/installer, Linux packaging format, iOS IPA or not); the honest iOS install story documented in the README; versioning and release cadence; what runs on PR vs on tag; and the repo's public posture — license, disclaimer/attribution text, and whether to give the One Pace team a courtesy heads-up before publishing.

## Resolution

Grilled 2026-08-01, grounded in the [CI research](../../docs/research/ci-pipeline.md).

**Artifacts per release (`vX.Y.Z` tag, atomic — appears only when all platforms build):**
- Windows: zip of the release bundle, unsigned (SmartScreen warning documented as normal).
- Linux: tar.gz of the bundle from v1; AppImage via fastforge as a fast follow; Flatpak/Snap deferred indefinitely.
- Android: signed **fat APK plus per-ABI split APKs** (both — splits are free and much smaller for users who know their arch). Keystore lives base64-encoded in repo secrets; same keystore forever.
- iOS: **unsigned IPA ships from v1**, Spotube-style, labeled for sideloading — the 7-day free-Apple-ID re-sign treadmill is documented honestly, not hidden.

**Versioning & cadence:** single source of truth `pubspec.yaml` `X.Y.Z+N`; tag `vX.Y.Z` must match (CI guard); `+N` monotonic for Android upgrades. Start at **v0.1.0** and stay 0.x until the app has survived real use on all four platforms. **Release-when-ready, no fixed schedule.**

**CI split:** `ci.yml` on PR/push-to-main — `flutter analyze` + `flutter test` + Linux smoke build, ubuntu-only. `release.yml` on tag `v*` — full 4-platform matrix → `softprops/action-gh-release` with `generate_release_notes: true` (no hand-written changelog). Plus `workflow_dispatch` on `release.yml` so the full matrix can be dry-run before tagging. A failed tag build is cheap: delete tag, fix, re-tag.

**License: GPL-3.0.** Two grounds: (1) media_kit bundles libmpv, whose standard builds are GPL — licensing the app GPL-3.0 makes the linkage situation unambiguous (IINA precedent); (2) fork hygiene — ad-mill repacks of a fan client would poison relations with the One Pace team, and copyleft forces such forks into the open.

**Disclaimer & attribution:**
- README: "What this is / What this isn't" block near the top — unofficial fan client; unaffiliated with One Pace, Toei, Shueisha, Crunchyroll; hosts no video (plays streams the One Pace project itself distributes); credit + links to onepace.net and their donation page; a line encouraging support of official One Piece releases.
- In-app: **About screen** (via settings) with the same disclaimer + prominent onepace.net/donate links, **plus** a small "Support One Pace" entry on the home screen (overflow/menu area of the carousel — visible, not a nag banner). Home-screen presence is what makes the courtesy email credible.
- No "will remove upon request" theater in-app; the courtesy email itself genuinely offers to change course.

**Arc backdrops: runtime fetch, nothing vendored.** A GPL repo must not carry unlicensed copyrighted art in its history. Backdrop URLs travel through the existing catalog pipeline (clients never scrape); aggressive persistent disk cache (refresh only when the catalog row's URL changes — offline-friendly, bundled-feel after first launch); one original GPL-safe placeholder backdrop ships for offline-first-launch/fetch-failure. If the One Pace team's reply blesses bundling, vendoring becomes a cheap later upgrade.

**README install docs:** Windows — unzip and run, expect SmartScreen; Linux — extract and run; Android — allow-unknown-sources; iOS — sideload via AltStore (auto-refresh near AltServer) or Sideloadly, 7-day/3-app free-Apple-ID limits stated as "an Apple restriction, not ours", one line each on the $99/yr developer-account out and EU/JP/BR marketplaces (no v1 commitment); no push-notification promises on iOS.

**Courtesy contact:** already its own ticket — [Task: email the One Pace team](15-contact-one-pace-team.md), now unblocked by this resolution.
