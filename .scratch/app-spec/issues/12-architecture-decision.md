# Decide: app architecture and state management

Type: grilling
Status: resolved
Assignee: Rexyness
Blocked by: 08, 09, 10

## Question

Note (from the content-source decision): the architecture must also cover the **catalog sync path** — the scheduled Supabase edge function maintaining the watch-page → Pixeldrain mapping, the client's cache/refresh of it, and the vendored metadata snapshot's update story.

With the playback stack, backend, and download design known, what is the app's architecture? Decide: state management (e.g. Riverpod vs BLoC) and why; project/module structure; the local persistence layer (catalog cache, progress store, download registry — e.g. Drift vs Hive vs Isar) and how it plays with the sync backend's offline story; and how platform differences (desktop vs mobile layouts, storage, notifications) are isolated so the codebase stays one app, not four.

## Resolution (2026-08-01)

Decided with the user (grilled 2026-08-01):

1. **State management: Riverpod (v3, with code generation).** One tool for both DI and reactive plumbing — providers form the DI graph and `StreamProvider`s project DB/queue streams onto the UI. Provider overrides deliver the fake-shim testability the isolation strategy assumes. Rejected: BLoC (event/state ceremony without payoff here, still needs a separate DI story) and minimal ChangeNotifier+get_it (two tools for one job).
2. **Persistence: Drift (SQLite) for all three stores; `shared_preferences` for settings.** The data is relational (home screen = arc → episodes → progress → download-state join), Drift queries are watchable streams that plug into Riverpod, and the LWW sync merge ("apply iff `updated_at` newer") is expressed in SQL mirroring the server RPC. Bundled sqlite3 works identically on all four platforms; migrations are battle-tested. Rejected: Isar (maintenance stalled — disqualifying), Hive (abandoned upstream, KV-only), raw sqflite (no types/streams/desktop). Codegen cost already sunk via Riverpod's build_runner.
3. **Module structure: single package, two layers.** `lib/data/` — headless plain-Dart services by domain (`db/` Drift, `catalog/`, `playback/` media_kit shim, `downloads/` background_downloader shim + registry, `sync/` Supabase auth + progress push/pull, `notifications/`) — and `lib/features/` — UI + its providers per surface (home, player, downloads, settings, account), plus `lib/app/` for MaterialApp/router/theme. Import rules: features → data only, never the reverse; engine packages never leak past their shim folder (lint-enforceable via import_lint if wanted). Rejected: melos multi-package (friction without payoff solo) and full Clean Architecture (the shims are the abstraction boundary).
4. **Platform isolation: a `PlatformCapabilities` value + size-adaptive layouts, no per-platform widget trees.** Capabilities flags (`canChooseDownloadDir`, `hasCellularToggle`, `notificationStyle`, …) exposed via provider; feature code branches on capabilities, never `Platform.isX` — raw platform checks confined to `data/` adapters and the capabilities builder. Layout adapts by window-size breakpoints (compact/expanded), not OS; player adds desktop affordances (keyboard shortcuts, hover-to-reveal) behind input checks. Behavior divergence (storage paths, notification delivery) lives inside the owning `data/` service as internal adapters. Desktop: `window_manager` for remember-size/min-size; no system tray in v1.
5. **Catalog sync path: edge function → Postgres tables → watermark refresh → Drift → UI.** The scheduled edge function writes `arcs`/`episodes`/`sources` (+ `releases`) tables; clients read via PostgREST with anon key + read-only RLS (no bespoke API). UI reads Drift only; `CatalogRepository` refreshes on launch + manual pull-to-refresh using an `updated_at` watermark cursor (no background polling in v1 — dead-link handling already forces targeted refreshes). Vendored JSON snapshot bundled as an asset seeds an empty DB on first run; a CI step in the release workflow regenerates it from the live catalog so every release ships a build-date-fresh snapshot.
