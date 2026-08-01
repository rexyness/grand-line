# Task: assemble the implementation-ready spec

Type: task
Status: resolved
Blocked by: 06, 08, 09, 10, 11, 12, 13, 16

## Question

Assemble every closed decision on the map into `.scratch/app-spec/spec.md` — the destination. The spec must be implementable without reopening any decision: features and screens (from the UI prototype), content source strategy, playback stack, backend and account model, download design, notification design, architecture, and release pipeline, each linking back to its ticket for the reasoning. Ends with a suggested ticket breakdown for the implementation effort (e.g. via `/to-tickets`).

## Resolution

2026-08-01: **[spec.md](../spec.md) written** — 12 sections covering product shape, content sourcing, backend, features/screens, playback, architecture, downloads, sync, notifications, release posture, a 14-ticket implementation breakdown (Android ASS spike mandatory first), and a decision index linking every section to its ticket.

The last fog item — secondary surfaces in the immersive-carousel idiom — was designed during assembly (spec §4.3–4.6): search as a local-only overlay (`/`/Ctrl+K on desktop), a two-section downloads manager (queue + library with storage readouts), a sectioned settings page gated by `PlatformCapabilities`, and the email-OTP account surface inside settings.

One ticket remains open on the map — [Task: email the One Pace team](15-contact-one-pace-team.md) (HITL: user sends the prepared draft before the repo goes public); a reply may amend §10.5 (backdrop vendoring) and the server UA, both flagged in the spec.
