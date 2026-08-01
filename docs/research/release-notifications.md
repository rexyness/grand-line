# Research: detecting new One Pace releases and notifying users per platform

Resolves [.scratch/app-spec/issues/11-research-release-notifications.md](../../.scratch/app-spec/issues/11-research-release-notifications.md). Research date: 2026-08-01, against the live RSS feed, Supabase docs/pricing, pub.dev package pages, and Apple/Google/Microsoft first-party docs.

## TL;DR

- The releases RSS feed is a clean delta source: full history, stable infohash GUIDs, newest-first — the already-planned scheduled edge function diffs it into a `releases` table by upserting on infohash.
- Supabase free tier gives us everything server-side (Cron/pg_cron + Edge Functions + plain PostgREST reads) and nothing push-shaped — Supabase has **no push service**; wiring FCM is possible but buys almost nothing here.
- OS notifications: **Android is the only platform where notify-while-closed is cheap and honest** (WorkManager poll + local notification). iOS remote push is **impossible** for a free-Apple-ID sideloaded app (paid-program entitlement); background fetch nominally works but is unreliable. Windows/Linux toasts work fine via `flutter_local_notifications` — but only while the app is running.
- Recommendation: in-app "new releases" surface everywhere (check on launch), OS notifications where cheap (Android background; desktop while-running), nothing exotic.

---

## 1. New-release signal: the releases RSS feed

Verified live 2026-08-01 (`GET https://onepace.net/en/releases/rss.xml`):

- **403 without a browser-like User-Agent, 200 with one** (Cloudflare-fronted, `Server: cloudflare`) — same behavior as the rest of the site per [content-sources research](content-sources.md). Only the edge function fetches it, so a fixed browser-ish UA (or honest UA if the One Pace team blesses it — see the contact ticket) lives server-side in one place.
- **Full history, not a window**: 358 `<item>`s, newest-first, from the latest batch (3 items, `pubDate` Wed 29 Jul 2026) back to Mar 2013. Channel carries `<lastBuildDate>` (Thu 30 Jul 2026) but **no `<ttl>`**.
- **Stable unique key**: `<guid isPermaLink="false">urn:btih:{infohash}</guid>`, duplicated in `<torrent:infoHash>`. Also per item: `<title>` ("Drum Island 02"), `<pubDate>`, `<link>` (nyaa.si view page), `<enclosure>` (.torrent), `<torrent:magnetURI>`, `<torrent:fileName>` (canonical MKV filename embedding chapter range, quality, CRC32), and `<category domain="https://onepace.net/releases">` values `variant/regular|extended|alternate_g8` plus `outdated` on 90 superseded items.
- **No conditional-GET support**: response has no `ETag` or `Last-Modified` (checked with a HEAD request), and `cf-cache-status: DYNAMIC` — every poll downloads the full ~674 KB. Another reason polling belongs on the server, once, not on N clients.

### Diffing it into a `new_releases` table

The scheduled edge function (already planned for the Pixeldrain-mapping refresh) parses the feed and upserts into a `releases` table keyed by **infohash**:

- Row: `infohash (pk)`, `title`, `pub_date`, `variant`, `outdated (bool)`, `filename`, `crc32` (parsed from `torrent:fileName` — joins to the `ladyisatis/one-pace-metadata` CRC32-keyed catalog), `magnet`, `first_seen_at`.
- **New release = insert of an unseen infohash.** Re-runs are idempotent; the `outdated` flag is updated in place when the team flags supersessions.
- One wrinkle: re-releases reuse titles (the feed holds e.g. multiple "Drum Island 02" entries, older ones categorized `outdated`). For the user-facing "new episode" feed, treat a new infohash whose (arc, episode-number) already exists as a *re-release/quality-bump*, and a new (arc, number) as a *new episode* — distinguishable by joining on the community metadata.
- Clients never see the feed; they read the table (or a derived view like `select title, pub_date from releases where outdated = false order by pub_date desc limit 50`) with the anon key under a read-only RLS policy — **no account required**, consistent with opt-in auth.

## 2. Backend-assisted options on Supabase free tier

- **Scheduling — solved, free.** Supabase Cron "uses the `pg_cron` Postgres database extension", schedules "anywhere from every second to once a year", and Jobs can "make an HTTP request, such as invoking a Supabase Edge Function" (via pg_net). — <https://supabase.com/docs/guides/cron>
- **Edge Functions**: 500K invocations/month included free — two RSS polls a day uses ~60. — <https://supabase.com/pricing>
- **Realtime**: free tier includes **200 concurrent connections** and 2M messages/month. — <https://supabase.com/pricing>. Technically a client could subscribe to a broadcast channel ("Allow public access" channels work without sign-in; private channels need RLS on `realtime.messages` — <https://supabase.com/docs/guides/realtime/authorization>), but every open app holds a connection, so the 201st simultaneous user breaks it — a hard ceiling spent on delivering, at best, one event per week. Not worth it for daily-granularity news.
- **Push — Supabase has none.** The official guide integrates third-party push (FCM or Expo) by having a Database Webhook invoke an Edge Function that reads stored device tokens and calls the provider. — <https://supabase.com/docs/guides/functions/examples/push-notifications>. That means: a Firebase project dependency, a per-device token table (doable without accounts, but it's device-tracking infrastructure), and it would only ever serve Android here (iOS push is impossible sideloaded — §3.2; FCM has no Windows/Linux desktop client). Skip.
- **Device-level polling** (no auth): plain PostgREST `GET` with the anon key. A "new releases since X" response is a few hundred bytes; even 10K daily clients is well under the 5 GB/month egress line item. No edge function in the hot path at all.

