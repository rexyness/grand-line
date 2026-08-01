# One Pace content sources: catalog, hosting, and formats

Research date: 2026-08-01. All endpoints below were verified live on that date unless noted.

## TL;DR

- The official site is **onepace.net** (Next.js App Router, server-rendered). **onepace.co is an unofficial WordPress SEO clone** (built with Rank Math SEO plugin; meta description is keyword spam) — ignore it.
- The old public GraphQL API (`https://onepace.net/api/graphql`) **was removed** in the early-2026 site rebuild; it now returns the Next.js 404 page. Confirmed by [jwueller/jellyfin-plugin-onepace issue #92](https://github.com/jwueller/jellyfin-plugin-onepace/issues/92) ("One Pace GraphQL API has been removed", opened 2026-03-17) and by a live POST test.
- The two machine-readable-ish official surfaces today are the **releases RSS/Atom feeds** (full release history, torrent-centric) and the **server-rendered HTML** of `/en/watch` and `/en/releases` (which also embeds a JSON "timeline" payload in the React Server Component flight data).
- Video ships two ways: **canonical MKV releases** (HEVC + dual audio + multi-language soft ASS subs) via nyaa.si torrents/magnets and single Pixeldrain files, and **web-friendly MP4 re-encodes** (H.264 + AAC, subs burned in) organized in per-arc Pixeldrain lists at three qualities.
- **Pixeldrain fully supports progressive HTTP streaming**: `GET https://pixeldrain.net/api/file/{id}` answers Range requests with `206 Partial Content`, `Accept-Ranges: bytes`, and `Access-Control-Allow-Origin: *`.

---

## 1. The official catalog: onepace.net

### 1.1 Site tech

`https://onepace.net/en/watch` is a Next.js App Router app (script tags under `/_next/static/chunks/`, data delivered via `self.__next_f.push(...)` RSC flight payloads — there is **no** `__NEXT_DATA__` blob and no `/_next/data/*.json` routes). Everything relevant is server-rendered into the HTML, so plain HTML scraping works. Plain `curl` gets 403 without a browser-like `User-Agent`; with one, it returns 200.

### 1.2 Watch page structure (`/en/watch`)

One page listing every arc as an `<h2>` section with a slug anchor (`#romance-dawn`, `#orange-town`, … `#wano`, `#egghead`, plus specials like `#warship-island-01-april-fools-2025`). Per arc, download groups are labeled by variant, each with per-quality **Pixeldrain list** links:

- Variants seen: `English Subtitles`, `Dub`, `Extended` (e.g. Arlong Park has an "English Subtitles / Extended" group).
- Qualities: **480p / 720p / 1080p** (169 `https://pixeldrain.net/l/{id}` links on the English page alone).
- Example (Romance Dawn, En Sub): 480p `https://pixeldrain.net/l/LC22RWvq`, 720p `https://pixeldrain.net/l/At73d5SH`, 1080p `https://pixeldrain.net/l/LVyeVAjL`.

The RSC flight payload embedded in the same page contains a structured `data.timeline.segments[]` JSON array — per arc: `slug`, `title`, `description`, `special` (bool), `chapters` (e.g. `"1-7"`), `episodes` (e.g. `"1-3, 19, 312, Episode of East Blue"`), and `backdrops[]` (image `src`/`width`/`height`/`blurDataURL`). Extracting it means concatenating the `self.__next_f.push([1,"..."])` string chunks and parsing — doable but coupled to Next.js internals; the rendered HTML carries the same facts.

The page is localized (`/en/`, `/de/`, `/es/`, `/fr/`, `/ja/`, `/pt/`, `/ru/`, `/tr/`, `/zh-Hans/`, … — the full locale list is enumerated in robots.txt). Each locale's watch page lists that language's own subtitle-variant Pixeldrain lists.

### 1.3 Releases page (`/en/releases`) — the richest surface

`https://onepace.net/en/releases` (~3.2 MB HTML) lists **every release ever** (a "356 Previous Releases" section plus the recent ones). Per release block:

- Title (e.g. "Drum Island 02"), release date, **manga chapters** (`132-135`), **anime episodes** (`80-81`), quality (`1080p`), **subtitle tracks** (`de, en, it, ja, tr`), **audio tracks** (`en, ja`).
- Download links, one of each:
  - `magnet:?xt=urn:btih:...` (with ~20 trackers),
  - `https://nyaa.si/download/{id}.torrent` (e.g. `2138920`),
  - `https://pixeldrain.net/u/{fileId}` (single-file direct link, e.g. `s79kDrd7`).

### 1.4 RSS / Atom feeds (the sanctioned machine-readable interface)

- `https://onepace.net/en/releases/rss.xml` and `https://onepace.net/en/releases/atom.xml`.
- The RSS feed contained **358 `<item>`s** — i.e. the full historical release list, not just recent ones.
- Per item: `<guid>` = `urn:btih:{infohash}`, `<title>` (e.g. "Drum Island 02"), `<pubDate>`, `<link>` to the nyaa.si view page, `<enclosure type="application/x-bittorrent">` pointing at `https://nyaa.si/download/{id}.torrent`, and ezrss extensions `<torrent:infoHash>`, `<torrent:magnetURI>`, `<torrent:fileName>` (the canonical MKV filename, which embeds chapter range, quality, and CRC32). A `<description>` CDATA block carries a `<dl>` with manga chapters etc.
- `<category domain="https://onepace.net/releases">` values observed: `variant/regular` (340), `variant/extended` (16), `variant/alternate_g8` (2), plus an `outdated` category on 90 items (superseded releases).
- **No Pixeldrain links in the feed** — it is torrent-centric. Pixeldrain links only appear in the HTML pages.
- Feed contact: `onepaceproject@gmail.com (One Pace Team)`.

### 1.5 robots.txt

`https://onepace.net/robots.txt` allows `/` but **disallows `/api/` and every `/{locale}/watch` page** (the `/releases` pages are *not* disallowed). A well-behaved client should therefore prefer the RSS feed and `/releases`, and treat `/watch` scraping as tolerated-but-not-invited.

---

## 2. Video hosting

### 2.1 Pixeldrain (direct download + streaming)

One Pace links `pixeldrain.net`; the same file IDs work on `pixeldrain.com` (verified: `pixeldrain.com/api/file/RwHyfKZs` also answers 206). One Pace pays for the hosting — the site's donation blurb says donations cover "hosting our website and offering pixeldrain streaming", and file objects show `bandwidth_used_paid` in the billions.

Relevant API (no auth needed, verified live):

- `GET https://pixeldrain.net/api/list/{listId}` → JSON: `{success, id, title, date_created, file_count, files: [...]}`. Example: list `LC22RWvq` → `title: "[1-7] Romance Dawn [En Sub][480p]"`, `file_count: 4`.
- Each `files[]` entry: `id`, `name`, `size` (bytes), `mime_type`, `hash_sha256`, `date_upload`, `views`, `downloads`, `bandwidth_used`, `thumbnail_href` (`/file/{id}/thumbnail`), `availability`, `can_download`, `embed_domains`, `show_ads`, `download_speed_limit`, `delete_after_date` (zeroed — no expiry set).
- `GET https://pixeldrain.net/api/file/{id}` → the bytes. **Verified: `Range: bytes=0-1023` returns `HTTP/1.1 206 Partial Content`, `Accept-Ranges: bytes`, `Content-Range`, `Access-Control-Allow-Origin: *`, `Cache-Control: public, max-age=31536000`** — progressive streaming and seeking work; a Flutter video player can play these URLs directly.
- `GET https://pixeldrain.net/api/file/{id}/info` → same JSON shape as a list entry.
- Rate limiting: responses carry `X-Ratelimit-Limit: 3000` / `X-Ratelimit-Remaining` / `X-Ratelimit-Reset` (per-IP). Files served this way had `show_ads: true` and `embed_domains: ["onepace.net"]` (the latter restricts pixeldrain's iframe embed player to onepace.net — it does **not** block direct API/byte access, which is CORS-open).
- File naming convention inside lists: `[One Pace][{chapterRange}] {Arc} {NN} [{quality}][{variant}][{CRC32}].mp4`, e.g. `[One Pace][1] Romance Dawn 01 [480p][En Sub][2A8F5846].mp4`.

### 2.2 Torrents (nyaa.si)

Canonical releases are published on nyaa.si (anime category `c=1_2`; the Drum Island 02 torrent `nyaa.si/view/2138920` was submitted by user `Galaxy9000` and links back to onepace.net). Magnet URIs in the RSS/HTML carry ~20 public trackers (`nyaa.tracker.wf:7777`, `tracker.opentrackr.org:1337`, etc.). Single-file torrents, e.g. `[One Pace][132-135] Drum Island 02 [1080p][42F9FF82].mkv` (1.1 GiB).

---

## 3. Containers, codecs, subtitles (probed with ffprobe over HTTP)

Two distinct encodes exist:

### 3.1 Canonical MKV releases (torrents + `/u/` Pixeldrain files on /releases)

Probe of `https://pixeldrain.net/api/file/s79kDrd7` (`[One Pace][132-135] Drum Island 02 [1080p][42F9FF82].mkv`, 1.16 GB, `video/x-matroska`):

- Video: **HEVC**, 1440x1080 (anamorphic 4:3).
- Audio: **2x AAC** — `jpn` ("Japanese") and `eng` ("English") — dual audio in one file.
- Subtitles: **ASS soft subs**, multiple tracks: English, "Signs and Songs" (eng), German, Italian, Japanese, Turkish — matching the "Subtitle tracks: de, en, it, ja, tr" metadata on the releases page (language sets vary per release).
- Attachments: TTF/OTF fonts for ASS rendering.
- Filename embeds a **CRC32** of the file (the standard anime-release integrity check; also the key used by third-party metadata projects).

Implication for a Flutter app: playing MKV+HEVC+ASS needs an ffmpeg-based player (e.g. media_kit/mpv); ExoPlayer-based playback of ASS subs and HEVC MKVs is unreliable.

### 3.2 Web MP4 re-encodes (the `/l/` lists on /watch)

Probe of `https://pixeldrain.net/api/file/RwHyfKZs` (`[One Pace][1] Romance Dawn 01 [480p][En Sub][2A8F5846].mp4`, 101 MB, uploaded 2026-02-08):

- Container MP4, **H.264 High + AAC-LC**, exactly two streams — **no subtitle track at all**, so the "En Sub" subtitles are **burned into the video**. "Dub" variants carry English audio instead.
- Sizes (Romance Dawn, per ~18-min episode): 480p ≈ 100 MB, 1080p ≈ 265–383 MB.
- `moov` atom is **not** at the front of the file (a 3 MB prefix fails to probe; ffprobe over HTTP succeeds via range requests). Browser/native players handle this fine over HTTP ranges, but "start playing while sequentially downloading" won't — the player must be able to seek to the tail.
- These MP4s are maximally compatible: any platform video player (including ExoPlayer/AVPlayer) can stream them directly.

---

## 4. How existing open-source clients get their data

- **[jwueller/jellyfin-plugin-onepace](https://github.com/jwueller/jellyfin-plugin-onepace)** (`JWueller.Jellyfin.OnePace/WebRepository.cs`): POSTed a GraphQL query to `https://onepace.net/api/graphql` requesting `{series{invariant_title translations{...}} arcs{id part invariant_title manga_chapters released_at translations{...} images{src width} episodes{id part invariant_title manga_chapters released_at crc32 ...}}}`, and matched local files by **CRC32 in the filename**, manga chapter range, or title. **This endpoint is dead** (live test 2026-08-01: HTTP 404) — issue #92 tracks it, unresolved as of 2026-08-01. Cautionary tale: the official site's internals are not a stable API.
- **[ladyisatis/one-pace-metadata](https://github.com/ladyisatis/one-pace-metadata)** (v2 branch) — the best current community metadata source. A GitHub Actions pipeline **checks the One Pace RSS feed hourly** and the team's episode-description/episode-guide spreadsheets every 6 hours, and publishes static exports under `https://raw.githubusercontent.com/ladyisatis/one-pace-metadata/refs/heads/v2/metadata/`: `data.json`/`data.min.json`, `arcs.json`, `episodes.json`, `descriptions.json`, `tvshow.json`, `status.json`, plus `data.sqlite`. `episodes.min.json` (verified) is a dict keyed by **CRC32** → `{arc, episode, manga_chapters, anime_episodes, released, duration, hashes:{crc32, blake2s}, file:{id (nyaa id), name, size, hash (sha1), index}}` — 514 entries. Consumed by [ladyisatis/OnePaceOrganizer](https://github.com/ladyisatis/OnePaceOrganizer) (`src/organizer.py` defaults `metadata_url` to that raw GitHub base).
- **[tissla/opforjellyfin](https://github.com/tissla/opforjellyfin)** (Go): **scrapes nyaa.si search HTML** (`https://nyaa.si/?f=0&c=1_2&q=one+pace&p={page}`, goquery selectors over `table tbody tr`; config in [tissla/one-pace-jellyfin](https://github.com/tissla/one-pace-jellyfin) `config.json`), downloads via the torrent links, and maps files to a hand-maintained `metadata-index.json` (season/episode keyed by chapter range) in the same repo.
- **[SpykerNZ/one-pace-for-plex](https://github.com/SpykerNZ/one-pace-for-plex)** and [IceToast/one-pace-jellyfin-metadata](https://github.com/IceToast/one-pace-jellyfin-metadata): static hand-written `.nfo` metadata checked into git; no fetching at all. Used as fallback data by other projects (e.g. luucaslfs/one-pace-for-jellyfin, created specifically as a workaround after the GraphQL removal).
- **[matteron/one-pace-plex-api](https://github.com/matteron/one-pace-plex-api)**: pushes metadata into Plex via the Plex API, sourcing its data from OnePaceOrganizer's dataset.

Pattern: nobody has a supported first-party API anymore; the durable strategies are (a) the RSS feed + torrent ecosystem, (b) community-maintained static metadata on raw.githubusercontent.com keyed by CRC32, (c) scraping the SSR HTML.

## 5. Etiquette, stability, link rot

- **No official API and no stated support for third-party apps.** The team removed the GraphQL endpoint in the 2026 rebuild without a replacement, breaking the Jellyfin plugin; the site's FAQ points to their Discord. Contact: `onepaceproject@gmail.com`.
- **robots.txt** explicitly disallows `/api/` and all `/watch` pages, but allows `/releases` (and its RSS/Atom feeds are clearly meant for consumption).
- **Cloudflare-ish UA filtering**: requests without a browser User-Agent get 403.
- **Pixeldrain**: per-IP rate limit (headers show a 3000-request budget), CORS open, hotlink-friendly; One Pace pays for the bandwidth (donation-funded), so a client that hammers Pixeldrain directly spends the project's money — cache aggressively, stream rather than re-download, and surface their donation link. Files have no expiry set (`delete_after_date` zeroed) and were actively served (480p Romance Dawn 01: ~24k downloads, last view same-day).
- **Link rot**: the watch-page list IDs were re-uploaded wholesale in Feb 2026 (all MP4 upload dates 2026-02-08) — IDs churn when the team re-encodes; 90 of 358 RSS items are flagged `outdated`. Don't hardcode Pixeldrain IDs; re-scrape/re-sync. Old torrents rely on public-tracker seeding.
- The One Pace team distributes recut copyrighted footage for free and asks nothing of viewers; a third-party client should keep the same spirit — free, no ads, attribute onepace.net prominently.

## 6. Recommended sourcing strategy for grand-line

1. **Catalog/metadata**: consume `ladyisatis/one-pace-metadata` v2 JSON (CRC32-keyed, hourly-updated, stable raw.githubusercontent URLs) as the primary metadata source; mirror/vendor a snapshot in-app for offline-first startup.
2. **New-release detection**: poll `https://onepace.net/en/releases/rss.xml` (full history, infohashes, filenames).
3. **Stream/download URLs**: scrape `/en/watch` (per-arc `/l/{listId}` per variant+quality) and `/en/releases` (`/u/{fileId}` canonical MKVs), then resolve episodes via `GET pixeldrain.net/api/list/{id}`. Refresh periodically; treat IDs as perishable.
4. **Playback**: default to the MP4 lists (universal codec support, hardsubbed, three qualities) streamed via `pixeldrain.net/api/file/{id}` with range requests; offer the MKV releases (soft subs, dual audio, HEVC) as a power-user/download option behind an mpv-based player.
