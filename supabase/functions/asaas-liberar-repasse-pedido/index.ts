import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-worker-secret',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'Metodo nao permitido.' }, 405);

  try {
    authorizeWorker(req);
    const supabase = createClient(requiredEnv('SUPABASE_URL'), requiredEnv('SUPABASE_SERVICE_ROLE_KEY'), {
      auth: { persistSession: false },
    });
    const asaasApiKey = requiredEnv('ASAAS_API_KEY');
    const asaasBaseUrl = (Deno.env.get('ASAAS_BASE_URL') ?? 'https://api-sandbox.asaas.com/v3').replace(/\/$/, '');

    const body = await req.json().catch(() => ({}));
    const pedidoId = String(body.pedido_id ?? '').trim();
    if (!pedidoId) return json({ error: 'pedido_id obrigatorio.' }, 400);

    const { data: cfg } = await supabase.rpc('fn_get_config_financeira');
    const modo = String(cfg?.modo_repasse ?? 'pos_entrega');
    if (modo === 'checkout_imediato') {
      return json({ ok: true, skipped: true, reason: 'checkout_imediato' });
    }
    if (cfg?.retencao_temporaria_ativa === true && Number(cfg?.retencao_temporaria_horas ?? 0) > 0) {
      return json({ ok: true, skipped: true, reason: 'retencao_temporaria' });
    }

    const { data: pedido, error: pedidoError } = await supabase
      .from('pedidos')
      .select('id, status, pagamento_status, asaas_payment_id, entregador_id, estabelecimento_id, repasse_processado')
      .eq('id', pedidoId)
      .single();
    if (pedidoError || !pedido) throw new HttpError('Pedido nao encontrado.', 404);

    if (pedido.repasse_processado) return json({ ok: true, duplicate: true });
    if (pedido.pagamento_status !== 'confirmado') {
      return json({ ok: false, error: 'Pagamento ainda nao confirmado.' }, 409);
    }
    if (modo === 'pos_entrega' && pedido.status !== 'entregue') {
      return json({ ok: false, error: 'Pedido ainda nao entregue.' }, 409);
    }
    if (modo === 'pos_coleta' && !['coletado', 'a_caminho_cliente', 'em_entrega', 'entregue'].includes(pedido.status)) {
      return json({ ok: false, error: 'Pedido ainda nao coletado.' }, 409);
    }

    const eventId = `REPASSE:${pedidoId}`;
    const { data: claimed, error: claimError } = await supabase
      .from('asaas_eventos_financeiros')
      .insert({
        asaas_event_id: eventId,
        asaas_payment_id: pedido.asaas_payment_id,
        evento: 'REPASSE_PEDIDO',
        pedido_id: pedidoId,
        processado: false,
      })
      .select('id, processado')
      .single();
    if (claimError) {
      if (claimError.code === '23505') return json({ ok: true, duplicate: true });
      throw claimError;
    }

    const { data: split, error: splitError } = await supabase
      .from('splits_pagamento')
      .select('*')
      .eq('pedido_id', pedidoId)
      .maybeSingle();
    if (splitError) throw splitError;
    if (!split) throw new HttpError('Split do pedido nao encontrado.', 404);

    const pctEstab = Number(cfg?.repasse_estabelecimento_pct ?? 100) / 100;
    const pctEnt = Number(cfg?.repasse_entregador_pct ?? 100) / 100;
    const valorEstab = round2(Number(split.estabelecimento_valor ?? 0) * pctEstab);
    const valorEnt = round2(Number(split.entregador_valor_total ?? split.entregador_taxa_entrega_valor ?? 0) * pctEnt);

    const transferIds: Record<string, string> = { ...(split.asaas_transfer_ids ?? {}) };
    let estabOk = Boolean(split.repasse_estab_processado);
    let entOk = Boolean(split.repasse_entregador_processado) || valorEnt <= 0;

    if (!estabOk && valorEstab > 0 && split.estabelecimento_wallet_id) {
      const transfer = await asaasTransfer(asaasBaseUrl, asaasApiKey, {
        value: valorEstab,
        walletId: split.estabelecimento_wallet_id,
        description: `Repasse estabelecimento pedido ${pedidoId}`,
        externalReference: `${pedidoId}:estab`,
      });
      transferIds.estabelecimento = transfer.id;
      estabOk = true;
    }

    if (!entOk && valorEnt > 0) {
      let walletId = split.entregador_wallet_id as string | null;
      if (!walletId && pedido.entregador_id) {
        const { data: sub } = await supabase
          .from('asaas_subcontas')
          .select('asaas_wallet_id')
          .eq('entidade_tipo', 'entregador')
          .eq('entidade_id', pedido.entregador_id)
          .eq('status_conta', 'active')
          .eq('homologada', true)
          .maybeSingle();
        walletId = sub?.asaas_wallet_id ?? null;
      }
      if (!walletId) {
        await supabase.from('asaas_eventos_financeiros').update({
          erro: 'Entregador sem subconta homologada; taxa permanece na master.',
        }).eq('id', claimed.id);
      } else {
        const transfer = await asaasTransfer(asaasBaseUrl, asaasApiKey, {
          value: valorEnt,
          walletId,
          description: `Taxa entrega pedido ${pedidoId}`,
          externalReference: `${pedidoId}:entregador`,
        });
        transferIds.entregador = transfer.id;
        entOk = true;
        await supabase.from('splits_pagamento').update({
          entregador_id: pedido.entregador_id,
          entregador_wallet_id: walletId,
        }).eq('id', split.id);
      }
    }

    await supabase.from('splits_pagamento').update({
      status: estabOk ? 'processado' : 'pendente',
      repasse_estab_processado: estabOk,
      repasse_entregador_processado: entOk,
      asaas_transfer_ids: transferIds,
      processado_em: estabOk ? new Date().toISOString() : null,
    }).eq('id', split.id);

    if (estabOk) {
      await supabase.from('pedidos').update({
        repasse_processado: true,
        repasse_processado_em: new Date().toISOString(),
        split_processado: true,
      }).eq('id', pedidoId);
    }

    await supabase.from('asaas_eventos_financeiros').update({
      processado: estabOk,
      processado_em: estabOk ? new Date().toISOString() : null,
      split_pagamento_id: split.id,
      valor_bruto: round2(valorEstab + valorEnt),
      payload: { transferIds, modo, valorEstab, valorEnt },
      status_novo: estabOk ? 'repasse_liberado' : 'repasse_parcial',
    }).eq('id', claimed.id);

    return json({ ok: true, estabOk, entOk, transferIds });
  } catch (error) {
    console.error('[asaas-liberar-repasse-pedido]', error);
    const status = error instanceof HttpError ? error.status : 500;
    return json({ error: error instanceof Error ? error.message : 'Erro inesperado.' }, status);
  }
});

