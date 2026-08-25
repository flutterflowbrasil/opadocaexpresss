import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-worker-secret',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const HIGH_PRIORITY_EVENTS = new Set([
  'despacho_nova_oferta',
  'pedido_novo_estabelecimento',
]);

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'Metodo nao permitido.' }, 405);

  try {
    authorizeWorker(req);
    const supabase = createClient(requiredEnv('SUPABASE_URL'), requiredEnv('SUPABASE_SERVICE_ROLE_KEY'), {
      auth: { persistSession: false },
    });

    const oneSignalAppId = requiredEnv('ONESIGNAL_APP_ID');
    const oneSignalApiKey = requiredEnv('ONESIGNAL_REST_API_KEY');

    const { data: claimed, error: claimError } = await supabase.rpc('fn_claim_notificacoes_fila', { p_limit: 50 });
    if (claimError) throw claimError;
    const jobs = (claimed ?? []) as Array<Record<string, unknown>>;
    if (jobs.length === 0) return json({ ok: true, processed: 0 });

    let maxPush = 3;
    const { data: maxCfg } = await supabase
      .from('plataforma_configuracoes')
      .select('valor')
      .eq('chave', 'max_tentativas_push')
      .maybeSingle();
    const parsedMax = Number(maxCfg?.valor);
    if (Number.isFinite(parsedMax) && parsedMax > 0) maxPush = parsedMax;

    let sent = 0;
    let failed = 0;
    for (const job of jobs) {
      try {
        await processJob(supabase, job, oneSignalAppId, oneSignalApiKey);
        sent += 1;
      } catch (error) {
        failed += 1;
        console.error('[processar-notificacoes-fila] job', job.id, error);
        await markRetryOrFail(supabase, job, error instanceof Error ? error.message : 'erro_envio', maxPush);
      }
    }

    return json({ ok: true, processed: jobs.length, sent, failed });
  } catch (error) {
    console.error('[processar-notificacoes-fila]', error);
    const status = error instanceof HttpError ? error.status : 500;
    return json({ error: error instanceof Error ? error.message : 'Erro inesperado.' }, status);
  }
});

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

class HttpError extends Error {
  constructor(message: string, public status = 400) {
    super(message);
  }
}

function requiredEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Secret ${name} nao configurado.`);
  return value;
}

function authorizeWorker(req: Request) {
  const secret = Deno.env.get('PUSH_WORKER_SECRET')
    ?? Deno.env.get('FCM_WORKER_SECRET')
    ?? '';
  if (!secret) throw new HttpError('PUSH_WORKER_SECRET nao configurado.', 503);
  const header = req.headers.get('x-worker-secret')
    || req.headers.get('Authorization')?.replace(/^Bearer\s+/i, '')
    || '';
  if (header !== secret) throw new HttpError('Nao autorizado.', 401);
}

async function processJob(
  supabase: ReturnType<typeof createClient>,
  job: Record<string, unknown>,
  appId: string,
  apiKey: string,
) {
  const usuarioId = String(job.usuario_id);
  const titulo = String(job.titulo ?? '');
  const corpo = String(job.corpo ?? '');
  const highPriority = HIGH_PRIORITY_EVENTS.has(String(job.evento));
  const dados = normalizeData(job.dados);
  const canal = mapAndroidChannel(
    dados.canal_android,
    highPriority ? 'padoca_entregas_urgente' : 'padoca_geral',
  );

  const payload: Record<string, unknown> = {
    app_id: appId,
    target_channel: 'push',
    include_aliases: { external_id: [usuarioId] },
    headings: { en: titulo, pt: titulo },
    contents: { en: corpo, pt: corpo },
    data: dados,
    priority: highPriority ? 10 : 5,
    existing_android_channel_id: canal,
  };

  if (dados.som && dados.som !== 'default') {
    const som = dados.som.replace(/\.wav$/i, '');
    payload.android_sound = som;
    payload.ios_sound = som;
  }

  let response = await sendOneSignal(apiKey, payload);
  let body = await response.json().catch(() => ({}));

  if (!response.ok && isEmptyRecipients(body)) {
    const { data: devices } = await supabase
      .from('dispositivos_push')
      .select('id, token')
      .eq('usuario_id', usuarioId)
      .eq('ativo', true)
      .eq('invalido', false);

    const subscriptionIds = (devices ?? [])
      .map((d) => String(d.token))
      .filter((id) => id.length > 0);

    if (subscriptionIds.length === 0) {
      await archiveJob(supabase, job, 'sem_dispositivo', { motivo: 'nenhuma subscription ativa' });
      return;
    }

    const fallbackPayload = { ...payload };
    delete fallbackPayload.include_aliases;
    fallbackPayload.include_subscription_ids = subscriptionIds.slice(0, 2000);

    response = await sendOneSignal(apiKey, fallbackPayload);
    body = await response.json().catch(() => ({}));
  }

  if (!response.ok) {
    if (isInvalidSubscription(body)) {
      await markDevicesInvalid(supabase, usuarioId, String((body as { errors?: unknown[] }).errors?.[0] ?? 'invalid'));
    }
    const erro = String((body as { errors?: unknown[] }).errors?.[0] ?? JSON.stringify(body));
    throw new HttpError(`OneSignal recusou: ${erro}`, response.status);
  }

  await supabase.from('dispositivos_push').update({
    ultimo_uso_em: new Date().toISOString(),
  }).eq('usuario_id', usuarioId).eq('ativo', true);

  await archiveJob(supabase, job, 'enviado', {
    onesignal: body,
    notification_id: (body as { id?: string }).id ?? null,
  });
}

async function sendOneSignal(apiKey: string, payload: Record<string, unknown>) {
  return fetch('https://api.onesignal.com/notifications', {
    method: 'POST',
    headers: {
      Authorization: `Key ${apiKey}`,
      'Content-Type': 'application/json; charset=utf-8',
    },
    body: JSON.stringify(payload),
  });
}

function mapAndroidChannel(canal: string | undefined, fallback: string): string {
  switch (canal) {
    case 'pedidos':
      return 'padoca_pedidos';
    case 'entregas':
      return 'padoca_entregas_urgente';
    case 'geral':
    case 'promocoes':
    case 'financeiro':
    case 'sistema':
      return 'padoca_geral';
    default:
      return canal && canal.length > 0 ? canal : fallback;
  }
}

function isEmptyRecipients(body: unknown): boolean {
  const errors = (body as { errors?: string[] })?.errors ?? [];
  return errors.some((e) => /external_id|subscription|recipient|All included players are not subscribed/i.test(String(e)));
}

function isInvalidSubscription(body: unknown): boolean {
  const errors = (body as { errors?: string[] })?.errors ?? [];
  return errors.some((e) => /not subscribed|invalid|unsubscribed|Player/i.test(String(e)));
}

async function markDevicesInvalid(
  supabase: ReturnType<typeof createClient>,
  usuarioId: string,
  motivo: string,
) {
  await supabase.from('dispositivos_push').update({
    ativo: false,
    invalido: true,
    invalido_em: new Date().toISOString(),
    motivo_invalido: motivo.slice(0, 200),
  }).eq('usuario_id', usuarioId).eq('ativo', true);
}

function normalizeData(value: unknown): Record<string, string> {
  const source = value && typeof value === 'object' ? value as Record<string, unknown> : {};
  return Object.fromEntries(
    Object.entries(source).map(([key, item]) => [
      key,
      typeof item === 'string' ? item : JSON.stringify(item),
    ]),
  );
}

async function archiveJob(
  supabase: ReturnType<typeof createClient>,
  job: Record<string, unknown>,
  status: string,
  response: unknown,
) {
  const now = new Date().toISOString();
  await supabase.from('notificacoes_historico').insert({
    usuario_id: job.usuario_id,
    dispositivo_id: job.dispositivo_id,
    evento: job.evento,
    titulo: job.titulo,
    corpo: job.corpo,
    dados: job.dados,
    entidade_tipo: job.entidade_tipo,
    entidade_id: job.entidade_id,
    status,
    tentativas: job.tentativas,
    max_tentativas: job.max_tentativas,
    provedor_response: response,
    created_at: job.created_at,
    processado_em: now,
    enviado_em: status === 'enviado' ? now : null,
    falhou_em: status === 'enviado' ? null : now,
  });
  await supabase.from('notificacoes_fila').delete().eq('id', job.id);
}

async function markRetryOrFail(
  supabase: ReturnType<typeof createClient>,
  job: Record<string, unknown>,
  erro: string,
  maxPushFallback = 3,
) {
  const tentativas = Number(job.tentativas ?? 1);
  const max = Number(job.max_tentativas ?? maxPushFallback) || maxPushFallback;
  if (tentativas >= max) {
    await archiveJob(supabase, job, 'falhou', { erro });
    return;
  }
  const delayMin = Math.min(15, 2 ** tentativas);
  await supabase.from('notificacoes_fila').update({
    status: 'pendente',
    erro_codigo: 'retry',
    erro_detalhe: erro.slice(0, 500),
    proxima_tentativa_em: new Date(Date.now() + delayMin * 60_000).toISOString(),
  }).eq('id', job.id);
}
