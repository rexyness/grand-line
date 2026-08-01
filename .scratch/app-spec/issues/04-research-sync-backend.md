# Research: hosted backend options for auth + watch-progress sync

Type: research
Status: resolved

## Question

Which hosted backend best fits syncing watch progress (and possibly settings) across devices for a small open-source Flutter app? Compare Firebase (Auth + Firestore), Supabase, Appwrite Cloud, and self-hosted lightweight options (e.g. PocketBase), on:

- Auth options (email, OAuth, anonymous) and their Flutter SDK quality on **desktop** (Windows/Linux) as well as mobile — desktop support is often the weak spot.
- Free-tier fit for a hobby-scale user base, and what happens at the limit.
- Open-source repo hygiene: what config/keys end up in a public repo, and whether that's safe by design (e.g. Firebase API keys are public by design vs services where it isn't).
- Offline-first behavior: local cache with later sync, conflict story for "furthest progress wins"-style merges.
- Operational burden if self-hosted vs zero-ops hosted.

## Answer

**Supabase.** It is the only zero-ops candidate whose Flutter SDK (`supabase_flutter`, pure Dart) genuinely supports all four targets — Windows, Linux, Android, iOS. Firebase is disqualified: FlutterFire has no Linux support and Windows is officially "not intended for production", and Firestore's offline persistence (its main draw) is Android/Apple/web-only anyway. Appwrite Cloud's SDK covers all platforms, but its free plan pauses projects after 7 days without *console* activity and deletes them after 90 days paused — untrustworthy for a finished hobby app. PocketBase (pure-Dart SDK, single binary) fails the zero-ops requirement and is pre-1.0.

Key Supabase facts: free tier is 50K auth MAU / 500 MB DB / 5 GB egress, pausing only after a week of *API* inactivity (real users keep it alive); the URL + anon/publishable key are safe by design in a public repo provided RLS is enabled on every table; auth covers email, magic link, OAuth, and anonymous sign-ins (OAuth deep links don't cover Linux — lead with email/anonymous there). Offline-first is DIY but a clean fit: local DB as source of truth, background upsert via a Postgres RPC using `GREATEST(old_position, new_position)` — "furthest progress wins" is an order-independent max() merge, so no vendor sync machinery is needed.

Full findings with per-claim source URLs and a comparison table: [docs/research/sync-backend.md](../../../docs/research/sync-backend.md)
