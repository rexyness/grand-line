# Research: detecting and notifying new One Pace releases

Type: research
Status: resolved
Blocked by: 07, 09

## Question

Given the chosen content source and backend, how can the app detect new One Pace episodes and notify the user on each platform? Cover: what "new release" signal the chosen source exposes (feed, API delta, scrape diff); client-side polling vs a backend-assisted check (does the chosen sync backend offer cheap scheduled functions/push?); OS notification APIs from Flutter on Android, iOS (APNs constraints for a sideloaded app!), Windows, and Linux; and what cadence is respectful to One Pace's infrastructure.

## Context (now unblocked)

- Content source ([Decide: content source strategy](07-content-source-strategy.md)): new-release signal is the One Pace full-history releases RSS feed; a scheduled Supabase edge function already maintains the catalog server-side (clients never scrape onepace.net directly).
- Backend ([Decide: sync backend and account model](09-sync-backend-decision.md)): Supabase, so scheduled edge functions are available; accounts are strictly opt-in (email OTP), so any push design must not assume a signed-in user.
- Findings land in `docs/research/release-notifications.md`.

## Resolution (2026-08-01)

Findings in [docs/research/release-notifications.md](../../docs/research/release-notifications.md). Gist:

- **Signal**: the releases RSS is a clean delta source — full history (358 items), stable `urn:btih` infohash GUIDs to upsert by, `outdated` flags on superseded releases. It 403s without a browser UA and has no conditional GET (~674 KB/poll), so polling stays server-side only, as already planned.
- **Server hop**: Supabase free tier covers it — pg_cron + pg_net invoking an edge function that diffs the feed into a `releases` table. Supabase has **no push service**; Realtime's 200-concurrent-connection cap rules it out. Clients poll the table via anon-key PostgREST — no account needed, negligible egress.
- **iOS**: remote push is **flatly impossible** sideloaded (`aps-environment` entitlement is gated behind the paid Developer Program; personal-team re-signs can't carry it). Local notifications + `BGAppRefreshTask` do work sideloaded but are discretionary; the 7-day re-sign cadence guarantees weekly app-opens regardless.
- **Android**: the only cheap notify-while-closed platform — `workmanager` daily poll + `flutter_local_notifications` + in-context `POST_NOTIFICATIONS` permission. FCM skipped (needs Play services + a Firebase project).
- **Windows/Linux**: `flutter_local_notifications` v22 covers both (WinRT toasts work from an unpackaged zip; Linux via freedesktop D-Bus) — but only while the app runs; no background service.
- **Recommended design**: 12 h server cron → `releases` table; clients check on launch and show an in-app "New" badge/list everywhere; opt-in OS notifications only where cheap. Zero push providers, one table, one cron entry.

Design decisions graduate to [Decide: release-notification design](16-notification-design.md).
