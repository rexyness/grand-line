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
