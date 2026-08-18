import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

const GEOCODE_URL = 'https://maps.googleapis.com/maps/api/geocode/json';
const DIRECTIONS_URL = 'https://maps.googleapis.com/maps/api/directions/json';
const RATE_LIMIT_MINUTE = 30;
const RATE_LIMIT_HOUR = 200;
const LATLNG_RE = /^-?\d{1,3}(?:\.\d+)?,-?\d{1,3}(?:\.\d+)?$/;
const ALLOWED_MODES = new Set(['driving', 'walking', 'bicycling', 'transit']);

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'Metodo nao permitido.' }, 405);

  try {
    const apiKey = Deno.env.get('GOOGLE_MAPS_API_KEY')
      || Deno.env.get('GOOGLE_MAPS_SERVER_KEY')
      || '';
    if (!apiKey) return json({ error: 'GOOGLE_MAPS_API_KEY nao configurada.' }, 503);

    const supabase = createClient(requiredEnv('SUPABASE_URL'), requiredEnv('SUPABASE_SERVICE_ROLE_KEY'), {
      auth: { persistSession: false },
    });
    const user = await authenticatedUser(req, supabase);
    const body = await req.json().catch(() => ({})) as Record<string, unknown>;
    const action = resolveAction(body);

    const allowed = await enforceRateLimit(supabase, user.id, action);
    if (!allowed) return json({ error: 'Limite de consultas de mapa atingido. Tente novamente em instantes.' }, 429);

    const url = buildGoogleUrl(action, body, apiKey);
    const googleRes = await fetch(url);
    const data = await googleRes.json().catch(() => ({}));

    if (data.status === 'REQUEST_DENIED') {
      console.error('[geocode-proxy] Google API negou:', data.error_message);
      return json({ error: 'Servico de geocodificacao indisponivel.' }, 502);
    }

    return json(data);
  } catch (error) {
    console.error('[geocode-proxy]', error);
    const status = error instanceof HttpError ? error.status : 500;
    return json({ error: error instanceof Error ? error.message : 'Erro interno.' }, status);
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

async function authenticatedUser(req: Request, supabase: ReturnType<typeof createClient>) {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) throw new HttpError('Sessao obrigatoria.', 401);
  const { data: { user }, error } = await supabase.auth.getUser(authHeader.replace(/^Bearer\s+/i, ''));
  if (error || !user) throw new HttpError('Sessao invalida.', 401);
  return user;
}

function resolveAction(body: Record<string, unknown>): string {
  const action = typeof body.action === 'string' ? body.action.trim() : '';
  if (action) return action;
  if (body.lat !== undefined && body.lng !== undefined) return 'reverse';
  if (body.cep !== undefined) return 'geocode';
  throw new HttpError('Parametros invalidos.', 400);
}

function buildGoogleUrl(action: string, body: Record<string, unknown>, apiKey: string): string {
  if (action === 'directions') {
    const origin = latLngOrThrow(body.origin, 'origin');
    const destination = latLngOrThrow(body.destination, 'destination');
    const mode = typeof body.mode === 'string' && ALLOWED_MODES.has(body.mode) ? body.mode : 'driving';
    return `${DIRECTIONS_URL}?origin=${encodeURIComponent(origin)}&destination=${encodeURIComponent(destination)}&mode=${mode}&language=pt-BR&key=${apiKey}`;
  }

  if (action === 'geocode') {
    const address = typeof body.address === 'string' ? body.address.trim() : '';
    const cep = typeof body.cep === 'string' ? body.cep.replace(/\D/g, '') : '';
    const query = address || (cep.length === 8 ? `${cep}, Brasil` : '');
    if (!query || query.length > 200) throw new HttpError('Endereco invalido.', 400);
    return `${GEOCODE_URL}?address=${encodeURIComponent(query)}&language=pt-BR&region=BR&key=${apiKey}`;
  }

  if (action === 'reverse' || (body.lat !== undefined && body.lng !== undefined)) {
    const lat = Number(body.lat);
    const lng = Number(body.lng);
    if (!Number.isFinite(lat) || !Number.isFinite(lng) || Math.abs(lat) > 90 || Math.abs(lng) > 180) {
      throw new HttpError('Coordenadas invalidas.', 400);
    }
    return `${GEOCODE_URL}?latlng=${lat},${lng}&language=pt-BR&key=${apiKey}`;
  }

  throw new HttpError('Parametros invalidos.', 400);
}

function latLngOrThrow(value: unknown, field: string): string {
  const text = typeof value === 'string' ? value.trim() : '';
  if (!LATLNG_RE.test(text)) throw new HttpError(`${field} deve ser latitude,longitude.`, 400);
  const [lat, lng] = text.split(',').map(Number);
  if (Math.abs(lat) > 90 || Math.abs(lng) > 180) throw new HttpError(`${field} fora do intervalo.`, 400);
  return text;
}

async function enforceRateLimit(
  supabase: ReturnType<typeof createClient>,
  usuarioId: string,
  action: string,
): Promise<boolean> {
  const { count: minuteCount, error: minuteError } = await supabase
    .from('maps_proxy_uso')
    .select('id', { count: 'exact', head: true })
    .eq('usuario_id', usuarioId)
    .gte('created_at', new Date(Date.now() - 60_000).toISOString());
  if (minuteError) throw minuteError;
  if ((minuteCount ?? 0) >= RATE_LIMIT_MINUTE) return false;

  const { count: hourCount, error: hourError } = await supabase
    .from('maps_proxy_uso')
    .select('id', { count: 'exact', head: true })
    .eq('usuario_id', usuarioId)
    .gte('created_at', new Date(Date.now() - 3_600_000).toISOString());
  if (hourError) throw hourError;
  if ((hourCount ?? 0) >= RATE_LIMIT_HOUR) return false;

  const { error: insertError } = await supabase.from('maps_proxy_uso').insert({
    usuario_id: usuarioId,
    action,
  });
  if (insertError) throw insertError;
  return true;
}
