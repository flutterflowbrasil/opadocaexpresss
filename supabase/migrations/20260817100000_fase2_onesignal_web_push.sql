-- Fase 2: plataforma web em dispositivos_push, canal/som na fila,
-- templates alinhados aos canais Android locais e cron do worker OneSignal.

CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

ALTER TABLE public.dispositivos_push
  DROP CONSTRAINT IF EXISTS dispositivos_push_plataforma_check;

ALTER TABLE public.dispositivos_push
  ADD CONSTRAINT dispositivos_push_plataforma_check
  CHECK (plataforma IN ('android', 'ios', 'web', 'expo'));

CREATE OR REPLACE FUNCTION public.enfileirar_notificacao(
  p_usuario_id uuid,
  p_evento text,
  p_entidade_tipo text DEFAULT NULL,
  p_entidade_id uuid DEFAULT NULL,
  p_variaveis jsonb DEFAULT '{}'::jsonb,
  p_dados_extra jsonb DEFAULT '{}'::jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_template record;
  v_prefs record;
  v_titulo text;
  v_corpo text;
  v_notif_id uuid;
  v_chave text;
  v_valor text;
  v_flag text;
  v_agora time;
  v_tz text;
BEGIN
  SELECT valor INTO v_flag
    FROM public.plataforma_configuracoes
   WHERE chave = 'notif_ativa';
  IF FOUND AND lower(COALESCE(v_flag, 'true')) IN ('0', 'false', 'nao', 'off') THEN
    RETURN NULL;
  END IF;

  SELECT * INTO v_template
    FROM public.notificacao_templates
   WHERE evento = p_evento AND ativo = true;
  IF NOT FOUND THEN RETURN NULL; END IF;

  SELECT * INTO v_prefs
    FROM public.notificacao_preferencias
   WHERE usuario_id = p_usuario_id;

  IF FOUND THEN
    IF NOT v_prefs.push_ativo THEN RETURN NULL; END IF;
    IF p_evento LIKE 'pedido_%' AND NOT v_prefs.push_pedidos THEN RETURN NULL; END IF;
    IF p_evento LIKE 'despacho_%' AND NOT v_prefs.push_entregas THEN RETURN NULL; END IF;
    IF p_evento IN ('cupom_novo', 'cupom_expirando', 'promocao_estabelecimento')
       AND NOT v_prefs.push_promocoes THEN RETURN NULL; END IF;

    IF COALESCE(v_prefs.silencioso_ativo, false)
       AND p_evento NOT IN ('despacho_nova_oferta', 'pedido_novo_estabelecimento') THEN
      v_tz := COALESCE(v_prefs.silencioso_timezone, 'America/Sao_Paulo');
      v_agora := (now() AT TIME ZONE v_tz)::time;
      IF v_prefs.silencioso_inicio <= v_prefs.silencioso_fim THEN
        IF v_agora >= v_prefs.silencioso_inicio AND v_agora < v_prefs.silencioso_fim THEN
          RETURN NULL;
        END IF;
      ELSE
        IF v_agora >= v_prefs.silencioso_inicio OR v_agora < v_prefs.silencioso_fim THEN
          RETURN NULL;
        END IF;
      END IF;
    END IF;
  ELSE
    INSERT INTO public.notificacao_preferencias (usuario_id)
    VALUES (p_usuario_id)
    ON CONFLICT (usuario_id) DO NOTHING;
  END IF;

  IF p_evento LIKE 'pedido_%' THEN
    SELECT valor INTO v_flag FROM public.plataforma_configuracoes WHERE chave = 'notif_pedidos';
    IF FOUND AND lower(COALESCE(v_flag, 'true')) IN ('0', 'false', 'nao', 'off') THEN RETURN NULL; END IF;
  ELSIF p_evento LIKE 'despacho_%' THEN
    SELECT valor INTO v_flag FROM public.plataforma_configuracoes WHERE chave = 'notif_entregas';
    IF FOUND AND lower(COALESCE(v_flag, 'true')) IN ('0', 'false', 'nao', 'off') THEN RETURN NULL; END IF;
  ELSIF p_evento IN ('cupom_novo', 'cupom_expirando', 'promocao_estabelecimento') THEN
    SELECT valor INTO v_flag FROM public.plataforma_configuracoes WHERE chave = 'notif_promocoes';
    IF FOUND AND lower(COALESCE(v_flag, 'true')) IN ('0', 'false', 'nao', 'off') THEN RETURN NULL; END IF;
  END IF;

  v_titulo := v_template.titulo;
  v_corpo := v_template.corpo;

  FOR v_chave, v_valor IN SELECT key, value FROM jsonb_each_text(COALESCE(p_variaveis, '{}'::jsonb)) LOOP
    v_titulo := REPLACE(v_titulo, '{{' || v_chave || '}}', v_valor);
    v_corpo := REPLACE(v_corpo, '{{' || v_chave || '}}', v_valor);
  END LOOP;

  INSERT INTO public.notificacoes_fila
    (usuario_id, evento, titulo, corpo, entidade_tipo, entidade_id, dados)
  VALUES
    (p_usuario_id, p_evento, v_titulo, v_corpo, p_entidade_tipo, p_entidade_id,
     COALESCE(p_dados_extra, '{}'::jsonb) || jsonb_build_object(
       'evento', p_evento,
       'canal_android', COALESCE(v_template.canal_android, 'padoca_geral'),
       'som', COALESCE(v_template.som, 'default')
     ))
  RETURNING id INTO v_notif_id;

  RETURN v_notif_id;
END;
$$;

REVOKE ALL ON FUNCTION public.enfileirar_notificacao(uuid, text, text, uuid, jsonb, jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.enfileirar_notificacao(uuid, text, text, uuid, jsonb, jsonb) TO service_role;

UPDATE public.notificacao_templates
   SET canal_android = CASE
         WHEN evento = 'despacho_nova_oferta' THEN 'padoca_entregas_urgente'
         WHEN evento = 'pedido_novo_estabelecimento' THEN 'padoca_pedidos_urgente'
         WHEN canal_android IN ('pedidos') THEN 'padoca_pedidos'
         WHEN canal_android IN ('geral', 'promocoes', 'entregas', 'financeiro', 'sistema') THEN 'padoca_geral'
         ELSE canal_android
       END,
       som = CASE
         WHEN evento = 'despacho_nova_oferta' THEN 'notificacoes_entregador'
         ELSE som
       END,
       updated_at = now();

CREATE OR REPLACE FUNCTION public.fn_processar_notificacoes_fila_cron()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, vault, net
AS $$
DECLARE
  v_secret text;
BEGIN
  SELECT decrypted_secret INTO v_secret
    FROM vault.decrypted_secrets
   WHERE name = 'push_worker_secret'
   LIMIT 1;

  IF v_secret IS NULL OR length(v_secret) = 0 THEN
    RAISE WARNING 'push_worker_secret ausente no vault';
    RETURN;
  END IF;

  PERFORM net.http_post(
    url := 'https://blibxmylxcrztfhvllkj.supabase.co/functions/v1/processar-notificacoes-fila',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-worker-secret', v_secret
    ),
    body := '{}'::jsonb
  );
END;
$$;

REVOKE ALL ON FUNCTION public.fn_processar_notificacoes_fila_cron() FROM PUBLIC, anon, authenticated;

DO $$
DECLARE
  v_jobid bigint;
BEGIN
  FOR v_jobid IN SELECT jobid FROM cron.job WHERE jobname = 'processar-notificacoes-fila'
  LOOP
    PERFORM cron.unschedule(v_jobid);
  END LOOP;
END $$;

SELECT cron.schedule(
  'processar-notificacoes-fila',
  '* * * * *',
  $$SELECT public.fn_processar_notificacoes_fila_cron();$$
);
