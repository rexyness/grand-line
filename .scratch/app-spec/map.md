# Map: grand-line — One Pace watch app spec

Label: wayfinder:map

## Destination

An implementation-ready spec at `.scratch/app-spec/spec.md` for **grand-line**: an open-source Flutter app (Windows, Linux, Android, iOS) for streaming and downloading One Pace episodes, with watch progress + resume synced through a hosted backend, subtitle and quality selection, and new-release notifications. The map is done when every decision the spec depends on is closed and the spec is written.

## Notes

- Domain: cross-platform Flutter media app. Content is One Pace (fan re-edit of One Piece, distributed free via **onepace.net** — onepace.co, named in the original idea, is an unofficial SEO clone; see the content-sources research).
- Tracker: local markdown, this folder. Tickets live in `issues/NN-<slug>.md` with `Type:`, `Status:`, and `Blocked by:` lines (see repo tracker conventions). A ticket is unblocked when every ticket it lists is `resolved`; open + unblocked + not `claimed` = frontier.
- Skills: `/grilling` + `/domain-modeling` for grilling tickets, `/prototype` for the UI ticket, `/research` background subagents for research tickets. The `custom-plugin-flutter:*` agents are available for Flutter deep dives.
- Research findings land in `docs/research/<slug>.md`.
- Standing preferences (settled during charting):
  - Playback: streaming AND offline downloads.
  - Features: watch progress + resume, subtitle selection, quality selection, new-release notifications.
  - Distribution: open-source on GitHub with Releases (APK + Windows/Linux binaries); no app stores.
  - Watch progress syncs via **Supabase** — decided in [Decide: sync backend and account model](issues/09-sync-backend-decision.md).
  - Name: **grand-line** (Dart package `grand_line`), living at `D:\dev\grand-line`.
- Wayfinder default holds: plan, don't build. Execution starts after the spec exists.

## Decisions so far

<!-- one line per closed ticket: [ticket title](issues/NN-slug.md) — gist of the answer -->

