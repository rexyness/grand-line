# Research: CI and release pipeline for a 4-platform open-source Flutter app

Resolves: `.scratch/app-spec/issues/05-research-ci-pipeline.md`
Date: 2026-08-01

## TL;DR

- **Cost is a non-issue.** GitHub Actions standard hosted runners are **free with no minute cap for public repositories** — including macOS runners. Multipliers (Linux 1x / Windows ~1.67x / macOS ~10x by price) only matter for private repos. ([GitHub billing docs](https://docs.github.com/en/billing/managing-billing-for-your-products/managing-billing-for-github-actions/about-billing-for-github-actions))
- One tag-triggered workflow with a 4-job matrix (`ubuntu-latest`, `windows-latest`, macOS for iOS, plus Android on ubuntu) using `subosito/flutter-action@v2`, uploading everything to a GitHub Release, is the standard, proven shape (LocalSend, Spotube do exactly this).
- **Linux:** ship a `tar.gz` of the build bundle as the least-effort baseline; add AppImage as the best effort/UX ratio. Defer Flatpak/Snap.
- **Android:** signed APKs via a base64 keystore in repo secrets — well-trodden, safe for public repos.
- **iOS honest story:** CI produces an **unsigned IPA** (`flutter build ipa --no-codesign`); users must sideload it with AltStore/Sideloadly and (on a free Apple ID) re-sign **every 7 days, max 3 apps**. There is no way around Apple's rules without a $99/yr developer account (1-year signing) or, for EU/Japan/Brazil users, a notarized alternative-marketplace build. Ship the IPA, document the constraints plainly.

---

## 1. CI cost: macOS runners on the free tier

The GitHub billing docs are unambiguous:

> "GitHub Actions usage is free for self-hosted runners and for public repositories that use standard GitHub-hosted runners."

Since grand-line will be a public repo, **all four platform jobs — including the macOS job for iOS — cost zero minutes** on standard runners. The included-minute quotas (2,000/month on GitHub Free) and per-minute rates only apply to private repos:

| Runner | Rate (private repos) | Effective multiplier vs Linux |
|---|---|---|
| Linux 2-core x64 | $0.006/min | 1x |
| Windows 2-core x64 | $0.010/min | ~1.67x |
| macOS 3–4 core | $0.062/min | ~10x |

Source: [About billing for GitHub Actions](https://docs.github.com/en/billing/managing-billing-for-your-products/managing-billing-for-github-actions/about-billing-for-github-actions) and [GitHub Actions product billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions). Practical note: a Flutter iOS build on a hosted macOS runner typically takes 10–20 min; even if this repo were private, that's ~$0.60–$1.25 of the free quota per release at the 10x rate — but public means free regardless.

## 2. Per-platform build + packaging

### Toolchain setup (all jobs)

[`subosito/flutter-action@v2`](https://github.com/subosito/flutter-action) is the de-facto standard action: pin `flutter-version` (or point `flutter-version-file` at `pubspec.yaml`), `channel: stable`, `cache: true`. Works on ubuntu, windows, and macOS runners.

### Windows

- `flutter build windows --release`; output bundle at `build/windows/x64/runner/Release/` (exe + DLLs + `data/`).
- Outside the Microsoft Store, Flutter's docs say to ship the bundle **plus the Visual C++ redistributable DLLs**; a plain **zip of the release folder** is the documented minimal option, MSIX/installer optional later. ([Flutter Windows deployment docs](https://docs.flutter.dev/deployment/windows))
- No code signing (would require a paid certificate); users will see SmartScreen warnings — normal for open-source Windows apps distributed via GitHub Releases (LocalSend/Spotube ship unsigned exe/zip the same way).

### Linux

- `flutter build linux --release`; self-contained bundle at `build/linux/x64/release/bundle/` (binary + `lib/*.so` + `data/`). Build deps on the runner: `clang cmake ninja-build pkg-config libgtk-3-dev` (one `apt-get` line on ubuntu-latest). ([Flutter Linux build docs](https://docs.flutter.dev/platform-integration/linux/building))
- Flutter's docs confirm the bundle can simply be **tarred and run on another machine** provided GTK3 runtime libs are present (`libgtk-3-0 libblkid1 liblzma5` — preinstalled on essentially every desktop distro). ([Flutter Linux deployment docs](https://docs.flutter.dev/deployment/linux))
- **Least effort with acceptable UX, in order:**
  1. **`tar.gz` of the bundle** — zero extra tooling, works everywhere, "extract and run". Ship this first.
  2. **AppImage** — single double-clickable file, best UX-per-effort; Flutter docs point at [fastforge](https://github.com/fastforgedev/fastforge) (one config file, also emits deb/rpm) as the community tool. Add in a follow-up.
  3. **Flatpak** (via [flatpak-flutter](https://github.com/TheAppgineer/flatpak-flutter)/Flathub) and **Snap** — best desktop integration but each is its own publishing pipeline with store review; not worth it for v1. (Flutter's official docs lead with Snap, but Snap requires the Snap Store; for GitHub-Releases-only distribution tar.gz/AppImage fit better.)

### Android

- `flutter build apk --release` (single fat APK is simplest for GitHub Releases; `--split-per-abi` gives three smaller per-arch APKs — Flutter recommends split, but a fat APK is the friendlier single download for release pages; shipping both costs nothing). Output: `build/app/outputs/flutter-apk/`. ([Flutter Android deployment docs](https://docs.flutter.dev/deployment/android))
- **Signing in CI for a public repo** (required — unsigned APKs won't install):
  1. Generate an upload keystore locally with `keytool`; never commit it.
  2. Store `base64 < upload-keystore.jks` plus the store/key passwords and alias as **GitHub Actions repo secrets**.
  3. In the workflow, decode the keystore to `android/app/` and write `android/key.properties` from secrets; `build.gradle.kts` reads `key.properties` via the standard `signingConfigs` block from the Flutter docs.
  - The Flutter docs describe the keystore/`key.properties`/`signingConfigs` mechanics; the base64-in-secrets step is the standard CI adaptation (used by the widely-referenced community workflows, e.g. [this walkthrough](https://medium.com/@colonal/automating-flutter-builds-and-releases-with-github-actions-77ccf4a1ccdd)).
  - Keep the same keystore forever: Android updates require identical signing keys. Losing it means users must uninstall/reinstall.

### iOS (unsigned)

- On a macOS runner: `flutter build ipa --release --no-codesign`. The `--no-codesign` flag exists precisely so CI can build without any Apple credentials ([flutter/flutter#101765](https://github.com/flutter/flutter/issues/101765)). Alternative/equivalent: `flutter build ios --release --no-codesign`, then package `Runner.app` into `Payload/` and zip it as `.ipa` — the IPA format is literally a zip containing `Payload/Runner.app` ([community reference](https://filippovalle.medium.com/how-to-create-a-ipa-file-in-flutter-without-signin-70e9c6a2087f)).
- The resulting IPA is **unsigned**: it cannot be installed by tapping it. It exists to be *re-signed on the user's own machine* by a sideloading tool (section 3).
- Caveat: builds relying on special entitlements (push notifications, app groups) can lose them in unsigned CI builds ([flutter/flutter#153980](https://github.com/flutter/flutter/issues/153980)) — fine for grand-line, which needs none; plan for local-notification/polling rather than APNs push on iOS.

## 3. The honest iOS install story (non-App-Store, open source)

What users must actually do, in 2026:

- **Free Apple ID via AltStore Classic or Sideloadly** (the realistic default):
  - Apple's free-tier rules, which no tool can remove: apps signed with a free Apple ID **expire after 7 days** and only **3 sideloaded apps** can be installed at once ([AltStore FAQ](https://faq.altstore.io/), corroborated by [comparison](https://ios18apps.com/altstore-vs-sideloadly-vs-sidestore/)).
  - **AltStore Classic** requires AltServer running on a PC/Mac; it auto-re-signs ("refreshes") apps over Wi-Fi when phone and computer share a network. **Sideloadly** is a simpler one-shot USB/Wi-Fi installer (Windows/macOS), same 7-day/3-app limits. **SideStore** removes the "computer nearby every week" pain for many users but is more fiddly to set up.
- **Paid Apple Developer account ($99/yr)**: sideloaded apps signed with a developer certificate last **1 year** and the 3-app limit doesn't apply. Only worth mentioning for power users.
- **EU / Japan / Brazil — alternative marketplaces**: [AltStore PAL](https://faq.altstore.io/altstore-pal/what-is-altstore-pal) is an Apple-authorized marketplace (free since its grant funding — [TechCrunch overview](https://techcrunch.com/2026/02/22/move-over-apple-meet-the-alternative-app-stores-available-in-the-eu-and-elsewhere/)): apps **never expire, no computer, no app limit** — but apps must be **notarized by Apple**, which requires the developer (us) to hold a paid Apple Developer account and accept Apple's alternative-distribution terms. A possible later upgrade for EU users; not a v1 commitment, and it does nothing for US users.
- **Precedent:** [Spotube](https://github.com/KRTirtho/spotube) (open-source Flutter) ships exactly this: an `.ipa` in GitHub Releases labeled "Requires sideloading with AltStore or similar tools." [LocalSend](https://github.com/localsend/localsend) chose the opposite: App Store only for iOS, no sideload artifact — evidence that some Flutter projects judge the sideload UX not worth supporting, and that shipping the IPA is a low-cost "power users only" offer, not a mainstream channel.

**What's realistic to offer:** attach the unsigned IPA to each release with a README section that says, verbatim honestly: *"iOS: sideload with AltStore or Sideloadly. With a free Apple ID the app must be re-signed every 7 days (AltStore automates this while your phone is near a computer running AltServer) and Apple limits you to 3 sideloaded apps. This is an Apple restriction, not ours."* Do not promise notifications-via-push or painless installs on iOS.

## 4. Release automation and versioning

- **Trigger:** `on: push: tags: ['v*']`. Tag `vX.Y.Z` → workflow builds all platforms → attaches artifacts to a GitHub Release for that tag. This is the pattern used by LocalSend/Spotube and every community guide ([example](https://medium.com/@colonal/automating-flutter-builds-and-releases-with-github-actions-77ccf4a1ccdd)).
- **Release step:** `softprops/action-gh-release@v2` with a glob of artifacts, `permissions: contents: write` on the job, and `generate_release_notes: true` for free changelogs. Build jobs upload via `actions/upload-artifact@v4`; a final `release` job downloads all and attaches them (keeps the release atomic — it appears only when every platform built).
- **Versioning:** single source of truth in `pubspec.yaml` `version: X.Y.Z+N` (semver + build number; the `+N` becomes Android `versionCode`/iOS build number). Git tag must match (`vX.Y.Z`); a cheap guard step can assert `pubspec.yaml` version == tag. Bump `+N` monotonically for every Android release so upgrades install cleanly.
- **Artifact naming:** `grand-line-vX.Y.Z-{windows-x64.zip, linux-x64.tar.gz, android.apk, ios-unsigned.ipa}` (+ per-abi APKs if split).

## 5. Recommended pipeline shape

Two workflows:

**`ci.yml`** — on PR/push to main: `ubuntu-latest` only — `flutter analyze` + `flutter test` + a `flutter build linux` smoke build. Fast and free.

**`release.yml`** — on tag `v*`:

```
jobs:
  build-windows   (windows-latest): flutter build windows → zip Release/ folder
  build-linux     (ubuntu-latest):  apt-get GTK deps → flutter build linux → tar.gz bundle
                                    (later: + fastforge AppImage)
  build-android   (ubuntu-latest):  decode keystore secret → key.properties →
                                    flutter build apk [--split-per-abi] → signed APK(s)
  build-ios       (macos-latest):   flutter build ipa --release --no-codesign →
                                    unsigned .ipa from build/ios/ipa (or zip Payload/)
  release (needs: all four):        download-artifact → softprops/action-gh-release
```

All jobs: `actions/checkout@v4` + `subosito/flutter-action@v2` (pinned Flutter version, `cache: true`). Total runner cost: $0 (public repo). Expected wall-clock ~15–25 min per release, dominated by the macOS job.

**iOS bottom line for the spec:** grand-line can *build* iOS for free forever, but can only *deliver* iOS as a sideload artifact with a 7-day re-sign treadmill for free-Apple-ID users. That constraint should be stated in the README and factored into iOS feature decisions (no APNs push; notifications on iOS = local/polled while app runs).

## Sources

- https://docs.github.com/en/billing/managing-billing-for-your-products/managing-billing-for-github-actions/about-billing-for-github-actions
- https://docs.github.com/en/billing/concepts/product-billing/github-actions
- https://docs.flutter.dev/deployment/windows
- https://docs.flutter.dev/deployment/linux
- https://docs.flutter.dev/platform-integration/linux/building
- https://docs.flutter.dev/deployment/android
- https://github.com/subosito/flutter-action
- https://github.com/flutter/flutter/issues/101765
- https://github.com/flutter/flutter/issues/153980
- https://faq.altstore.io/altstore-pal/what-is-altstore-pal
- https://techcrunch.com/2026/02/22/move-over-apple-meet-the-alternative-app-stores-available-in-the-eu-and-elsewhere/
- https://ios18apps.com/altstore-vs-sideloadly-vs-sidestore/
- https://github.com/KRTirtho/spotube
- https://github.com/localsend/localsend
- https://medium.com/@colonal/automating-flutter-builds-and-releases-with-github-actions-77ccf4a1ccdd
- https://filippovalle.medium.com/how-to-create-a-ipa-file-in-flutter-without-signin-70e9c6a2087f
