# Decide: sync backend and account model

Type: grilling
Status: resolved
Blocked by: 04

## Question

Given the backend research, which hosted backend does watch-progress sync use, and what is the account model? Decide: the provider; sign-in methods (email/OAuth/anonymous-first?); whether the app is fully usable without an account (local-only mode) and what upgrading to synced looks like; exactly what syncs (progress, settings, download list?); and the conflict rule when two devices disagree.

## Resolution (2026-08-01)

- **Provider: Supabase.** Per the [backend research](../../docs/research/sync-backend.md): the only zero-ops option whose Flutter SDK genuinely covers Windows/Linux/Android/iOS (pure Dart over HTTP), anon key + RLS is safe by design in a public repo, and the free tier stays alive under real user API traffic. Firebase fails Linux/Windows; Appwrite's console-inactivity pause/delete policy is fatal for a finished hobby app; PocketBase contradicts zero-ops and is pre-1.0.
- **Account model: local-only by default, sync strictly opt-in.** The app is fully usable with no account; the local DB is the source of truth regardless. A "Sign in to sync" affordance upgrades: on first sign-in, local history uploads, then background syncing begins. **No anonymous-first**: an anonymous identity is device-bound, so it can't deliver cross-device sync (the only point of sync) while burning MAU quota and filling the DB with orphan rows.
- **Sign-in: email OTP only for v1** (type email, receive 6-digit code, type it in). No passwords (reset flows, breach hygiene — for a watch-progress account), no OAuth (`supabase_flutter` has no deep-link support on Linux; the loopback workaround isn't worth it for a nice-to-have). One identical flow on all four platforms; sessions persist so it's roughly once per device. OAuth is additive later if ever wanted.
- **What syncs: watch progress only** — per-`(user, episode)` playback position + watched state. Settings stay local (splitting device-bound vs taste settings is modeling work for ten seconds of user savings). Download list stays local on principle: downloads are per-device facts; syncing the list would imply files follow you or force a wishlist/downloaded-here split.
- **Conflict rule: most-recent-activity wins, per episode** — *supersedes the "furthest progress wins" sketch from charting.* Each row carries `position`, `watched`, `updated_at` (client-stamped at the watch event); an incoming write applies iff its `updated_at` is newer than the stored one, enforced in a Postgres RPC server-side and mirrored client-side on pull. Furthest-wins can't honor a deliberate rewatch (refuses to move a resume point backward) and can't propagate mark-unwatched (monotonic merges never un-set). Most-recent-wins stays idempotent and order-independent; worst case under device clock skew is a briefly stale resume point. `watched` is sticky in the UI sense — finishing sets it; only an explicit user toggle clears it.
