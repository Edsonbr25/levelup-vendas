create extension if not exists pgcrypto;

create table if not exists public.vendedores (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  role text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.sales (
  id uuid primary key default gen_random_uuid(),
  sale_date date not null,
  seller_id uuid references public.vendedores(id),
  seller_name text,
  sale_amount numeric not null default 0,
  sale_type text not null check (sale_type in ('store', 'seller')),
  created_at timestamptz not null default now()
);

create table if not exists public.goals (
  id uuid primary key default gen_random_uuid(),
  goal_type text not null check (goal_type in ('store', 'seller')),
  seller_id uuid references public.vendedores(id),
  seller_name text,
  period_type text not null check (period_type in ('weekly', 'monthly')),
  period_start date not null,
  period_end date not null,
  goal_amount numeric not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.challenge_records (
  id uuid primary key default gen_random_uuid(),
  challenge_date date not null,
  seller_id uuid references public.vendedores(id),
  seller_name text,
  challenge_type text not null check (
    challenge_type in ('store_goal', 'biggest_ticket', 'pa')
  ),
  challenge_amount numeric not null default 0,
  notes text,
  created_at timestamptz not null default now()
);

create index if not exists vendedores_is_active_idx
  on public.vendedores(is_active);

create index if not exists sales_sale_date_idx
  on public.sales(sale_date);

create index if not exists sales_seller_id_idx
  on public.sales(seller_id);

create index if not exists goals_owner_period_idx
  on public.goals(goal_type, seller_id, period_type, period_start);

create index if not exists challenge_records_date_idx
  on public.challenge_records(challenge_date);

create index if not exists challenge_records_seller_type_idx
  on public.challenge_records(seller_id, challenge_type);
