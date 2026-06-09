-- ============================================================
-- APRI POCO 원가·운영 앱 · 클라우드 저장 (매장 코드별 1행)
-- Supabase 대시보드 → SQL Editor → New query → 붙여넣고 Run (한 번만)
-- 기존 cm_* (다른 앱)과는 완전히 별개입니다.
-- ============================================================

create table if not exists public.apripoco_stores (
  code        text primary key,
  data        jsonb not null default '{}'::jsonb,
  updated_at  timestamptz not null default now()
);

alter table public.apripoco_stores enable row level security;
-- 직접 접근은 막고(정책 없음), 아래 SECURITY DEFINER 함수로만 읽고/쓴다.

create or replace function public.ap_load(p_code text)
returns jsonb
language sql security definer set search_path = public as $$
  select data from public.apripoco_stores where code = p_code;
$$;

create or replace function public.ap_save(p_code text, p_data jsonb)
returns timestamptz
language plpgsql security definer set search_path = public as $$
declare ts timestamptz;
begin
  insert into public.apripoco_stores(code, data, updated_at)
  values (p_code, p_data, now())
  on conflict (code) do update set data = excluded.data, updated_at = now()
  returning updated_at into ts;
  return ts;
end;
$$;

grant execute on function public.ap_load(text)         to anon, authenticated;
grant execute on function public.ap_save(text, jsonb)  to anon, authenticated;
