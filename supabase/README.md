# grand-line backend (Supabase)

Spec §3. Free tier, zero-ops: catalog + releases tables written by the
`catalog-sync` edge function, read anonymously by clients; watch progress
behind owner-only RLS with a most-recent-activity-wins RPC.

## Live project (set up 2026-08-01)

- Project ref `phekxdvpamrqgjvkpuab` (Central EU, Frankfurt), URL
  `https://phekxdvpamrqgjvkpuab.supabase.co`. Publishable (anon) key in
  [`dart_defines.json`](../dart_defines.json) — public by design, RLS
  enforces everything.
- Both migrations applied via the SQL editor; `catalog-sync` deployed from
  the dashboard editor (same two files as this repo); `CRON_SECRET` set;
  `pg_cron`/`pg_net` enabled; jobs `releases-diff` (every 12 h) and
  `catalog-full-sync` (daily 04:30 UTC) active. First full seed: 37 arcs,
  477 episodes, 2227 stream + 488 download sources, 358 releases.
- Still pending (implementation step 10): auth email-OTP configuration
  (6-digit token template).
- Run the app against it: `flutter run --dart-define-from-file=dart_defines.json`

## One-time setup (from scratch)

1. Create a project at [database.new](https://database.new) (free tier).
2. Install the [Supabase CLI](https://supabase.com/docs/guides/cli), then from
   the repo root:

   ```sh
   supabase login
   supabase link --project-ref <PROJECT_REF>
   supabase db push                     # applies supabase/migrations/
   supabase secrets set CRON_SECRET=<long random string>
   supabase functions deploy catalog-sync
   ```

3. Seed once and verify (should return per-task row counts as JSON):

   ```sh
   curl -H "x-cron-secret: <CRON_SECRET>" \
     "https://<PROJECT_REF>.supabase.co/functions/v1/catalog-sync"
   ```

4. Schedule it. In the dashboard enable the `pg_cron` and `pg_net` extensions,
   then run in the SQL editor (spec §3.2 — releases every 12 h, the heavier
   full refresh daily):

   ```sql
   select cron.schedule('releases-diff', '0 */12 * * *', $$
     select net.http_get(
       url := 'https://<PROJECT_REF>.supabase.co/functions/v1/catalog-sync?tasks=releases',
       headers := jsonb_build_object('x-cron-secret', '<CRON_SECRET>')
     );
   $$);

   select cron.schedule('catalog-full-sync', '30 4 * * *', $$
     select net.http_get(
       url := 'https://<PROJECT_REF>.supabase.co/functions/v1/catalog-sync',
       headers := jsonb_build_object('x-cron-secret', '<CRON_SECRET>'),
       timeout_milliseconds := 300000
     );
   $$);
   ```

5. Auth settings (dashboard → Authentication): enable **Email** provider with
   **OTP** only (no passwords) — the app's sole sign-in method (spec §8.2).

The cron traffic doubles as the keep-alive against the free tier's 1-week
API-inactivity pause; the planned GitHub Actions keep-alive ping (spec §10.3)
is belt-and-braces for the pre-launch window once Actions is unblocked.

## Client wiring

The app needs only the project URL and anon key (safe to ship publicly —
RLS enforces everything; spec §3). They land in the app as build-time config
in a later implementation step.

## Development

Parser logic for the edge function is pure and tested:

```sh
deno test supabase/functions/catalog-sync/lib_test.ts
```
