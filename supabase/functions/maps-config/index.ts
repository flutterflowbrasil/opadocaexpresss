import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'GET') return json({ error: 'Metodo nao permitido.' }, 405);

  try {
    await authenticatedUser(req);
    const key = Deno.env.get('GOOGLE_MAPS_WEB_KEY') ?? '';
    return json({ key });
  } catch (error) {
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

async function authenticatedUser(req: Request) {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) throw new HttpError('Sessao obrigatoria.', 401);
  const supabase = createClient(
    requiredEnv('SUPABASE_URL'),
    requiredEnv('SUPABASE_ANON_KEY'),
    { global: { headers: { Authorization: authHeader } }, auth: { persistSession: false } },
  );
  const { data: { user }, error } = await supabase.auth.getUser(authHeader.replace(/^Bearer\s+/i, ''));
  if (error || !user) throw new HttpError('Sessao invalida.', 401);
  return user;
}

function requiredEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Secret ${name} nao configurado.`);
  return value;
}
