import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

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
    const asaasBaseUrl = (Deno.env.get('ASAAS_BASE_URL') ?? 'https://api-sandbox.asaas.com/v3').replace(/\/$/, '');
    const asaasApiKey = requiredEnv('ASAAS_API_KEY');

    const user = await authenticatedUser(req, supabase);
    const body = await req.json().catch(() => ({}));
    const pedidoId = text(body.pedido_id);
    const metodoPagamento = text(body.metodo_pagamento) || undefined;
    const cartao = body.cartao as Record<string, unknown> | undefined;
    if (!pedidoId) return json({ error: 'pedido_id obrigatorio.' }, 400);

    const { data: pedido, error: pedidoError } = await supabase
      .from('pedidos')
      .select('*, clientes(*, usuarios(*)), estabelecimentos(*), entregadores(*)')
      .eq('id', pedidoId)
      .single();
    if (pedidoError || !pedido) throw new Error('Pedido nao encontrado.');

    const pedidoCliente = firstRelation(pedido.clientes);
    const clienteUsuarioId = firstRelation(pedidoCliente?.usuarios)?.id;
    if (clienteUsuarioId !== user.id) {
      return json({ error: 'Pedido nao pertence ao cliente autenticado.' }, 403);
    }

    if (pedido.asaas_payment_id) {
      const pix = pedido.pagamento_metodo === 'pix'
        ? await getPixQrCode(asaasBaseUrl, asaasApiKey, pedido.asaas_payment_id)
        : null;
      return json({
        paymentId: pedido.asaas_payment_id,
        invoiceUrl: pedido.asaas_invoice_url,
        pixQrCode: pix?.encodedImage,
        pixCopiaECola: pix?.payload,
        status: pedido.pagamento_status,
      });
    }

    const metodo = normalizeMetodo(metodoPagamento ?? pedido.pagamento_metodo);
    if (metodo === 'cartao_debito') {
      return json({ error: 'Cartao de debito ainda nao esta habilitado no contrato Asaas deste fluxo.' }, 400);
    }

    const estabelecimento = firstRelation(pedido.estabelecimentos);
    const entregador = firstRelation(pedido.entregadores);
    const cliente = pedidoCliente;
    const clienteUsuario = firstRelation(cliente.usuarios);
    if (!estabelecimento) throw new Error('Estabelecimento do pedido nao encontrado.');
    if (!cliente) throw new Error('Cliente do pedido nao encontrado.');

    const estabelecimentoSubconta = await activeSubaccount(supabase, 'estabelecimento', pedido.estabelecimento_id);
    if (!estabelecimentoSubconta?.asaas_wallet_id) {
      return json({ error: 'Estabelecimento ainda nao possui conta Asaas ativa para recebimento.' }, 409);
    }

    const entregadorSubconta = pedido.entregador_id
      ? await activeSubaccount(supabase, 'entregador', pedido.entregador_id)
      : null;

    const customerId = await ensureCustomer(
      asaasBaseUrl,
      asaasApiKey,
      supabase,
      cliente,
      clienteUsuario,
      pedido,
      cartao,
    );
    const financeiro = await calcularFinanceiro(supabase, pedido);
    const split = buildSplit({
      pedido,
      financeiro,
      estabelecimentoWalletId: estabelecimentoSubconta.asaas_wallet_id,
      entregadorWalletId: entregadorSubconta?.asaas_wallet_id,
    });

    const paymentPayload: Record<string, unknown> = {
      customer: customerId,
      billingType: billingTypeFor(metodo),
      value: financeiro.valor_total,
      dueDate: dueDate(),
      description: `Pedido ${pedido.numero_pedido ?? pedido.id}`,
      externalReference: pedido.id,
      split: split.asaasSplit,
    };

    if (metodo === 'cartao_credito') {
      Object.assign(paymentPayload, {
        creditCard: buildCreditCard(cartao),
        creditCardHolderInfo: buildCreditCardHolder(cartao, clienteUsuario, pedido),
        remoteIp: req.headers.get('x-forwarded-for')?.split(',')[0]?.trim() || '127.0.0.1',
      });
    }

    const endpoint = metodo === 'cartao_credito' ? `${asaasBaseUrl}/payments/` : `${asaasBaseUrl}/payments`;
    const asaasResponse = await fetch(endpoint, {
      method: 'POST',
      headers: { access_token: asaasApiKey, 'Content-Type': 'application/json' },
      body: JSON.stringify(paymentPayload),
    });
    const asaasData = await asaasResponse.json().catch(() => ({}));
    if (!asaasResponse.ok) {
      return json({ error: 'Asaas recusou a criacao da cobranca.', details: asaasData }, 502);
    }

    const paymentId = text(asaasData.id);
    const invoiceUrl = text(asaasData.invoiceUrl);
    const bankSlipUrl = text(asaasData.bankSlipUrl);
    const pix = metodo === 'pix' ? await getPixQrCode(asaasBaseUrl, asaasApiKey, paymentId) : null;

    const { data: splitRow, error: splitError } = await supabase.from('splits_pagamento').upsert({
      pedido_id: pedido.id,
      estabelecimento_id: pedido.estabelecimento_id,
      entregador_id: pedido.entregador_id,
      valor_total: financeiro.valor_total,
      estabelecimento_wallet_id: estabelecimentoSubconta.asaas_wallet_id,
      estabelecimento_valor: split.estabelecimentoValor,
      entregador_wallet_id: entregadorSubconta?.asaas_wallet_id ?? null,
      entregador_taxa_entrega_valor: split.entregadorValor,
      entregador_valor_total: split.entregadorValor,
      plataforma_valor: split.plataformaValor,
      status: 'pendente',
      asaas_payment_id: paymentId,
      status_asaas: text(asaasData.status) || 'PENDING',
      asaas_response: sanitizePayment(asaasData),
      valor_liquido: numberOrNull(asaasData.netValue),
      metadata: {
        calculo_financeiro: financeiro,
        entregador_split_pendente: pedido.entregador_id == null,
        observacao: pedido.entregador_id == null
          ? 'Pedido cobrado antes de entregador atribuido; nao ha saque interno no Opadoca.'
          : null,
      },
    }, { onConflict: 'pedido_id' }).select('id').single();
    if (splitError) throw splitError;

    const { error: pedidoUpdateError } = await supabase.from('pedidos').update({
      asaas_payment_id: paymentId,
      asaas_invoice_url: invoiceUrl || null,
      pagamento_metodo: metodo,
      pagamento_status: statusFromAsaas(text(asaasData.status)),
      taxa_plataforma_calculada: financeiro.comissao_plataforma,
      taxa_asaas: numberOrNull(asaasData.value) && numberOrNull(asaasData.netValue)
        ? round2(numberOrNull(asaasData.value)! - numberOrNull(asaasData.netValue)!)
        : 0,
      valor_liquido: numberOrNull(asaasData.netValue),
      split_processado: false,
    }).eq('id', pedido.id);
    if (pedidoUpdateError) throw pedidoUpdateError;

    await supabase.from('asaas_eventos_financeiros').insert({
      asaas_payment_id: paymentId,
      evento: 'PAYMENT_CREATED',
      pedido_id: pedido.id,
      split_pagamento_id: splitRow.id,
      valor_bruto: financeiro.valor_total,
      valor_liquido: numberOrNull(asaasData.netValue),
      taxa_asaas: numberOrNull(asaasData.value) && numberOrNull(asaasData.netValue)
        ? round2(numberOrNull(asaasData.value)! - numberOrNull(asaasData.netValue)!)
        : null,
      status_novo: text(asaasData.status),
      payload: sanitizePayment(asaasData),
      processado: true,
      processado_em: new Date().toISOString(),
    });

    return json({
      paymentId,
      status: statusFromAsaas(text(asaasData.status)),
      invoiceUrl,
      bankSlipUrl,
      pixQrCode: pix?.encodedImage,
      pixCopiaECola: pix?.payload,
    });
  } catch (error) {
    console.error('[asaas-criar-pagamento-pedido]', error);
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

async function authenticatedUser(req: Request, supabase: ReturnType<typeof createClient>) {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) throw new HttpError('Sessao obrigatoria.', 401);
  const { data: { user }, error } = await supabase.auth.getUser(authHeader.replace('Bearer ', ''));
  if (error || !user) throw new HttpError('Sessao invalida.', 401);
  return user;
}

