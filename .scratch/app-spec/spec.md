# grand-line — implementation spec

**grand-line** is a free, ad-free, open-source Flutter app (GPL-3.0) for streaming and
downloading [One Pace](https://onepace.net) episodes on **Windows, Linux, Android, and iOS**,
with watch progress synced through an opt-in account, subtitle/audio/quality selection,
offline downloads, and new-release notifications.

This spec assembles every decision closed on the
[wayfinder map](map.md). It is implementable without reopening any decision; each section
links its ticket(s) for the reasoning. Dart package name: `grand_line`.

**Assembled:** 2026-08-01 · **Resolves:** [Task: assemble the implementation-ready spec](issues/14-write-spec.md)

---

## 1. Product shape

- **Content:** One Pace arcs and episodes (fan re-edit of One Piece, distributed free by the
  One Pace team). The app hosts nothing; it plays what the project publishes.
- **Modes:** streaming (MP4, quality selection) and offline downloads (MKV, full track
  selection). Fully usable with no account; sync is strictly opt-in.
- **Distribution:** GitHub Releases only — no app stores
  ([out of scope](map.md#out-of-scope)).
- **Posture:** unofficial, unaffiliated, attributes onepace.net prominently, surfaces their
  donation link, never ads or charges. A courtesy email precedes the repo going public
  ([Task: email the One Pace team](issues/15-contact-one-pace-team.md)).

## 2. Content sourcing

Decisions: [content source strategy](issues/07-content-source-strategy.md) ·
research: [content sources](../../docs/research/content-sources.md)

### 2.1 Two file flavors

| | Streaming | Downloads |
|---|---|---|
| Container | MP4 (H.264 + AAC) | MKV (HEVC, 1440x1080) |
| Subtitles | Hardsubbed (En Sub) or Dub variant | Soft ASS, multi-language + fonts |
| Audio | Per variant | Dual `jpn`/`eng` AAC |
| Quality | **480p / 720p / 1080p picker** | One canonical flavor, **no picker** — show file size before download |
| Source | Pixeldrain lists (`/l/{id}`) from the watch page | Pixeldrain single files (`/u/{id}`) from the releases page |

Pixeldrain serves bytes at `GET https://pixeldrain.net/api/file/{id}` with range-request
support (`206`, `Accept-Ranges`, CORS-open) — players stream directly; note the MP4 `moov`
atom sits at the tail, so playback requires range seeking, not sequential fetch.
Per-IP rate limit ~3000 requests (headers `X-Ratelimit-*`).

### 2.2 Catalog

- **Primary metadata:** `ladyisatis/one-pace-metadata` v2 JSON (hourly-updated,
  **CRC32-keyed**, raw.githubusercontent.com). Single-maintainer risk accepted, mitigated by
  the vendored snapshot.
- **Vendored snapshot:** a JSON snapshot ships as an app asset and seeds an empty Drift DB on
  first run (offline first launch works). A CI step in the release workflow regenerates it so
  every release ships a build-date-fresh snapshot.
- **New releases:** the official releases RSS (`/en/releases/rss.xml`) — full history, stable
  `urn:btih:{infohash}` GUIDs, `outdated` categories; needs a browser-like User-Agent
  (server-side only; the courtesy email offers to switch to an honest `grand-line-bot` UA).

### 2.3 Link resolution — clients never scrape

A scheduled Supabase edge function refreshes the watch-page → Pixeldrain list/file ID mapping
(~daily) and the RSS diff (12 h), writing Postgres tables (§3). Clients read those tables and
cache hard. Individual installs never touch onepace.net.

### 2.4 Degradation

On stream/download 404 or probe failure: client re-pulls the mapping (targeted refresh);
if still dead, the episode shows **"temporarily unavailable" + retry**, and offers a
**magnet handoff** to an external torrent client (RSS infohashes don't rot). No embedded
torrent engine. (`dtorrent_task_v2` remains a desktop-only contingency, not in v1.)

### 2.5 Etiquette

Aggressive caching everywhere; frugal Pixeldrain use (donation-funded — stream, don't
re-download; 2-lane download queue in §7); prominent attribution + donation links (§10.4);
polling budgets in §3.2/§8.

## 3. Backend (Supabase)

Decisions: [sync backend & account model](issues/09-sync-backend-decision.md) ·
[notification design](issues/16-notification-design.md) ·
research: [sync backend](../../docs/research/sync-backend.md),
[release notifications](../../docs/research/release-notifications.md)

Free tier, zero-ops. The anon key + URL ship in the public repo (safe by design); **RLS
enabled on every table**; the service_role key never ships. SQL migrations live in the repo
(`supabase/` via the Supabase CLI). A GitHub Actions cron pings the project during the
pre-launch zero-user window to defeat the 1-week API-inactivity pause.

### 3.1 Tables

| Table | Written by | Read by clients | Purpose |
|---|---|---|---|
| `arcs`, `episodes`, `sources` | edge function | anon, read-only RLS | catalog + Pixeldrain ID mapping |
| `releases` | edge function | anon, read-only RLS | RSS diff; pk `infohash`, `title`, `pub_date`, `variant`, `outdated`, `filename`, `crc32`, `magnet`, `first_seen_at` |
| `progress` | clients (RPC) | owner-only RLS (`user_id = auth.uid()`) | per-`(user, episode)`: `position`, `watched`, `updated_at` |

New release = insert of an unseen infohash (idempotent upsert; `outdated` maintained in
place). A new infohash for an existing (arc, episode) = *updated release*; a new
(arc, episode) = *new episode* — distinguished via the CRC32 join to the catalog.

### 3.2 Edge function & cron

One scheduled edge function (Supabase Cron / pg_cron): watch-page mapping refresh ~daily and
RSS→`releases` upsert every **12 h** (may share one job). ~60 invocations/month against a
500K free budget. The full user base costs One Pace the traffic of one visitor.

### 3.3 Progress sync RPC

An RPC applies an incoming progress row **iff its client-stamped `updated_at` is newer** than
the stored one (most-recent-activity-wins, per episode — see §8.3). Mirrored client-side on
pull. Clients read catalog/releases via plain PostgREST with the anon key — no bespoke API.

## 4. Features & screens

Decision: [core UI prototype](issues/06-prototype-core-ui.md) (Variant E "Immersive
carousel" won; asset on branch `prototype/core-ui`). Secondary surfaces below were designed
at spec assembly in the same idiom, per the map's fog note.

### 4.1 Home — immersive carousel

- Full-bleed backdrop of the focused arc, cross-fading on focus change.
- Minimal top chrome: logo · **search** · **downloads** · **bell ("New")** · overflow menu
  (Settings, Support One Pace, About).
- Bottom **arc strip**: every arc as a small backdrop card in voyage (saga) order; focused
  card enlarged/outlined. Unseen-release dots per §9.2.
- **Episode chips** row for the focused arc: `E1 ✓` watched, `E2 ▶` in progress; one tap to
  play. Primary actions on the focused arc: **Resume/Start** and **Download**.
- Layout adapts by window-size breakpoints (compact/expanded), not OS; same structure on
  mobile with shrunken cards/strip.

### 4.2 Player

Full-screen page. Seek bar, play/pause, next-episode; **pill menus** for subtitle track,
audio track, and quality:

- Streaming: quality pill (480/720/1080) + variant (En Sub hardsub / Dub); no track menus
  (MP4s carry none).
- Downloaded/local MKV: subtitle + audio track pills from embedded tracks; no quality pill.
- Styled ASS rendered over video (libass). Desktop adds keyboard shortcuts
  (space, ←/→ seek, F fullscreen, ↑/↓ volume) and hover-to-reveal controls behind input
  checks — not `Platform.isX`.
- Position is checkpointed to the local DB during playback and on exit; crossing the watched
  threshold sets `watched` (§8.3).

### 4.3 Search (designed at assembly)

Overlay (not a page): tap the search icon (or `/` / Ctrl+K on desktop) → dim the home,
text field up top, live-filtered results in two groups — **Arcs** and **Episodes**
(arc + episode number + title, with watched/progress markers). Enter/tap plays or focuses
the arc in the carousel. Local Drift query only — no network. Esc/back dismisses.

### 4.4 Downloads manager (designed at assembly)

Page from the downloads icon, two sections:

- **Queue:** active/queued items with per-item progress, pause/resume/cancel; global
  pause-all; failed items show "failed — tap to retry" (§7.4).
- **Library:** downloaded episodes grouped by arc with per-episode and per-arc size, storage
  readout (total + per-arc), per-episode/per-arc/delete-all controls.

Compact widths stack the sections; expanded shows them side by side.

### 4.5 Settings (designed at assembly)

Standard page from the overflow menu. Sections:

- **Playback:** preferred subtitle language + audio (jpn/eng) defaults for MKVs; default
  streaming quality (Auto→1080 default) and variant (En Sub / Dub).
- **Downloads:** download folder (desktop only, via `file_selector`); "Wi-Fi only"
  (mobile only, default ON); "Auto-delete watched episodes" (default OFF).
- **Notifications:** "Notify me about new episodes" (default OFF; §9.3), with per-platform
  honest copy (iOS: "iOS decides when sideloaded apps may check in the background").
- **Account:** sign in / sync status / sign out (§4.6).
- **About:** disclaimer, attribution + donation links, license, version (§10.4).

All settings are local (`shared_preferences`); visibility gated by `PlatformCapabilities`
flags, never raw platform checks.

### 4.6 Account & sync surface (designed at assembly)

Inside Settings → Account:

- Signed out: "Sign in to sync watch progress" → email field → 6-digit OTP field → done.
  One identical flow on all four platforms. No passwords, no OAuth (v1).
- First sign-in: local history uploads, then background syncing begins (§8.2).
- Signed in: account email, last-sync time, "Sync now", "Sign out" (local data stays).

## 5. Playback stack

Decision: [playback stack](issues/08-playback-stack-decision.md) ·
research: [playback stack](../../docs/research/playback-stack.md)

- **media_kit everywhere** — one engine (libmpv) for MP4 streams and MKV files on all four
  platforms. `PlayerConfiguration(libass: true)` for styled ASS; supply `libassAndroidFont`
  asset on Android. Track switching via `setSubtitleTrack`/`setAudioTrack`.
- **Isolation:** all playback sits behind an app-owned `PlaybackController` in
  `data/playback/`; no media_kit types leak out. A fallback swap stays contained to one module.
- **Implementation step 0 — Android ASS spike (mandatory, first):** play a current One Pace
  MKV on Android with `libass: true` + bundled font, streamed and local, verifying styled subs
  render and track switching works. **Switch trigger (written):** if styled subs don't render
  correctly or track switching fails and can't be worked around, switch to
  **video_player + fvp** (closed-source libmdk core; track switching via fvp's backend API).
  A failed spike reopens the playback decision and the subtitle UI wiring — accepted risk.
- **Caveats to carry:** pin media_kit's version (community-carried maintenance, bursty
  releases); accept the binary-size cost (heaviest option); follow media_kit docs for
  iOS/desktop packaging.

## 6. Local data & architecture

Decision: [architecture & state management](issues/12-architecture-decision.md)

### 6.1 Stack

- **Riverpod v3 + codegen** — DI graph and reactive plumbing in one tool; `StreamProvider`s
  project DB/queue streams onto the UI; provider overrides deliver fake-shim testability.
- **Drift (SQLite)** for all three stores — catalog cache, progress store, download registry.
  Relational joins power the home screen (arc → episodes → progress → download state);
  watchable queries stream into Riverpod; the LWW merge is expressed in SQL mirroring the
  server RPC. `shared_preferences` for settings.
- Rejected (do not revisit): BLoC, get_it+ChangeNotifier, Isar, Hive, raw sqflite.

### 6.2 Module structure — single package, two layers

```
lib/
  app/        MaterialApp, router, theme
  data/       headless plain-Dart services by domain:
    db/            Drift schema + DAOs
    catalog/       CatalogRepository (snapshot seed, watermark refresh)
    playback/      PlaybackController (media_kit shim)
    downloads/     DownloadService (background_downloader shim) + registry
    sync/          Supabase auth + progress push/pull
    notifications/ release polling + local-notification adapters
  features/   UI + providers per surface: home, player, downloads, settings, account
```

Import rules: `features/ → data/` only, never the reverse; engine packages
(media_kit, background_downloader, supabase_flutter) never leak past their shim folder
(lint-enforceable via import_lint).

### 6.3 Platform isolation

A `PlatformCapabilities` value (provider-exposed) with flags like `canChooseDownloadDir`,
`hasCellularToggle`, `notificationStyle`. Feature code branches on capabilities, never
`Platform.isX`; raw checks live only in `data/` adapters and the capabilities builder.
Desktop: `window_manager` for remember-size/min-size. No system tray, no per-platform widget
trees.

### 6.4 Catalog flow

Edge function → Postgres tables → client watermark refresh (`updated_at` cursor) → Drift →
UI. `CatalogRepository` refreshes on launch + manual pull-to-refresh; no background catalog
polling in v1 (dead-link handling already forces targeted refreshes). Vendored snapshot
seeds first run (§2.2).

## 7. Downloads & storage

Decision: [download manager & storage UX](issues/10-download-storage-ux.md) ·
research: [download manager](../../docs/research/download-manager.md)

1. **Engine:** `background_downloader` v9.x on all four platforms behind the
   `DownloadService` shim; `dio` stays API-only. Native background behavior: iOS URLSession
   (~4 h completion window), Android WorkManager with `allowPause: true` chunking.
2. **MKV-only, no quality picker** — show file size (from Pixeldrain metadata) before
   committing. "Compact MP4 downloads" is post-launch, not v1.
3. **Storage:** app-private on mobile (uninstall deletes episodes; accepted; no
   export-to-shared-storage in v1). Desktop: per-user app-data default + "download folder"
   setting (`file_selector`). Advisory free-space pre-flight (Content-Length vs free bytes)
   that warns but doesn't block; honest ENOSPC handling; work around Linux `/tmp` staging
   for multi-GB files (background_downloader issue #556).
4. **Queue:** 2 fixed lanes, FIFO — no concurrency setting, no manual reordering. Per-item
   pause/resume/cancel + global pause-all; 3 auto-retries then visible
   "failed — tap to retry" chaining into §2.4 degradation. Queue survives restarts via the
   package's persistent task DB; the app reconciles its registry against it on every launch.
   Mobile: "Wi-Fi only" toggle, default ON.
5. **Cleanup:** manual per-episode/per-arc/delete-all + storage readout. Opt-in
   auto-delete-watched (default OFF): triggers only on *locally* watched — never on synced-in
   state — and fires when leaving the episode after crossing the watched threshold. No time-
   or size-based eviction.

## 8. Accounts & watch-progress sync

Decision: [sync backend & account model](issues/09-sync-backend-decision.md)

1. **Local-only by default.** The local Drift DB is the source of truth regardless of
   sign-in state. "Sign in to sync" upgrades: first sign-in uploads local history, then
   background sync runs. No anonymous-first accounts.
2. **Email OTP is the sole sign-in method** (v1). Sessions persist per device.
3. **Only watch progress syncs:** per-`(user, episode)` `position` + `watched` +
   client-stamped `updated_at`. Settings and the download list stay local on principle.
4. **Merge — most-recent-activity wins, per episode.** Apply iff incoming `updated_at` is
   newer; enforced in the Postgres RPC and mirrored client-side on pull. Chosen over
   furthest-wins because rewatches and mark-unwatched must be able to move state backward.
   Idempotent and order-independent; worst case under clock skew is a briefly stale resume
   point. `watched` is sticky in the UI: finishing sets it; only an explicit user toggle
   clears it.

## 9. New-release experience

Decision: [notification design](issues/16-notification-design.md) ·
research: [release notifications](../../docs/research/release-notifications.md)

1. **Server:** §3's 12 h RSS diff into `releases`.
2. **Client checks:** on launch/foreground everywhere (rows newer than the local seen-
   watermark); Android adds a daily `workmanager` poll; desktop re-checks on a 6–12 h
   in-app timer while running. No FCM/Firebase, no Realtime subscriptions.
3. **In-app surface (universal):** badged **bell** in the home top chrome → chronological
   release list, rows labeled *new episode* vs *updated release*, deep-linking to the
   episode; plus unseen-dots on affected arc-strip cards. Badges/dots clear per-item when
   the row is seen or the episode opened. No inline feed rail — the home stays an arc stage.
4. **OS notifications — one per-device toggle, default OFF:**
   - Android: toggle → `POST_NOTIFICATIONS` requested in context → daily WorkManager poll +
     local notification (`flutter_local_notifications`). Works on degoogled devices.
   - iOS: best-effort `BGAppRefreshTask` + local notification, honestly labeled. APNs is
     impossible for sideloaded apps and is never promised; the 7-day re-sign cadence
     guarantees regular opens where the badge catches up.
   - Windows/Linux: OS toast (WinRT / freedesktop D-Bus) when the running app's check finds
     news; closed apps catch up at next launch. Smoke-test unpackaged-Windows toast
     activation early; `package:msix` is the known fallback.
5. **Storage:** toggle and seen-watermark are local per device (Drift/prefs), never synced.

## 10. Release, distribution & repo posture

Decision: [release & distribution strategy](issues/13-release-strategy.md) ·
research: [CI pipeline](../../docs/research/ci-pipeline.md)

### 10.1 Artifacts per release (tag `vX.Y.Z`, atomic)

`grand-line-vX.Y.Z-…`: `windows-x64.zip` (unsigned; SmartScreen expected) ·
`linux-x64.tar.gz` (AppImage via fastforge as a fast follow; Flatpak/Snap deferred) ·
`android.apk` fat **and** per-ABI splits (signed; base64 keystore in repo secrets — same
keystore forever) · `ios-unsigned.ipa` (sideload-only, Spotube-style).

### 10.2 Versioning

`pubspec.yaml` `version: X.Y.Z+N` is the single source of truth; tag must match (CI guard);
`+N` bumps monotonically every Android release. Start **v0.1.0**, stay 0.x until proven on
all four platforms. Release-when-ready, no schedule.

### 10.3 CI

- `ci.yml` (PR + push to main): `flutter analyze` + `flutter test` + Linux smoke build,
  ubuntu-only.
- `release.yml` (tag `v*` + `workflow_dispatch` dry-run): 4-job matrix
  (`subosito/flutter-action@v2`, pinned Flutter, cache on) → `actions/upload-artifact` →
  one release job → `softprops/action-gh-release@v2` with `generate_release_notes: true`.
- Plus: vendored-snapshot regeneration step (§2.2) and the pre-launch Supabase keep-alive
  cron. All free (public repo).

### 10.4 License, disclaimer, attribution

- **GPL-3.0** (libmpv linkage per IINA precedent; copyleft deters ad-mill forks).
- README: "What this is / What this isn't" block near the top — unofficial, unaffiliated
  (One Pace team, Toei, Shueisha, Crunchyroll), hosts no video, credits the One Pace team,
  links onepace.net + donation page, encourages supporting official One Piece releases.
  Install docs per platform, including the honest iOS story: AltStore/Sideloadly, 7-day
  re-sign + 3-app free-Apple-ID limits ("an Apple restriction, not ours"), one line each on
  the $99/yr developer-account out and EU/JP/BR marketplaces (no v1 commitment).
- In-app: **About** screen with the same disclaimer + prominent links, and a
  **"Support One Pace"** entry in the home overflow menu.

### 10.5 Arc backdrops

**Runtime-fetched, never vendored** (a GPL repo must not carry unlicensed art in its
history). URLs travel through the catalog pipeline; persistent disk cache keyed on the
catalog row's URL (refresh only on URL change — bundled feel after first launch, offline-
friendly); one original GPL-safe placeholder ships for offline first launch / fetch failure.
If the One Pace team blesses bundling (asked in the courtesy email), vendoring becomes a
cheap upgrade.

## 11. Suggested implementation ticket breakdown

Ordered; each is roughly one focused session unless noted. **Step 0 is mandatory first.**

1. **Spike: Android ASS rendering** (step 0, §5) — go/no-go on media_kit; on failure,
   execute the written switch to video_player+fvp before anything else builds on the player.
2. **Scaffold** — Flutter project, `app/`+`data/`+`features/` layout, Riverpod codegen,
   lints/import rules, `window_manager`, CI (`ci.yml`) from day one.
3. **Drift schema + vendored snapshot seed** — arcs/episodes/sources/progress/downloads
   tables, DAOs, first-run seeding from the bundled JSON.
4. **Supabase project + migrations** — tables, RLS policies, progress RPC, anon read
   policies; repo-committed SQL; keep-alive cron.
5. **Edge function** — watch-page mapping refresh + RSS→`releases` diff, pg_cron schedules.
6. **CatalogRepository** — PostgREST watermark refresh, pull-to-refresh, backdrop cache
   (§10.5) with placeholder fallback.
7. **Home carousel** — arc strip, episode chips, Resume/Start, backdrop cross-fade,
   adaptive breakpoints. (Meaty; may split visual polish out.)
8. **PlaybackController + player screen** — media_kit shim, streaming quality/variant
   pills, MKV track pills, desktop shortcuts, progress checkpointing.
9. **DownloadService + downloads manager screen** — background_downloader shim, 2-lane
   queue, registry reconciliation, storage settings + readouts, cleanup + auto-delete.
10. **Sync** — email OTP flow, first-sign-in upload, LWW push/pull, account surface.
11. **New-release surface** — seen-watermark, bell + list, arc-strip dots; then the OS
    notification tiers (Android WorkManager, iOS BGAppRefresh, desktop toasts) behind the
    toggle.
12. **Search overlay + settings screen + About** — local search, settings sections wired to
    capabilities, disclaimer/attribution/donation surfaces.
13. **Release pipeline** — `release.yml` matrix, signing secrets, snapshot regeneration,
    artifact naming, version guard; first `v0.1.0` tag.
14. **README + repo public** — disclaimer, install docs, iOS story; **send the courtesy
    email first** ([ticket 15](issues/15-contact-one-pace-team.md)) and fold in any reply.

Post-launch candidates (explicitly not v1): AppImage, compact MP4 downloads, Android
export-to-shared-storage, OAuth sign-in, Flatpak/Snap, EU alternative-marketplace iOS.

## 12. Decision index

| Area | Ticket |
|---|---|
| Content sources | [07](issues/07-content-source-strategy.md) (research [01](issues/01-research-content-sources.md)) |
| Core UI | [06](issues/06-prototype-core-ui.md) |
| Playback | [08](issues/08-playback-stack-decision.md) (research [02](issues/02-research-playback-stack.md)) |
| Sync & accounts | [09](issues/09-sync-backend-decision.md) (research [04](issues/04-research-sync-backend.md)) |
| Downloads | [10](issues/10-download-storage-ux.md) (research [03](issues/03-research-download-manager.md)) |
| Architecture | [12](issues/12-architecture-decision.md) |
| Release & distribution | [13](issues/13-release-strategy.md) (research [05](issues/05-research-ci-pipeline.md)) |
| Notifications | [16](issues/16-notification-design.md) (research [11](issues/11-research-release-notifications.md)) |
| One Pace contact | [15](issues/15-contact-one-pace-team.md) (open — HITL send) |
