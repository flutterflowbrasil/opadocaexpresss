import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, asaas-access-token, x-asaas-token',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'Metodo nao permitido.' }, 405);

  const supabase = createClient(requiredEnv('SUPABASE_URL'), requiredEnv('SUPABASE_SERVICE_ROLE_KEY'), {
    auth: { persistSession: false },
  });

  try {
    validateWebhookToken(req);
    const payload = await req.json();
    const evento = String(payload.event ?? '');
    const asaasEventId = String(payload.id ?? payload.eventId ?? `${evento}:${payload.payment?.id ?? crypto.randomUUID()}`);
    const payment = payload.payment ?? {};
    const paymentId = payment.id ?? payload.paymentId;

    const { data: log, error: logError } = await supabase.from('asaas_webhooks_log').upsert({
      evento,
      asaas_event_id: asaasEventId,
      payload,
      processado: false,
    }, { onConflict: 'asaas_event_id' }).select('id, processado').single();
    if (logError) throw logError;
    if (log.processado) return json({ ok: true, duplicate: true });

    const { data: pedido } = paymentId
      ? await supabase.from('pedidos').select('id, pagamento_status').eq('asaas_payment_id', paymentId).maybeSingle()
      : { data: null };

    const { data: split } = paymentId
      ? await supabase.from('splits_pagamento').select('id').eq('asaas_payment_id', paymentId).maybeSingle()
      : { data: null };

    const pagamentoStatus = statusFromEvent(evento, payment.status);
    const updatePedido: Record<string, unknown> = {};
    if (pagamentoStatus) updatePedido.pagamento_status = pagamentoStatus;
    if (['PAYMENT_RECEIVED', 'PAYMENT_CONFIRMED'].includes(evento)) {
      updatePedido.pagamento_confirmado_em = new Date().toISOString();
      updatePedido.financeiro_processado = true;
      updatePedido.financeiro_processado_em = new Date().toISOString();
      updatePedido.split_processado = true;
    }
    if (evento === 'PAYMENT_DELETED') updatePedido.pagamento_cancelado_em = new Date().toISOString();
    if (['PAYMENT_REFUNDED', 'PAYMENT_CHARGEBACK'].includes(evento)) {
      updatePedido.pagamento_estornado_em = new Date().toISOString();
    }
    if (payment.netValue != null) updatePedido.valor_liquido = payment.netValue;
    if (payment.value != null && payment.netValue != null) updatePedido.taxa_asaas = round2(Number(payment.value) - Number(payment.netValue));

    if (pedido && Object.keys(updatePedido).length > 0) {
      await supabase.from('pedidos').update(updatePedido).eq('id', pedido.id);
    }

    if (split) {
      await supabase.from('splits_pagamento').update({
        status: ['PAYMENT_RECEIVED', 'PAYMENT_CONFIRMED'].includes(evento) ? 'processado' : undefined,
        status_asaas: payment.status ?? evento,
        webhook_confirmado: ['PAYMENT_RECEIVED', 'PAYMENT_CONFIRMED'].includes(evento),
        webhook_evento_id: asaasEventId,
        taxa_asaas_valor: payment.value != null && payment.netValue != null ? round2(Number(payment.value) - Number(payment.netValue)) : undefined,
        valor_liquido: payment.netValue ?? undefined,
        processado_em: ['PAYMENT_RECEIVED', 'PAYMENT_CONFIRMED'].includes(evento) ? new Date().toISOString() : undefined,
      }).eq('id', split.id);
    }

    await supabase.from('asaas_eventos_financeiros').upsert({
      asaas_event_id: asaasEventId,
      asaas_payment_id: paymentId,
      evento,
      pedido_id: pedido?.id ?? null,
      split_pagamento_id: split?.id ?? null,
      valor_bruto: payment.value ?? null,
      valor_liquido: payment.netValue ?? null,
      taxa_asaas: payment.value != null && payment.netValue != null ? round2(Number(payment.value) - Number(payment.netValue)) : null,
      status_anterior: pedido?.pagamento_status ?? null,
      status_novo: pagamentoStatus ?? payment.status ?? null,
      payload,
      processado: true,
      processado_em: new Date().toISOString(),
    }, { onConflict: 'asaas_event_id' });

    await supabase.from('asaas_webhooks_log').update({
      processado: true,
      processado_em: new Date().toISOString(),
      erro: null,
    }).eq('asaas_event_id', asaasEventId);

    return json({ ok: true });
  } catch (error) {
    console.error('[asaas-webhook]', error);
    return json({ error: error instanceof Error ? error.message : 'Erro inesperado.' }, error instanceof HttpError ? error.status : 500);
  }
});

function validateWebhookToken(req: Request) {
  const expected = Deno.env.get('ASAAS_WEBHOOK_TOKEN');
  if (!expected) return;
  const received =
    req.headers.get('asaas-access-token') ??
    req.headers.get('x-asaas-token') ??
    req.headers.get('authorization')?.replace(/^Bearer\s+/i, '');
  if (received !== expected) throw new HttpError('Webhook Asaas nao autorizado.', 401);
}

function statusFromEvent(event: string, fallback: string | undefined) {
  return ({
    PAYMENT_CREATED: 'aguardando_pagamento',
    PAYMENT_RECEIVED: 'confirmado',
    PAYMENT_CONFIRMED: 'confirmado',
    PAYMENT_OVERDUE: 'vencido',
    PAYMENT_DELETED: 'cancelado',
    PAYMENT_REFUNDED: 'estornado',
    PAYMENT_CHARGEBACK: 'chargeback',
    PAYMENT_SPLIT_DIVERGENCE_BLOCK: 'bloqueado_divergencia_split',
    PAYMENT_SPLIT_DIVERGENCE_BLOCK_FINISHED: 'confirmado',
  } as Record<string, string>)[event] ?? (fallback ? String(fallback).toLowerCase() : null);
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
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

function round2(value: number): number {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}