async function activeSubaccount(supabase: ReturnType<typeof createClient>, tipo: string, id: string) {
  const { data, error } = await supabase
    .from('asaas_subcontas')
    .select('asaas_wallet_id, status_conta')
    .eq('entidade_tipo', tipo)
    .eq('entidade_id', id)
    .in('status_conta', ['pending', 'active'])
    .maybeSingle();
  if (error) throw error;
  return data;
}

async function ensureCustomer(
  asaasBaseUrl: string,
  asaasApiKey: string,
  supabase: ReturnType<typeof createClient>,
  cliente: Record<string, unknown>,
  usuario: Record<string, unknown>,
  pedido: Record<string, unknown>,
  cartao?: Record<string, unknown>,
) {
  const existing = text(cliente.asaas_customer_id);
  if (existing) return existing;

  const endereco = (pedido.endereco_entrega_snapshot ?? {}) as Record<string, unknown>;
  const cpfCnpj = onlyDigits(text(cliente.cpf) || text(cartao?.cpfCnpj));
  if (!cpfCnpj) throw new HttpError('CPF do cliente e obrigatorio para criar a cobranca Asaas.', 400);

  const payload = removeEmpty({
    name: text(usuario.nome_completo_fantasia) || 'Cliente Opadoca',
    email: text(usuario.email),
    phone: onlyDigits(text(usuario.telefone)),
    mobilePhone: onlyDigits(text(usuario.telefone)),
    cpfCnpj,
    address: text(endereco.logradouro),
    addressNumber: text(endereco.numero),
    complement: text(endereco.complemento),
    province: text(endereco.bairro),
    postalCode: onlyDigits(text(endereco.cep)),
    externalReference: text(cliente.id),
    notificationDisabled: true,
  });

  const response = await fetch(`${asaasBaseUrl}/customers`, {
    method: 'POST',
    headers: { access_token: asaasApiKey, 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) throw new HttpError(`Asaas recusou o cliente: ${JSON.stringify(data)}`, 502);

  const id = text(data.id);
  if (!id) throw new HttpError('Resposta incompleta ao criar cliente Asaas.', 502);
  await supabase.from('clientes').update({
    asaas_customer_id: id,
    asaas_customer_payload: sanitizePayment(data),
  }).eq('id', cliente.id);
  return id;
}

async function calcularFinanceiro(supabase: ReturnType<typeof createClient>, pedido: Record<string, unknown>) {
  const { data, error } = await supabase.rpc('calcular_financeiro_pedido', {
    p_subtotal_produtos: number(pedido.subtotal_produtos),
    p_distancia_km: number(pedido.distancia_km),
    p_estabelecimento_id: pedido.estabelecimento_id,
    p_desconto: number(pedido.desconto_cupom),
    p_taxa_servico_app: number(pedido.taxa_servico_app),
  });
  if (error) throw error;
  return data as Record<string, number>;
}

function buildSplit(args: {
  pedido: Record<string, unknown>;
  financeiro: Record<string, number>;
  estabelecimentoWalletId: string;
  entregadorWalletId?: string;
}) {
  let estabelecimentoValor = round2(args.financeiro.estabelecimento_valor);
  let entregadorValor = args.entregadorWalletId ? round2(args.financeiro.entregador_valor) : 0;
  const total = round2(args.financeiro.valor_total);
  const overflow = round2(estabelecimentoValor + entregadorValor - total);
  if (overflow > 0) estabelecimentoValor = Math.max(0, round2(estabelecimentoValor - overflow));
  const plataformaValor = round2(total - estabelecimentoValor - entregadorValor);

  const asaasSplit = [
    {
      walletId: args.estabelecimentoWalletId,
      fixedValue: estabelecimentoValor,
      externalReference: `${args.pedido.id}:estabelecimento`,
      description: 'Repasse do estabelecimento',
    },
  ];
  if (args.entregadorWalletId && entregadorValor > 0) {
    asaasSplit.push({
      walletId: args.entregadorWalletId,
      fixedValue: entregadorValor,
      externalReference: `${args.pedido.id}:entregador`,
      description: 'Taxa de entrega do entregador',
    });
  }

  return { estabelecimentoValor, entregadorValor, plataformaValor, asaasSplit };
}

async function getPixQrCode(asaasBaseUrl: string, asaasApiKey: string, paymentId: string) {
  if (!paymentId) return null;
  const response = await fetch(`${asaasBaseUrl}/payments/${paymentId}/pixQrCode`, {
    headers: { access_token: asaasApiKey },
  });
  if (!response.ok) return null;
  return await response.json().catch(() => null);
}

function normalizeMetodo(value: string) {
  if (['pix', 'boleto', 'cartao_credito', 'cartao_debito'].includes(value)) return value;
  return 'pix';
}

function billingTypeFor(metodo: string) {
  if (metodo === 'boleto') return 'BOLETO';
  if (metodo === 'cartao_credito') return 'CREDIT_CARD';
  return 'PIX';
}

function buildCreditCard(cartao?: Record<string, unknown>) {
  if (!cartao) throw new HttpError('Dados do cartao obrigatorios.', 400);
  const [month, rawYear] = text(cartao.vencimento).split('/');
  const year = rawYear?.length === 2 ? `20${rawYear}` : rawYear;
  return {
    holderName: text(cartao.nomeTitular),
    number: onlyDigits(text(cartao.numero)),
    expiryMonth: month,
    expiryYear: year,
    ccv: onlyDigits(text(cartao.cvv)),
  };
}

function buildCreditCardHolder(cartao: Record<string, unknown> | undefined, usuario: Record<string, unknown>, pedido: Record<string, unknown>) {
  if (!cartao) throw new HttpError('Dados do titular do cartao obrigatorios.', 400);
  const endereco = (pedido.endereco_entrega_snapshot ?? {}) as Record<string, unknown>;
  return {
    name: text(cartao.nomeTitular) || text(usuario.nome_completo_fantasia),
    email: text(usuario.email),
    cpfCnpj: onlyDigits(text(cartao.cpfCnpj)),
    postalCode: onlyDigits(text(endereco.cep)),
    addressNumber: text(endereco.numero),
    phone: onlyDigits(text(usuario.telefone)) || '11999999999',
    mobilePhone: onlyDigits(text(usuario.telefone)) || '11999999999',
  };
}

function statusFromAsaas(status: string) {
  return ({
    PENDING: 'aguardando_pagamento',
    RECEIVED: 'confirmado',
    CONFIRMED: 'confirmado',
    OVERDUE: 'vencido',
    REFUNDED: 'estornado',
    CHARGEBACK_REQUESTED: 'chargeback',
    CHARGEBACK_DISPUTE: 'chargeback',
    AWAITING_RISK_ANALYSIS: 'em_analise',
  } as Record<string, string>)[status] ?? 'aguardando_pagamento';
}

function dueDate() {
  return new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
}

function firstRelation(value: unknown): any {
  return Array.isArray(value) ? value[0] : value;
}

function text(value: unknown): string {
  return typeof value === 'string' ? value.trim() : '';
}

function onlyDigits(value: string): string {
  return value.replace(/\D/g, '');
}

function number(value: unknown): number {
  return typeof value === 'number' ? value : Number(value ?? 0) || 0;
}

function numberOrNull(value: unknown): number | null {
  const parsed = number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function round2(value: number): number {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

function removeEmpty(payload: Record<string, unknown>) {
  return Object.fromEntries(Object.entries(payload).filter(([, value]) => value !== undefined && value !== null && value !== ''));
}

function sanitizePayment(data: Record<string, unknown>) {
  const copy = { ...data };
  delete copy.creditCard;
  return copy;
}
