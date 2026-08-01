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
- Still pending (one manual dashboard step, see below): the auth email
  templates must be edited to contain the 6-digit `{{ .Token }}` — the
  defaults send only a confirmation *link*, which the app's OTP flow
  (implementation step 10) can't use.
- Run the app against it: `flutter run --dart-define-from-file=dart_defines.json`

### Email-OTP template (manual — blocked on custom SMTP)

Checked 2026-08-01: the dashboard (Authentication → Emails → Templates)
only allows editing email templates **after custom SMTP is configured**;
until then Supabase's built-in mailer sends the default templates, and the
default "Magic link or OTP" email contains only a sign-in *link* — no
6-digit code — so the app's OTP flow can't complete. To unblock:

1. Create an account with an SMTP provider (e.g. Resend or Brevo free
   tier) and set it under Authentication → Emails → SMTP Settings.
2. Then edit the **Confirm sign up** and **Magic link or OTP** templates
   so the body includes the code, e.g.

   ```html
   <h2>Your grand-line sign-in code</h2>
   <p>Enter this code in the app: <strong>{{ .Token }}</strong></p>
   <p>It expires in one hour. If you didn't request it, ignore this email.</p>
   ```

   (Both templates matter: Supabase uses *Confirm sign up* for a
   first-time email and *Magic link or OTP* afterwards.)

Everything else about the flow already works — the server generates and
verifies the token regardless of what the email shows, and the client's
`verifyOTP` path is wired and tested.

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
RLS enforces everything; spec §3), passed as build-time defines from
[`dart_defines.json`](../dart_defines.json). Catalog reads go through
PostgREST anonymously; watch progress syncs through the `apply_progress*`
RPCs once the user signs in with an email OTP (`lib/data/sync/`). Without
the defines the app runs fully local-only.

## Development

Parser logic for the edge function is pure and tested:

```sh
deno test supabase/functions/catalog-sync/lib_test.ts
```
