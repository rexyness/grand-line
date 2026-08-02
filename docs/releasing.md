# Releasing grand-line

The pipeline (spec §10.1–10.3) is `.github/workflows/release.yml`: pushing a
tag `vX.Y.Z` builds all four platforms and publishes one atomic GitHub
Release. Running the workflow manually (**Actions → Release → Run workflow**)
is the dry run — it builds every artifact but publishes nothing.

## One-time setup: Android signing keystore

Release APKs must be signed with the *same key forever* — Android refuses
updates signed with a different key, and a lost keystore means every user
must uninstall/reinstall. Do this once, back the file up somewhere safe
(password manager / offline), and never commit it.

1. Generate the keystore (any machine with a JDK; Flutter ships one under
   `flutter doctor -v` → Java binary):

   ```sh
   keytool -genkey -v -keystore upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

   Pick a store password (and reuse it for the key when prompted, or note
   both).

2. Base64-encode it:

   ```sh
   # Git Bash / Linux / macOS
   base64 -w0 upload-keystore.jks > keystore.b64
   # PowerShell
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) > keystore.b64
   ```

3. Add four **repository secrets** (GitHub → Settings → Secrets and
   variables → Actions):

   | Secret | Value |
   |---|---|
   | `ANDROID_KEYSTORE_BASE64` | contents of `keystore.b64` |
   | `ANDROID_KEYSTORE_PASSWORD` | the store password |
   | `ANDROID_KEY_ALIAS` | `upload` |
   | `ANDROID_KEY_PASSWORD` | the key password |

Without these secrets the workflow still runs but signs with the debug key
— fine for dry runs, never for a published release.

## Cutting a release

1. Make sure `pubspec.yaml`'s `version: X.Y.Z+N` is what you intend — the
   tag must equal `vX.Y.Z` (the workflow fails otherwise), and `+N` must
   bump on every release that ships an APK.
2. Optionally run the dry run first and sanity-check the four artifacts.
3. Tag and push:

   ```sh
   git tag v0.1.0
   git push origin v0.1.0
   ```

4. The release appears with generated notes once **all four** platform
   builds succeed. Artifacts: `windows-x64.zip`, `linux-x64.tar.gz`, fat +
   per-ABI `android.apk`s, `ios-unsigned.ipa` (sideload-only).

Notes:

- Every build refreshes the vendored catalog snapshot from
  `ladyisatis/one-pace-metadata` first, so releases ship current data.
- While the repo is private, Actions minutes are billed against the free
  quota with a 10× multiplier on the macOS job (~15 min ≈ 150 quota
  minutes per run). Public repos are unmetered.
- The iOS artifact is unsigned by design; AltStore/Sideloadly re-sign it
  on the user's device (see the README's iOS section for the 7-day story).
