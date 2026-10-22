-- Meu Imóvel — esquema inicial (MVP: imóveis e contratos)
-- Cada proprietário só enxerga e altera os próprios dados (RLS por owner_id).

create extension if not exists pgcrypto;

-- ─────────────────────────────────────────────
-- Imóveis
-- ─────────────────────────────────────────────
create table public.imoveis (
  id           uuid primary key default gen_random_uuid(),
  owner_id     uuid not null default auth.uid() references auth.users (id) on delete cascade,
  apelido      text not null check (char_length(apelido) between 1 and 80),
  endereco     text not null,
  tipo         text not null default 'casa'
               check (tipo in ('casa', 'apartamento', 'comercial', 'outro')),
  observacoes  text,
  created_at   timestamptz not null default now()
);

create index imoveis_owner_idx on public.imoveis (owner_id);

-- ─────────────────────────────────────────────
-- Contratos (dados do inquilino ficam no próprio contrato no MVP)
-- ─────────────────────────────────────────────
create table public.contratos (
  id                  uuid primary key default gen_random_uuid(),
  owner_id            uuid not null default auth.uid() references auth.users (id) on delete cascade,
  imovel_id           uuid not null references public.imoveis (id) on delete cascade,
  inquilino_nome      text not null,
  inquilino_telefone  text,
  inquilino_email     text,
  valor_aluguel       numeric(12, 2) not null check (valor_aluguel > 0),
  dia_vencimento      smallint not null check (dia_vencimento between 1 and 31),
  data_inicio         date not null,
  data_fim            date,
  status              text not null default 'ativo' check (status in ('ativo', 'encerrado')),
  created_at          timestamptz not null default now(),
  constraint contratos_datas_validas check (data_fim is null or data_fim >= data_inicio)
);

create index contratos_owner_idx  on public.contratos (owner_id);
create index contratos_imovel_idx on public.contratos (imovel_id);

-- Só um contrato ativo por imóvel
create unique index contratos_um_ativo_por_imovel
  on public.contratos (imovel_id) where status = 'ativo';

-- ─────────────────────────────────────────────
-- Row Level Security
-- ─────────────────────────────────────────────
alter table public.imoveis   enable row level security;
alter table public.contratos enable row level security;

create policy "imoveis: dono acessa"
  on public.imoveis for all
  to authenticated
  using      (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

create policy "contratos: dono acessa"
  on public.contratos for all
  to authenticated
  using (owner_id = (select auth.uid()))
  with check (
    owner_id = (select auth.uid())
    and exists (
      select 1 from public.imoveis i
      where i.id = imovel_id and i.owner_id = (select auth.uid())
    )
  );