function authorizeWorker(req: Request) {
  const secret = Deno.env.get('FINANCE_WORKER_SECRET')
    ?? Deno.env.get('PUSH_WORKER_SECRET')
    ?? '';
  if (!secret) throw new HttpError('FINANCE_WORKER_SECRET nao configurado.', 503);
  const header = req.headers.get('x-worker-secret')
    || req.headers.get('Authorization')?.replace(/^Bearer\s+/i, '')
    || '';
  if (header !== secret) throw new HttpError('Nao autorizado.', 401);
}

async function asaasTransfer(
  baseUrl: string,
  apiKey: string,
  payload: { value: number; walletId: string; description: string; externalReference: string },
) {
  const response = await fetch(`${baseUrl}/transfers`, {
    method: 'POST',
    headers: { access_token: apiKey, 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new HttpError(`Asaas recusou transfer: ${JSON.stringify(data)}`, 502);
  }
  const id = String(data.id ?? '');
  if (!id) throw new HttpError('Transfer Asaas sem id.', 502);
  return { id, ...data };
}

function round2(n: number) {
  return Math.round((n + Number.EPSILON) * 100) / 100;
}

function requiredEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Secret ${name} nao configurado.`);
  return value;
}

class HttpError extends Error {
  constructor(message: string, public status = 400) {
    super(message);
  }
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
