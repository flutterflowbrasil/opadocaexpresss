-- Ajustes pos-deploy da integracao Asaas.
-- Mantem a view app-facing respeitando RLS/permissoes do usuario chamador
-- e remove indice redundante criado sobre pedidos.asaas_payment_id.

alter view if exists public.v_asaas_subcontas_app
  set (security_invoker = true);

drop index if exists public.pedidos_asaas_payment_id_idx;;
