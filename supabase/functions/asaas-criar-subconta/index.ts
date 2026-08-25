import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';
import { loadAsaasCredentials, requiredEnv } from '../_shared/asaas_client.ts';

type EntityType = 'estabelecimento' | 'entregador';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'Metodo nao permitido.' }, 405);

  try {
    const supabase = createClient(requiredEnv('SUPABASE_URL'), requiredEnv('SUPABASE_SERVICE_ROLE_KEY'), {
      auth: { persistSession: false },
    });
    const { baseUrl: asaasBaseUrl, apiKey: asaasApiKey } = loadAsaasCredentials();

    const user = await authenticatedUser(req, supabase);
    const body = await req.json().catch(() => ({}));
    const entityType = body.entidade_tipo as EntityType | undefined;
    const entityId = body.entidade_id as string | undefined;

    if (!entityType || !['estabelecimento', 'entregador'].includes(entityType)) {
      return json({ error: 'entidade_tipo invalido.' }, 400);
    }
    if (!entityId) return json({ error: 'entidade_id obrigatorio.' }, 400);

    const { data: existing, error: existingError } = await supabase
      .from('asaas_subcontas')
      .select('asaas_account_id, asaas_wallet_id, status_conta, onboarding_url')
      .eq('entidade_tipo', entityType)
      .eq('entidade_id', entityId)
      .maybeSingle();
    if (existingError) throw existingError;
    if (existing) {
      return json({
        alreadyExists: true,
        status: existing.status_conta,
        asaas_account_id: existing.asaas_account_id,
        asaas_wallet_id: existing.asaas_wallet_id,
        onboarding_url: existing.onboarding_url,
        mensagem: 'Conta de recebimento criada. Conclua a validacao no Asaas para receber e movimentar seus valores.',
      });
    }

    const loaded = await loadEntity(supabase, entityType, entityId);
    await assertPermission(supabase, user.id, loaded.entity, entityType, entityId);

    const accountPayload = buildAsaasAccountPayload(entityType, loaded.entity, loaded.user, loaded.enderecoNormalizado);
    validateAccountPayload(accountPayload);

    // Log do payload enviado ao Asaas (sem cpfCnpj completo por segurança)
    const payloadLog = { ...accountPayload, cpfCnpj: accountPayload.cpfCnpj ? `***${String(accountPayload.cpfCnpj).slice(-3)}` : undefined };
    console.log('[asaas-criar-subconta] payload enviado:', JSON.stringify(payloadLog));

    const asaasResponse = await fetch(`${asaasBaseUrl}/accounts`, {
      method: 'POST',
      headers: {
        access_token: asaasApiKey,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(accountPayload),
    });

    const asaasData = await asaasResponse.json().catch(() => ({}));
    if (!asaasResponse.ok) {
      console.error('[asaas-criar-subconta] rejeitado pelo Asaas:', JSON.stringify(asaasData));
      return json({ error: 'Asaas recusou a criacao da subconta.', details: asaasData }, 502);
    }

    const accountId = text(asaasData.id);
    const walletId = text(asaasData.walletId);
    const apiKey = text(asaasData.apiKey);
    if (!accountId || !walletId || !apiKey) {
      return json({ error: 'Resposta incompleta do Asaas.', details: sanitizeAsaasResponse(asaasData) }, 502);
    }

    const subcontaRow = {
      entidade_tipo: entityType,
      entidade_id: entityId,
      asaas_account_id: accountId,
      asaas_wallet_id: walletId,
      asaas_api_key: apiKey,
      status_conta: 'pending',
      dados_comerciais: accountPayload,
      onboarding_url: text(asaasData.onboardingUrl) || null,
      metadata: { asaas_response: sanitizeAsaasResponse(asaasData) },
      ultima_sincronizacao: new Date().toISOString(),
    };

    const { error: upsertError } = await supabase
      .from('asaas_subcontas')
      .upsert(subcontaRow, { onConflict: 'entidade_tipo,entidade_id' });
    if (upsertError) throw upsertError;

    const table = entityType === 'estabelecimento' ? 'estabelecimentos' : 'entregadores';
    const { error: updateError } = await supabase
      .from(table)
      .update({ asaas_account_id: accountId, asaas_wallet_id: walletId })
      .eq('id', entityId);
    if (updateError) throw updateError;

    return json({
      status: 'pending',
      asaas_account_id: accountId,
      asaas_wallet_id: walletId,
      onboarding_url: subcontaRow.onboarding_url,
      mensagem: 'Conta de recebimento criada. Conclua a validacao no Asaas para receber e movimentar seus valores.',
    });
  } catch (error) {
    console.error('[asaas-criar-subconta]', error);
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

async function authenticatedUser(req: Request, supabase: ReturnType<typeof createClient>) {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) throw new HttpError('Sessao obrigatoria.', 401);
  const token = authHeader.replace('Bearer ', '');
  const { data: { user }, error } = await supabase.auth.getUser(token);
  if (error || !user) throw new HttpError('Sessao invalida.', 401);
  return user;
}

class HttpError extends Error {
  constructor(message: string, public status = 400) {
    super(message);
  }
}

async function loadEntity(supabase: ReturnType<typeof createClient>, entityType: EntityType, entityId: string) {
  const table = entityType === 'estabelecimento' ? 'estabelecimentos' : 'entregadores';
  const { data: entity, error: entityError } = await supabase.from(table).select('*').eq('id', entityId).single();
  if (entityError || !entity) throw new Error('Entidade nao encontrada.');

  const { data: user, error: userError } = await supabase
    .from('usuarios')
    .select('id, email, telefone, nome_completo_fantasia, tipo_usuario')
    .eq('id', entity.usuario_id)
    .single();
  if (userError || !user) throw new Error('Usuario da entidade nao encontrado.');

  // Para entregadores, busca o endereço na tabela dedicada (fonte primária).
  // O campo legado entity.endereco é usado apenas como fallback.
  let enderecoNormalizado: Record<string, unknown> | null = null;
  if (entityType === 'entregador') {
    const { data: enderecoRow } = await supabase
      .from('entregador_enderecos')
      .select('logradouro, numero, complemento, bairro, cidade, estado, cep')
      .eq('entregador_id', entityId)
      .eq('is_principal', true)
      .maybeSingle();
    if (enderecoRow) {
      enderecoNormalizado = enderecoRow as Record<string, unknown>;
    }
  }

  return { entity, user, enderecoNormalizado };
}

async function assertPermission(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  entity: Record<string, unknown>,
  entityType: EntityType,
  entityId: string,
) {
  const { data: caller } = await supabase.from('usuarios').select('tipo_usuario').eq('id', userId).maybeSingle();
  if (caller?.tipo_usuario === 'admin' || entity.usuario_id === userId) return;

  if (entityType === 'estabelecimento') {
    const { data: admin } = await supabase
      .from('administradores_estabelecimento')
      .select('id')
      .eq('usuario_id', userId)
      .eq('estabelecimento_id', entityId)
      .eq('ativo', true)
      .maybeSingle();
    if (admin) return;
  }

  throw new HttpError('Usuario sem permissao para criar esta subconta.', 403);
}

function buildAsaasAccountPayload(
  entityType: EntityType,
  entity: Record<string, unknown>,
  user: Record<string, unknown>,
  enderecoNormalizado: Record<string, unknown> | null = null,
) {
  const fallbackIncome = Number(Deno.env.get('ASAAS_DEFAULT_INCOME_VALUE') ?? '2500');
  const defaultAddress = {
    address: Deno.env.get('ASAAS_DEFAULT_ADDRESS') ?? '',
    addressNumber: Deno.env.get('ASAAS_DEFAULT_ADDRESS_NUMBER') ?? '',
    province: Deno.env.get('ASAAS_DEFAULT_PROVINCE') ?? '',
    postalCode: onlyDigits(Deno.env.get('ASAAS_DEFAULT_POSTAL_CODE') ?? ''),
  };

  if (entityType === 'entregador') {
    // Prioridade: tabela entregador_enderecos > campo JSONB legado entity.endereco > env fallback.
    const endTbl = enderecoNormalizado ?? {};
    const endJson = (entity.endereco ?? {}) as Record<string, unknown>;
    return removeEmpty({
      name: text(user.nome_completo_fantasia) || 'Entregador Opadoca',
      email: text(user.email),
      loginEmail: text(user.email),
      cpfCnpj: onlyDigits(text(entity.cpf)),
      birthDate: toIsoDate(text(entity.data_nascimento)),
      mobilePhone: onlyDigits(text(user.telefone)),
      incomeValue: fallbackIncome,
      address: text(endTbl.logradouro) || text(endJson.logradouro) || text(entity.logradouro) || defaultAddress.address,
      addressNumber: text(endTbl.numero) || text(endJson.numero) || text(entity.numero) || defaultAddress.addressNumber,
      complement: text(endTbl.complemento) || text(endJson.complemento) || text(entity.complemento),
      province: text(endTbl.bairro) || text(endJson.bairro) || text(entity.bairro) || defaultAddress.province,
      postalCode: onlyDigits(text(endTbl.cep) || text(endJson.cep) || text(entity.cep)) || defaultAddress.postalCode,
    });
  }

  const endereco = (entity.endereco ?? {}) as Record<string, unknown>;
  const document = onlyDigits(text(entity.cnpj) || text(entity.responsavel_cpf));
  return removeEmpty({
    name: text(entity.razao_social) || text(entity.nome_fantasia) || text(user.nome_completo_fantasia) || 'Estabelecimento Opadoca',
    email: text(entity.email_comercial) || text(user.email),
    loginEmail: text(entity.email_comercial) || text(user.email),
    cpfCnpj: document,
    companyType: document.length === 14 ? 'MEI' : undefined,
    phone: onlyDigits(text(entity.telefone_comercial) || text(user.telefone)),
    mobilePhone: onlyDigits(text(entity.whatsapp) || text(user.telefone)),
    incomeValue: fallbackIncome,
    address: text(endereco.logradouro) || text(entity.logradouro) || defaultAddress.address,
    addressNumber: text(endereco.numero) || text(entity.numero) || defaultAddress.addressNumber,
    complement: text(endereco.complemento) || text(entity.complemento),
    province: text(endereco.bairro) || text(entity.bairro) || defaultAddress.province,
    postalCode: onlyDigits(text(endereco.cep) || text(entity.cep)) || defaultAddress.postalCode,
  });
}

function validateAccountPayload(payload: Record<string, unknown>) {
  for (const field of ['name', 'email', 'cpfCnpj', 'mobilePhone', 'incomeValue', 'address', 'addressNumber', 'province', 'postalCode']) {
    if (!payload[field]) {
      throw new HttpError(`Dados insuficientes para criar subconta Asaas: ${field}.`, 400);
    }
  }
}

function text(value: unknown): string {
  return typeof value === 'string' ? value.trim() : '';
}

function onlyDigits(value: string): string {
  return value.replace(/\D/g, '');
}

function toIsoDate(value: string): string | undefined {
  if (!value) return undefined;
  if (/^\d{4}-\d{2}-\d{2}/.test(value)) return value.slice(0, 10);
  const match = value.match(/^(\d{2})\/(\d{2})\/(\d{4})$/);
  return match ? `${match[3]}-${match[2]}-${match[1]}` : undefined;
}

function removeEmpty(payload: Record<string, unknown>) {
  return Object.fromEntries(Object.entries(payload).filter(([, value]) => value !== undefined && value !== null && value !== ''));
}

function sanitizeAsaasResponse(data: Record<string, unknown>) {
  const copy = { ...data };
  delete copy.apiKey;
  return copy;
}
