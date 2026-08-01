# Research: offline download management in Flutter across four platforms

Ticket: [.scratch/app-spec/issues/03-research-download-manager.md](../../.scratch/app-spec/issues/03-research-download-manager.md)
Date: 2026-08-01. Sources are pub.dev/GitHub as of this date.

## Question

Best way to implement an episode download manager (hundreds of MB to GB per file) in Flutter for Windows, Linux, Android, and iOS — packages, platform coverage, background behavior, resume/retry, storage locations, free-space checks, progress, queuing, and torrent viability.

## Candidates

### background_downloader (recommended)

Source: <https://pub.dev/packages/background_downloader> · <https://github.com/781flyingdutchman/background_downloader>

- **Version/maintenance:** v9.5.7, published days ago by verified publisher bbflight.com; 234 stars, 912 commits, responsive maintainer. Actively maintained.
- **Platforms:** iOS, Android, macOS, **Windows, Linux** — the only serious download package covering all four targets. "No setup is required for Windows or Linux."
- **Background behavior:** true native background downloads — iOS uses `URLSession` (downloads continue with app suspended; must finish within ~4 h of enqueue), Android uses a `DownloadWorker` (WorkManager; ~9-minute task limit unless `allowPause: true` enables auto pause/resume chunking, or foreground-service mode for very long downloads). The README warns background tasks are "aggressively controlled by the native platform" — status updates can stop without warning, so the app must reconcile state from the package's persistent task database on resume.
- **Resume/retry:** pause/resume supported (`allowPause`); automatic resumption after Android timeouts; configurable per-task retries; tasks persist across app restarts via a persistent database. Fits GB-scale episode files.
- **Progress/queuing:** `onProgress`/`onStatus` callbacks per task plus a central `FileDownloader().updates` stream; `enqueueAll()`, `TaskQueue` and `holdingQueue` for concurrency limits; claims hundreds of simultaneous tasks; `ParallelDownloadTask` for multi-server chunked downloads.
- **Storage:** cross-platform `BaseDirectory` (applicationDocuments/support/temporary/library) + subdirectory + filename; can move completed files to shared storage; supports Android `content://` URIs and iOS URL bookmarks, with built-in file/directory pickers on mobile.
- **Desktop caveats:** desktop is clearly second priority to mobile. Known issue: on Linux, in-progress downloads are staged in `/tmp` (issue [#556](https://github.com/781flyingdutchman/background_downloader/issues/556), closed "not planned") — on systems with small tmpfs this matters for GB files; mitigate by downloading to a final-volume temp dir or verifying tmp capacity. Overall the desktop issue tracker is quiet, which reads as "works, lightly exercised" rather than "broken."

### flutter_downloader (rejected)

Source: <https://pub.dev/packages/flutter_downloader>

- v1.12.0, published ~18 months ago (fluttercommunity.dev). **iOS and Android only — no Windows/Linux**, which disqualifies it outright for grand-line.
- Where it does run it is decent (WorkManager / `NSURLSessionDownloadTask`, pause/resume, queue with default 3 concurrent), but it is slower-moving, resume issues a new task ID, iOS saves are restricted to `NSDocumentDirectory`, and older versions had SQL-injection vulnerabilities.

### dio (raw HTTP; not sufficient alone)

Source: <https://pub.dev/packages/dio>

- v5.11.0, actively maintained; all six platforms. `dio.download()` gives progress callbacks and `CancelToken` cancellation.
- **No background story:** downloads run in the app process and die when iOS/Android suspend the app. Resume is manual (`Range` headers + append-to-partial-file bookkeeping you write yourself), as is queuing, retry, and persistence.
- Verdict: keep dio for API calls (it may already be the HTTP client), but hand large episode downloads to background_downloader. Reimplementing queue + resume + background on top of dio is exactly the wheel background_downloader already ships.

## Storage locations, free space, user-picked directories

- **Default locations:** background_downloader's `BaseDirectory.applicationSupport` (or `applicationDocuments`) is the sane cross-platform default; on desktop these map to per-user app-data dirs via the same conventions as `path_provider` (<https://pub.dev/packages/path_provider>, supports all four targets).
- **User-picked location on desktop:** `file_selector`'s `getDirectoryPath()` supports Windows/Linux/macOS (<https://pub.dev/packages/file_selector>) — offer a "download folder" setting on desktop; on mobile stay inside app storage (iOS effectively requires it; Android scoped storage makes app-private simplest, with an optional "export/move to shared storage" using background_downloader's built-in move-to-shared-storage support).
- **Free-space checks:** no first-party plugin; community options exist, e.g. `disk_space_2` (fork covering Android/iOS/Windows/Linux, <https://pub.dev/packages/disk_space_2>) and `storage_space` (<https://pub.dev/packages/storage_space>). All are small/low-adoption; treat as advisory pre-flight checks (file size from `Content-Length` vs free bytes) and still handle ENOSPC failures gracefully. On Linux also account for the `/tmp` staging caveat above.

## Torrent viability (contingency)

Sources: <https://pub.dev/packages/dtorrent_task> · <https://pub.dev/packages/dtorrent_task_v2> · <https://github.com/atlet99/dtorrent_task_v2>

- Pure-Dart BitTorrent exists: `dtorrent_task` (original, stale) and its active fork `dtorrent_task_v2` (v0.5.4, published ~2 months ago; BitTorrent v1+v2, magnet links, built-in DHT, sequential/streaming mode, file selection, queue with priorities, UPnP).
- Reality check: unverified publisher, 3 likes, ~250 weekly downloads — feature-rich on paper but essentially un-battle-tested at grand-line's file sizes and platform spread. No mobile background story at all (a Dart torrent engine stops when the OS suspends the app), and torrenting from iOS is additionally hostile territory.
- **Verdict:** viable as a desktop-only, foreground/tray-running fallback if the content-sources research concludes direct HTTP is unavailable; not viable as the primary mobile download path. An alternative if torrents become mandatory on desktop is bundling a native engine (e.g. libtorrent via FFI) — significant effort, decide only if forced.

## Recommendation

**Use `background_downloader` as the single download engine on all four platforms**, with `dio` remaining the general HTTP client for API traffic. Configure episode tasks with `allowPause: true`, retries, and the built-in queue for 1–3 concurrent downloads; drive UI from the central updates stream and reconcile against its persistent task database on app start. Store to app-support dirs by default; on desktop expose a user-chosen directory via `file_selector`; pre-flight free space with `disk_space_2`-style checks plus hard error handling. Treat torrents as a desktop-only contingency via `dtorrent_task_v2` only if content-sources research forces it.

### Trade-offs accepted

- **Single-package dependency:** the whole offline feature leans on one community package (one primary maintainer). Mitigated by its verified publisher, release cadence, and the fact that its API is a thin layer we could shim.
- **Desktop is the less-trodden path:** works, but expect to own quirks like Linux `/tmp` staging; budget for desktop-specific testing with multi-GB files.
- **Mobile OS limits are real:** iOS 4-hour completion window and Android's pause/resume chunking mean very slow connections may need multiple resume cycles; the UI must present paused/interrupted states honestly.
- **Free-space checking is advisory only:** the ecosystem packages are small; failures at write time must still be handled.
