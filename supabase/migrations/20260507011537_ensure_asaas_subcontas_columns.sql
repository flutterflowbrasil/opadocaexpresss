-- Garante as colunas consumidas pela Edge Function asaas-criar-subconta.
-- A apiKey da subconta permanece apenas em public.asaas_subcontas.

alter table public.asaas_subcontas
  add column if not exists kyc_status text,
  add column if not exists onboarding_url text,
  add column if not exists motivo_rejeicao text,
  add column if not exists documentos_enviados boolean not null default false,
  add column if not exists homologada boolean not null default false,
  add column if not exists limite_recebimento numeric,
  add column if not exists valor_recebido_total numeric not null default 0,
  add column if not exists ultima_sincronizacao timestamptz,
  add column if not exists metadata jsonb not null default '{}'::jsonb;

create unique index if not exists asaas_subcontas_entidade_unique
  on public.asaas_subcontas (entidade_tipo, entidade_id);
