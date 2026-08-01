# Task: email the One Pace team for a courtesy blessing

Type: task
Status: claimed
Blocked by: 13

## Question

Send a courtesy email to the One Pace team (their published contact: onepaceproject@gmail.com; FAQ also points to their Discord) before the repo goes public. One coherent message covering: (a) that grand-line is a free, ad-free, open-source fan client that attributes onepace.net and surfaces their donation link; (b) the central sync service that reads their watch page ~daily on behalf of all users (so individual installs never scrape); (c) whether their arc backdrop images may ship in the repo/app or should be fetched at runtime; (d) an offer to change course if they object to any of it.

Blocked by the release-strategy ticket because the email should describe the final public posture (license, artifacts, disclaimer) rather than guesses. Draft the email AFK; sending it is the user's call from their own address. The answer records what was sent and any reply — a reply may update the etiquette posture or asset decisions.

## Progress

- 2026-08-01: AFK half done — draft written at [assets/one-pace-email-draft.md](../assets/one-pace-email-draft.md), grounded in the resolved release posture (GPL-3.0, ad-free, GitHub-only, home-screen donation link, runtime-fetched backdrops, 12 h RSS cadence). Adds one extra courtesy ask surfaced by the notifications research: whether the server job should use an honest `grand-line-bot` User-Agent. **Remaining (HITL):** user fills in repo link + sign-off, sends from their own address before the repo goes public, and the reply (or non-reply after ~2 weeks + Discord ping) gets recorded here as the resolution.
- 2026-08-01 (later session): user chose to hold off on sending for now — no repo URL exists yet (no GitHub remote). Ticket stays claimed; don't re-prompt until the user brings the repo URL or says they've sent it.
