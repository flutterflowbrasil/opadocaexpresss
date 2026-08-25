import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';
import {
  asaasAmbiente,
  assertAsaasMasterKey,
  errorToResponse,
  HttpError,
  jsonResponse,
  loadAsaasCredentials,
  requiredEnv,
} from '../_shared/asaas_client.ts';

serve(async (req) => {
  if (req.method === 'OPTIONS') return jsonResponse({ ok: true });
  if (req.method !== 'POST' && req.method !== 'GET') {
    return jsonResponse({ error: 'Metodo nao permitido.' }, 405);
  }

  try {
    const serviceRoleKey = requiredEnv('SUPABASE_SERVICE_ROLE_KEY');
    const supabase = createClient(requiredEnv('SUPABASE_URL'), serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const authHeader = req.headers.get('Authorization');
    if (!authHeader) throw new HttpError('Sessao obrigatoria.', 401);
    const { data: { user }, error } = await supabase.auth.getUser(
      authHeader.replace('Bearer ', ''),
    );
    if (error || !user) throw new HttpError('Sessao invalida.', 401);

    const { data: adminRow } = await supabase
      .from('usuarios')
      .select('id')
      .eq('id', user.id)
      .eq('tipo_usuario', 'admin')
      .maybeSingle();
    if (!adminRow) throw new HttpError('Apenas administradores da plataforma.', 403);

    const { baseUrl, apiKey } = loadAsaasCredentials();
    await assertAsaasMasterKey(baseUrl, apiKey);

    return jsonResponse({
      ok: true,
      ambiente: asaasAmbiente(baseUrl),
    });
  } catch (error) {
    return errorToResponse(error, '[asaas-health]');
  }
});
