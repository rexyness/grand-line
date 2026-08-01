// Pure parsing/transform logic for catalog-sync — no network, no Deno APIs,
// so everything here is unit-testable (see lib_test.ts).
//
// Upstream shapes are documented in docs/research/content-sources.md.

// ---------------------------------------------------------------------------
// Types matching the import RPC payloads (migration 20260801000002)

export interface ArcRow {
  part: number;
  saga: string;
  title: string;
  shortcode: string;
  description: string;
  mkvcode: string;
  backdrop_url: string | null;
}

export interface EpisodeRow {
  arc_part: number;
  number: number;
  title: string | null;
  manga_chapters: string | null;
  anime_episodes: string | null;
  released: string | null;
  duration_seconds: number | null;
}

export interface SourceRow {
  arc_part: number;
  number: number;
  kind: "stream" | "download";
  variant: string;
  quality: number;
  pixeldrain_id: string | null;
  crc32: string | null;
  file_name: string | null;
  size_bytes: number | null;
}

export interface ReleaseRow {
  infohash: string;
  title: string;
  pub_date: string | null;
  variant: string | null;
  outdated: boolean;
  filename: string | null;
  crc32: string | null;
  magnet: string | null;
}

// ---------------------------------------------------------------------------
// Catalog: ladyisatis/one-pace-metadata v2 JSON -> arcs/episodes/MKV sources
// (server-side twin of the app's lib/data/catalog/snapshot.dart)

export function buildCatalogRows(
  arcsJson: unknown,
  episodesJson: unknown,
  descriptionsJson: unknown,
): { arcs: ArcRow[]; episodes: EpisodeRow[]; sources: SourceRow[] } {
  // deno-lint-ignore no-explicit-any
  const arcList: any[] = (arcsJson as any)?.en ?? [];
  // deno-lint-ignore no-explicit-any
  const byCrc: Record<string, any> = (episodesJson as Record<string, any>) ?? {};
  // deno-lint-ignore no-explicit-any
  const descriptions: any[] = (descriptionsJson as any)?.en ?? [];

  const titles = new Map<string, { title?: string; description?: string }>();
  for (const d of descriptions) titles.set(`${d.arc}/${d.episode}`, d);

  const arcs: ArcRow[] = [];
  const episodes: EpisodeRow[] = [];
  const sources: SourceRow[] = [];

  for (const arc of arcList) {
    const part = arc.part as number;
    arcs.push({
      part,
      saga: arc.saga ?? "",
      title: arc.title ?? "",
      shortcode: arc.shortcode ?? "",
      description: arc.description ?? "",
      mkvcode: arc.mkvcode ?? "",
      backdrop_url: null,
    });

    for (const ep of arc.episodes ?? []) {
      const number = parseInt(ep.episode, 10);
      if (!Number.isFinite(number)) continue;
      const standardCrc = ep.standard || null;
      const extendedCrc = ep.extended || null;
      const detail = byCrc[standardCrc ?? ""] ?? byCrc[extendedCrc ?? ""];
      const desc = titles.get(`${part}/${number}`);

      episodes.push({
        arc_part: part,
        number,
        title: desc?.title || null,
        manga_chapters: detail?.manga_chapters || null,
        anime_episodes: detail?.anime_episodes || null,
        released: detail?.released || null,
        duration_seconds: detail?.duration ?? null,
      });

      for (
        const [variant, crc] of [
          ["standard", standardCrc],
          ["extended", extendedCrc],
        ] as const
      ) {
        const d = byCrc[crc ?? ""];
        if (!crc || !d) continue;
        sources.push({
          arc_part: part,
          number,
          kind: "download",
          variant,
          quality: 0,
          pixeldrain_id: null,
          crc32: crc,
          file_name: d.file?.name || null,
          size_bytes: parseHumanSize(d.file?.size),
        });
      }
    }
  }

  return { arcs, episodes, sources };
}

