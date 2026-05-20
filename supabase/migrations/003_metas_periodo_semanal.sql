alter table public.metas
  add column if not exists weekly_start_date date,
  add column if not exists weekly_end_date date;

update public.metas
set
  weekly_start_date = coalesce(
    weekly_start_date,
    date_trunc('week', created_at)::date
  ),
  weekly_end_date = coalesce(
    weekly_end_date,
    (date_trunc('week', created_at)::date + 6)
  )
where weekly_start_date is null
   or weekly_end_date is null;
