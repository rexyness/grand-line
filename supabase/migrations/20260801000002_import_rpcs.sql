-- Import RPCs called by the catalog-sync edge function (service role only).
-- All upserts guard with IS DISTINCT FROM so updated_at bumps only on real
-- change — clients refresh on an updated_at watermark (spec §6.4), so a no-op
-- sync must not invalidate their cache.

create or replace function public.import_arcs(p jsonb)
returns void language sql security invoker set search_path = public as $$
  insert into arcs (part, saga, title, shortcode, description, mkvcode, backdrop_url)
  select (r ->> 'part')::int, r ->> 'saga', r ->> 'title', r ->> 'shortcode',
         coalesce(r ->> 'description', ''), coalesce(r ->> 'mkvcode', ''),
         r ->> 'backdrop_url'
  from jsonb_array_elements(p) as r
  on conflict (part) do update set
    saga = excluded.saga,
    title = excluded.title,
    shortcode = excluded.shortcode,
    description = excluded.description,
    mkvcode = excluded.mkvcode,
    -- a sync that failed to find a backdrop never erases a known one
    backdrop_url = coalesce(excluded.backdrop_url, arcs.backdrop_url),
    updated_at = now()
  where (arcs.saga, arcs.title, arcs.shortcode, arcs.description, arcs.mkvcode, arcs.backdrop_url)
    is distinct from
    (excluded.saga, excluded.title, excluded.shortcode, excluded.description,
     excluded.mkvcode, coalesce(excluded.backdrop_url, arcs.backdrop_url));
$$;

create or replace function public.import_episodes(p jsonb)
returns void language sql security invoker set search_path = public as $$
  insert into episodes (arc_part, number, title, manga_chapters, anime_episodes, released, duration_seconds)
  select (r ->> 'arc_part')::int, (r ->> 'number')::int, r ->> 'title',
         r ->> 'manga_chapters', r ->> 'anime_episodes',
         (r ->> 'released')::date, (r ->> 'duration_seconds')::int
  from jsonb_array_elements(p) as r
  on conflict (arc_part, number) do update set
    title = excluded.title,
    manga_chapters = excluded.manga_chapters,
    anime_episodes = excluded.anime_episodes,
    released = excluded.released,
    duration_seconds = excluded.duration_seconds,
    updated_at = now()
  where (episodes.title, episodes.manga_chapters, episodes.anime_episodes,
         episodes.released, episodes.duration_seconds)
    is distinct from
    (excluded.title, excluded.manga_chapters, excluded.anime_episodes,
     excluded.released, excluded.duration_seconds);
$$;

create or replace function public.import_sources(p jsonb)
returns void language sql security invoker set search_path = public as $$
  insert into sources (arc_part, number, kind, variant, quality, pixeldrain_id, crc32, file_name, size_bytes)
  select (r ->> 'arc_part')::int, (r ->> 'number')::int, r ->> 'kind',
         r ->> 'variant', coalesce((r ->> 'quality')::int, 0),
         r ->> 'pixeldrain_id', r ->> 'crc32', r ->> 'file_name',
         (r ->> 'size_bytes')::bigint
  from jsonb_array_elements(p) as r
  on conflict (arc_part, number, kind, variant, quality) do update set
    pixeldrain_id = coalesce(excluded.pixeldrain_id, sources.pixeldrain_id),
    crc32 = coalesce(excluded.crc32, sources.crc32),
    file_name = coalesce(excluded.file_name, sources.file_name),
    size_bytes = coalesce(excluded.size_bytes, sources.size_bytes),
    updated_at = now()
  where (sources.pixeldrain_id, sources.crc32, sources.file_name, sources.size_bytes)
    is distinct from
    (coalesce(excluded.pixeldrain_id, sources.pixeldrain_id),
     coalesce(excluded.crc32, sources.crc32),
     coalesce(excluded.file_name, sources.file_name),
     coalesce(excluded.size_bytes, sources.size_bytes));
$$;

-- Attach Pixeldrain /u/ file ids (scraped from /en/releases) to the MKV
-- download sources that already exist from the catalog import, matched by
-- CRC32. Elements: {"crc32": text, "pixeldrain_id": text}.
create or replace function public.import_download_ids(p jsonb)
returns void language sql security invoker set search_path = public as $$
  update sources s
  set pixeldrain_id = m.pixeldrain_id, updated_at = now()
  from (
    select upper(r ->> 'crc32') as crc32, r ->> 'pixeldrain_id' as pixeldrain_id
    from jsonb_array_elements(p) as r
  ) as m
  where s.kind = 'download'
    and upper(s.crc32) = m.crc32
    and s.pixeldrain_id is distinct from m.pixeldrain_id;
$$;

-- RSS diff (spec §3.1): insert unseen infohashes, maintain outdated/metadata
-- in place, preserve first_seen_at.
create or replace function public.import_releases(p jsonb)
returns void language sql security invoker set search_path = public as $$
  insert into releases (infohash, title, pub_date, variant, outdated, filename, crc32, magnet)
  select lower(r ->> 'infohash'), r ->> 'title', (r ->> 'pub_date')::timestamptz,
         r ->> 'variant', coalesce((r ->> 'outdated')::boolean, false),
         r ->> 'filename', upper(r ->> 'crc32'), r ->> 'magnet'
  from jsonb_array_elements(p) as r
  on conflict (infohash) do update set
    title = excluded.title,
    pub_date = excluded.pub_date,
    variant = excluded.variant,
    outdated = excluded.outdated,
    filename = excluded.filename,
    crc32 = excluded.crc32,
    magnet = excluded.magnet
  where (releases.title, releases.pub_date, releases.variant, releases.outdated,
         releases.filename, releases.crc32, releases.magnet)
    is distinct from
    (excluded.title, excluded.pub_date, excluded.variant, excluded.outdated,
     excluded.filename, excluded.crc32, excluded.magnet);
$$;

-- Only the service role (the edge function) may import.
revoke execute on function public.import_arcs(jsonb) from public, anon, authenticated;
revoke execute on function public.import_episodes(jsonb) from public, anon, authenticated;
revoke execute on function public.import_sources(jsonb) from public, anon, authenticated;
revoke execute on function public.import_download_ids(jsonb) from public, anon, authenticated;
revoke execute on function public.import_releases(jsonb) from public, anon, authenticated;
