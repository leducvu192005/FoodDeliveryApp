-- Backend/sql/supabase_shipper_schema.sql
-- Run this script in Supabase SQL editor.

create extension if not exists "pgcrypto";

create table if not exists shippers (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    phone text,
    avatar text,
    is_online boolean not null default false,
    lat double precision,
    lng double precision,
    accept_radius integer not null default 5,
    updated_at timestamptz not null default now()
);

create index if not exists idx_shippers_online on shippers(is_online);
create index if not exists idx_shippers_updated_at on shippers(updated_at desc);

create or replace function fn_shippers_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_shippers_touch_updated_at on shippers;
create trigger trg_shippers_touch_updated_at
before update on shippers
for each row
execute function fn_shippers_touch_updated_at();
