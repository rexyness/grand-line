import { assertEquals } from "jsr:@std/assert@1";
import {
  buildCatalogRows,
  buildStreamSources,
  extractBackdrops,
  extractListIds,
  parseHumanSize,
  parseListTitle,
  parseMp4Name,
  parseReleasesPage,
  parseRssReleases,
  slugify,
} from "./lib.ts";

Deno.test("parseMp4Name parses the verified filename convention", () => {
  const info = parseMp4Name("[One Pace][1] Romance Dawn 01 [480p][En Sub][2A8F5846].mp4");
  assertEquals(info, {
    arcTitle: "Romance Dawn",
    episode: 1,
    quality: 480,
    variant: "ensub",
    crc32: "2A8F5846",
  });
  assertEquals(parseMp4Name("[One Pace][132-135] Drum Island 02 [1080p][42F9FF82].mkv"), null);
});

Deno.test("parseListTitle parses list names", () => {
  assertEquals(parseListTitle("[1-7] Romance Dawn [En Sub][480p]"), {
    arcTitle: "Romance Dawn",
    variant: "ensub",
    quality: 480,
  });
  assertEquals(parseListTitle("not a list"), null);
});

Deno.test("parseHumanSize matches the Dart twin", () => {
  assertEquals(parseHumanSize("789.0 MiB"), Math.round(789.0 * 1048576));
  assertEquals(parseHumanSize("1.1 GiB"), Math.round(1.1 * 1073741824));
  assertEquals(parseHumanSize("garbage"), null);
});

Deno.test("extractListIds dedupes across net/com", () => {
  const html = `<a href="https://pixeldrain.net/l/LC22RWvq">480</a>
    <a href="https://pixeldrain.com/l/LC22RWvq">480</a>
    <a href="https://pixeldrain.net/l/At73d5SH">720</a>`;
  assertEquals(extractListIds(html).sort(), ["At73d5SH", "LC22RWvq"]);
});

Deno.test("extractBackdrops reads escaped RSC flight payloads", () => {
  const html =
    `self.__next_f.push([1,"{\\"slug\\":\\"romance-dawn\\",\\"title\\":\\"Romance Dawn\\",\\"backdrops\\":[{\\"src\\":\\"/images/arcs/romance-dawn.jpg\\",\\"width\\":1920}]}"])`;
  const map = extractBackdrops(html);
  assertEquals(map.get("romance-dawn"), "https://onepace.net/images/arcs/romance-dawn.jpg");
});

Deno.test("buildStreamSources maps files through the arc index", () => {
  const rows = buildStreamSources(
    {
      title: "[1-7] Romance Dawn [En Sub][480p]",
      files: [
        { id: "RwHyfKZs", name: "[One Pace][1] Romance Dawn 01 [480p][En Sub][2A8F5846].mp4", size: 105906176 },
        { id: "zzz", name: "README.txt", size: 10 },
      ],
    },
    new Map([[slugify("Romance Dawn"), 1]]),
  );
  assertEquals(rows.length, 1);
  assertEquals(rows[0].arc_part, 1);
  assertEquals(rows[0].kind, "stream");
  assertEquals(rows[0].variant, "ensub");
  assertEquals(rows[0].quality, 480);
  assertEquals(rows[0].pixeldrain_id, "RwHyfKZs");
});

Deno.test("parseReleasesPage pairs /u/ ids with the nearest MKV CRC", () => {
  const html = `
    <h3>Drum Island 02</h3>
    <span>[One Pace][132-135] Drum Island 02 [1080p][42F9FF82].mkv</span>
    <a href="magnet:?xt=urn:btih:abc">magnet</a>
    <a href="https://pixeldrain.net/u/s79kDrd7">direct</a>
    <h3>Other</h3>
    <span>[One Pace][1] Romance Dawn 01 [1080p][AABBCCDD].mkv</span>
    <a href="https://pixeldrain.net/u/xyz123AB">direct</a>`;
  assertEquals(parseReleasesPage(html), [
    { crc32: "42F9FF82", pixeldrain_id: "s79kDrd7" },
    { crc32: "AABBCCDD", pixeldrain_id: "xyz123AB" },
  ]);
});

Deno.test("parseRssReleases parses items with variants and outdated flags", () => {
  const xml = `<rss><channel>
    <item>
      <guid isPermaLink="false">urn:btih:AB12CD34EF56AB12CD34EF56AB12CD34EF56AB12</guid>
      <title>Drum Island 02</title>
      <pubDate>Mon, 14 Mar 2022 00:00:00 GMT</pubDate>
      <link>https://nyaa.si/view/2138920</link>
      <category domain="https://onepace.net/releases">variant/regular</category>
      <torrent:fileName>[One Pace][132-135] Drum Island 02 [1080p][42F9FF82].mkv.torrent</torrent:fileName>
      <torrent:magnetURI>magnet:?xt=urn:btih:ab12&amp;dn=x</torrent:magnetURI>
    </item>
    <item>
      <guid>urn:btih:FFFF</guid>
      <title>Old Release</title>
      <category>variant/extended</category>
      <category>outdated</category>
    </item>
  </channel></rss>`;
  const rows = parseRssReleases(xml);
  assertEquals(rows.length, 2);
  assertEquals(rows[0].infohash, "ab12cd34ef56ab12cd34ef56ab12cd34ef56ab12");
  assertEquals(rows[0].variant, "regular");
  assertEquals(rows[0].outdated, false);
  assertEquals(rows[0].crc32, "42F9FF82");
  assertEquals(rows[0].filename, "[One Pace][132-135] Drum Island 02 [1080p][42F9FF82].mkv");
  assertEquals(rows[0].magnet, "magnet:?xt=urn:btih:ab12&dn=x");
  assertEquals(rows[1].outdated, true);
  assertEquals(rows[1].variant, "extended");
});

Deno.test("buildCatalogRows merges the three metadata files", () => {
  const rows = buildCatalogRows(
    {
      en: [{
        part: 1,
        saga: "East Blue",
        title: "Romance Dawn",
        shortcode: "RD",
        description: "d",
        mkvcode: "romance-dawn",
        episodes: [{ episode: "01", standard: "2A8F5846", extended: "" }],
      }],
    },
    {
      "2A8F5846": {
        arc: 1,
        episode: 1,
        manga_chapters: "1",
        anime_episodes: "1",
        released: "2020-01-01",
        duration: 1080,
        file: { name: "[One Pace][1] Romance Dawn 01 [1080p][2A8F5846].mkv", size: "265.0 MiB" },
      },
    },
    { en: [{ arc: 1, episode: 1, title: "Ep Title", description: "" }] },
  );
  assertEquals(rows.arcs.length, 1);
  assertEquals(rows.episodes[0].title, "Ep Title");
  assertEquals(rows.episodes[0].duration_seconds, 1080);
  assertEquals(rows.sources.length, 1);
  assertEquals(rows.sources[0].variant, "standard");
  assertEquals(rows.sources[0].size_bytes, Math.round(265 * 1048576));
});