## 3. OS notification APIs from Flutter

Package baseline: **`flutter_local_notifications` v22.2.0** supports **Android, iOS, macOS, Linux (Desktop Notifications Specification), Windows (C++/WinRT toasts), and Web** — <https://pub.dev/packages/flutter_local_notifications>. Background execution: **`workmanager` v0.9.0** (verified publisher fluttercommunity.dev) — "Execute Dart code in the background, even when your app is closed", via "workmanager_android: Android implementation using WorkManager" and "workmanager_apple: iOS/macOS implementation using Background Tasks". — <https://pub.dev/packages/workmanager>

### 3.1 Android — the full story works

- **Background poll**: WorkManager periodic work has a **15-minute minimum interval** and is deliberately inexact — "the exact time that the worker is going to be executed depends on the constraints ... and on the optimizations performed by the system", and runs "could be delayed, or even skipped". — <https://developer.android.com/develop/background-work/background-tasks/persistent/getting-started/define-work>. For a daily "any new episodes?" poll this sloppiness is irrelevant.
- **Permission**: "Android 13 (API level 33) and higher supports a runtime permission for sending non-exempt ... notifications from an app: `POST_NOTIFICATIONS`"; denied means "your app can't send notifications". Request it in context (when the user flips the "notify me" toggle), not at first launch. — <https://developer.android.com/develop/ui/views/notifications/notification-permission>
- **FCM in a non-Play APK**: explicitly allowed — "you are not limited to deploying your Android apps through Google Play Store" — but "FCM clients require devices ... that also have the Google Play Store app installed". — <https://firebase.google.com/docs/cloud-messaging/android/client>. So FCM would work for our GitHub-Releases APK on GMS devices, but fails degoogled devices (a real slice of the sideloading audience) and drags in a Firebase project. The WorkManager poll needs neither.

### 3.2 iOS (sideloaded, free-Apple-ID-signed) — what is impossible vs awkward

