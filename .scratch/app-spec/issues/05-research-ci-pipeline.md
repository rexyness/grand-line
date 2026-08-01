# Research: CI and release pipeline for a 4-platform open-source Flutter app

Type: research
Status: resolved

## Question

How should GitHub Actions build and release this app for Windows, Linux, Android, and iOS? Cover:

- Working workflow patterns for `flutter build windows` / `linux` (incl. Linux packaging: AppImage, Flatpak, tar.gz — which is least effort with acceptable UX), `apk`, and iOS.
- The iOS story for a **non-App-Store, open-source** app: unsigned IPA builds on CI, sideloading via AltStore/Sideloadly, signing constraints and 7-day/1-year re-sign cadences — what's realistic to offer users.
- Android signing in CI for a public repo (keystore via secrets).
- Release automation: tag-triggered builds attaching artifacts to GitHub Releases; versioning conventions.
- Rough CI-minutes cost of macOS runners for the iOS job on the free tier.

## Answer

One tag-triggered (`v*`) GitHub Actions workflow with four build jobs + a release job, all on `subosito/flutter-action@v2`. CI cost is $0: standard GitHub-hosted runners — including macOS — are free with no minute cap for public repos; the 10x macOS multiplier only applies to private repos. Windows: zip of `flutter build windows` bundle. Linux: tar.gz of the bundle first (GTK3 is the only runtime dep), AppImage via fastforge as the best-UX follow-up; skip Flatpak/Snap for v1. Android: signed fat + per-abi APKs, keystore base64-encoded in repo secrets, `key.properties` written at build time — keep the keystore forever. iOS: `flutter build ipa --release --no-codesign` on `macos-latest` produces an unsigned IPA attached to the release; users sideload with AltStore/Sideloadly under Apple's hard limits — 7-day expiry and 3-app cap on free Apple IDs (1 year with a $99/yr dev account; AltStore PAL removes limits but is EU/JP/BR-only and needs Apple notarization). Ship the IPA as a documented power-user channel and don't rely on APNs push on iOS. Release job aggregates artifacts via `softprops/action-gh-release`; version source of truth is `pubspec.yaml` `X.Y.Z+N` matching tag `vX.Y.Z`. Precedent: Spotube ships exactly this artifact set incl. sideload IPA; LocalSend skips the iOS sideload channel entirely.

Full findings with sources: [docs/research/ci-pipeline.md](../../../docs/research/ci-pipeline.md)