/** `"789.0 MiB"` -> bytes (twin of the Dart parser). */
export function parseHumanSize(size: string | undefined | null): number | null {
  if (!size) return null;
  const m = /^([\d.]+)\s*(B|KiB|MiB|GiB|TiB)$/.exec(size.trim());
  if (!m) return null;
  const mult: Record<string, number> = {
    B: 1,
    KiB: 1024,
    MiB: 1048576,
    GiB: 1073741824,
    TiB: 1099511627776,
  };
  return Math.round(parseFloat(m[1]) * mult[m[2]]);
}

// ---------------------------------------------------------------------------
// Watch page -> Pixeldrain list ids and arc backdrops

/** All unique Pixeldrain list ids (`/l/{id}`) on the watch page. */
export function extractListIds(watchHtml: string): string[] {
  const ids = new Set<string>();
  for (const m of watchHtml.matchAll(/pixeldrain\.(?:net|com)\/l\/([A-Za-z0-9]+)/g)) {
    ids.add(m[1]);
  }
  return [...ids];
}

/**
 * Arc backdrops from the RSC flight payload: `"slug":"..."` followed by
 * `"backdrops":[{"src":"..."}]`. Quotes may be JSON-escaped (`\"`) inside the
 * `self.__next_f.push` string chunks, so the regex tolerates backslashes.
 * Returns slug -> absolute URL. Best-effort: an empty map is fine (import
 * keeps known backdrops).
 */
export function extractBackdrops(watchHtml: string): Map<string, string> {
  const out = new Map<string, string>();
  const re =
    /\\?"slug\\?":\\?"([a-z0-9-]+)\\?"[\s\S]{0,3000}?\\?"backdrops\\?":\[\{[\s\S]{0,200}?\\?"src\\?":\\?"([^"\\]+)/g;
  for (const m of watchHtml.matchAll(re)) {
    const url = m[2].startsWith("http") ? m[2] : `https://onepace.net${m[2]}`;
    if (!out.has(m[1])) out.set(m[1], url);
  }
  return out;
}

/** "Romance Dawn" -> "romance-dawn" (matches onepace.net anchors). */
export function slugify(title: string): string {
  return title
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

// ---------------------------------------------------------------------------
// Pixeldrain list metadata -> stream sources

export interface ListInfo {
  arcTitle: string;
  variant: string;
  quality: number;
}

/** `"[1-7] Romance Dawn [En Sub][480p]"` -> arc/variant/quality. */
export function parseListTitle(title: string): ListInfo | null {
  const m = /^\[[^\]]*\]\s*(.+?)\s*\[([^\]]+)\]\[(\d+)p\]$/.exec(title.trim());
  if (!m) return null;
  return { arcTitle: m[1], variant: normalizeVariant(m[2]), quality: parseInt(m[3], 10) };
}

export interface Mp4Info {
  arcTitle: string;
  episode: number;
  quality: number;
  variant: string;
  crc32: string;
}

/** `"[One Pace][1] Romance Dawn 01 [480p][En Sub][2A8F5846].mp4"` */
export function parseMp4Name(name: string): Mp4Info | null {
  const m = /^\[One Pace\]\[[^\]]*\]\s*(.+?)\s+(\d+)\s+\[(\d+)p\]\[([^\]]+)\]\[([0-9A-Fa-f]{8})\]\.mp4$/
    .exec(name.trim());
  if (!m) return null;
  return {
    arcTitle: m[1],
    episode: parseInt(m[2], 10),
    quality: parseInt(m[3], 10),
    variant: normalizeVariant(m[4]),
    crc32: m[5].toUpperCase(),
  };
}

/** "En Sub" -> "ensub", "Dub" -> "dub", "Extended" -> "extended". */
export function normalizeVariant(v: string): string {
  return v.toLowerCase().replace(/[^a-z0-9]+/g, "");
}

/**
 * Builds stream source rows from one Pixeldrain list response
 * (`GET /api/list/{id}`), matching arc titles to parts via [titleToPart].
 * Per-file variant/quality (from the filename) wins over the list title.
 */
