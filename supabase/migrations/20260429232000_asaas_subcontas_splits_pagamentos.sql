-- Estrutura incremental para pagamentos Asaas com subcontas e split automatico.
-- O app nao processa saque: movimentacao e saque acontecem diretamente no Asaas.

alter table public.clientes
  add column if not exists asaas_customer_id text unique,
  add column if not exists asaas_customer_payload jsonb default '{}'::jsonb;

alter table public.splits_pagamento
  add column if not exists estabelecimento_id uuid references public.estabelecimentos(id),
  add column if not exists entregador_id uuid references public.entregadores(id);

create unique index if not exists asaas_subcontas_entidade_unique
  on public.asaas_subcontas (entidade_tipo, entidade_id);

create index if not exists splits_pagamento_estabelecimento_idx
  on public.splits_pagamento (estabelecimento_id, created_at desc);

create index if not exists splits_pagamento_entregador_idx
  on public.splits_pagamento (entregador_id, created_at desc);

create index if not exists pedidos_asaas_payment_id_idx
  on public.pedidos (asaas_payment_id);

-- View sem asaas_api_key para uso do Flutter/Admin.
create or replace view public.v_asaas_subcontas_app
as
select
  s.id,
  s.entidade_tipo,
  s.entidade_id,
  s.asaas_account_id,
  s.asaas_wallet_id,
  s.status_conta,
  s.kyc_status,
  s.onboarding_url,
  s.motivo_rejeicao,
  s.documentos_enviados,
  s.homologada,
  s.limite_recebimento,
  s.valor_recebido_total,
  s.ultima_sincronizacao,
  s.metadata,
  s.created_at,
  s.updated_at
from public.asaas_subcontas s
where
  exists (
    select 1 from public.usuarios u
    where u.id = auth.uid() and u.tipo_usuario = 'admin'
  )
  or (
    s.entidade_tipo = 'estabelecimento'
    and exists (
      select 1 from public.estabelecimentos e
      where e.id = s.entidade_id and e.usuario_id = auth.uid()
    )
  )
  or (
    s.entidade_tipo = 'entregador'
    and exists (
      select 1 from public.entregadores e
      where e.id = s.entidade_id and e.usuario_id = auth.uid()
    )
  );

-- Calculo financeiro central do pedido.
-- Respeita comissao de 6% com teto mensal de R$408 por estabelecimento.
create or replace function public.calcular_financeiro_pedido(
  p_subtotal_produtos numeric,
  p_distancia_km numeric,
  p_estabelecimento_id uuid,
  p_desconto numeric default 0,
  p_taxa_servico_app numeric default 0
)
returns jsonb
language plpgsql
stable
as $$
declare
  v_comissao_pct numeric := 0.06;
  v_teto_mensal numeric := 408.00;
  v_base_km numeric := 5.00;
  v_base_valor numeric := 8.50;
  v_km_excedente numeric := 1.60;
  v_usado_mes numeric := 0;
  v_comissao_bruta numeric := 0;
  v_comissao numeric := 0;
  v_taxa_entrega numeric := 0;
  v_estabelecimento numeric := 0;
  v_total numeric := 0;
begin
  select coalesce(max(valor::numeric), v_comissao_pct * 100) / 100
    into v_comissao_pct
  from public.plataforma_configuracoes
  where chave = 'percentual_comissao_estabelecimento';

  select coalesce(max(valor::numeric), v_teto_mensal)
    into v_teto_mensal
  from public.plataforma_configuracoes
  where chave = 'teto_comissao_mensal';

  select coalesce(max(valor::numeric), v_base_km)
    into v_base_km
  from public.plataforma_configuracoes
  where chave = 'entrega_base_km';

  select coalesce(max(valor::numeric), v_base_valor)
    into v_base_valor
  from public.plataforma_configuracoes
  where chave = 'entrega_base_valor';

  select coalesce(max(valor::numeric), v_km_excedente)
    into v_km_excedente
  from public.plataforma_configuracoes
  where chave = 'entrega_valor_km_excedente';

  select coalesce(sum(sp.plataforma_valor), 0)
    into v_usado_mes
  from public.splits_pagamento sp
  where sp.estabelecimento_id = p_estabelecimento_id
    and sp.created_at >= date_trunc('month', now())
    and sp.created_at < date_trunc('month', now()) + interval '1 month';

  v_taxa_entrega := round(
    case
      when coalesce(p_distancia_km, 0) <= v_base_km then v_base_valor
      else v_base_valor + ((coalesce(p_distancia_km, 0) - v_base_km) * v_km_excedente)
    end,
    2
  );

  v_comissao_bruta := round(coalesce(p_subtotal_produtos, 0) * v_comissao_pct, 2);
  v_comissao := least(v_comissao_bruta, greatest(v_teto_mensal - v_usado_mes, 0));
  v_estabelecimento := round(coalesce(p_subtotal_produtos, 0) - v_comissao, 2);
  v_total := round(
    greatest(
      coalesce(p_subtotal_produtos, 0) + v_taxa_entrega + coalesce(p_taxa_servico_app, 0) - coalesce(p_desconto, 0),
      0
    ),
    2
  );

  return jsonb_build_object(
    'subtotal_produtos', round(coalesce(p_subtotal_produtos, 0), 2),
    'taxa_entrega', v_taxa_entrega,
    'taxa_servico_app', round(coalesce(p_taxa_servico_app, 0), 2),
    'desconto', round(coalesce(p_desconto, 0), 2),
    'comissao_plataforma', v_comissao,
    'comissao_plataforma_bruta', v_comissao_bruta,
    'comissao_teto_mensal', v_teto_mensal,
    'comissao_usada_mes', v_usado_mes,
    'estabelecimento_valor', v_estabelecimento,
    'entregador_valor', v_taxa_entrega,
    'valor_total', v_total
  );
