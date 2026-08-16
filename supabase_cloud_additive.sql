-- HJ VFX cloud schema: additive only, no DROP.
create table if not exists public.portfolio_items (
  id text primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  type text default '其他',
  description text default '',
  sort_order integer default 0,
  created_at timestamptz default now(),
  is_public boolean default true
);
create table if not exists public.portfolio_files (
  work_id text primary key references public.portfolio_items(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  path text not null,
  name text,
  mime_type text,
  size bigint,
  url text
);
create table if not exists public.portfolio_data (
  owner_id uuid not null references auth.users(id) on delete cascade,
  key text not null,
  value jsonb,
  primary key(owner_id,key)
);
alter table public.portfolio_items enable row level security;
alter table public.portfolio_files enable row level security;
alter table public.portfolio_data enable row level security;

do $$ begin
 if not exists(select 1 from pg_policies where schemaname='public' and tablename='portfolio_items' and policyname='public_read_portfolio_items') then
  create policy public_read_portfolio_items on public.portfolio_items for select using (is_public=true or auth.uid()=owner_id);
 end if;
 if not exists(select 1 from pg_policies where schemaname='public' and tablename='portfolio_items' and policyname='owner_write_portfolio_items') then
  create policy owner_write_portfolio_items on public.portfolio_items for all using(auth.uid()=owner_id) with check(auth.uid()=owner_id);
 end if;
 if not exists(select 1 from pg_policies where schemaname='public' and tablename='portfolio_files' and policyname='public_read_portfolio_files') then
  create policy public_read_portfolio_files on public.portfolio_files for select using(true);
 end if;
 if not exists(select 1 from pg_policies where schemaname='public' and tablename='portfolio_files' and policyname='owner_write_portfolio_files') then
  create policy owner_write_portfolio_files on public.portfolio_files for all using(auth.uid()=owner_id) with check(auth.uid()=owner_id);
 end if;
 if not exists(select 1 from pg_policies where schemaname='public' and tablename='portfolio_data' and policyname='owner_rw_portfolio_data') then
  create policy owner_rw_portfolio_data on public.portfolio_data for all using(auth.uid()=owner_id) with check(auth.uid()=owner_id);
 end if;
end $$;

insert into storage.buckets(id,name,public)
values('portfolio-media','portfolio-media',true)
on conflict(id) do nothing;

do $$ begin
 if not exists(select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname='public_read_portfolio_media') then
  create policy public_read_portfolio_media on storage.objects for select using(bucket_id='portfolio-media');
 end if;
 if not exists(select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname='owner_upload_portfolio_media') then
  create policy owner_upload_portfolio_media on storage.objects for insert to authenticated with check(bucket_id='portfolio-media' and (storage.foldername(name))[1]=auth.uid()::text);
 end if;
 if not exists(select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname='owner_update_portfolio_media') then
  create policy owner_update_portfolio_media on storage.objects for update to authenticated using(bucket_id='portfolio-media' and (storage.foldername(name))[1]=auth.uid()::text);
 end if;
 if not exists(select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname='owner_delete_portfolio_media') then
  create policy owner_delete_portfolio_media on storage.objects for delete to authenticated using(bucket_id='portfolio-media' and (storage.foldername(name))[1]=auth.uid()::text);
 end if;
end $$;
