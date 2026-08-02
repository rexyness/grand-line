# grand-line

A free, ad-free, open-source Flutter app for streaming and downloading
[One Pace](https://onepace.net) episodes on Windows, Linux, Android, and iOS.

> **Status: early development — not yet released.**

## What this is / what this isn't

grand-line is an **unofficial fan project**. It is not affiliated with the One
Pace team, Toei Animation, Shueisha, or Crunchyroll. The app hosts no video —
it plays the streams and torrents the One Pace project publishes. All credit
for One Pace belongs to [the One Pace team](https://onepace.net); please
[support them](https://onepace.net) and official One Piece releases.

## Installing

Grab the latest artifacts from [Releases](https://github.com/rexyness/grand-line/releases).
(None published yet — see the status note above.)

### Windows

Download `grand-line-vX.Y.Z-windows-x64.zip`, extract anywhere, run
`grand_line.exe`. The binaries are unsigned, so SmartScreen will warn on
first launch — choose **More info → Run anyway**.

### Linux

Download `grand-line-vX.Y.Z-linux-x64.tar.gz`, extract, run `grand_line`.
Needs GTK 3 and libmpv (`libmpv2`/`mpv` in most distro repos). An AppImage
is planned as a follow-up.

### Android

Download the APK — `grand-line-vX.Y.Z-android-arm64-v8a.apk` fits most
modern phones; the fat `-android.apk` works everywhere but is larger.
Allow installs from unknown sources when prompted. Updates install over
the top (same signing key every release).

### iOS

Apple doesn't allow apps like this on the App Store, so iOS installs are
**sideload-only**: download `grand-line-vX.Y.Z-ios-unsigned.ipa` and
install it with [AltStore](https://altstore.io) or
[Sideloadly](https://sideloadly.io), which re-sign it with your own Apple
ID. With a free Apple ID the app must be re-signed every **7 days** (the
tools automate this while on the same network) and only **3 sideloaded
apps** can be installed at once — an Apple restriction, not ours. A paid
Apple Developer account ($99/yr) extends signing to a year, and in the
EU/JP/BR alternative marketplaces may eventually be an option (no
commitment for v1).

## Development

- Flutter (stable), targets: Windows, Linux, Android, iOS.
- Layout: `lib/app/` (shell) · `lib/data/` (headless services) ·
  `lib/features/` (UI per surface). `features/ → data/` only; engine packages
  never leak past their shim folder — enforced by `test/architecture_test.dart`.
- Spec: `.scratch/app-spec/spec.md`.

```sh
flutter pub get
dart run build_runner build   # codegen (committed)
flutter test
flutter run
```

## License

[GPL-3.0](LICENSE).
