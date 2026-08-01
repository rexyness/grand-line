# Research: how One Pace distributes episodes and metadata

Type: research
Status: resolved

## Question

What are the concrete, current ways to programmatically get One Pace episode metadata and video files? Cover:

- How onepace.co (and onepace.net, if distinct) structures its catalog — any public API, GraphQL endpoint, or scrapeable JSON (e.g. Next.js data payloads).
- Where the video files are hosted: direct-download hosts (e.g. Pixeldrain), torrents, anything else — and whether those links support progressive HTTP streaming (range requests) or only full downloads.
- Available qualities (480p/720p/1080p), containers, and codecs per episode.
- How subtitles ship: embedded soft subs (format? ASS?) vs external files; which languages; sub vs dub variants.
- How existing open-source One Pace apps/clients source their data (find them on GitHub and read their fetching code).
- Etiquette and stability constraints: rate limits, robots.txt, how often links rot, any statement from the One Pace team about third-party apps.

## Answer

Full findings with verified endpoints and JSON shapes: [docs/research/content-sources.md](../../../docs/research/content-sources.md).

- Official site is onepace.net (onepace.co is an unofficial SEO clone). The old public GraphQL API (`onepace.net/api/graphql`) was removed in the early-2026 site rebuild (verified 404; jwueller/jellyfin-plugin-onepace#92). Today's surfaces: server-rendered HTML on `/en/watch` and `/en/releases`, and full-history RSS/Atom feeds at `/en/releases/rss.xml` (358 items with infohash, magnet, nyaa .torrent, filename, variant categories).
- Video is dual-track: canonical MKV releases (HEVC 1440x1080, dual AAC audio jpn+eng, multi-language soft ASS subs + font attachments, CRC32 in filename) via nyaa.si torrents and Pixeldrain `/u/{id}` files; plus web MP4 re-encodes (H.264+AAC, subs burned in, no text track) in per-arc Pixeldrain lists `/l/{id}` at 480p/720p/1080p per variant (En Sub / Dub / Extended).
- Pixeldrain streams: `GET pixeldrain.net/api/file/{id}` answers Range requests with 206, `Accept-Ranges: bytes`, CORS `*`; `GET /api/list/{id}` returns full file JSON (name, size, sha256, mime). Per-IP rate limit headers (3000 budget). Bandwidth is donation-funded by the One Pace team — be frugal.
- Best community metadata source: `ladyisatis/one-pace-metadata` (v2), an hourly RSS-driven pipeline publishing CRC32-keyed JSON/SQLite on raw.githubusercontent.com; other clients scrape nyaa.si HTML or ship static NFOs.
- Etiquette: robots.txt disallows `/api/` and `/watch` (but not `/releases`); UA-less requests get 403; no official third-party-app support — Pixeldrain IDs churn on re-encodes (all watch-page MP4s re-uploaded 2026-02-08), so sync rather than hardcode.
