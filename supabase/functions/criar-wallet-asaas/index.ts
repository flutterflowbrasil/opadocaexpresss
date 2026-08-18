import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

type EntityType = 'estabelecimento' | 'entregador';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return json({ error: 'Metodo nao permitido.' }, 405);
  }

  return json({
    error: 'criar-wallet-asaas foi descontinuada. Use asaas-criar-subconta.',
  }, 410);

  try {
    const supabaseUrl = requiredEnv('SUPABASE_URL');
    const serviceRoleKey = requiredEnv('SUPABASE_SERVICE_ROLE_KEY');
    const asaasApiKey = requiredEnv('ASAAS_API_KEY');
    const asaasBaseUrl = Deno.env.get('ASAAS_BASE_URL') ??
      'https://api-sandbox.asaas.com/v3';

    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return json({ error: 'Sessao obrigatoria.' }, 401);
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });

    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser(authHeader.replace('Bearer ', ''));

    if (userError || !user) {
      return json({ error: 'Sessao invalida.' }, 401);
    }

    const { data: caller, error: callerError } = await supabase
      .from('usuarios')
      .select('tipo_usuario')
      .eq('id', user.id)
      .single();

    if (callerError || caller?.tipo_usuario !== 'admin') {
      return json({ error: 'Apenas administradores podem criar subconta Asaas.' }, 403);
    }

    const payload = await req.json();
    const entityType = payload.entidade_tipo as EntityType | undefined;
    const entityId = payload.entidade_id as string | undefined;

    if (!entityType || !['estabelecimento', 'entregador'].includes(entityType)) {
      return json({ error: 'entidade_tipo invalido.' }, 400);
    }

    if (!entityId) {
      return json({ error: 'entidade_id obrigatorio.' }, 400);
    }

    const { data: existing, error: existingError } = await supabase
      .from('asaas_subcontas')
      .select('asaas_account_id, asaas_wallet_id, status_conta')
      .eq('entidade_tipo', entityType)
      .eq('entidade_id', entityId)
      .maybeSingle();

    if (existingError) {
      throw existingError;
    }

    if (existing) {
      return json({
        alreadyExists: true,
        accountId: existing.asaas_account_id,
        walletId: existing.asaas_wallet_id,
        status: existing.status_conta,
      });
    }

    const entity = await loadEntity(supabase, entityType, entityId);
    const accountPayload = buildAsaasAccountPayload(entityType, entity.entity, entity.user);

    const asaasResponse = await fetch(`${asaasBaseUrl.replace(/\/$/, '')}/accounts`, {
      method: 'POST',
      headers: {
        access_token: asaasApiKey,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(accountPayload),
    });

    const asaasData = await asaasResponse.json().catch(() => ({}));

    if (!asaasResponse.ok) {
      return json({
        error: 'Asaas recusou a criacao da subconta.',
        details: asaasData,
      }, 502);
    }

    const accountId = asaasData.id;
    const walletId = asaasData.walletId;
    const apiKey = asaasData.apiKey;

    if (!accountId || !walletId || !apiKey) {
      return json({
        error: 'Resposta incompleta do Asaas.',
        details: asaasData,
      }, 502);
    }

    const { error: insertError } = await supabase.from('asaas_subcontas').insert({
      entidade_tipo: entityType,
      entidade_id: entityId,
      asaas_account_id: accountId,
      asaas_wallet_id: walletId,
      asaas_api_key: apiKey,
      status_conta: 'pending',
      dados_comerciais: accountPayload,
      metadata: { asaas_response: sanitizeAsaasResponse(asaasData) },
      ultima_sincronizacao: new Date().toISOString(),
    });

    if (insertError) {
      throw insertError;
    }

    const table = entityType === 'estabelecimento'
      ? 'estabelecimentos'
      : 'entregadores';

    const { error: updateError } = await supabase.from(table).update({
      asaas_account_id: accountId,
      asaas_wallet_id: walletId,
    }).eq('id', entityId);

    if (updateError) {
      throw updateError;
    }

    return json({
      accountId,
      walletId,
      status: 'pending',
    });
  } catch (error) {
    console.error('[criar-wallet-asaas]', error);
    return json({
      error: error instanceof Error ? error.message : 'Erro inesperado.',
    }, 500);
  }
});

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}

function requiredEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) {
    throw new Error(`Secret ${name} nao configurado.`);
  }
  return value;
}

async function loadEntity(
  supabase: ReturnType<typeof createClient>,
  entityType: EntityType,
  entityId: string,
) {
  const table = entityType === 'estabelecimento'
    ? 'estabelecimentos'
    : 'entregadores';

  const { data: entity, error: entityError } = await supabase
    .from(table)
    .select('*')
    .eq('id', entityId)
    .single();

  if (entityError || !entity) {
    throw new Error('Entidade nao encontrada.');
  }

  const { data: user, error: userError } = await supabase
    .from('usuarios')
    .select('id, email, telefone, nome_completo_fantasia')
    .eq('id', entity.usuario_id)
    .single();

  if (userError || !user) {
    throw new Error('Usuario da entidade nao encontrado.');
  }

  return { entity, user };
}

function buildAsaasAccountPayload(
  entityType: EntityType,
  entity: Record<string, unknown>,
  user: Record<string, unknown>,
) {
  if (entityType === 'entregador') {
    return removeEmpty({
      name: text(user.nome_completo_fantasia) || 'Entregador Padoca Express',
      email: text(user.email),
      cpfCnpj: onlyDigits(text(entity.cpf)),
      birthDate: toIsoDate(text(entity.data_nascimento)),
      companyType: 'INDIVIDUAL',
      phone: onlyDigits(text(user.telefone)),
      mobilePhone: onlyDigits(text(user.telefone)),
    });
  }

  const endereco = (entity.endereco ?? {}) as Record<string, unknown>;
  return removeEmpty({
    name: text(entity.razao_social) ||
      text(entity.nome_fantasia) ||
      text(user.nome_completo_fantasia) ||
      'Estabelecimento Padoca Express',
    email: text(entity.email_comercial) || text(user.email),
    cpfCnpj: onlyDigits(text(entity.cnpj) || text(entity.responsavel_cpf)),
    birthDate: undefined,
    companyType: text(entity.cnpj) ? 'MEI' : 'INDIVIDUAL',
    phone: onlyDigits(text(entity.telefone_comercial) || text(user.telefone)),
    mobilePhone: onlyDigits(text(entity.whatsapp) || text(user.telefone)),
    address: text(endereco.logradouro) || text(entity.logradouro),
    addressNumber: text(endereco.numero) || text(entity.numero),
    complement: text(endereco.complemento) || text(entity.complemento),
    province: text(endereco.bairro) || text(entity.bairro),
    postalCode: onlyDigits(text(endereco.cep) || text(entity.cep)),
  });
}

function text(value: unknown): string {
  return typeof value === 'string' ? value.trim() : '';
}

function onlyDigits(value: string): string {
  return value.replace(/\D/g, '');
}

function toIsoDate(value: string): string | undefined {
  if (!value) return undefined;
  if (/^\d{4}-\d{2}-\d{2}/.test(value)) {
    return value.slice(0, 10);
  }
  const match = value.match(/^(\d{2})\/(\d{2})\/(\d{4})$/);
  if (!match) return undefined;
  return `${match[3]}-${match[2]}-${match[1]}`;
}

function removeEmpty(payload: Record<string, unknown>) {
  return Object.fromEntries(
    Object.entries(payload).filter(([, value]) => {
      return value !== undefined && value !== null && value !== '';
    }),
  );
}

function sanitizeAsaasResponse(data: Record<string, unknown>) {
  const copy = { ...data };
  delete copy.apiKey;
  return copy;
}