- [Research: offline download management in Flutter across four platforms](issues/03-research-download-manager.md) — use `background_downloader` on all four platforms (native background downloads, pause/resume, persistent queue); dio for API calls only; torrents (`dtorrent_task_v2`) desktop-only contingency.
- [Research: CI and release pipeline for a 4-platform open-source Flutter app](issues/05-research-ci-pipeline.md) — one tag-triggered GitHub Actions matrix (free for public repos, even macOS) releasing Windows zip, Linux tar.gz (+AppImage later), signed APKs, and an unsigned iOS IPA users sideload via AltStore/Sideloadly with a 7-day free-Apple-ID re-sign cadence.
- [Research: hosted backend options for auth + watch-progress sync](issues/04-research-sync-backend.md) — Supabase: only zero-ops option with real Windows+Linux SDK support (pure Dart), anon key safe in public repo with RLS, free tier survives on API traffic; offline sync is DIY via local-DB queue + `GREATEST()` max-merge RPC. Firebase lacks Linux, Appwrite free tier pauses/deletes idle projects, PocketBase is self-host + pre-1.0.
- [Research: Flutter video playback stack for Windows/Linux/Android/iOS](issues/02-research-playback-stack.md) — media_kit (libmpv, `libass: true`) recommended: only open-source stack with MKV + styled ASS + track APIs on all four targets; spike Android ASS rendering first, with video_player+fvp (closed-source libmdk core) as fallback.
- [Research: how One Pace distributes episodes and metadata](issues/01-research-content-sources.md) — no official API (old GraphQL removed 2026); source catalog from the full-history releases RSS + community CRC32-keyed JSON (ladyisatis/one-pace-metadata), stream hardsubbed MP4s (480/720/1080p) straight off Pixeldrain's range-request/CORS-open file API, with canonical multi-sub HEVC MKVs via torrent/Pixeldrain as the download option.
- [Prototype: core UI — arc/episode browser and player screen](issues/06-prototype-core-ui.md) — Variant E "Immersive carousel" wins: full-bleed arc backdrop home with bottom arc strip + episode chips, Resume/Download as primary actions, full-screen player with track/quality pill menus; 5-variant prototype captured on branch `prototype/core-ui`.
- [Decide: content source strategy](issues/07-content-source-strategy.md) — MP4s for streaming (quality tiers, hardsub/dub) and canonical MKVs for downloads (track selection offline); catalog from ladyisatis/one-pace-metadata JSON + vendored snapshot, RSS for new releases; Pixeldrain IDs via a scheduled Supabase edge function (clients never scrape); dead links auto-refresh then degrade honestly to retry + magnet handoff.
- [Decide: playback stack](issues/08-playback-stack-decision.md) — media_kit (libass on) everywhere behind an app-owned PlaybackController abstraction; ASS-on-Android spike is implementation step 0 with a written switch-trigger to video_player+fvp; pin media_kit's version.
- [Decide: sync backend and account model](issues/09-sync-backend-decision.md) — Supabase; app fully usable local-only with sync strictly opt-in (local history uploads on first sign-in); email OTP as sole sign-in method; watch progress only syncs (position + watched per episode); most-recent-activity-wins merge on client `updated_at` (supersedes furthest-wins — rewatch and mark-unwatched must move backward).
- [Decide: download manager and storage UX](issues/10-download-storage-ux.md) — `background_downloader` behind an app-owned shim; MKV-only downloads (no quality picker, show size upfront); app-private storage on mobile, configurable folder on desktop; 2-lane FIFO queue with pause/resume, 3 auto-retries, Wi-Fi-only default ON on mobile; manual deletion + opt-in auto-delete locally-watched, no eviction caps.
- [Decide: app architecture and state management](issues/12-architecture-decision.md) — Riverpod (v3+codegen) and Drift; single package with headless `data/` services + `features/` per screen (shims never leak); `PlatformCapabilities` + size-adaptive layouts instead of per-platform trees; catalog flows edge-function → Postgres → watermark refresh → Drift with a CI-regenerated vendored snapshot.
- [Research: detecting and notifying new One Pace releases](issues/11-research-release-notifications.md) — releases RSS is a clean server-side delta source (stable infohash GUIDs, `outdated` flags; 403s without browser UA); Supabase pg_cron → `releases` table, clients poll it anon on launch; remote push impossible on sideloaded iOS, cheap only on Android; desktop notifies only while running. Recommended: in-app "New" list everywhere + opt-in OS notifications where cheap.
- [Decide: release and distribution strategy](issues/13-release-strategy.md) — GPL-3.0; releases ship Windows zip, Linux tar.gz (AppImage follow-up), fat+per-ABI signed APKs, and an unsigned IPA with the sideload treadmill documented; v0.1.0 start, release-when-ready; ubuntu-only PR CI + tag-triggered full matrix (`workflow_dispatch` dry-run); README/About disclaimer + home-screen "Support One Pace" link; arc backdrops runtime-fetched with persistent cache, never vendored (unless One Pace blesses it).
- [Decide: release-notification design](issues/16-notification-design.md) — research shape adopted as-is (12 h cron → `releases` table, anon client reads on launch); badged bell + release list in the home top area with unseen-dots on arc strip (no inline feed rail); one per-device opt-in toggle, off by default, wiring Android daily WorkManager, best-effort honest iOS BGAppRefresh, while-running desktop toasts; toggle and seen-watermark local in Drift, never synced.
- [Task: assemble the implementation-ready spec](issues/14-write-spec.md) — **[spec.md](spec.md) written — the destination is reached.** Every decision assembled with links back to its ticket; secondary surfaces (search overlay, downloads manager, settings, account) designed during assembly in the carousel idiom; ends with a 14-step implementation ticket breakdown (Android ASS spike first).

## Not yet specified

*(empty — the fog is cleared; the last patch, secondary-surface UI, was designed during spec assembly: see [spec.md](spec.md) §4.3–4.6.)*

## Out of scope

- App store publishing (Play Store / App Store) — declined during charting; fan-content apps face rejection/takedown there.
- macOS and web targets — the requested platforms are Windows, Linux, Android, iOS.
- Building the app itself — the destination is the spec; implementation is a follow-on effort.
- Features beyond One Pace content (general-purpose anime player ambitions).
