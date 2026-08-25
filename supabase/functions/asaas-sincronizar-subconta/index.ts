import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';
import { approveSandboxAccount, asaasHeaders, loadAsaasCredentials } from '../_shared/asaas_client.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

// Mapeamento dos status do Asaas para o status interno do sistema
// Ref: https://docs.asaas.com/reference/subconta
const ASAAS_STATUS_MAP: Record<string, string> = {
  ACTIVE: 'active',
  PENDING: 'pending',
  INACTIVE: 'blocked',
  DECLINED: 'rejected',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'Metodo nao permitido.' }, 405);

  try {
    const supabase = createClient(requiredEnv('SUPABASE_URL'), requiredEnv('SUPABASE_SERVICE_ROLE_KEY'), {
      auth: { persistSession: false },
    });
    const { baseUrl: asaasBaseUrl, isSandbox } = loadAsaasCredentials();

    const user = await authenticatedUser(req, supabase);

    const body = await req.json().catch(() => ({}));
    const entidadeTipo = text(body.entidade_tipo);
    const entidadeId = text(body.entidade_id);
    const accountIdInput = text(body.asaas_account_id);

    // Localiza a subconta no banco
    let subcontaQuery;
    if (accountIdInput) {
      subcontaQuery = supabase.from('asaas_subcontas').select('*').eq('asaas_account_id', accountIdInput).maybeSingle();
    } else if (entidadeTipo && entidadeId) {
      subcontaQuery = supabase.from('asaas_subcontas').select('*').eq('entidade_tipo', entidadeTipo).eq('entidade_id', entidadeId).maybeSingle();
    } else {
      return json({ error: 'Informe asaas_account_id ou entidade_tipo + entidade_id.' }, 400);
    }

    const { data: subconta, error: subcontaError } = await subcontaQuery;
    if (subcontaError) throw subcontaError;
    if (!subconta) return json({ error: 'Subconta nao encontrada.' }, 404);

    await assertPermission(supabase, user.id, subconta.entidade_tipo, subconta.entidade_id);

    // Usa a apiKey da PRÓPRIA subconta para buscar os dados dela no Asaas.
    // A master key só consegue ver a conta master. Para subcontas, usa a chave delas.
    const subcontaApiKey = text(subconta.asaas_api_key);
    if (!subcontaApiKey) {
      return json({ error: 'api_key da subconta nao encontrada. Recrie a subconta.' }, 422);
    }

    const asaasRespStatus = await fetch(`${asaasBaseUrl}/myAccount/status`, {
      headers: asaasHeaders(subcontaApiKey, false),
    });
    let statusData = await asaasRespStatus.json().catch(() => ({}));

    if (isSandbox && text(statusData.general).toUpperCase() !== 'APPROVED') {
      await approveSandboxAccount(asaasBaseUrl, subcontaApiKey);
      const refreshed = await fetch(`${asaasBaseUrl}/myAccount/status`, {
        headers: asaasHeaders(subcontaApiKey, false),
      });
      statusData = await refreshed.json().catch(() => statusData);
    }

    const asaasResp = await fetch(`${asaasBaseUrl}/myAccount`, {
      headers: asaasHeaders(subcontaApiKey, false),
    });
    const accountData = await asaasResp.json().catch(() => ({}));

    if (!asaasResp.ok) {
      console.error('[asaas-sincronizar-subconta] erro ao consultar myAccount:', JSON.stringify(accountData));
      return json({ error: 'Asaas recusou a consulta da subconta.', details: accountData }, 502);
    }

    console.log('[asaas-sincronizar-subconta] accountData:', JSON.stringify(sanitizeAccount(accountData)));

    // Mapeia o status do Asaas → status interno
    const asaasAccountStatus = text(accountData.accountStatus ?? accountData.status ?? '').toUpperCase();
    const statusInterno = ASAAS_STATUS_MAP[asaasAccountStatus] ?? subconta.status_conta ?? 'pending';

    // KYC: usa o campo commercialInfo do Asaas
    const kycStatus = inferKycStatus(accountData, statusInterno);

    const update = {
      status_conta: statusInterno,
      kyc_status: kycStatus,
      documentos_enviados: kycStatus !== 'pendente',
      homologada: statusInterno === 'active',
      motivo_rejeicao: statusInterno === 'rejected'
        ? (text(accountData.observations) || text(accountData.tradingName) || null)
        : null,
      ultima_sincronizacao: new Date().toISOString(),
      metadata: {
        ...(subconta.metadata ?? {}),
        asaas_account: sanitizeAccount(accountData),
        ultima_sinc_status: asaasAccountStatus,
      },
    };

    const { error: updateError } = await supabase
      .from('asaas_subcontas')
      .update(update)
      .eq('id', subconta.id);
    if (updateError) throw updateError;

    // Atualiza também a tabela da entidade
    const entityTable = subconta.entidade_tipo === 'estabelecimento' ? 'estabelecimentos' : 'entregadores';
    const entityUpdate: Record<string, unknown> = {
      asaas_wallet_id: text(accountData.walletId) || subconta.asaas_wallet_id,
      asaas_account_id: subconta.asaas_account_id,
    };
    // Só promove para 'aprovado' no sistema se o Asaas confirmou a conta como active
    if (statusInterno === 'active') entityUpdate.status_cadastro = 'aprovado';

    await supabase.from(entityTable).update(entityUpdate).eq('id', subconta.entidade_id);

    let enderecoPersistido: Record<string, string> | null = null;
    if (subconta.entidade_tipo === 'entregador') {
      enderecoPersistido = await persistirEnderecoEntregador(
        supabase,
        subconta.entidade_id,
        accountData,
      );
    }

    return json({
      status: statusInterno,
      kyc_status: kycStatus,
      documentos_enviados: update.documentos_enviados,
      homologada: update.homologada,
      asaas_account_id: subconta.asaas_account_id,
      asaas_wallet_id: entityUpdate.asaas_wallet_id,
      endereco: enderecoPersistido,
      mensagem: statusMessage(statusInterno),
    });
  } catch (error) {
    console.error('[asaas-sincronizar-subconta]', error);
    return json(
      { error: error instanceof Error ? error.message : 'Erro inesperado.' },
      error instanceof HttpError ? error.status : 500,
    );
  }
});

