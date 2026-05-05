
-- ============================================================
-- SISTEMA DE DESPACHO COM FILA AUTOMÁTICA
-- Ôpadoca Express
-- ============================================================
-- Fluxo:
-- 1. pedido.status = 'pronto' → trigger chama fn_iniciar_despacho()
-- 2. fn_iniciar_despacho() seleciona melhor entregador por score
-- 3. Insere em despacho_pedidos (status=aguardando)
-- 4. trigger trg_notif_despacho já enfileira push automático ✅
-- 5. Entregador rejeita/expira → fn_proximo_entregador_fila()
-- 6. Repete até max_tentativas ou aceite
-- ============================================================

-- ── 1. Função principal: seleciona melhor entregador e cria despacho ──────
CREATE OR REPLACE FUNCTION public.fn_iniciar_despacho(p_pedido_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_estab_lat       numeric;
  v_estab_lng       numeric;
  v_raio_inicial    numeric;
  v_raio_expansao   numeric;
  v_raio_maximo     numeric;
  v_tempo_resposta  integer;
  v_max_tent        integer;
  v_tentativa       integer;
  v_entregador      record;
  v_despacho_id     uuid;
  v_raio_atual      numeric;
  v_total_tent      integer;
BEGIN
  -- Busca coordenadas do estabelecimento
  SELECT e.latitude, e.longitude
    INTO v_estab_lat, v_estab_lng
    FROM public.pedidos p
    JOIN public.estabelecimentos e ON e.id = p.estabelecimento_id
   WHERE p.id = p_pedido_id;

  IF v_estab_lat IS NULL THEN
    RAISE WARNING '[despacho] Pedido % sem coordenadas do estabelecimento', p_pedido_id;
    RETURN NULL;
  END IF;

  -- Lê configurações da plataforma
  SELECT COALESCE(valor::numeric, 3.0) INTO v_raio_inicial
    FROM public.plataforma_configuracoes WHERE chave = 'raio_busca_inicial_km';
  SELECT COALESCE(valor::numeric, 1.5) INTO v_raio_expansao
    FROM public.plataforma_configuracoes WHERE chave = 'raio_busca_expansao_km';
  SELECT COALESCE(valor::numeric, 10.0) INTO v_raio_maximo
    FROM public.plataforma_configuracoes WHERE chave = 'raio_busca_maximo_km';
  SELECT COALESCE(valor::integer, 30) INTO v_tempo_resposta
    FROM public.plataforma_configuracoes WHERE chave = 'tempo_resposta_seg';
  SELECT COALESCE(valor::integer, 10) INTO v_max_tent
    FROM public.plataforma_configuracoes WHERE chave = 'max_tentativas';

  -- Conta tentativas já feitas para este pedido
  SELECT COUNT(*) INTO v_total_tent
    FROM public.despacho_pedidos
   WHERE pedido_id = p_pedido_id;

  IF v_total_tent >= v_max_tent THEN
    -- Esgotou tentativas: volta para fila manual do estabelecimento
    UPDATE public.pedidos
       SET status = 'pronto',
           updated_at = now()
     WHERE id = p_pedido_id;
    RAISE WARNING '[despacho] Pedido % esgotou % tentativas, retornou para fila manual', p_pedido_id, v_max_tent;
    RETURN NULL;
  END IF;

  v_tentativa  := v_total_tent + 1;
  -- Raio cresce a cada tentativa para ampliar a busca
  v_raio_atual := LEAST(v_raio_inicial + (v_raio_expansao * (v_tentativa - 1)), v_raio_maximo);

  -- Seleciona o melhor entregador disponível
  -- Critério híbrido: distância (40%) + avaliação (30%) + score_fila (30%)
  -- Exclui entregadores que já recusaram/expiraram neste pedido
  SELECT
    e.id,
    e.usuario_id,
    e.avaliacao_media,
    e.score_fila,
    -- Distância em km usando fórmula de Haversine (aproximação plana para curtas distâncias)
    ROUND(
      111.045 * degrees(acos(
        LEAST(1.0, cos(radians(v_estab_lat))
          * cos(radians(e.latitude))
          * cos(radians(e.longitude) - radians(v_estab_lng))
          + sin(radians(v_estab_lat))
          * sin(radians(e.latitude))
        )
      ))::numeric, 2
    ) AS distancia_km,
    -- Score composto (menor distância = melhor, maior avaliação = melhor, maior score_fila = melhor)
    (
      (1.0 / GREATEST(1.0, 111.045 * degrees(acos(
        LEAST(1.0, cos(radians(v_estab_lat))
          * cos(radians(e.latitude))
          * cos(radians(e.longitude) - radians(v_estab_lng))
          + sin(radians(v_estab_lat))
          * sin(radians(e.latitude))
        )
      )))) * 0.40
      + (COALESCE(e.avaliacao_media, 5.0) / 5.0) * 0.30
      + (LEAST(e.score_fila, 100) / 100.0) * 0.30
    ) AS score_final
  INTO v_entregador
  FROM public.entregadores e
  WHERE
    e.status_online     = true
    AND e.status_despacho = 'livre'
    AND e.status_cadastro = 'ativo'
    AND e.latitude       IS NOT NULL
    AND e.longitude      IS NOT NULL
    -- Dentro do raio de busca expandido
    AND (111.045 * degrees(acos(
          LEAST(1.0, cos(radians(v_estab_lat))
            * cos(radians(e.latitude))
            * cos(radians(e.longitude) - radians(v_estab_lng))
            + sin(radians(v_estab_lat))
            * sin(radians(e.latitude))
          )
        ))) <= v_raio_atual
    -- Não recusou/expirou neste pedido antes
    AND e.id NOT IN (
      SELECT entregador_id FROM public.despacho_pedidos
       WHERE pedido_id = p_pedido_id
         AND status IN ('rejeitado', 'expirado')
    )
  ORDER BY score_final DESC
  LIMIT 1;

  IF v_entregador.id IS NULL THEN
    -- Nenhum entregador disponível neste raio, agenda retry
    RAISE WARNING '[despacho] Nenhum entregador disponível em % km para pedido %', v_raio_atual, p_pedido_id;
    RETURN NULL;
  END IF;

  -- Marca entregador como aguardando aceite
  UPDATE public.entregadores
     SET status_despacho = 'aguardando_aceite',
         updated_at = now()
   WHERE id = v_entregador.id;

  -- Insere o despacho (trigger trg_notif_despacho enviará o push automaticamente)
  INSERT INTO public.despacho_pedidos (
    pedido_id, entregador_id, tentativa, status,
    distancia_km, score_no_momento,
    ofertado_em, expira_em,
    metadata
  ) VALUES (
    p_pedido_id,
    v_entregador.id,
    v_tentativa,
    'aguardando',
    v_entregador.distancia_km,
    v_entregador.score_final,
    now(),
    now() + (v_tempo_resposta || ' seconds')::interval,
    jsonb_build_object(
      'raio_busca_km', v_raio_atual,
      'total_candidatos', 1
    )
  )
  RETURNING id INTO v_despacho_id;

  RAISE LOG '[despacho] Pedido % → entregador % (tentativa %, dist %.1f km, raio %.1f km)',
    p_pedido_id, v_entregador.id, v_tentativa, v_entregador.distancia_km, v_raio_atual;

  RETURN v_despacho_id;
END;
$$;

-- ── 2. Função chamada quando entregador rejeita ou expira → próximo da fila ──
CREATE OR REPLACE FUNCTION public.fn_proximo_entregador_fila()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_max_tentativas integer;
  v_total_tent     integer;
BEGIN
  -- Só age quando status muda para rejeitado ou expirado
  IF NEW.status NOT IN ('rejeitado', 'expirado') THEN
    RETURN NEW;
  END IF;
  IF OLD.status = NEW.status THEN
    RETURN NEW;
  END IF;

  -- Libera entregador de volta para livre
  UPDATE public.entregadores
     SET status_despacho = 'livre',
         updated_at = now()
   WHERE id = NEW.entregador_id
     AND status_despacho = 'aguardando_aceite';

  -- Aumenta score_fila do entregador (mais tempo sem pedido = maior prioridade na próxima vez)
  UPDATE public.entregadores
     SET score_fila = LEAST(score_fila + 2, 100)
   WHERE id = NEW.entregador_id;

  -- Lê max_tentativas
  SELECT COALESCE(valor::integer, 10) INTO v_max_tentativas
    FROM public.plataforma_configuracoes WHERE chave = 'max_tentativas';

  -- Conta total de tentativas para este pedido
  SELECT COUNT(*) INTO v_total_tent
    FROM public.despacho_pedidos
   WHERE pedido_id = NEW.pedido_id;

  IF v_total_tent >= v_max_tentativas THEN
    -- Esgotou: pedido volta para status 'pronto' sem entregador (fila manual)
    RAISE LOG '[despacho] Pedido % esgotou tentativas, voltando para fila manual', NEW.pedido_id;
    RETURN NEW;
  END IF;

  -- Tenta o próximo entregador imediatamente
  PERFORM public.fn_iniciar_despacho(NEW.pedido_id);

  RETURN NEW;
END;
$$;

-- ── 3. Trigger: ao rejeitar/expirar → chama próximo da fila ─────────────────
DROP TRIGGER IF EXISTS trg_despacho_proximo_entregador ON public.despacho_pedidos;
CREATE TRIGGER trg_despacho_proximo_entregador
  AFTER UPDATE OF status ON public.despacho_pedidos
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_proximo_entregador_fila();

-- ── 4. Trigger: quando pedido fica 'pronto' → inicia despacho automático ────
CREATE OR REPLACE FUNCTION public.trg_pedido_pronto_despacho()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Só dispara quando status muda para 'pronto' e ainda não tem entregador
  IF NEW.status = 'pronto'
     AND OLD.status IS DISTINCT FROM 'pronto'
     AND NEW.entregador_id IS NULL
  THEN
    PERFORM public.fn_iniciar_despacho(NEW.id);
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_pedido_pronto_inicia_despacho ON public.pedidos;
CREATE TRIGGER trg_pedido_pronto_inicia_despacho
  AFTER UPDATE OF status ON public.pedidos
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_pedido_pronto_despacho();

-- ── 5. Função para expirar despachos vencidos (chamada pela Edge Function) ──
CREATE OR REPLACE FUNCTION public.fn_expirar_despachos_vencidos()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_count integer := 0;
  v_row   record;
BEGIN
  FOR v_row IN
    SELECT id, pedido_id, entregador_id
    FROM public.despacho_pedidos
    WHERE status = 'aguardando'
      AND expira_em < now()
  LOOP
    UPDATE public.despacho_pedidos
       SET status = 'expirado', respondido_em = now()
     WHERE id = v_row.id;
    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END;
$$;

-- ── 6. Índices para performance da fila ──────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_despacho_pedido_status
  ON public.despacho_pedidos (pedido_id, status);

CREATE INDEX IF NOT EXISTS idx_despacho_expira
  ON public.despacho_pedidos (expira_em)
  WHERE status = 'aguardando';

CREATE INDEX IF NOT EXISTS idx_entregadores_disponivel
  ON public.entregadores (status_online, status_despacho, latitude, longitude)
  WHERE status_online = true AND status_despacho = 'livre';

-- ── 7. Garante que template 'despacho_nova_oferta' existe e está correto ─────
INSERT INTO public.notificacao_templates (evento, titulo, corpo, canal_android, dados_extras)
VALUES (
  'despacho_nova_oferta',
  '🛵 Nova entrega disponível!',
  '{{estabelecimento}} — {{distancia_km}} km de você. Aceitar em {{tempo_resposta}}s',
  'pedidos',
  '{"prioridade": "alta", "tela": "oferta_entrega"}'::jsonb
)
ON CONFLICT (evento) DO UPDATE SET
  titulo       = EXCLUDED.titulo,
  corpo        = EXCLUDED.corpo,
  canal_android = EXCLUDED.canal_android,
  dados_extras = EXCLUDED.dados_extras,
  ativo        = true;

INSERT INTO public.notificacao_templates (evento, titulo, corpo, canal_android)
VALUES (
  'despacho_expirado',
  '⏰ Oferta expirada',
  'O tempo para aceitar a entrega do {{estabelecimento}} esgotou.',
  'pedidos'
)
ON CONFLICT (evento) DO NOTHING;
;
