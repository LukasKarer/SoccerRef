create table if not exists public.game_sessions (
  id text primary key,
  "homeTeam" text not null,
  "awayTeam" text not null,
  "startTime" timestamptz not null,
  events text[] not null default '{}',
  "firstHalfDuration" integer not null default 45,
  "secondHalfDuration" integer not null default 45,
  "firstHalfExtraTime" integer not null default 0,
  "secondHalfExtraTime" integer not null default 0,
  "isActive" boolean not null default true,
  "isGameStarted" boolean not null default false,
  "endTime" timestamptz,
  "firstHalfStartTime" timestamptz,
  "secondHalfStartTime" timestamptz,
  "homeRoster" text[] not null default '{}',
  "awayRoster" text[] not null default '{}',
  "onPitchHomeLabels" text[] not null default '{}',
  "onPitchAwayLabels" text[] not null default '{}',
  "homeTeamColorRgb" text not null default '#0000ff',
  "awayTeamColorRgb" text not null default '#ff0000',
  "sentOffHomeNumbers" integer[] not null default '{}',
  "sentOffAwayNumbers" integer[] not null default '{}',
  "homeTeamScore" integer not null default 0,
  "awayTeamScore" integer not null default 0,
  "deviceId" text,
  "lastDateChanged" timestamptz not null default now()
);

create index if not exists game_sessions_start_time_idx
  on public.game_sessions ("startTime");

create index if not exists game_sessions_is_active_idx
  on public.game_sessions ("isActive");

alter table public.game_sessions enable row level security;

create policy "Allow anonymous game session reads"
  on public.game_sessions for select
  to anon
  using (true);

create policy "Allow anonymous game session inserts"
  on public.game_sessions for insert
  to anon
  with check (true);

create policy "Allow anonymous game session updates"
  on public.game_sessions for update
  to anon
  using (true)
  with check (true);

create policy "Allow anonymous game session deletes"
  on public.game_sessions for delete
  to anon
  using (true);
