
-- ── 1. Novos status ───────────────────────────────────────────────────────────
ALTER TABLE public.pedidos DROP CONSTRAINT IF EXISTS pedidos_status_check;
ALTER TABLE public.pedidos ADD CONSTRAINT pedidos_status_check CHECK (
  status = ANY (ARRAY[
    'pendente','confirmado','preparando','pronto',
    'a_caminho_coleta','no_estabelecimento','coletado','a_caminho_cliente',
    'em_entrega','entregue',
    'cancelado_cliente','cancelado_estab','cancelado_sistema'
  ])
);

-- ── 2. Novos timestamps em pedidos ────────────────────────────────────────────
ALTER TABLE public.pedidos
  ADD COLUMN IF NOT EXISTS a_caminho_coleta_em      timestamptz,
  ADD COLUMN IF NOT EXISTS chegou_estabelecimento_em timestamptz,
  ADD COLUMN IF NOT EXISTS coletado_em               timestamptz,
  ADD COLUMN IF NOT EXISTS a_caminho_cliente_em      timestamptz;

-- ── 3. Tabela pedido_logistica ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.pedido_logistica (
  id                        uuid        PRIMARY KEY DEFAULT uuid_generate_v4(),
  pedido_id                 uuid        NOT NULL UNIQUE REFERENCES public.pedidos(id) ON DELETE CASCADE,
  codigo_coleta_balcao      text        NOT NULL,
  codigo_coleta_validado    boolean     NOT NULL DEFAULT false,
  codigo_coleta_tentativas  integer     NOT NULL DEFAULT 0,
  codigo_coleta_validado_em timestamptz,
  chegou_lat                numeric(10,7),
  chegou_lng                numeric(10,7),
  distancia_chegada_metros  numeric(8,1),
  validado_por_tipo         text CHECK (validado_por_tipo IN ('entregador','estabelecimento','sistema')),
  created_at                timestamptz NOT NULL DEFAULT now(),
  updated_at                timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.pedido_logistica IS
  'Detalhe da coleta no balcão: código POS, GPS de chegada, validação.';

-- ── 4. Trigger: cria logistica ao aceitar (entregador_id preenchido) ──────────
CREATE OR REPLACE FUNCTION public.fn_criar_logistica_pedido()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_codigo text;
BEGIN
  IF NEW.entregador_id IS NOT NULL AND OLD.entregador_id IS NULL THEN
    v_codigo := LPAD(
      (1000 + (('x' || SUBSTR(REVERSE(NEW.id::text), 1, 8))::bit(32)::bigint % 9000))::text,
      4, '0'
    );
    INSERT INTO public.pedido_logistica (pedido_id, codigo_coleta_balcao)
    VALUES (NEW.id, v_codigo)
    ON CONFLICT (pedido_id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_criar_logistica_ao_aceitar ON public.pedidos;
CREATE TRIGGER trg_criar_logistica_ao_aceitar
  AFTER UPDATE OF entregador_id ON public.pedidos
  FOR EACH ROW EXECUTE FUNCTION public.fn_criar_logistica_pedido();

-- ── 5. fn_checkin_estabelecimento ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_checkin_estabelecimento(
  p_pedido_id uuid,
  p_lat       numeric DEFAULT NULL,
  p_lng       numeric DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_codigo     text;
  v_dist       numeric;
  v_estab_lat  numeric;
  v_estab_lng  numeric;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.pedidos p2
    WHERE p2.id = p_pedido_id
      AND p2.status IN ('a_caminho_coleta','confirmado','pronto')
  ) THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Status inválido para check-in');
  END IF;

  IF p_lat IS NOT NULL AND p_lng IS NOT NULL THEN
    SELECT e.latitude, e.longitude INTO v_estab_lat, v_estab_lng
      FROM public.pedidos p2
      JOIN public.estabelecimentos e ON e.id = p2.estabelecimento_id
     WHERE p2.id = p_pedido_id;
    IF v_estab_lat IS NOT NULL THEN
      v_dist := ROUND((111045 * degrees(acos(
        LEAST(1.0, cos(radians(v_estab_lat)) * cos(radians(p_lat))
          * cos(radians(p_lng) - radians(v_estab_lng))
          + sin(radians(v_estab_lat)) * sin(radians(p_lat)))
      )))::numeric, 0);
    END IF;
  END IF;

  UPDATE public.pedido_logistica pl
     SET chegou_lat               = p_lat,
         chegou_lng               = p_lng,
         distancia_chegada_metros = v_dist,
         updated_at               = now()
   WHERE pl.pedido_id = p_pedido_id
   RETURNING pl.codigo_coleta_balcao INTO v_codigo;

  UPDATE public.pedidos SET
    status                    = 'no_estabelecimento',
    chegou_estabelecimento_em = now()
  WHERE id = p_pedido_id;

  RETURN jsonb_build_object('ok', true, 'codigo_coleta_balcao', v_codigo, 'distancia_metros', v_dist);
END;
$$;

-- ── 6. fn_validar_codigo_balcao ───────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_validar_codigo_balcao(
  p_pedido_id uuid,
  p_codigo    text
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_log      record;
  v_max_tent CONSTANT integer := 5;
BEGIN
  SELECT * INTO v_log FROM public.pedido_logistica pl WHERE pl.pedido_id = p_pedido_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Logística não encontrada');
  END IF;
  IF v_log.codigo_coleta_validado THEN
    RETURN jsonb_build_object('ok', true, 'mensagem', 'Código já validado');
  END IF;
  IF v_log.codigo_coleta_tentativas >= v_max_tent THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Limite de tentativas atingido');
  END IF;

  UPDATE public.pedido_logistica pl
     SET codigo_coleta_tentativas = codigo_coleta_tentativas + 1, updated_at = now()
   WHERE pl.pedido_id = p_pedido_id;

  IF v_log.codigo_coleta_balcao != p_codigo THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Código incorreto',
      'tentativas_restantes', v_max_tent - v_log.codigo_coleta_tentativas - 1);
  END IF;

  UPDATE public.pedido_logistica pl
     SET codigo_coleta_validado    = true,
         codigo_coleta_validado_em = now(),
         validado_por_tipo         = 'entregador',
         updated_at                = now()
   WHERE pl.pedido_id = p_pedido_id;

  UPDATE public.pedidos SET status = 'coletado', coletado_em = now() WHERE id = p_pedido_id;

  RETURN jsonb_build_object('ok', true, 'mensagem', 'Pedido coletado com sucesso!');
END;
$$;

-- ── 7. fn_saiu_para_cliente ───────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_saiu_para_cliente(p_pedido_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.pedidos p2
    WHERE p2.id = p_pedido_id AND p2.status IN ('coletado','no_estabelecimento')
  ) THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Pedido precisa estar coletado primeiro');
  END IF;

  UPDATE public.pedidos SET
    status               = 'a_caminho_cliente',
    a_caminho_cliente_em = now(),
    em_entrega_em        = now()
  WHERE id = p_pedido_id;

  RETURN jsonb_build_object('ok', true);
END;
$$;

-- ── 8. Atualiza trg_notif_status_pedido para novos status ────────────────────
CREATE OR REPLACE FUNCTION public.trg_notif_status_pedido()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_usuario_id    uuid;
  v_usuario_estab uuid;
  v_estab_nome    text;
  v_entregador_nome text;
  v_evento        text;
  v_variaveis     jsonb;
BEGIN
  IF OLD.status = NEW.status THEN RETURN NEW; END IF;

  v_evento := CASE NEW.status
    WHEN 'confirmado'         THEN 'pedido_confirmado'
    WHEN 'preparando'         THEN 'pedido_preparando'
    WHEN 'pronto'             THEN 'pedido_pronto'
    WHEN 'a_caminho_coleta'   THEN 'pedido_entregador_a_caminho'
    WHEN 'no_estabelecimento' THEN 'pedido_entregador_chegou'
    WHEN 'coletado'           THEN 'pedido_coletado'
    WHEN 'a_caminho_cliente'  THEN 'pedido_em_entrega'
    WHEN 'em_entrega'         THEN 'pedido_em_entrega'
    WHEN 'entregue'           THEN 'pedido_entregue'
    WHEN 'cancelado_cliente'  THEN 'pedido_cancelado'
    WHEN 'cancelado_estab'    THEN 'pedido_cancelado'
    WHEN 'cancelado_sistema'  THEN 'pedido_cancelado'
    ELSE NULL
  END;
  IF v_evento IS NULL THEN RETURN NEW; END IF;

  SELECT u.id INTO v_usuario_id
    FROM public.clientes c JOIN public.usuarios u ON u.id = c.usuario_id
   WHERE c.id = NEW.cliente_id;

  SELECT e.usuario_id INTO v_usuario_estab
    FROM public.estabelecimentos e WHERE e.id = NEW.estabelecimento_id;

  SELECT u.nome_completo_fantasia INTO v_estab_nome
    FROM public.estabelecimentos e JOIN public.usuarios u ON u.id = e.usuario_id
   WHERE e.id = NEW.estabelecimento_id;

  v_variaveis := jsonb_build_object(
    'estabelecimento', COALESCE(v_estab_nome, 'o estabelecimento'),
    'motivo',          COALESCE(NEW.motivo_cancelamento, 'não informado')
  );

  IF NEW.status IN ('a_caminho_coleta','no_estabelecimento','coletado','a_caminho_cliente','em_entrega')
     AND NEW.entregador_id IS NOT NULL THEN
    SELECT u.nome_completo_fantasia INTO v_entregador_nome
      FROM public.entregadores e JOIN public.usuarios u ON u.id = e.usuario_id
     WHERE e.id = NEW.entregador_id;
    v_variaveis := v_variaveis || jsonb_build_object(
      'entregador',     COALESCE(v_entregador_nome, 'o entregador'),
      'tempo_estimado', COALESCE(NEW.tempo_estimado_entrega_min::text, '?')
    );
  END IF;

  -- Notifica cliente
  IF v_usuario_id IS NOT NULL THEN
    PERFORM public.enfileirar_notificacao(
      p_usuario_id    := v_usuario_id,
      p_evento        := v_evento,
      p_entidade_tipo := 'pedido',
      p_entidade_id   := NEW.id,
      p_variaveis     := v_variaveis,
      p_dados_extra   := jsonb_build_object('tela', 'pedido', 'pedido_id', NEW.id)
    );
  END IF;

  -- Notifica estabelecimento quando entregador chega ao balcão
  IF NEW.status = 'no_estabelecimento' AND v_usuario_estab IS NOT NULL THEN
    PERFORM public.enfileirar_notificacao(
      p_usuario_id    := v_usuario_estab,
      p_evento        := 'pedido_entregador_chegou',
      p_entidade_tipo := 'pedido',
      p_entidade_id   := NEW.id,
      p_variaveis     := v_variaveis,
      p_dados_extra   := jsonb_build_object('tela', 'pedido', 'pedido_id', NEW.id)
    );
  END IF;

  RETURN NEW;
END;
$$;

-- ── 9. Templates de notificação ───────────────────────────────────────────────
INSERT INTO public.notificacao_templates (evento, titulo, corpo, canal_android)
VALUES
  ('pedido_entregador_a_caminho','🛵 Entregador a caminho!','{{entregador}} está indo buscar seu pedido no {{estabelecimento}}.','pedidos'),
  ('pedido_entregador_chegou','📍 Entregador chegou!','{{entregador}} chegou ao balcão. Prepare o pedido para retirada.','pedidos'),
  ('pedido_coletado','📦 Pedido coletado!','Seu pedido foi retirado por {{entregador}} e está a caminho!','pedidos')
ON CONFLICT (evento) DO UPDATE SET titulo = EXCLUDED.titulo, corpo = EXCLUDED.corpo, ativo = true;

-- ── 10. RLS ───────────────────────────────────────────────────────────────────
ALTER TABLE public.pedido_logistica ENABLE ROW LEVEL SECURITY;

CREATE POLICY "entregador_ve_propria_logistica" ON public.pedido_logistica FOR SELECT
  USING (pedido_id IN (SELECT p2.id FROM public.pedidos p2 WHERE p2.entregador_id = public.get_entregador_id()));

CREATE POLICY "entregador_atualiza_propria_logistica" ON public.pedido_logistica FOR UPDATE
  USING (pedido_id IN (SELECT p2.id FROM public.pedidos p2 WHERE p2.entregador_id = public.get_entregador_id()));

CREATE POLICY "estab_ve_logistica" ON public.pedido_logistica FOR SELECT
  USING (pedido_id IN (
    SELECT p2.id FROM public.pedidos p2
    JOIN public.estabelecimentos e ON e.id = p2.estabelecimento_id
    WHERE e.usuario_id = auth.uid()
  ));

CREATE POLICY "service_role_logistica_full" ON public.pedido_logistica FOR ALL
  USING (auth.role() = 'service_role');

-- ── 11. Índices ────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_pedido_logistica_pedido ON public.pedido_logistica (pedido_id);
CREATE INDEX IF NOT EXISTS idx_pedidos_novos_status ON public.pedidos (status)
  WHERE status IN ('a_caminho_coleta','no_estabelecimento','coletado','a_caminho_cliente');

-- ── 12. updated_at automático ─────────────────────────────────────────────────
DROP TRIGGER IF EXISTS handle_pedido_logistica_updated_at ON public.pedido_logistica;
CREATE TRIGGER handle_pedido_logistica_updated_at
  BEFORE UPDATE ON public.pedido_logistica
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();
;
