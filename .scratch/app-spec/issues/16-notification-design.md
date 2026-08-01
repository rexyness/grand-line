# Decide: release-notification design

Type: grilling
Status: resolved
Blocked by: 11

## Question

Given the [release-notifications research](../../docs/research/release-notifications.md), what is grand-line's new-release experience? Decide: whether to adopt the recommended shape (12 h server cron diffing the RSS into a `releases` table; clients check on launch; in-app "New" badge/list as the universal surface) and the cadence for both hops; where the badge/list lives in the immersive-carousel UI; which platforms get OS notifications and their opt-in story (Android background poll, best-effort iOS BGAppRefresh, while-running toasts on desktop — or fewer); and how notification preferences are stored (local, per the sync decision that settings don't sync).

## Resolution

Grilled 2026-08-01, grounded in the [release-notifications research](../../docs/research/release-notifications.md). The research's recommended architecture is adopted unchanged; the decisions below add the UI placement and preference posture it left open.

**Architecture & cadence (research shape, as-is):** the existing scheduled Supabase edge function also upserts the releases RSS into a `releases` table — keyed on infohash, `outdated` maintained in place, CRC32-joined to the community catalog to distinguish *new episode* (new arc/episode-number) from *updated release* (new infohash for an existing one). Cron every **12 h**. Clients read the table anonymously under read-only RLS: on launch/foreground everywhere, a **daily** WorkManager poll on Android, a 6–12 h in-app timer on desktop while running. No FCM/Firebase, no Realtime subscriptions, no push providers — one table, one cron entry.

**UI surface (immersive-carousel idiom):** a **badged bell/"New" entry in the home screen's top overflow area** (alongside Support One Pace/settings) opens a chronological release list; rows are labeled *new episode* vs *updated release* and deep-link to the episode. Additionally, small unseen-dots on affected arcs in the bottom arc strip tie news to browsing. No inline "new releases" rail — the home stays an arc stage, not a feed. Badges/dots clear per-item when the row is seen or the episode opened.

**OS notifications — all three tiers, one toggle, off by default.** A single per-device "Notify me about new episodes" setting:
- **Android:** toggle → `POST_NOTIFICATIONS` requested in context (never at first launch) → daily WorkManager poll + local notification. Works on degoogled devices.
- **iOS:** same toggle wires best-effort `BGAppRefreshTask` + local notification, honestly labeled ("iOS decides when sideloaded apps may check in the background"). APNs is impossible sideloaded and is never promised; the 7-day re-sign cadence guarantees the in-app badge catches up.
- **Windows/Linux:** same toggle gates an OS toast when the running app's periodic check finds news; closed apps catch up at next launch via the in-app surface.

Default **off** everywhere — the always-on in-app badge is the baseline; the OS notification is earned.

**Storage — everything local, per-device, in Drift.** The toggle is an ordinary local setting; the unseen watermark (newest seen `pub_date`/infohash) is also local and **not synced** — a release seen on desktop badges once more on the phone, deliberately: the badge is "news for this device," it clears in a tap, and syncing it would widen the sync surface the sync decision kept to watch progress only. No new storage machinery.
