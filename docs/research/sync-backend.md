# Research: hosted backend options for auth + watch-progress sync

Resolves [.scratch/app-spec/issues/04-research-sync-backend.md](../../.scratch/app-spec/issues/04-research-sync-backend.md). Researched 2026-08-01 against official docs, pricing pages, and SDK package pages. Candidates: Firebase (Auth + Firestore), Supabase, Appwrite Cloud, PocketBase (self-hosted).

Grand-line's constraints, restated: open-source public repo; targets **Windows, Linux, Android, iOS**; hobby-scale users; data is watch progress (+ maybe settings) with a "furthest progress wins" merge; prefer zero ops.

## 1. Firebase (Auth + Firestore)

**Desktop SDK support — disqualifying for this project.**

- The official FlutterFire setup docs support iOS, Android, Web, and other Apple platforms. **Linux does not appear in the platform matrix at all**, and Windows is explicitly caveated: "Firebase on Windows is not intended for production use cases, only local development workflows." — <https://firebase.google.com/docs/flutter/setup>
- Firestore **offline persistence** (the best-in-class feature here) is "supported only in Android, Apple, and web apps" — so even where Windows partially works, the offline story doesn't come with it. Persistence is on by default on Android/Apple; conflict handling for queued writes is last-write-wins per document. — <https://firebase.google.com/docs/firestore/manage-data/enable-offline>

**Free tier (Spark plan).**

- Auth: 50K MAU. Firestore: 1 GiB storage, 50K reads/day, 20K writes/day, 20K deletes/day; daily quotas reset around midnight Pacific. — <https://firebase.google.com/pricing>, <https://firebase.google.com/docs/firestore/quotas>
- At the limit: no surprise bills on Spark — "your project's usage of that specific product will be shut off for the remainder of that month" (daily quotas resume next day). Upgrade path is the pay-as-you-go Blaze plan. — <https://firebase.google.com/docs/projects/billing/firebase-pricing-plans>

**Public-repo hygiene: safe by design.**

- "API keys for Firebase services do not need to be treated as secrets, and it's safe to include them in your code or configuration files." Security is enforced by Firestore Security Rules (mandatory) and optionally App Check; API-key restrictions should still be applied. — <https://firebase.google.com/docs/projects/api-keys>

**Ops burden:** zero (fully hosted).

**Verdict:** best offline/sync machinery and clean public-repo story, but **no Linux SDK and Windows is dev-only** — it cannot serve two of grand-line's four platforms.

## 2. Supabase

**Desktop SDK support — full, because it's pure Dart over HTTP.**

