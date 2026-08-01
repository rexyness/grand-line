-- grand-line initial schema (spec §3).
-- Catalog + releases are written only by the scheduled edge function (service
-- role, bypasses RLS) and read by everyone; progress is owner-only.

-- ---------------------------------------------------------------------------
-- Catalog (mirrors the client's Drift schema; spec §3.1)

create table public.arcs (
  part int primary key,
  saga text not null,
  title text not null,
  shortcode text not null,
  description text not null default '',
  mkvcode text not null default '',
  backdrop_url text,
  updated_at timestamptz not null default now()
);

create table public.episodes (
  arc_part int not null references public.arcs (part) on delete cascade,
  number int not null,
  title text,
  manga_chapters text,
  anime_episodes text,
  released date,
  duration_seconds int,
  updated_at timestamptz not null default now(),
  primary key (arc_part, number)
);

-- One row per obtainable file: kind 'stream' (hardsub MP4; variant
-- 'ensub'/'dub', quality 480/720/1080) or 'download' (canonical MKV; variant
-- 'standard'/'extended', quality 0). Quality is non-null so the unique
-- constraint holds.
create table public.sources (
  id bigint generated always as identity primary key,
  arc_part int not null,
  number int not null,
  kind text not null check (kind in ('stream', 'download')),
  variant text not null,
  quality int not null default 0,
  pixeldrain_id text,
  crc32 text,
  file_name text,
  size_bytes bigint,
  updated_at timestamptz not null default now(),
  unique (arc_part, number, kind, variant, quality),
  foreign key (arc_part, number)
    references public.episodes (arc_part, number) on delete cascade
);

-- Clients refresh with an updated_at watermark cursor (spec §6.4).
create index arcs_updated_at_idx on public.arcs (updated_at);
create index episodes_updated_at_idx on public.episodes (updated_at);
create index sources_updated_at_idx on public.sources (updated_at);

-- ---------------------------------------------------------------------------
-- Releases (12 h RSS diff; spec §3.1/§9)

create table public.releases (
  infohash text primary key,
  title text not null,
  pub_date timestamptz,
  variant text,
  outdated boolean not null default false,
  filename text,
  crc32 text,
  magnet text,
  first_seen_at timestamptz not null default now()
);

create index releases_first_seen_at_idx on public.releases (first_seen_at);

-- ---------------------------------------------------------------------------
-- Watch progress (spec §3.1/§8): only position + watched sync, keyed by the
-- logical episode identity; updated_at is client-stamped and drives the
-- most-recent-activity-wins merge.

create table public.progress (
  user_id uuid not null references auth.users (id) on delete cascade,
  arc_part int not null,
  number int not null,
  position_ms bigint not null default 0,
  watched boolean not null default false,
  updated_at timestamptz not null,
  primary key (user_id, arc_part, number)
);

-- ---------------------------------------------------------------------------
-- RLS (spec §3: enabled on every table; anon key ships in the public repo)

alter table public.arcs enable row level security;
alter table public.episodes enable row level security;
alter table public.sources enable row level security;
alter table public.releases enable row level security;
alter table public.progress enable row level security;

-- Catalog + releases: world-readable, no client writes (edge function uses
-- the service role, which bypasses RLS).
create policy "catalog read" on public.arcs for select using (true);
create policy "catalog read" on public.episodes for select using (true);
create policy "catalog read" on public.sources for select using (true);
create policy "releases read" on public.releases for select using (true);

-- Progress: owner-only, via the RPC below (security invoker, so these
-- policies are what authorizes it).
create policy "own progress read" on public.progress
  for select using (auth.uid() = user_id);
create policy "own progress insert" on public.progress
  for insert with check (auth.uid() = user_id);
create policy "own progress update" on public.progress
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Progress RPC — most-recent-activity-wins (spec §3.3/§8.4). Applies the row
-- iff the incoming client-stamped updated_at is newer than the stored one.
-- Idempotent and order-independent; mirrored client-side in Drift.

create or replace function public.apply_progress(
  p_arc_part int,
  p_number int,
  p_position_ms bigint,
  p_watched boolean,
  p_updated_at timestamptz
) returns void
language sql
security invoker
as $$
  insert into public.progress (user_id, arc_part, number, position_ms, watched, updated_at)
  values (auth.uid(), p_arc_part, p_number, p_position_ms, p_watched, p_updated_at)
  on conflict (user_id, arc_part, number) do update
    set position_ms = excluded.position_ms,
        watched = excluded.watched,
        updated_at = excluded.updated_at
    where excluded.updated_at > progress.updated_at;
$$;

-- Batch form for the first-sign-in history upload (spec §8.1). Each element:
-- {"arc_part": int, "number": int, "position_ms": int, "watched": bool,
--  "updated_at": iso8601}.
create or replace function public.apply_progress_batch(p_rows jsonb)
returns void
language sql
security invoker
as $$
  insert into public.progress (user_id, arc_part, number, position_ms, watched, updated_at)
  select auth.uid(),
         (r ->> 'arc_part')::int,
         (r ->> 'number')::int,
         (r ->> 'position_ms')::bigint,
         (r ->> 'watched')::boolean,
         (r ->> 'updated_at')::timestamptz
  from jsonb_array_elements(p_rows) as r
  on conflict (user_id, arc_part, number) do update
    set position_ms = excluded.position_ms,
        watched = excluded.watched,
        updated_at = excluded.updated_at
    where excluded.updated_at > progress.updated_at;
$$;
