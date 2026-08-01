# Research: offline download management in Flutter across four platforms

Type: research
Status: resolved

## Question

What is the best way to implement an episode download manager in Flutter for Windows, Linux, Android, and iOS? Cover:

- Candidate packages (e.g. `background_downloader`, `flutter_downloader`, plain `dio` downloads) and their platform coverage — especially desktop support and background/paused-app behavior on Android and iOS.
- Resume/retry of interrupted large downloads (episodes are hundreds of MB to GB).
- Sensible storage locations per platform, free-space checks, and letting the user pick a location on desktop.
- Progress reporting and concurrent-download queuing.
- If torrents turn out to be a required source (see the content-sources research), what Dart/Flutter torrent options exist and how viable they are.

## Answer

Use **`background_downloader`** (v9.5.x, verified publisher, actively maintained) as the single download engine — it is the only credible package covering all four targets (iOS/Android/macOS/Windows/Linux), with true native background downloads (URLSession / WorkManager), pause/resume (`allowPause`), retries, a persistent task database that survives restarts, per-task and central progress streams, and queueing (`TaskQueue`/`holdingQueue`). `flutter_downloader` is mobile-only (disqualified); plain `dio` has no background story and would mean hand-rolling resume/queue/persistence — keep it for API calls only. Storage: app-support dirs by default, user-picked folder on desktop via `file_selector`, advisory free-space checks (`disk_space_2`-style) plus hard ENOSPC handling; note the Linux `/tmp` staging caveat for GB files. Torrents: `dtorrent_task_v2` is feature-complete but tiny-adoption and has no mobile background story — desktop-only contingency at best.

Full findings with source URLs and trade-offs: [docs/research/download-manager.md](../../../docs/research/download-manager.md)
