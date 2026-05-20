alter table public.desafios
  add column if not exists challenge_date date,
  add column if not exists challenge_type text,
  add column if not exists challenge_amount numeric(12, 2) default 0,
  add column if not exists notes text,
  add column if not exists created_at timestamptz default now();

alter table public.desafios
  drop constraint if exists desafios_challenge_type_check;

alter table public.desafios
  add constraint desafios_challenge_type_check
  check (
    challenge_type is null
    or challenge_type in ('store_goal', 'pa', 'biggest_ticket')
  );

insert into public.desafios (
  challenge_date,
  challenge_type,
  challenge_amount,
  notes,
  created_at
)
select
  coalesce(challenge_date, created_at::date, current_date),
  'store_goal',
  0,
  'Migrado do formato antigo',
  coalesce(created_at, now())
from public.desafios
cross join generate_series(1, greatest(coalesce(store_goal_challenge, 0), 0))
where challenge_type is null;

insert into public.desafios (
  challenge_date,
  challenge_type,
  challenge_amount,
  notes,
  created_at
)
select
  coalesce(challenge_date, created_at::date, current_date),
  'pa',
  0,
  'Migrado do formato antigo',
  coalesce(created_at, now())
from public.desafios
cross join generate_series(1, greatest(coalesce(pa_challenge, 0), 0))
where challenge_type is null;

insert into public.desafios (
  challenge_date,
  challenge_type,
  challenge_amount,
  notes,
  created_at
)
select
  coalesce(challenge_date, created_at::date, current_date),
  'biggest_ticket',
  0,
  'Migrado do formato antigo',
  coalesce(created_at, now())
from public.desafios
cross join generate_series(1, greatest(coalesce(biggest_ticket_challenge, 0), 0))
where challenge_type is null;

create index if not exists desafios_challenge_date_idx
  on public.desafios (challenge_date desc);

create index if not exists desafios_challenge_type_idx
  on public.desafios (challenge_type);
