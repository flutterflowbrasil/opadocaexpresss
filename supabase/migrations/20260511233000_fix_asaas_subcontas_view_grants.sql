-- Corrige o acesso da view v_asaas_subcontas_app quando security_invoker=true.
-- A tabela base guarda asaas_api_key, entao o app recebe grant apenas nas
-- colunas seguras que a view expoe.

revoke all on public.asaas_subcontas from anon, authenticated;

grant select (
  id,
  entidade_tipo,
  entidade_id,
  asaas_account_id,
  asaas_wallet_id,
  status_conta,
  kyc_status,
  onboarding_url,
  motivo_rejeicao,
  documentos_enviados,
  homologada,
  limite_recebimento,
  valor_recebido_total,
  ultima_sincronizacao,
  metadata,
  created_at,
  updated_at
) on public.asaas_subcontas to authenticated;

grant select on public.v_asaas_subcontas_app to authenticated;

alter view if exists public.v_asaas_subcontas_app
  set (security_invoker = true);

drop policy if exists "asaas_subcontas_owner_select" on public.asaas_subcontas;
create policy "asaas_subcontas_owner_select"
on public.asaas_subcontas
for select
to authenticated
using (
  (
    entidade_tipo = 'estabelecimento'
    and exists (
      select 1
      from public.estabelecimentos e
      where e.id = asaas_subcontas.entidade_id
        and e.usuario_id = (select auth.uid())
    )
  )
  or (
    entidade_tipo = 'entregador'
    and exists (
      select 1
      from public.entregadores e
      where e.id = asaas_subcontas.entidade_id
        and e.usuario_id = (select auth.uid())
    )
  )
);
