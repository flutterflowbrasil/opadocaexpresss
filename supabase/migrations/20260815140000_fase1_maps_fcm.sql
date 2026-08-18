-- Fase 1/2: log de mapas, claim da fila FCM, templates criticos e sync de preferencias.

CREATE TABLE IF NOT EXISTS public.maps_proxy_uso (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id uuid NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
  action text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS maps_proxy_uso_usuario_created_idx
  ON public.maps_proxy_uso (usuario_id, created_at DESC);

ALTER TABLE public.maps_proxy_uso ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.maps_proxy_uso FROM anon, authenticated;

CREATE INDEX IF NOT EXISTS rastreamento_entregadores_pedido_created_idx
  ON public.rastreamento_entregadores (pedido_id, registrado_em DESC);

-- ── Claim atomico da fila de push ───────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_claim_notificacoes_fila(p_limit integer DEFAULT 50)
RETURNS SETOF public.notificacoes_fila
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  WITH candidatas AS (
    SELECT id
      FROM public.notificacoes_fila
     WHERE (
            status = 'pendente'
            AND COALESCE(proxima_tentativa_em, now()) <= now()
           )
        OR (
            status = 'processando'
            AND COALESCE(processado_em, created_at) < now() - interval '5 minutes'
           )
     ORDER BY created_at
     LIMIT GREATEST(1, LEAST(COALESCE(p_limit, 50), 100))
     FOR UPDATE SKIP LOCKED
  )
  UPDATE public.notificacoes_fila n
     SET status = 'processando',
         tentativas = COALESCE(n.tentativas, 0) + 1,
         processado_em = now()
    FROM candidatas c
   WHERE n.id = c.id
  RETURNING n.*;
END;
$$;

REVOKE ALL ON FUNCTION public.fn_claim_notificacoes_fila(integer) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.fn_claim_notificacoes_fila(integer) TO service_role;

-- ── Preferencias: flags da plataforma + horario silencioso ──────────────────
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
     COALESCE(p_dados_extra, '{}'::jsonb) || jsonb_build_object('evento', p_evento))
  RETURNING id INTO v_notif_id;

  RETURN v_notif_id;
END;
$$;

REVOKE ALL ON FUNCTION public.enfileirar_notificacao(uuid, text, text, uuid, jsonb, jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.enfileirar_notificacao(uuid, text, text, uuid, jsonb, jsonb) TO service_role;

CREATE OR REPLACE FUNCTION public.fn_enfileirar_notificacao_admin(
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
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'nao autorizado';
  END IF;
  RETURN public.enfileirar_notificacao(
    p_usuario_id, p_evento, p_entidade_tipo, p_entidade_id, p_variaveis, p_dados_extra
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.fn_enfileirar_notificacao_admin(uuid, text, text, uuid, jsonb, jsonb) TO authenticated;

-- ── Sync entregador_configuracoes -> notificacao_preferencias ───────────────
CREATE OR REPLACE FUNCTION public.trg_sync_entregador_notif_prefs()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_usuario uuid;
BEGIN
  SELECT usuario_id INTO v_usuario
    FROM public.entregadores
   WHERE id = NEW.entregador_id;
  IF v_usuario IS NULL THEN
    RETURN NEW;
  END IF;

  INSERT INTO public.notificacao_preferencias (usuario_id, push_ativo, push_entregas)
  VALUES (v_usuario, COALESCE(NEW.notif_novos_pedidos, true), COALESCE(NEW.notif_novos_pedidos, true))
  ON CONFLICT (usuario_id) DO UPDATE
    SET push_entregas = EXCLUDED.push_entregas,
        push_ativo = CASE
          WHEN EXCLUDED.push_entregas THEN true
          ELSE public.notificacao_preferencias.push_ativo
        END,
        updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_entregador_notif_prefs ON public.entregador_configuracoes;
CREATE TRIGGER trg_sync_entregador_notif_prefs
AFTER INSERT OR UPDATE OF notif_novos_pedidos, notif_atualizacoes
ON public.entregador_configuracoes
FOR EACH ROW
EXECUTE FUNCTION public.trg_sync_entregador_notif_prefs();

-- ── Templates criticos ──────────────────────────────────────────────────────
CREATE UNIQUE INDEX IF NOT EXISTS notificacao_templates_evento_key
  ON public.notificacao_templates (evento);

INSERT INTO public.notificacao_templates (evento, titulo, corpo, canal_android, som, ativo)
VALUES
  ('pedido_novo_estabelecimento',
   '🔔 Novo pedido!',
   'Pedido {{numero_pedido}} — total {{total}}',
   'padoca_entregas_urgente', 'default', true),
  ('split_confirmado',
   '💰 Pagamento recebido',
   'Seu split do pedido {{numero_pedido}} foi confirmado.',
   'geral', 'default', true),
  ('split_falhou',
   '⚠️ Falha no split',
   'Nao foi possivel processar o split do pedido {{numero_pedido}}.',
   'geral', 'default', true),
  ('subconta_rejeitada',
   '⚠️ Conta Asaas recusada',
   'Sua conta de recebimento precisa de correcao. Abra a carteira para revisar.',
   'geral', 'default', true),
  ('saque_solicitado',
   'Saque em processamento',
   'R$ {{valor}} esta sendo enviado para sua chave PIX.',
   'geral', 'default', true)
ON CONFLICT (evento) DO UPDATE
  SET titulo = EXCLUDED.titulo,
      corpo = EXCLUDED.corpo,
      canal_android = EXCLUDED.canal_android,
      ativo = true,
      updated_at = now();

CREATE OR REPLACE FUNCTION public.trg_pedido_novo_notificar_estab()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_usuario uuid;
BEGIN
  SELECT usuario_id INTO v_usuario
    FROM public.estabelecimentos
   WHERE id = NEW.estabelecimento_id;
  IF v_usuario IS NOT NULL THEN
    PERFORM public.enfileirar_notificacao(
      v_usuario,
      'pedido_novo_estabelecimento',
      'pedido',
      NEW.id,
      jsonb_build_object(
        'numero_pedido', COALESCE(NEW.numero_pedido::text, left(NEW.id::text, 8)),
        'total', COALESCE(NEW.total::text, '')
      ),
      jsonb_build_object('pedido_id', NEW.id)
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_pedido_novo_notificar_estab ON public.pedidos;
CREATE TRIGGER trg_pedido_novo_notificar_estab
AFTER INSERT ON public.pedidos
FOR EACH ROW
EXECUTE FUNCTION public.trg_pedido_novo_notificar_estab();
