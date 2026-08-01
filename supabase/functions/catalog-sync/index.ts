// catalog-sync: the one scheduled job (spec §3.2). Refreshes, in order:
//   catalog   — metadata JSON -> arcs/episodes/MKV download sources
//   streams   — watch page -> Pixeldrain lists -> stream sources + backdrops
//   downloads — releases page -> /u/ file ids onto MKV sources (by CRC32)
//   releases  — releases RSS -> releases table (12 h diff)
//
// Invoked by Supabase Cron via HTTP with `x-cron-secret` (see supabase/README).
// `?tasks=releases` runs a subset — the cron runs `releases` every 12 h and the
// full set daily, so the whole user base costs One Pace one visitor's traffic.

import { createClient } from "jsr:@supabase/supabase-js@2";
import {
  buildCatalogRows,
  buildStreamSources,
  extractBackdrops,
  extractListIds,
  parseReleasesPage,
  parseRssReleases,
  slugify,
} from "./lib.ts";

// The site 403s non-browser user agents. The courtesy email offers to switch
// this to an honest `grand-line-bot` UA if the One Pace team prefers.
const USER_AGENT =
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36 grand-line-sync";

const METADATA_BASE =
  "https://raw.githubusercontent.com/ladyisatis/one-pace-metadata/refs/heads/v2/metadata";

async function fetchText(url: string): Promise<string> {
  const res = await fetch(url, { headers: { "User-Agent": USER_AGENT } });
  if (!res.ok) throw new Error(`GET ${url} -> ${res.status}`);
  return await res.text();
}

async function fetchJson(url: string): Promise<unknown> {
  return JSON.parse(await fetchText(url));
}

function client() {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
}

async function rpc(name: string, rows: unknown[]): Promise<number> {
  if (rows.length === 0) return 0;
  const { error } = await client().rpc(name, { p: rows });
  if (error) throw new Error(`${name}: ${error.message}`);
  return rows.length;
}

async function syncCatalog(): Promise<Record<string, number>> {
  const [arcsJson, episodesJson, descriptionsJson] = await Promise.all([
    fetchJson(`${METADATA_BASE}/arcs.json`),
    fetchJson(`${METADATA_BASE}/episodes.min.json`),
    fetchJson(`${METADATA_BASE}/descriptions.json`),
  ]);
  const { arcs, episodes, sources } = buildCatalogRows(
    arcsJson,
    episodesJson,
    descriptionsJson,
  );
  return {
    arcs: await rpc("import_arcs", arcs),
    episodes: await rpc("import_episodes", episodes),
    download_sources: await rpc("import_sources", sources),
  };
}

async function syncStreams(): Promise<Record<string, number>> {
  const watchHtml = await fetchText("https://onepace.net/en/watch");

  // Arc title (slug) -> part, for matching list/file names to catalog rows.
  const { data: arcRows, error } = await client().from("arcs").select("part, title");
  if (error) throw new Error(`arcs select: ${error.message}`);
  const titleToPart = new Map<string, number>(
    (arcRows ?? []).map((a) => [slugify(a.title), a.part]),
  );

  // Backdrops piggyback on the same fetch (spec §10.5).
  const backdrops = extractBackdrops(watchHtml);
  const backdropRows = (arcRows ?? [])
    .filter((a) => backdrops.has(slugify(a.title)))
    .map((a) => ({
      part: a.part,
      title: a.title,
      backdrop_url: backdrops.get(slugify(a.title)),
    }));
  // import_arcs coalesces: rows carry only what we want to touch, but the RPC
  // requires full shape — refetch full arc rows and merge the URL in.
  const { data: fullArcs } = await client().from("arcs").select(
    "part, saga, title, shortcode, description, mkvcode",
  );
  const byPart = new Map((fullArcs ?? []).map((a) => [a.part, a]));
  const arcUpdates = backdropRows.flatMap((b) => {
    const full = byPart.get(b.part);
    return full ? [{ ...full, backdrop_url: b.backdrop_url }] : [];
  });

  const listIds = extractListIds(watchHtml);
  let streamRows = 0;
  const failedLists: string[] = [];
  for (const id of listIds) {
    try {
      const list = await fetchJson(`https://pixeldrain.net/api/list/${id}`) as {
        title?: string;
        // deno-lint-ignore no-explicit-any
        files?: any[];
      };
      streamRows += await rpc("import_sources", buildStreamSources(list, titleToPart));
    } catch (_) {
      failedLists.push(id);
    }
  }

  return {
    lists: listIds.length,
    failed_lists: failedLists.length,
    stream_sources: streamRows,
    backdrops: await rpc("import_arcs", arcUpdates),
  };
}

async function syncDownloadIds(): Promise<Record<string, number>> {
  const html = await fetchText("https://onepace.net/en/releases");
  const pairs = parseReleasesPage(html);
  return { download_ids: await rpc("import_download_ids", pairs) };
}

async function syncReleases(): Promise<Record<string, number>> {
  const xml = await fetchText("https://onepace.net/en/releases/rss.xml");
  return { releases: await rpc("import_releases", parseRssReleases(xml)) };
}

const TASKS: Record<string, () => Promise<Record<string, number>>> = {
  catalog: syncCatalog,
  streams: syncStreams,
  downloads: syncDownloadIds,
  releases: syncReleases,
};

Deno.serve(async (req) => {
  const secret = Deno.env.get("CRON_SECRET");
  if (!secret || req.headers.get("x-cron-secret") !== secret) {
    return new Response("forbidden", { status: 403 });
  }

  const requested = new URL(req.url).searchParams.get("tasks")?.split(",") ??
    Object.keys(TASKS);
  const results: Record<string, unknown> = {};
  let failed = false;
  for (const name of requested) {
    const task = TASKS[name];
    if (!task) continue;
    try {
      results[name] = await task();
    } catch (e) {
      results[name] = { error: String(e) };
      failed = true;
    }
  }

  return new Response(JSON.stringify(results, null, 2), {
    status: failed ? 500 : 200,
    headers: { "Content-Type": "application/json" },
  });
});