- `supabase_flutter` supports **Android, iOS, Linux, macOS, Web, and Windows**. — <https://pub.dev/packages/supabase_flutter>
- Auth: email/password, magic link, OAuth providers, passkeys (beta), plus **anonymous sign-ins** (<https://supabase.com/docs/guides/auth/auth-anonymous>). One desktop caveat from the package docs: deep links (needed for the OAuth redirect round-trip) are listed for "Android, iOS, Web, MacOS and Windows" — **Linux is absent from the deep-link list**, so on Linux plan for email/magic-link/anonymous auth, or a loopback-server OAuth workaround. — <https://pub.dev/packages/supabase_flutter>

**Free tier.**

- 500 MB database (shared CPU, 500 MB RAM), 50K auth MAU, 5 GB egress, 1 GB file storage, **2 active projects**; "Free projects are paused after 1 week of inactivity" and can be resumed without data loss. Exceeding limits pushes you toward Pro (~$25/mo). — <https://supabase.com/pricing>
- Note: Supabase's inactivity trigger is API inactivity — an app with any real users generates API traffic and stays alive (contrast Appwrite below, whose criterion is *console* activity).

**Public-repo hygiene: safe by design.**

- The publishable/anon key is "Safe to expose online: web page, mobile or desktop app, GitHub actions, CLIs, source code." Security rests on Row Level Security — RLS must be enabled with policies on every table; the secret/service_role key bypasses RLS and must never ship. — <https://supabase.com/docs/guides/api/api-keys>

**Offline-first: not built in.**

- No offline persistence is documented in `supabase_flutter`; only session state is persisted locally. — <https://pub.dev/packages/supabase_flutter>
- For watch progress this is a small lift, not a blocker: keep the local DB (drift/Hive — needed anyway for offline downloads) as the source of truth, queue upserts, and merge server-side with `GREATEST(existing.position, incoming.position)` in a Postgres function/RPC. "Furthest progress wins" is order-independent (a max() merge), so conflicts resolve trivially without vendor sync machinery.

**Ops burden:** zero (hosted); Postgres schema migrations are yours to manage (SQL files in the repo — good for open source, reproducible via `supabase` CLI).

## 3. Appwrite Cloud

**Desktop SDK support — nominally full.**

- The Appwrite Flutter SDK "currently supports building apps for Android, iOS, Linux, Mac OS, Web and Windows"; desktop apps register their package name as a platform in the console. OAuth flows are documented for iOS/macOS (ASWebAuthenticationSession), Android (callback activity), and Web — desktop OAuth is comparatively under-documented. — <https://pub.dev/packages/appwrite>
- Auth: email/password, OAuth2, and anonymous sessions. — <https://appwrite.io/docs/products/auth/anonymous>

**Free tier — the deal-breaker.**

- Free plan: 75K MAU, 5 GB bandwidth, 2 GB storage, 750K function executions, 2 projects; on exceeding limits "Your project will freeze, and Appwrite Console will continue running in read-only mode." — <https://appwrite.io/pricing>
- **Free projects with no activity for 7 consecutive days are automatically paused, and projects paused for 90 days are deleted with all their resources.** Crucially, the "activity" criterion is developer activity in the Console — community threads report projects paused *despite daily active users*. For a finished hobby app that stops receiving console attention, this is fatal on the free tier. — <https://appwrite.io/changelog/entry/2026-02-20-1>, <https://appwrite.io/docs/advanced/platform/free>, <https://appwrite.io/threads/1481574986136158322>

**Public-repo hygiene: safe.**

- Client apps use only endpoint + project ID (shown openly in official init snippets), gated by the registered-platform allowlist; "API keys should be treated as a secret. Never share the API key and keep API keys out of client applications" — API keys are server-side only and never needed in the app repo. — <https://appwrite.io/docs/advanced/platform/api-keys>

**Offline-first:** no offline persistence documented in the current Flutter SDK. — <https://pub.dev/packages/appwrite>

**Ops burden:** zero if Cloud (but see pause/delete policy); self-hosting Appwrite is a full Docker-compose stack — heavier than PocketBase.

## 4. PocketBase (self-hosted)

**Desktop SDK support — full.**

- The `pocketbase` Dart SDK is multi-platform pure Dart (built on `package:http`): Android, iOS, Linux, macOS, Web, Windows. Auth: email/password, OAuth2 (all-in-one or manual flow), OTP; realtime subscriptions via SSE; `AsyncAuthStore` for persisting sessions. **No anonymous auth** among the documented flows. — <https://pub.dev/packages/pocketbase>

**"Free tier":** there is none because there is no official hosted offering — PocketBase is a single Go binary with embedded SQLite, **self-host only**. Your cost is a VPS (~$4–6/mo) or a third-party host, plus your time. — <https://pocketbase.io/docs/>

**Public-repo hygiene:** fine — the repo only needs the server URL; superuser credentials and server config stay on the server. But the *server deployment* (TLS, backups, updates) becomes part of the project's story.

**Offline-first:** none built in; same client-side queue + max() merge approach as Supabase, but you also write the merge logic as Go/JS hooks or accept last-write-wins.

**Operational burden — the deal-breaker for "zero ops":** you own uptime, TLS, backups, and upgrades, and PocketBase itself warns: "PocketBase is NOT recommended for production critical applications yet" — pre-1.0 (v0.39.x), with manual migration steps between releases and no backward-compatibility guarantee before 1.0. For an open-source app whose contributors can't share one production server's secrets, self-hosting also centralizes trust in whoever runs the box. — <https://pocketbase.io/docs/>

## Comparison table

| | Firebase (Auth+Firestore) | Supabase | Appwrite Cloud | PocketBase (self-host) |
|---|---|---|---|---|
| Windows SDK | Dev-only, "not for production" | Yes (pure Dart) | Yes | Yes (pure Dart) |
| Linux SDK | **No** | Yes | Yes | Yes |
| Android/iOS SDK | Yes (first-class) | Yes | Yes | Yes |
| Auth: email / OAuth / anonymous | Yes / Yes / Yes | Yes / Yes (no deep links on Linux) / Yes | Yes / Yes (desktop under-documented) / Yes | Yes / Yes / **No** |
| Free tier | 50K MAU; 1 GiB, 50K reads/day, 20K writes/day | 50K MAU; 500 MB DB, 5 GB egress | 75K MAU; 5 GB bandwidth, 2 GB storage | n/a (VPS ~$4–6/mo) |
| At the limit | Product shut off till quota resets; no auto-billing | Upgrade nudge; project pause after 1 wk *API* inactivity | Project freezes; **paused after 7 days without *console* activity, deleted after 90 days paused** | Your server, your problem |
| Safe-in-public-repo credentials | API key + config (safe by design; Rules required) | URL + anon key (safe by design; RLS required) | Endpoint + project ID (platform allowlist) | Server URL only |
| Offline-first built in | Yes (Android/Apple/web only — not desktop) | No (DIY queue + server-side max() merge) | No | No |
| "Furthest progress wins" merge | Client transaction or last-write-wins | Postgres RPC: `GREATEST(old, new)` — clean fit | Server function needed | Go/JS hook needed |
| Ops burden | Zero | Zero (SQL migrations in repo) | Zero, but keep-alive babysitting | Full: uptime, TLS, backups, pre-1.0 upgrades |

## Recommendation: Supabase

**Supabase** is the only zero-ops option whose Flutter SDK genuinely covers all four target platforms, with a free tier that stays alive under real user traffic and credentials (URL + anon key) that are safe by design in a public repo.

Trade-offs accepted:

- **No built-in offline sync** — Firebase's headline feature. Mitigated because (a) Firestore's offline persistence doesn't work on desktop anyway, and (b) watch progress merges as a simple max(): local DB as source of truth, background upsert through a Postgres RPC using `GREATEST()`, order-independent and conflict-free. RLS policies (`user_id = auth.uid()`) enforce isolation.
- **OAuth on Linux is awkward** (no deep-link support in `supabase_flutter` there). Mitigation: lead with email/magic-link and anonymous sign-in (progress syncs before any signup friction); OAuth becomes a nice-to-have.
- **Free-tier pause after 1 week of API inactivity** — only bites while the app has zero users; a trivial scheduled ping (GitHub Actions cron) covers the pre-launch window.
- **500 MB DB cap** — watch-progress rows are tiny (~100 bytes/episode/user); tens of thousands of users fit comfortably.

Why not the others: **Firebase** fails the Linux/Windows requirement outright. **Appwrite Cloud**'s 7-day console-inactivity pause and 90-day deletion make the free tier untrustworthy for a finished hobby app. **PocketBase** contradicts the zero-ops requirement and is pre-1.0 with breaking changes.
