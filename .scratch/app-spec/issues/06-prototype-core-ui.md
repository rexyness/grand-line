# Prototype: core UI — arc/episode browser and player screen

Type: prototype
Status: resolved

## Question

What should the app's core screens look and feel like? Produce a cheap, concrete Flutter UI prototype (via `/prototype`) covering: the arc/episode browser (One Pace organizes by arc, not season), a "continue watching" surface, the player screen with subtitle/quality controls, and where downloads and new-release indicators live. React with the user until the shape is agreed; link the prototype as an asset.

Desktop and mobile differ enough (pointer + wide window vs touch) that the prototype should show both layouts at least roughly.

## Comments

**Prototype built (asset):** `prototype/ui_prototype/` — throwaway Flutter app, verified compiling on Windows.
Run with: `cd prototype\ui_prototype && flutter run -d windows`. Switch variants with the floating bottom pill or ←/→ keys; resize the window narrow (<700px) to judge the mobile layout.

- **A — Shelf home**: streaming-service style; Continue-watching + per-saga arc shelves → arc detail page → full-screen player.
- **B — Library sidebar**: desktop-first; persistent arc sidebar (progress rings, NEW/download badges) + dense episode table with inline progress and per-episode download; collapses to a two-level list when narrow.
- **C — Player-first**: the app opens into the resume screen; browsing is an overlay panel (side panel wide / bottom sheet narrow) over the video.
- **D — Voyage timeline**: one continuous scroll down the Grand Line; arcs as waypoints on a progress route with big backdrop banners; episodes expand inline, no page navigation; "you are here" jump chip.
- **E — Immersive carousel**: console-dashboard style; full-bleed backdrop of the focused arc, horizontal arc strip, episode chips, Resume/Start + Download actions; minimal chrome.

**Assets note:** `assets/images/` holds the 24 official per-arc backdrops (640px) fetched once from onepace.net's watch page (`/_next/static/media/*backdrop*`); used across all variants and as the fake video frame in the player. These are One Pace's own episode snapshots — fine for a local prototype, but shipping them in a public repo should be reconsidered at the release-strategy ticket.

Awaiting user reactions — winner (or combination) resolves this ticket.

## Answer

**Winner: Variant E — "Immersive carousel"** (user's pick from five variants). The spec's core UI is:

- **Home**: full-bleed official arc backdrop of the focused arc, cross-fading on focus change; minimal chrome (logo + search + downloads up top).
- **Arc navigation**: a horizontal arc strip along the bottom — every arc as a small backdrop card, the focused one enlarged and outlined; ordered as the voyage (saga order).
- **Episode navigation**: a chips row for the focused arc (E1 ✓ watched, E2 ▶ in progress), one tap to play; primary actions are **Resume/Start** and **Download** on the focused arc.
- **Player**: full-screen page with subtitle-track, audio-track, and quality pickers as pill menus, seek bar, next-episode; styled-subs rendered over video.
- **Mobile**: same structure — the layout is already touch-first; card/strip sizes shrink at narrow widths.
- **Still to design in this idiom** (fog, for spec assembly): search, downloads-manager view, settings, and account/sync surfaces.

Rejected: A (shelf home), B (library sidebar), C (player-first), D (voyage timeline). D's "you are here" jump chip and E's episode chips overlap; no elements from other variants were requested.

**Asset**: the full 5-variant prototype is captured on the throwaway branch `prototype/core-ui` (run: `git checkout prototype/core-ui; cd prototype/ui_prototype; flutter run -d windows`). Arc backdrops (24 official 640px snapshots from onepace.net) live in the prototype's `assets/images/`; whether they may ship in the public repo is deferred to the release-strategy ticket.
