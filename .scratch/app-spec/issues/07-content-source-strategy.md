# Decide: content source strategy

Type: grilling
Status: resolved
Blocked by: 01

## Question

Given the content-sources research, which source(s) does the app use for metadata and video, and with what fallback behavior? Decide: primary metadata source (API vs scrape vs bundled/cached catalog), primary video source for streaming and for downloads, quality/language variant handling, and how the app degrades when a link is dead or the source changes shape. Also decide the etiquette posture (caching, request frequency) toward the One Pace infrastructure.

## Answer

Decided with the user (grilled 2026-08-01):

1. **File flavors — MP4 streams, MKV downloads.** Streaming uses the web MP4s (480/720/1080p quality selection; hardsubbed En Sub or Dub variant; plays on any player). Downloads use the canonical MKVs (HEVC, dual jpn/eng audio, multi-language soft ASS subs) — so full subtitle/audio selection applies to downloaded/offline playback, quality selection applies to streaming.
2. **Catalog — community JSON, vendored.** Primary metadata is `ladyisatis/one-pace-metadata` v2 JSON (hourly-updated, CRC32-keyed, raw.githubusercontent.com), with a snapshot vendored into the app so first launch works offline. The official releases RSS (`/en/releases/rss.xml`) drives new-release detection. Single-maintainer risk is accepted, mitigated by the snapshot.
3. **Link resolution — central sync service.** A scheduled Supabase edge function (backend per the sync-backend research) refreshes the watch-page → Pixeldrain list/file ID mapping ~daily and serves it as JSON to all clients; clients cache hard and never scrape onepace.net themselves. A courtesy email to the One Pace team asking a blessing accompanies this (see the contact-One-Pace task ticket).
4. **Degradation — auto-refresh, honest fallback.** On 404/probe failure the client re-pulls the mapping; if still dead, the episode shows "temporarily unavailable" + retry, and offers a magnet handoff to an external torrent client (RSS infohashes don't rot). No embedded torrent engine.
5. **Etiquette.** Aggressive caching; frugal Pixeldrain use (donation-funded); prominent onepace.net attribution + donation link in-app; honest User-Agent; robots-disallowed pages touched only by the single central service, gently.
