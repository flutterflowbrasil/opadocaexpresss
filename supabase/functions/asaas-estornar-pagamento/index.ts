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
    if (cfg?.estorno_automatico_ativo === false) {
      return json({ ok: true, skipped: true, reason: 'estorno_desligado' });
    }

    const { data: pedido, error: pedidoError } = await supabase
      .from('pedidos')
      .select('id, status, pagamento_status, asaas_payment_id, estorno_solicitado_em')
      .eq('id', pedidoId)
      .single();
    if (pedidoError || !pedido) throw new HttpError('Pedido nao encontrado.', 404);
    if (!pedido.asaas_payment_id) throw new HttpError('Pedido sem cobranca Asaas.', 409);
    if (!String(pedido.status ?? '').startsWith('cancelado')) {
      return json({ ok: false, error: 'Pedido nao esta cancelado.' }, 409);
    }
    if (['estornado', 'cancelado', 'chargeback'].includes(pedido.pagamento_status)) {
      return json({ ok: true, duplicate: true });
    }

    const eventId = `ESTORNO:${pedidoId}`;
    const { data: claimed, error: claimError } = await supabase
      .from('asaas_eventos_financeiros')
      .insert({
        asaas_event_id: eventId,
        asaas_payment_id: pedido.asaas_payment_id,
        evento: 'ESTORNO_PEDIDO',
        pedido_id: pedidoId,
        processado: false,
      })
      .select('id, processado')
      .single();
    if (claimError) {
      if (claimError.code === '23505') return json({ ok: true, duplicate: true });
      throw claimError;
    }

    await supabase.from('pedidos').update({
      estorno_solicitado_em: new Date().toISOString(),
    }).eq('id', pedidoId);

    const asaasResult = await refundOrDelete(asaasBaseUrl, asaasApiKey, pedido.asaas_payment_id);

    await supabase.from('splits_pagamento').update({
      status: 'estornado',
    }).eq('pedido_id', pedidoId);

    await supabase.from('asaas_eventos_financeiros').update({
      processado: true,
      processado_em: new Date().toISOString(),
      payload: asaasResult,
      status_anterior: pedido.pagamento_status,
      status_novo: 'estornado',
    }).eq('id', claimed.id);

    return json({ ok: true, asaas: asaasResult });
  } catch (error) {
    console.error('[asaas-estornar-pagamento]', error);
    const status = error instanceof HttpError ? error.status : 500;
    return json({ error: error instanceof Error ? error.message : 'Erro inesperado.' }, status);
  }
});

async function refundOrDelete(baseUrl: string, apiKey: string, paymentId: string) {
  const getRes = await fetch(`${baseUrl}/payments/${paymentId}`, {
    headers: { access_token: apiKey },
  });
  const payment = await getRes.json().catch(() => ({}));
  const status = String(payment.status ?? '').toUpperCase();

  if (['PENDING', 'OVERDUE'].includes(status)) {
    const del = await fetch(`${baseUrl}/payments/${paymentId}`, {
      method: 'DELETE',
      headers: { access_token: apiKey },
    });
    const data = await del.json().catch(() => ({}));
    if (!del.ok) throw new HttpError(`Asaas recusou cancelamento: ${JSON.stringify(data)}`, 502);
    return { action: 'delete', status, data };
  }

  const refund = await fetch(`${baseUrl}/payments/${paymentId}/refund`, {
    method: 'POST',
    headers: { access_token: apiKey, 'Content-Type': 'application/json' },
    body: JSON.stringify({}),
  });
  const data = await refund.json().catch(() => ({}));
  if (!refund.ok) throw new HttpError(`Asaas recusou estorno: ${JSON.stringify(data)}`, 502);
  return { action: 'refund', status, data };
}

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
