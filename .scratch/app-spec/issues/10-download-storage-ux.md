# Decide: download manager and storage UX

Type: grilling
Status: resolved
Assignee: Rexyness
Blocked by: 03, 07

## Question

Given the download-manager research and the chosen sources, how do downloads work from the user's perspective and the app's? Decide: the download package/approach; per-download quality choice vs a global default; storage locations per platform and whether the user can choose; queue behavior (concurrency, pause/resume, retry); and the deletion/cleanup policy (manual only, or auto-delete watched episodes as an option).

## Resolution (2026-08-01)

Decided with the user (grilled 2026-08-01):

1. **Engine — `background_downloader` v9.x everywhere, behind an app-owned shim.** The single download engine on all four platforms (same shim pattern as `PlaybackController` from the playback decision); `dio` stays API-only. Accepted trade-offs: single-maintainer dependency, desktop as the less-trodden path (budget multi-GB desktop testing).
2. **No quality choice — downloads are MKV-only.** The canonical HEVC MKVs come in one flavor, so no quality picker exists for downloads (quality selection remains a streaming concern, per the content-source decision). This keeps "downloaded episodes have full audio/subtitle selection" universally true. Mitigation for size: show file size before committing to a download. "Compact MP4 downloads" is a possible post-launch follow-up, not v1.
3. **Storage — fixed app-private on mobile, configurable on desktop.** Android/iOS: app-private storage, not user-configurable (uninstall deletes episodes; accepted). Windows/Linux: default per-user app-data dir + a "download folder" setting via `file_selector`. Free-space: advisory pre-flight (Content-Length vs free bytes) that warns but doesn't block, plus honest ENOSPC handling; work around the Linux `/tmp` staging issue for multi-GB files. No Android export-to-shared-storage in v1.
4. **Queue — 2 fixed lanes, FIFO.** Concurrency fixed at 2 (frugal toward donation-funded Pixeldrain), no setting and no manual reordering in v1. Per-item pause/resume/cancel + global pause-all. `allowPause: true` + 3 auto-retries, then a visible "failed — tap to retry" state chaining into the decided dead-link degradation (mapping refresh → honest failure + magnet handoff). Queue survives restarts via the package's persistent task DB; app reconciles its records against it on every launch. Mobile gets a "Wi-Fi only" toggle, default ON; desktop has no such toggle.
5. **Cleanup — manual baseline + opt-in auto-delete watched.** Per-episode, per-arc, and delete-all controls with a storage-usage readout (total + per-arc). Auto-delete-watched is opt-in, default OFF; triggers only on *locally* watched (never on sync-in from another device) and fires when leaving the episode after crossing the watched threshold, not mid-credits. No time- or size-based eviction in v1.
