alter table public.desafios
  add column if not exists id uuid default gen_random_uuid();

update public.desafios
set id = gen_random_uuid()
where id is null;

alter table public.desafios
  alter column id set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'desafios_pkey'
      and conrelid = 'public.desafios'::regclass
  ) then
    alter table public.desafios
      add constraint desafios_pkey primary key (id);
  end if;
end $$;