- **Remote push (APNs): impossible.** Registering with APNs requires the `aps-environment` entitlement, granted through the provisioning profile — <https://developer.apple.com/documentation/bundleresources/entitlements/aps-environment>. Apple's capabilities reference lists Push Notifications as an **Apple Developer Program (paid) capability**; free-agreement accounts "can't distribute apps" and don't get it — <https://developer.apple.com/help/account/reference/supported-capabilities-ios/>. AltStore/Sideloadly re-sign the IPA with the user's free-Apple-ID personal-team profile, so even an IPA we signed with a paid account would lose the entitlement at install time. There is no workaround; do not design anything that assumes APNs.
- **Local notifications: fine.** `UNUserNotificationCenter` needs only user permission, no entitlement; `flutter_local_notifications` supports scheduled and periodic notifications on iOS (64-pending limit). — <https://pub.dev/packages/flutter_local_notifications>
- **Background fetch (BGTaskScheduler): awkward, not impossible.** Configuration is Info.plist-only — `UIBackgroundModes: fetch` for `BGAppRefreshTask` plus the task identifier in `BGTaskSchedulerPermittedIdentifiers` — not a provisioning-profile entitlement (confirmed by the config surface: it's the plist keys App Store validation checks — e.g. <https://github.com/fluttercommunity/flutter_workmanager/issues/105>). Working existence proof: AltStore itself relies on iOS background refresh to re-sign sideloaded apps ("Background App Refresh should be enabled for AltStore ... App refreshes depend on iOS's background fetch, which can be unreliable" — <https://faq.altstore.io/>). So a sideloaded grand-line *can* schedule `BGAppRefreshTask` via `workmanager` — but iOS runs it entirely at its own discretion, users can disable Background App Refresh globally, and reliability for a rarely-opened app is poor.
- **The 7-day cliff dominates anyway**: "Apps installed with AltStore expire after 7 days, at which point they can no longer be opened" (free Apple ID; also a 3-sideloaded-app limit) — <https://faq.altstore.io/>. An expired app runs nothing, including background tasks. Any iOS user of this app necessarily touches their device's sideloading tooling weekly — a check-on-launch badge is never more than days stale in practice.

### 3.3 Windows — toasts work, but only while running

- `flutter_local_notifications` v22 ships Windows support (C++/WinRT). Unpackaged apps (our case — plain zip, no MSIX) **can show toasts**; the limitation is management: "Windows only allows apps with package identity to retrieve previously shown notifications. This means that on an app that was not packaged as an MSIX installer, cancel does nothing and getActiveNotifications will return an empty list." Also "Windows does not support repeating notifications, so `periodicallyShow` ... will throw". — <https://pub.dev/packages/flutter_local_notifications>
- Initialization requires `appName`, an `appUserModelId` ("CompanyName.ProductName..." form), and a callback `guid` — <https://pub.dev/documentation/flutter_local_notifications_windows/latest/flutter_local_notifications_windows/WindowsInitializationSettings-class.html>. Classic-Win32 background: Windows associates toasts with an AppUserModelID; Microsoft's classic guidance is a Start-menu shortcut carrying `System.AppUserModel.ID` ("Without a valid shortcut installed in the Start screen ... you cannot raise a toast notification from a desktop app" — <https://learn.microsoft.com/en-us/windows/win32/shell/enable-desktop-toast-with-appusermodelid>); the plugin performs AUMID registration itself on modern Windows 10/11, so a zip-shipped app works — worth a smoke test in the prototype, with MSIX (`package:msix`) as the known fallback if activation proves flaky.
- **No background service**: a zip-shipped Flutter desktop app has no notify-while-closed story short of installing an autostart/tray background process — out of scope and user-hostile for a hobby app. Toasts fire from an in-app timer while the app runs.

### 3.4 Linux — freedesktop notifications, same while-running constraint

- `flutter_local_notifications_linux` implements the freedesktop **Desktop Notifications Specification** (D-Bus `org.freedesktop.Notifications`); "capabilities depend on the system notification server implementation" and "scheduled/pending notifications is currently not supported due to the lack of a scheduler API". — <https://pub.dev/packages/flutter_local_notifications>, spec: <https://specifications.freedesktop.org/notification-spec/latest/>
- Works out of the box on GNOME/KDE/most desktops. As on Windows: only while the app process is alive.

### 3.5 Closed-vs-running summary

| Platform | Notify while app closed? | Notify while running | Mechanism |
|---|---|---|---|
| Android | **Yes** (WorkManager poll, inexact; survives reboot) | Yes | `workmanager` + `flutter_local_notifications`, `POST_NOTIFICATIONS` opt-in |
| iOS (sideloaded) | Best-effort only (`BGAppRefreshTask`, discretionary; dead after 7-day expiry) | Yes (local notif / in-app) | `workmanager` + `flutter_local_notifications`; **APNs impossible** |
| Windows (zip) | No (no service) | Yes (toast) | `flutter_local_notifications` WinRT, unpackaged caveats |
| Linux | No (no service) | Yes (D-Bus notification) | `flutter_local_notifications` freedesktop spec |

## 4. Respectful cadence

Two hops, two budgets:

- **Hop 1 — edge function → onepace.net RSS: every 12 hours** (Supabase Cron job invoking the function; can share the ~daily Pixeldrain-mapping refresh job). One Pace ships releases in batches weeks apart; the feed has no ETag/Last-Modified so each poll is a full ~674 KB — twice daily is ~1.4 MB/day *total, for the entire user base*, against a Cloudflare-cached site. This is the whole point of centralizing: N users cost One Pace the same as one.
- **Hop 2 — clients → Supabase table: on app launch/foreground, plus (Android only) a daily WorkManager poll; while-running desktop apps re-check on a 6–12 h in-app timer.** Responses are a few hundred bytes against *our* free-tier egress, not One Pace's servers. Clients store the newest `pub_date`/infohash they've surfaced and query for newer rows only. No Realtime subscription.

## Recommendation

**In-app new-release surface everywhere; OS notifications only where they're cheap.** Concretely:

1. **Server**: extend the existing scheduled edge function with the RSS→`releases` upsert (keyed on infohash, `outdated` maintained, CRC32 joined to the community catalog). Cron at 12 h. Clients read it anon, RLS read-only — works with zero accounts.
2. **All platforms**: on launch/foreground, fetch rows newer than last-seen and show a "New" badge + release list in-app (with the re-release vs new-episode distinction). This is the guaranteed path and the only one that behaves identically everywhere.
3. **Android**: opt-in "Notify me about new episodes" toggle → request `POST_NOTIFICATIONS` in context → daily `workmanager` periodic task polls the table and fires a local notification. No Firebase/FCM — no second backend, and it works on degoogled devices.
4. **iOS**: same toggle wires a best-effort `BGAppRefreshTask` + local notification, honestly labeled (Settings copy: "iOS decides when sideloaded apps may check in the background"). Never promise push; the 7-day re-sign cadence already guarantees regular app-opens where the in-app badge catches up.
5. **Windows/Linux**: show an OS toast (WinRT / freedesktop) when the running app's periodic check finds news — nice when the app is open in the background; no background service, so a closed app simply catches up at next launch via the in-app surface.

Total new infrastructure: one table, one cron entry, zero push providers.