export function buildStreamSources(
  // deno-lint-ignore no-explicit-any
  list: { title?: string; files?: any[] },
  titleToPart: Map<string, number>,
): SourceRow[] {
  const fromTitle = parseListTitle(list.title ?? "");
  const rows: SourceRow[] = [];
  for (const file of list.files ?? []) {
    const info = parseMp4Name(file.name ?? "");
    if (!info) continue;
    const part = titleToPart.get(slugify(info.arcTitle)) ??
      (fromTitle ? titleToPart.get(slugify(fromTitle.arcTitle)) : undefined);
    if (part === undefined) continue;
    rows.push({
      arc_part: part,
      number: info.episode,
      kind: "stream",
      variant: info.variant,
      quality: info.quality,
      pixeldrain_id: file.id,
      crc32: info.crc32,
      file_name: file.name,
      size_bytes: typeof file.size === "number" ? file.size : null,
    });
  }
  return rows;
}

// ---------------------------------------------------------------------------
// Releases page -> CRC32 -> Pixeldrain /u/ id (for MKV downloads)

/**
 * Pairs each `/u/{id}` link with the nearest MKV CRC32 in the preceding
 * window (release blocks list the filename/magnet before the links).
 */
export function parseReleasesPage(html: string): { crc32: string; pixeldrain_id: string }[] {
  const out: { crc32: string; pixeldrain_id: string }[] = [];
  const seen = new Set<string>();
  for (const m of html.matchAll(/pixeldrain\.(?:net|com)\/u\/([A-Za-z0-9]+)/g)) {
    const window = html.slice(Math.max(0, m.index! - 4000), m.index!);
    const crcs = [...window.matchAll(/\[([0-9A-Fa-f]{8})\]\.mkv/g)];
    if (crcs.length === 0) continue;
    const crc32 = crcs[crcs.length - 1][1].toUpperCase();
    const key = `${crc32}/${m[1]}`;
    if (seen.has(key)) continue;
    seen.add(key);
    out.push({ crc32, pixeldrain_id: m[1] });
  }
  return out;
}

// ---------------------------------------------------------------------------
// Releases RSS -> release rows

export function parseRssReleases(xml: string): ReleaseRow[] {
  const rows: ReleaseRow[] = [];
  for (const item of xml.matchAll(/<item>([\s\S]*?)<\/item>/g)) {
    const body = item[1];
    const infohash = tag(body, "guid")?.replace(/^urn:btih:/i, "")?.toLowerCase();
    const title = decodeEntities(tag(body, "title") ?? "");
    if (!infohash || !title) continue;
    // Feed values end in ".mkv.torrent"; keep the canonical MKV filename.
    const fileName = tag(body, "torrent:fileName")?.replace(/\.torrent$/, "") ?? null;
    const crcMatch = fileName ? /\[([0-9A-Fa-f]{8})\](?:\.\w+)*$/.exec(fileName) : null;
    const categories = [...body.matchAll(/<category[^>]*>([\s\S]*?)<\/category>/g)]
      .map((c) => decodeEntities(c[1]).trim());
    const variant = categories
      .find((c) => c.startsWith("variant/"))
      ?.slice("variant/".length) ?? null;
    const pubDate = tag(body, "pubDate");
    rows.push({
      infohash,
      title,
      pub_date: pubDate ? new Date(pubDate).toISOString() : null,
      variant,
      outdated: categories.includes("outdated"),
      filename: fileName ?? null,
      crc32: crcMatch ? crcMatch[1].toUpperCase() : null,
      magnet: decodeEntities(tag(body, "torrent:magnetURI") ?? "") || null,
    });
  }
  return rows;
}

function tag(xml: string, name: string): string | null {
  const m = new RegExp(`<${name}[^>]*>([\\s\\S]*?)</${name}>`).exec(xml);
  if (!m) return null;
  return m[1].replace(/^<!\[CDATA\[([\s\S]*)\]\]>$/, "$1").trim();
}

function decodeEntities(s: string): string {
  return s
    .replaceAll("&amp;", "&")
    .replaceAll("&lt;", "<")
    .replaceAll("&gt;", ">")
    .replaceAll("&quot;", '"')
    .replaceAll("&#39;", "'");
}
