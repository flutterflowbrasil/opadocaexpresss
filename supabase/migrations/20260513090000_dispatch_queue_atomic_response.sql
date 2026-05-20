-- Garante que ofertas de despacho sejam respondidas de forma atomica.
-- O app do entregador nao deve aceitar pedidos direto em public.pedidos.

alter table public.despacho_pedidos
  add column if not exists motivo_rejeicao text;

alter table public.despacho_pedidos enable row level security;
grant select on public.despacho_pedidos to authenticated;

drop policy if exists "Entregadores podem ver pedidos prontos" on public.pedidos;
drop policy if exists "Entregadores podem aceitar pedidos prontos" on public.pedidos;

drop policy if exists "despacho_select_entregador" on public.despacho_pedidos;
create policy "despacho_select_entregador"
on public.despacho_pedidos
for select
to authenticated
using (
  entregador_id = public.get_entregador_id()
);

drop policy if exists "despacho_update_entregador" on public.despacho_pedidos;

create or replace function public.responder_despacho(
  p_despacho_id uuid,
  p_acao text,
  p_motivo text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_entregador_id uuid;
  v_despacho public.despacho_pedidos%rowtype;
begin
  v_entregador_id := public.get_entregador_id();

  if v_entregador_id is null then
    return jsonb_build_object(
      'ok', false,
      'codigo', 'entregador_nao_encontrado',
      'mensagem', 'Entregador nao encontrado para o usuario autenticado.'
    );
  end if;

  if p_acao not in ('aceitar', 'recusar') then
    return jsonb_build_object(
      'ok', false,
      'codigo', 'acao_invalida',
      'mensagem', 'Acao invalida para resposta de despacho.'
    );
  end if;

  select *
    into v_despacho
    from public.despacho_pedidos
   where id = p_despacho_id
     and entregador_id = v_entregador_id
   for update;

  if not found then
    return jsonb_build_object(
      'ok', false,
      'codigo', 'oferta_nao_encontrada',
      'mensagem', 'Oferta nao encontrada para este entregador.'
    );
  end if;

  if v_despacho.status <> 'aguardando' then
    return jsonb_build_object(
      'ok', false,
      'codigo', 'oferta_ja_respondida',
      'mensagem', 'Esta oferta ja foi respondida.',
      'status', v_despacho.status
    );
  end if;

  if v_despacho.expira_em <= now() then
    update public.despacho_pedidos
       set status = 'expirado',
           respondido_em = now()
     where id = v_despacho.id
       and status = 'aguardando';

    return jsonb_build_object(
      'ok', false,
      'codigo', 'oferta_expirada',
      'mensagem', 'O tempo para aceitar esta entrega expirou.'
    );
  end if;

  if p_acao = 'recusar' then
    update public.despacho_pedidos
       set status = 'rejeitado',
           respondido_em = now(),
           motivo_rejeicao = coalesce(p_motivo, 'Recusado pelo entregador')
     where id = v_despacho.id
       and status = 'aguardando';

    return jsonb_build_object(
      'ok', true,
      'acao', 'recusar',
      'pedido_id', v_despacho.pedido_id,
      'despacho_id', v_despacho.id
    );
  end if;

  update public.pedidos
     set entregador_id = v_entregador_id,
         status = 'a_caminho_coleta',
         updated_at = now()
   where id = v_despacho.pedido_id
     and entregador_id is null
     and status = 'pronto';

  if not found then
    return jsonb_build_object(
      'ok', false,
      'codigo', 'pedido_indisponivel',
      'mensagem', 'Pedido indisponivel para aceite.'
    );
  end if;

  update public.despacho_pedidos
     set status = 'aceito',
         respondido_em = now()
   where id = v_despacho.id
     and status = 'aguardando';

  update public.entregadores
     set status_despacho = 'em_pedido',
         pedido_atual_id = v_despacho.pedido_id,
         score_fila = greatest(coalesce(score_fila, 0) - 5, 0),
         updated_at = now()
   where id = v_entregador_id;

  return jsonb_build_object(
    'ok', true,
    'acao', 'aceitar',
    'pedido_id', v_despacho.pedido_id,
    'despacho_id', v_despacho.id
  );
end;
$$;

grant execute on function public.responder_despacho(uuid, text, text) to authenticated;

create or replace function public.fn_expirar_despachos_vencidos()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer := 0;
  v_row record;
begin
  for v_row in
    select id
      from public.despacho_pedidos
     where status = 'aguardando'
       and expira_em < now()
     for update skip locked
  loop
    update public.despacho_pedidos
       set status = 'expirado',
           respondido_em = now()
     where id = v_row.id
       and status = 'aguardando';

    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;

create extension if not exists pg_cron with schema extensions;

do $$
begin
  perform cron.unschedule('expirar-despachos-vencidos');
exception
  when others then
    null;
end $$;

select cron.schedule(
  'expirar-despachos-vencidos',
  '* * * * *',
  $$select public.fn_expirar_despachos_vencidos();$$
);
