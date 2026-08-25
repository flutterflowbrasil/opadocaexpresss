/** Cliente Asaas compartilhado. Lê ASAAS_API_KEY só de secrets (nunca no Flutter). */

export class HttpError extends Error {
  constructor(message: string, public status = 400, public code?: string) {
    super(message);
  }
}

export function requiredEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new HttpError(`Secret ${name} nao configurado.`, 503, 'SECRET_MISSING');
  return value;
}

export function resolveAsaasBaseUrl(): string {
  const raw = (Deno.env.get('ASAAS_BASE_URL') ?? 'https://api-sandbox.asaas.com/v3')
    .trim()
    .replace(/\/$/, '');
  const lower = raw.toLowerCase();
  if (lower.includes('sandbox.asaas.com') && !lower.includes('api-sandbox')) {
    return 'https://api-sandbox.asaas.com/v3';
  }
  return raw || 'https://api-sandbox.asaas.com/v3';
}

export function sanitizeAsaasApiKey(raw: string): string {
  let key = raw.trim().replace(/^\uFEFF/, '');
  if (
    (key.startsWith('"') && key.endsWith('"')) ||
    (key.startsWith("'") && key.endsWith("'"))
  ) {
    key = key.slice(1, -1).trim();
  }
  return key;
}

export function loadAsaasCredentials(): { baseUrl: string; apiKey: string; isSandbox: boolean } {
  const baseUrl = resolveAsaasBaseUrl();
  const apiKey = sanitizeAsaasApiKey(requiredEnv('ASAAS_API_KEY'));
  return { baseUrl, apiKey, isSandbox: baseUrl.includes('sandbox') };
}

export function asaasHeaders(apiKey: string, json = true): Record<string, string> {
  const headers: Record<string, string> = {
    access_token: apiKey,
    Accept: 'application/json',
    'User-Agent': 'OpadocaExpress/1.0 (Deno)',
  };
  if (json) headers['Content-Type'] = 'application/json';
  return headers;
}

export function asaasAmbiente(baseUrl: string): 'sandbox' | 'production' {
  return baseUrl.includes('sandbox') ? 'sandbox' : 'production';
}

export async function assertAsaasMasterKey(baseUrl: string, apiKey: string): Promise<void> {
  const response = await fetch(`${baseUrl}/myAccount`, {
    headers: asaasHeaders(apiKey, false),
  });
  if (response.ok) return;
  const data = await response.json().catch(() => ({}));
  console.error('[asaas] myAccount falhou', response.status, {
    host: safeHost(baseUrl),
    sandboxKey: apiKey.includes('_hmlg_'),
    prodKey: apiKey.includes('_prod_'),
    startsDollar: apiKey.startsWith('$'),
    body: data,
  });
  throw new HttpError(
    'Pagamentos temporariamente indisponiveis.',
    503,
    'ASAAS_KEY_INVALID',
  );
}

/** Só em sandbox. Nunca chama approve em produção. */
export async function approveSandboxAccount(baseUrl: string, apiKey: string) {
  if (!baseUrl.includes('sandbox') || !apiKey) return null;
  const response = await fetch(`${baseUrl}/sandbox/myAccount/approve`, {
    method: 'POST',
    headers: asaasHeaders(apiKey),
    body: '{}',
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    console.error('[asaas] sandbox approve', response.status, data);
    return null;
  }
  return data;
}

export function jsonResponse(
  body: unknown,
  status = 200,
  extraHeaders: Record<string, string> = {},
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers':
        'authorization, x-client-info, apikey, content-type, x-worker-secret, asaas-access-token, x-asaas-token',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      ...extraHeaders,
    },
  });
}

export function errorToResponse(error: unknown, logPrefix: string): Response {
  console.error(logPrefix, error);
  if (error instanceof HttpError) {
    const body: Record<string, unknown> = { error: error.message };
    if (error.code) body.code = error.code;
    return jsonResponse(body, error.status);
  }
  return jsonResponse(
    { error: error instanceof Error ? error.message : 'Erro inesperado.' },
    500,
  );
}

function safeHost(baseUrl: string): string {
  try {
    return new URL(baseUrl).host;
  } catch {
    return 'invalid-url';
  }
}
