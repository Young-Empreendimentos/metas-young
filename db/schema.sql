-- Metas Young — schema `metas` no Supabase (projeto young-workspace / vvtympzatclvjaqucebr)
-- Tabelas no schema proprio `metas` (padrao reorg 2026-08). RLS ligado; leitura p/ qualquer
-- usuario logado, escrita so para quem esta na allowlist metas.admins (adm e coord administrativo).
-- Aplicado via migrations: metas_schema_create + metas_move_storage_drop_public.
--
-- IMPORTANTE: para a API REST enxergar o schema, adicionar `metas` em
-- Supabase → Project Settings → API → Exposed schemas (feito no painel, nao por SQL).

create schema if not exists metas;
grant usage on schema metas to authenticated, service_role;

create table if not exists metas.admins (
  email text primary key,
  nome text,
  criado_em timestamptz not null default now()
);
alter table metas.admins enable row level security;
create policy admins_sel on metas.admins for select to authenticated using (true);
-- escrita na allowlist: so service_role (via SQL/painel). Nunca anon.

create or replace function metas.is_admin()
returns boolean language sql stable security invoker set search_path = metas, public as $$
  select exists (
    select 1 from metas.admins a
    where lower(a.email) = lower(coalesce(auth.jwt() ->> 'email',''))
  );
$$;
revoke execute on function metas.is_admin() from public, anon;
grant execute on function metas.is_admin() to authenticated;

create table if not exists metas.config (
  id text primary key,
  semestre_ativo text not null,
  sem_label text not null,
  meses jsonb not null default '[]'::jsonb,
  atualizado_em timestamptz not null default now()
);
alter table metas.config enable row level security;
create policy config_sel on metas.config for select to authenticated using (true);
create policy config_ins on metas.config for insert to authenticated with check (metas.is_admin());
create policy config_upd on metas.config for update to authenticated using (metas.is_admin()) with check (metas.is_admin());
create policy config_del on metas.config for delete to authenticated using (metas.is_admin());

create table if not exists metas.people (
  id text primary key,
  nome text not null,
  equipe text,
  cor text,
  foto_url text,
  atualizado_em timestamptz not null default now()
);
alter table metas.people enable row level security;
create policy people_sel on metas.people for select to authenticated using (true);
create policy people_ins on metas.people for insert to authenticated with check (metas.is_admin());
create policy people_upd on metas.people for update to authenticated using (metas.is_admin()) with check (metas.is_admin());
create policy people_del on metas.people for delete to authenticated using (metas.is_admin());

create table if not exists metas.goals (
  id text primary key,
  semestre text not null,
  equipe text, nivel text, rito text,
  indicador text not null,
  meta text, op text, target double precision, unidade text, direcao text,
  detalhamento text, fonte text, responsavel text, resp_key text, inicial text,
  valores jsonb not null default '{}'::jsonb,
  ordem int,
  atualizado_em timestamptz not null default now()
);
alter table metas.goals enable row level security;
create policy goals_sel on metas.goals for select to authenticated using (true);
create policy goals_ins on metas.goals for insert to authenticated with check (metas.is_admin());
create policy goals_upd on metas.goals for update to authenticated using (metas.is_admin()) with check (metas.is_admin());
create policy goals_del on metas.goals for delete to authenticated using (metas.is_admin());

grant select, insert, update, delete on metas.config, metas.people, metas.goals to authenticated;
grant select on metas.admins to authenticated;
grant all on metas.config, metas.people, metas.goals, metas.admins to service_role;

-- Storage: bucket publico de leitura; upload/alteracao so admin
insert into storage.buckets (id, name, public) values ('metas-fotos','metas-fotos', true) on conflict (id) do nothing;
create policy metas_fotos_sel on storage.objects for select to public using (bucket_id = 'metas-fotos');
create policy metas_fotos_ins on storage.objects for insert to authenticated with check (bucket_id = 'metas-fotos' and metas.is_admin());
create policy metas_fotos_upd on storage.objects for update to authenticated using (bucket_id = 'metas-fotos' and metas.is_admin()) with check (bucket_id = 'metas-fotos' and metas.is_admin());
create policy metas_fotos_del on storage.objects for delete to authenticated using (bucket_id = 'metas-fotos' and metas.is_admin());

-- Allowlist de quem edita (adm/coord): preencher os e-mails Google @young reais, ex.:
-- insert into metas.admins (email, nome) values
--   ('fulano@youngempreendimentos.com.br','Fulano (ADM)'),
--   ('ciclana@youngempreendimentos.com.br','Ciclana (Coord. Administrativo)')
-- on conflict (email) do nothing;