end;
$$;

create or replace view public.v_financeiro_pedido
with (security_invoker = true) as
select
  p.id as pedido_id,
  p.numero_pedido,
  p.cliente_id,
  p.estabelecimento_id,
  p.entregador_id,
  p.status,
  p.pagamento_status,
  p.pagamento_metodo,
  p.subtotal_produtos,
  p.taxa_entrega,
  p.taxa_servico_app,
  p.desconto_cupom,
  p.total as valor_total,
  p.taxa_plataforma_calculada,
  p.taxa_asaas,
  p.valor_liquido,
  p.asaas_payment_id,
  p.created_at,
  sp.estabelecimento_valor,
  sp.entregador_valor_total,
  sp.plataforma_valor,
  sp.status_asaas
from public.pedidos p
left join public.splits_pagamento sp on sp.pedido_id = p.id;

create or replace view public.v_financeiro_estabelecimento
with (security_invoker = true) as
select
  p.estabelecimento_id,
  date_trunc('month', p.created_at) as mes,
  count(*) as pedidos,
  coalesce(sum(p.total), 0) as valor_bruto_vendido,
  coalesce(sum(sp.estabelecimento_valor), 0) as valor_enviado_asaas,
  coalesce(sum(sp.plataforma_valor), 0) as comissao_opadoca,
  coalesce(sum(sp.taxa_asaas_valor), 0) as taxas_asaas
from public.pedidos p
left join public.splits_pagamento sp on sp.pedido_id = p.id
group by p.estabelecimento_id, date_trunc('month', p.created_at);

create or replace view public.v_financeiro_entregador
with (security_invoker = true) as
select
  p.entregador_id,
  date_trunc('month', p.created_at) as mes,
  count(*) as entregas,
  coalesce(sum(sp.entregador_valor_total), 0) as valor_enviado_asaas,
  coalesce(sum(sp.taxa_asaas_valor), 0) as taxas_asaas
from public.pedidos p
left join public.splits_pagamento sp on sp.pedido_id = p.id
where p.entregador_id is not null
group by p.entregador_id, date_trunc('month', p.created_at);

create or replace view public.v_conciliacao_asaas
with (security_invoker = true) as
select
  p.id as pedido_id,
  p.asaas_payment_id,
  p.pagamento_status,
  p.total as pedido_total,
  p.valor_liquido as pedido_valor_liquido,
  sp.id as split_pagamento_id,
  sp.valor_total as split_total,
  sp.valor_liquido as split_valor_liquido,
  sp.taxa_asaas_valor,
  sp.status_asaas,
  sp.webhook_confirmado,
  sp.webhook_evento_id,
  p.created_at
from public.pedidos p
left join public.splits_pagamento sp on sp.pedido_id = p.id;

alter table public.asaas_subcontas enable row level security;
alter table public.splits_pagamento enable row level security;
alter table public.asaas_webhooks_log enable row level security;
alter table public.asaas_eventos_financeiros enable row level security;

revoke all on public.asaas_subcontas from anon, authenticated;
grant select on public.v_asaas_subcontas_app to authenticated;
grant select on public.v_financeiro_pedido to authenticated;
grant select on public.v_financeiro_estabelecimento to authenticated;
grant select on public.v_financeiro_entregador to authenticated;
grant select on public.v_conciliacao_asaas to authenticated;

drop policy if exists "admin_select_asaas_subcontas" on public.asaas_subcontas;
create policy "admin_select_asaas_subcontas"
on public.asaas_subcontas
for select
to authenticated
using (
  exists (
    select 1 from public.usuarios u
    where u.id = auth.uid() and u.tipo_usuario = 'admin'
  )
);

drop policy if exists "select_splits_relacionados" on public.splits_pagamento;
create policy "select_splits_relacionados"
on public.splits_pagamento
for select
to authenticated
using (
  exists (
    select 1 from public.usuarios u
    where u.id = auth.uid() and u.tipo_usuario = 'admin'
  )
  or exists (
    select 1
    from public.pedidos p
    join public.clientes c on c.id = p.cliente_id
    where p.id = splits_pagamento.pedido_id and c.usuario_id = auth.uid()
  )
  or exists (
    select 1
    from public.pedidos p
    join public.estabelecimentos e on e.id = p.estabelecimento_id
    where p.id = splits_pagamento.pedido_id and e.usuario_id = auth.uid()
  )
  or exists (
    select 1
    from public.pedidos p
    join public.entregadores e on e.id = p.entregador_id
    where p.id = splits_pagamento.pedido_id and e.usuario_id = auth.uid()
  )
);

drop policy if exists "admin_select_asaas_eventos_financeiros" on public.asaas_eventos_financeiros;
create policy "admin_select_asaas_eventos_financeiros"
on public.asaas_eventos_financeiros
for select
to authenticated
using (
  exists (
    select 1 from public.usuarios u
    where u.id = auth.uid() and u.tipo_usuario = 'admin'
  )
);