// ─── Helpers ────────────────────────────────────────────────────────────────

function inferKycStatus(account: Record<string, unknown>, statusInterno: string): string {
  if (statusInterno === 'active') return 'aprovado';
  if (statusInterno === 'rejected') return 'reprovado';
  // Asaas retorna commercialInfoExpiration quando a conta está em análise
  const commercial = account.commercialInfoExpiration as Record<string, unknown> | undefined;
  if (commercial?.isExpired === true) return 'reprovado';
  if (account.walletId) return 'em_analise';
  return 'pendente';
}

function statusMessage(status: string): string {
  const msgs: Record<string, string> = {
    active: 'Conta Asaas ativa para recebimentos.',
    pending: 'Sua conta Asaas esta em analise.',
    blocked: 'Conta bloqueada. Entre em contato com o suporte Asaas.',
    rejected: 'Conta reprovada pelo Asaas. Verifique os dados cadastrados.',
  };
  return msgs[status] ?? 'Status desconhecido.';
}

async function authenticatedUser(req: Request, supabase: ReturnType<typeof createClient>) {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) throw new HttpError('Sessao obrigatoria.', 401);
  const { data: { user }, error } = await supabase.auth.getUser(authHeader.replace('Bearer ', ''));
  if (error || !user) throw new HttpError('Sessao invalida.', 401);
  return user;
}

async function assertPermission(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  tipo: string,
  entidadeId: string,
) {
  const { data: caller } = await supabase.from('usuarios').select('tipo_usuario').eq('id', userId).maybeSingle();
  if (caller?.tipo_usuario === 'admin') return;

  const table = tipo === 'estabelecimento' ? 'estabelecimentos' : 'entregadores';
  const { data } = await supabase.from(table).select('usuario_id').eq('id', entidadeId).maybeSingle();
  if (data?.usuario_id === userId) return;

  throw new HttpError('Usuario sem permissao para sincronizar esta subconta.', 403);
}

function sanitizeAccount(data: Record<string, unknown>) {
  const copy = { ...data };
  delete copy.apiKey;
  delete copy.accessToken;
  return copy;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function onlyDigits(value: string): string {
  return value.replace(/\D/g, '');
}

async function persistirEnderecoEntregador(
  supabase: ReturnType<typeof createClient>,
  entregadorId: string,
  account: Record<string, unknown>,
): Promise<Record<string, string> | null> {
  const cep = onlyDigits(text(account.postalCode));
  const logradouro = text(account.address);
  const numero = text(account.addressNumber);
  const complemento = text(account.complement);
  const bairro = text(account.province);
  const estado = text(account.state).toUpperCase().slice(0, 2);
  if (cep.length !== 8 || !logradouro || !numero || !bairro || estado.length !== 2) {
    return null;
  }

  let cidade = '';
  try {
    const cepRes = await fetch(`https://brasilapi.com.br/api/cep/v1/${cep}`, {
      headers: {
        Accept: 'application/json',
        'User-Agent': 'OpadocaExpress/1.0',
      },
    });
    if (cepRes.ok) {
      const cepData = await cepRes.json().catch(() => ({}));
      cidade = text(cepData.city);
    }
  } catch (error) {
    console.error('[asaas-sincronizar-subconta] cep lookup', error);
  }
  if (!cidade) return {
    cep, logradouro, numero, complemento, bairro, estado, cidade: '',
  };

  const endereco = {
    cep,
    logradouro,
    numero,
    complemento: complemento || null,
    bairro,
    cidade,
    estado,
  };

  await supabase.from('entregador_enderecos').upsert({
    entregador_id: entregadorId,
    ...endereco,
    is_principal: true,
  }, { onConflict: 'entregador_id' });

  await supabase.from('entregadores').update({
    endereco: {
      cep,
      logradouro,
      numero,
      ...(complemento ? { complemento } : {}),
      bairro,
      cidade,
      estado,
    },
  }).eq('id', entregadorId);

  return { cep, logradouro, numero, complemento, bairro, cidade, estado };
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

function text(value: unknown): string {
  return typeof value === 'string' ? value.trim() : '';
}
