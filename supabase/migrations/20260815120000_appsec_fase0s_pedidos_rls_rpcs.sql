-- ============================================================
-- FASE 0-S — AppSec: RLS de pedidos, RPCs de status/entrega/checkout
-- ============================================================

-- ── 1. Índice de lookup do webhook ──────────────────────────────────────────
CREATE INDEX IF NOT EXISTS pedidos_asaas_payment_id_idx
  ON public.pedidos (asaas_payment_id)
  WHERE asaas_payment_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS rastreamento_pedido_created_idx
  ON public.rastreamento_entregadores (pedido_id, registrado_em DESC);

-- ── 2. View pública de configs não-sensíveis (saques do entregador) ─────────
CREATE OR REPLACE VIEW public.v_plataforma_config_publica
WITH (security_invoker = false)
AS
SELECT chave, valor, tipo
FROM public.plataforma_configuracoes
WHERE chave IN (
  'saque_valor_minimo',
  'saque_tarifa_fixa',
  'saque_limite_diario',
  'taxa_servico_app_pct',
  'tempo_resposta_seg'
);

GRANT SELECT ON public.v_plataforma_config_publica TO authenticated;

-- ── 3. Proteção de colunas financeiras em UPDATE ────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_proteger_colunas_financeiras_pedido()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF auth.role() = 'service_role' THEN
    RETURN NEW;
  END IF;

  IF NEW.subtotal_produtos IS DISTINCT FROM OLD.subtotal_produtos
     OR NEW.taxa_entrega IS DISTINCT FROM OLD.taxa_entrega
     OR NEW.taxa_servico_app IS DISTINCT FROM OLD.taxa_servico_app
     OR NEW.desconto_cupom IS DISTINCT FROM OLD.desconto_cupom
     OR NEW.total IS DISTINCT FROM OLD.total
     OR NEW.pagamento_status IS DISTINCT FROM OLD.pagamento_status
     OR NEW.pagamento_metodo IS DISTINCT FROM OLD.pagamento_metodo
     OR NEW.split_processado IS DISTINCT FROM OLD.split_processado
     OR NEW.financeiro_processado IS DISTINCT FROM OLD.financeiro_processado
     OR NEW.asaas_payment_id IS DISTINCT FROM OLD.asaas_payment_id
     OR NEW.asaas_invoice_url IS DISTINCT FROM OLD.asaas_invoice_url
     OR NEW.valor_liquido IS DISTINCT FROM OLD.valor_liquido
     OR NEW.taxa_asaas IS DISTINCT FROM OLD.taxa_asaas
     OR NEW.taxa_plataforma_calculada IS DISTINCT FROM OLD.taxa_plataforma_calculada
     OR NEW.cliente_id IS DISTINCT FROM OLD.cliente_id
     OR NEW.estabelecimento_id IS DISTINCT FROM OLD.estabelecimento_id
  THEN
    RAISE EXCEPTION 'Colunas financeiras e de pagamento sao imutaveis pelo app.'
      USING ERRCODE = '42501';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_proteger_financeiro_pedido ON public.pedidos;
CREATE TRIGGER trg_proteger_financeiro_pedido
  BEFORE UPDATE ON public.pedidos
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_proteger_colunas_financeiras_pedido();

-- ── 4. Revoga UPDATE amplo em pedidos ───────────────────────────────────────
DROP POLICY IF EXISTS "pedidos_update" ON public.pedidos;
DROP POLICY IF EXISTS "pedidos_update_related" ON public.pedidos;
DROP POLICY IF EXISTS "Entregador avança status de coleta" ON public.pedidos;
DROP POLICY IF EXISTS "Entregadores podem aceitar pedidos prontos" ON public.pedidos;

-- INSERT de pedido só via RPC SECURITY DEFINER
DROP POLICY IF EXISTS "pedidos_insert_cliente" ON public.pedidos;
DROP POLICY IF EXISTS "pedidos_insert_bloqueado" ON public.pedidos;
CREATE POLICY "pedidos_insert_bloqueado"
  ON public.pedidos FOR INSERT
  TO authenticated
  WITH CHECK (false);

DROP POLICY IF EXISTS "pedidos_update_admin" ON public.pedidos;
CREATE POLICY "pedidos_update_admin"
  ON public.pedidos FOR UPDATE
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ── 5. Congela campos de despacho no perfil do entregador ───────────────────
DROP POLICY IF EXISTS "entregadores_update_proprio" ON public.entregadores;
CREATE POLICY "entregadores_update_proprio"
ON public.entregadores FOR UPDATE
USING (usuario_id = auth.uid())
WITH CHECK (
  usuario_id = auth.uid()
  AND status_cadastro IS NOT DISTINCT FROM (
    SELECT e.status_cadastro FROM public.entregadores e WHERE e.usuario_id = auth.uid()
  )
  AND asaas_wallet_id IS NOT DISTINCT FROM (
    SELECT e.asaas_wallet_id FROM public.entregadores e WHERE e.usuario_id = auth.uid()
  )
  AND score_fila IS NOT DISTINCT FROM (
    SELECT e.score_fila FROM public.entregadores e WHERE e.usuario_id = auth.uid()
  )
  AND pedido_atual_id IS NOT DISTINCT FROM (
    SELECT e.pedido_atual_id FROM public.entregadores e WHERE e.usuario_id = auth.uid()
  )
  AND status_despacho IS NOT DISTINCT FROM (
    SELECT e.status_despacho FROM public.entregadores e WHERE e.usuario_id = auth.uid()
  )
);

-- ── 6. RLS INSERT de rastreamento: só pedido ativo do próprio entregador ────
DROP POLICY IF EXISTS "rastreamento_insert" ON public.rastreamento_entregadores;
CREATE POLICY "rastreamento_insert"
ON public.rastreamento_entregadores FOR INSERT
TO authenticated
WITH CHECK (
  entregador_id = public.get_entregador_id()
  AND (
    pedido_id IS NULL
    OR EXISTS (
      SELECT 1 FROM public.pedidos p
      WHERE p.id = rastreamento_entregadores.pedido_id
        AND p.entregador_id = public.get_entregador_id()
        AND p.status IN (
          'a_caminho_coleta','no_estabelecimento','coletado',
          'a_caminho_cliente','em_entrega'
        )
    )
  )
);

-- ── 7. Helper: entregador dono do pedido ────────────────────────────────────
CREATE OR REPLACE FUNCTION public._entregador_dono_pedido(p_pedido_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.pedidos
    WHERE id = p_pedido_id
      AND entregador_id = public.get_entregador_id()
  );
$$;

CREATE OR REPLACE FUNCTION public._estab_dono_pedido(p_pedido_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.pedidos
    WHERE id = p_pedido_id
      AND estabelecimento_id = public.get_estabelecimento_id()
  );
$$;

-- ── 8. Preço canônico de item do carrinho ───────────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_preco_unitario_produto(
  p_produto_id uuid,
  p_tamanho_produto_id uuid DEFAULT NULL,
  p_opcoes jsonb DEFAULT '[]'::jsonb
)
RETURNS numeric
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_produto record;
  v_base numeric := 0;
  v_extras numeric := 0;
  v_grupo jsonb;
  v_item jsonb;
  v_grupo_nome text;
  v_item_nome text;
  v_item_id text;
  v_preco numeric;
BEGIN
  SELECT * INTO v_produto FROM public.produtos WHERE id = p_produto_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'produto_nao_encontrado';
  END IF;

  IF p_tamanho_produto_id IS NOT NULL THEN
    SELECT preco INTO v_base
      FROM public.produto_precos_tamanhos
     WHERE id = p_tamanho_produto_id
       AND produto_id = p_produto_id
       AND ativo = true;
  END IF;

  IF v_base IS NULL OR v_base = 0 THEN
    v_base := COALESCE(v_produto.ultima_mordida_preco, v_produto.preco_promocional, v_produto.preco, 0);
  END IF;

  FOR v_grupo IN SELECT * FROM jsonb_array_elements(COALESCE(p_opcoes, '[]'::jsonb))
  LOOP
    v_grupo_nome := COALESCE(v_grupo->>'nome', v_grupo->>'id', '');
    FOR v_item IN SELECT * FROM jsonb_array_elements(COALESCE(v_grupo->'itens', '[]'::jsonb))
    LOOP
      v_item_nome := COALESCE(v_item->>'nome', '');
      v_item_id := COALESCE(v_item->>'id', '');
      v_preco := 0;
      SELECT COALESCE(
        (i->>'preco')::numeric,
        (i->>'preco_adicional')::numeric,
        0
      ) INTO v_preco
      FROM jsonb_array_elements(COALESCE(v_produto.opcoes, '[]'::jsonb)) g
      CROSS JOIN LATERAL jsonb_array_elements(COALESCE(g->'itens', '[]'::jsonb)) i
      WHERE (COALESCE(g->>'nome', '') = v_grupo_nome OR COALESCE(g->>'id', '') = v_grupo_nome)
        AND (
          (v_item_id <> '' AND COALESCE(i->>'id', '') = v_item_id)
          OR COALESCE(i->>'nome', '') = v_item_nome
        )
      LIMIT 1;

      v_extras := v_extras + COALESCE(v_preco, 0);
    END LOOP;
  END LOOP;

  RETURN ROUND(COALESCE(v_base, 0) + COALESCE(v_extras, 0), 2);
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_validar_preco_item_carrinho()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_preco numeric;
BEGIN
  v_preco := public.fn_preco_unitario_produto(
    NEW.produto_id,
    NEW.tamanho_produto_id,
    COALESCE(NEW.opcoes_selecionadas, '[]'::jsonb)
  );
  NEW.preco_unitario := v_preco;
  NEW.subtotal := ROUND(v_preco * NEW.quantidade, 2);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validar_preco_item_carrinho ON public.itens_carrinho;
CREATE TRIGGER trg_validar_preco_item_carrinho
  BEFORE INSERT OR UPDATE ON public.itens_carrinho
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_validar_preco_item_carrinho();

-- ── 9. Checkout server-side ─────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.criar_pedido_validado(
  p_estabelecimento_id uuid,
  p_endereco_entrega_id uuid,
  p_pagamento_metodo text,
  p_cupom_codigo text DEFAULT NULL,
  p_observacao_geral text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cliente_id uuid;
  v_carrinho record;
  v_item record;
  v_endereco record;
  v_estab record;
  v_cupom record;
  v_itens jsonb := '[]'::jsonb;
  v_subtotal numeric := 0;
  v_preco numeric;
  v_distancia numeric := 0;
  v_taxa_pct numeric := 0.05;
  v_taxa_servico numeric := 0;
  v_desconto numeric := 0;
  v_financeiro jsonb;
  v_pedido_id uuid;
  v_usos_cliente integer;
  v_snapshot jsonb;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Sessao obrigatoria.');
  END IF;

  SELECT id INTO v_cliente_id
    FROM public.clientes
   WHERE usuario_id = auth.uid();
  IF v_cliente_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Perfil de cliente nao encontrado.');
  END IF;

  IF p_pagamento_metodo NOT IN ('pix', 'cartao_credito', 'cartao_debito', 'dinheiro') THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Metodo de pagamento invalido.');
  END IF;

  SELECT * INTO v_estab
    FROM public.estabelecimentos
   WHERE id = p_estabelecimento_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Estabelecimento nao encontrado.');
  END IF;

  SELECT * INTO v_endereco
    FROM public.enderecos_clientes
   WHERE id = p_endereco_entrega_id
     AND cliente_id = v_cliente_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Endereco nao pertence ao cliente.');
  END IF;

  SELECT * INTO v_carrinho
    FROM public.carrinhos
   WHERE cliente_id = v_cliente_id
     AND estabelecimento_id = p_estabelecimento_id
   ORDER BY updated_at DESC
   LIMIT 1;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Carrinho vazio.');
  END IF;

  FOR v_item IN
    SELECT ic.*, p.nome AS produto_nome, p.ativo, p.disponivel
      FROM public.itens_carrinho ic
      JOIN public.produtos p ON p.id = ic.produto_id
     WHERE ic.carrinho_id = v_carrinho.id
  LOOP
    IF v_item.ativo IS NOT TRUE OR v_item.disponivel IS NOT TRUE THEN
      RETURN jsonb_build_object('ok', false, 'erro', 'Produto indisponivel: ' || v_item.produto_nome);
    END IF;
    v_preco := public.fn_preco_unitario_produto(
      v_item.produto_id, v_item.tamanho_produto_id, v_item.opcoes_selecionadas
    );
    v_subtotal := v_subtotal + ROUND(v_preco * v_item.quantidade, 2);
    v_itens := v_itens || jsonb_build_array(jsonb_build_object(
      'produto_id', v_item.produto_id,
      'nome_produto', v_item.produto_nome,
      'produto_nome', v_item.produto_nome,
      'quantidade', v_item.quantidade,
      'preco_unitario', v_preco,
      'preco_unitario_final', v_preco,
      'opcoes_selecionadas', COALESCE(v_item.opcoes_selecionadas, '[]'::jsonb),
      'observacao', v_item.observacao,
      'tamanho_produto_id', v_item.tamanho_produto_id,
      'tamanho_produto_nome', v_item.tamanho_produto_nome,
      'subtotal', ROUND(v_preco * v_item.quantidade, 2)
    ));
  END LOOP;

  IF jsonb_array_length(v_itens) = 0 THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Carrinho vazio.');
  END IF;

  IF v_estab.latitude IS NOT NULL AND v_endereco.latitude IS NOT NULL THEN
    v_distancia := ROUND((111.045 * degrees(acos(LEAST(1.0,
      cos(radians(v_estab.latitude)) * cos(radians(v_endereco.latitude))
        * cos(radians(v_endereco.longitude) - radians(v_estab.longitude))
        + sin(radians(v_estab.latitude)) * sin(radians(v_endereco.latitude))
    ))))::numeric, 2);
  END IF;

  SELECT COALESCE(valor::numeric, 5) / 100 INTO v_taxa_pct
    FROM public.plataforma_configuracoes
   WHERE chave = 'taxa_servico_app_pct';
  v_taxa_servico := ROUND(v_subtotal * COALESCE(v_taxa_pct, 0.05), 2);

  IF p_cupom_codigo IS NOT NULL AND btrim(p_cupom_codigo) <> '' THEN
    SELECT * INTO v_cupom
      FROM public.cupons
     WHERE upper(codigo) = upper(btrim(p_cupom_codigo))
       AND ativo = true
     FOR UPDATE;
    IF NOT FOUND THEN
      RETURN jsonb_build_object('ok', false, 'erro', 'Cupom nao encontrado ou inativo.');
    END IF;
    IF v_cupom.estabelecimento_id IS NOT NULL
       AND v_cupom.estabelecimento_id <> p_estabelecimento_id THEN
      RETURN jsonb_build_object('ok', false, 'erro', 'Cupom nao vale neste estabelecimento.');
    END IF;
    IF v_cupom.data_inicio IS NOT NULL AND now() < v_cupom.data_inicio THEN
      RETURN jsonb_build_object('ok', false, 'erro', 'Cupom ainda nao vigente.');
    END IF;
    IF v_cupom.data_fim IS NOT NULL AND now() > v_cupom.data_fim THEN
      RETURN jsonb_build_object('ok', false, 'erro', 'Cupom expirado.');
    END IF;
    IF v_cupom.limite_usos IS NOT NULL AND COALESCE(v_cupom.usos_atuais, 0) >= v_cupom.limite_usos THEN
      RETURN jsonb_build_object('ok', false, 'erro', 'Cupom esgotado.');
    END IF;
    IF COALESCE(v_cupom.valor_minimo_pedido, 0) > v_subtotal THEN
      RETURN jsonb_build_object('ok', false, 'erro', 'Pedido abaixo do minimo do cupom.');
    END IF;
    IF v_cupom.limite_usos_por_cliente IS NOT NULL THEN
      SELECT COUNT(*) INTO v_usos_cliente
        FROM public.cupons_usos
       WHERE cupom_id = v_cupom.id AND cliente_id = v_cliente_id;
      IF v_usos_cliente >= v_cupom.limite_usos_por_cliente THEN
        RETURN jsonb_build_object('ok', false, 'erro', 'Limite de usos deste cupom atingido.');
      END IF;
    END IF;
  END IF;

  v_financeiro := public.calcular_financeiro_pedido(
    v_subtotal,
    v_distancia,
    p_estabelecimento_id,
    0,
    v_taxa_servico
  );

  IF v_cupom.id IS NOT NULL THEN
    v_desconto := CASE v_cupom.tipo
      WHEN 'percentual' THEN ROUND(v_subtotal * v_cupom.valor / 100, 2)
      WHEN 'valor_fixo' THEN LEAST(v_cupom.valor, v_subtotal)
      WHEN 'entrega_gratis' THEN COALESCE((v_financeiro->>'taxa_entrega')::numeric, 0)
      ELSE 0
    END;
    v_financeiro := public.calcular_financeiro_pedido(
      v_subtotal,
      v_distancia,
      p_estabelecimento_id,
      v_desconto,
      v_taxa_servico
    );
  END IF;

  v_snapshot := jsonb_build_object(
    'id', v_endereco.id,
    'cep', v_endereco.cep,
    'logradouro', v_endereco.logradouro,
    'numero', v_endereco.numero,
    'complemento', v_endereco.complemento,
    'bairro', v_endereco.bairro,
    'cidade', v_endereco.cidade,
    'estado', v_endereco.estado,
    'latitude', v_endereco.latitude,
    'longitude', v_endereco.longitude,
    'ponto_referencia', v_endereco.ponto_referencia,
    'instrucoes_entrega', v_endereco.instrucoes_entrega
  );

  INSERT INTO public.pedidos (
    estabelecimento_id, cliente_id, itens,
    subtotal_produtos, taxa_entrega, taxa_servico_app, desconto_cupom, total,
    pagamento_metodo, pagamento_status, status,
    endereco_entrega_id, endereco_entrega_snapshot, distancia_km,
    cupom_id, observacao_geral
  ) VALUES (
    p_estabelecimento_id, v_cliente_id, v_itens,
    v_subtotal,
    (v_financeiro->>'taxa_entrega')::numeric,
    v_taxa_servico,
    NULLIF(v_desconto, 0),
    (v_financeiro->>'valor_total')::numeric,
    p_pagamento_metodo, 'pendente', 'pendente',
    p_endereco_entrega_id, v_snapshot, v_distancia,
    v_cupom.id,
    NULLIF(left(btrim(COALESCE(p_observacao_geral, '')), 500), '')
  )
  RETURNING id INTO v_pedido_id;

  IF v_cupom.id IS NOT NULL THEN
    INSERT INTO public.cupons_usos (cupom_id, cliente_id, pedido_id)
    VALUES (v_cupom.id, v_cliente_id, v_pedido_id);
    UPDATE public.cupons
       SET usos_atuais = COALESCE(usos_atuais, 0) + 1
     WHERE id = v_cupom.id;
  END IF;

  DELETE FROM public.carrinhos WHERE id = v_carrinho.id;

  RETURN jsonb_build_object(
    'ok', true,
    'pedido_id', v_pedido_id,
    'subtotal_produtos', v_subtotal,
    'taxa_entrega', (v_financeiro->>'taxa_entrega')::numeric,
    'taxa_servico_app', v_taxa_servico,
    'desconto_cupom', v_desconto,
    'total', (v_financeiro->>'valor_total')::numeric,
    'distancia_km', v_distancia
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.criar_pedido_validado(uuid, uuid, text, text, text) TO authenticated;

-- ── 10. RPCs de status do estabelecimento ───────────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_atualizar_status_pedido_estab(
  p_pedido_id uuid,
  p_novo_status text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_pedido public.pedidos%ROWTYPE;
  v_permitido boolean := false;
BEGIN
  IF NOT public._estab_dono_pedido(p_pedido_id) AND NOT public.is_admin() THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Pedido nao pertence a este estabelecimento.');
  END IF;

  SELECT * INTO v_pedido FROM public.pedidos WHERE id = p_pedido_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Pedido nao encontrado.');
  END IF;

  v_permitido := CASE v_pedido.status
    WHEN 'pendente' THEN p_novo_status IN ('confirmado', 'cancelado_estab')
    WHEN 'confirmado' THEN p_novo_status IN ('preparando', 'cancelado_estab')
    WHEN 'preparando' THEN p_novo_status IN ('pronto', 'cancelado_estab')
    WHEN 'pronto' THEN p_novo_status IN ('cancelado_estab')
    ELSE false
  END;

  IF NOT v_permitido THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Transicao de status nao permitida.',
      'status_atual', v_pedido.status, 'novo_status', p_novo_status);
  END IF;

  UPDATE public.pedidos
     SET status = p_novo_status, updated_at = now()
   WHERE id = p_pedido_id;

  RETURN jsonb_build_object('ok', true, 'status', p_novo_status);
END;
$$;

GRANT EXECUTE ON FUNCTION public.fn_atualizar_status_pedido_estab(uuid, text) TO authenticated;

-- ── 11. RPCs do entregador ──────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_atualizar_localizacao_entrega(
  p_pedido_id uuid,
  p_lat numeric,
  p_lng numeric,
  p_velocidade_kmh numeric DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_entregador_id uuid := public.get_entregador_id();
BEGIN
  IF NOT public._entregador_dono_pedido(p_pedido_id) THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Pedido nao atribuido a este entregador.');
  END IF;

  INSERT INTO public.entregador_localizacao_atual (entregador_id, latitude, longitude, velocidade_kmh, updated_at)
  VALUES (v_entregador_id, p_lat, p_lng, p_velocidade_kmh, now())
  ON CONFLICT (entregador_id) DO UPDATE
    SET latitude = EXCLUDED.latitude,
        longitude = EXCLUDED.longitude,
        velocidade_kmh = EXCLUDED.velocidade_kmh,
        updated_at = now();

  INSERT INTO public.rastreamento_entregadores (entregador_id, pedido_id, latitude, longitude, velocidade_kmh)
  VALUES (v_entregador_id, p_pedido_id, p_lat, p_lng, p_velocidade_kmh);

  UPDATE public.pedidos
     SET localizacao_entregador = jsonb_build_object('lat', p_lat, 'lng', p_lng),
         updated_at = now()
   WHERE id = p_pedido_id;

  RETURN jsonb_build_object('ok', true);
END;
$$;

GRANT EXECUTE ON FUNCTION public.fn_atualizar_localizacao_entrega(uuid, numeric, numeric, numeric) TO authenticated;

CREATE OR REPLACE FUNCTION public.fn_iniciar_coleta(p_pedido_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public._entregador_dono_pedido(p_pedido_id) THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Pedido nao atribuido a este entregador.');
  END IF;

  UPDATE public.pedidos
     SET status = 'a_caminho_coleta',
         a_caminho_coleta_em = COALESCE(a_caminho_coleta_em, now()),
         updated_at = now()
   WHERE id = p_pedido_id
     AND status IN ('pronto', 'confirmado', 'a_caminho_coleta');

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Status invalido para iniciar coleta.');
  END IF;

  RETURN jsonb_build_object('ok', true, 'status', 'a_caminho_coleta');
END;
$$;

GRANT EXECUTE ON FUNCTION public.fn_iniciar_coleta(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.fn_checkin_estabelecimento(
  p_pedido_id uuid,
  p_lat numeric DEFAULT NULL,
  p_lng numeric DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_codigo text;
  v_dist numeric;
  v_estab_lat numeric;
  v_estab_lng numeric;
BEGIN
  IF NOT public._entregador_dono_pedido(p_pedido_id) THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Pedido nao atribuido a este entregador.');
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.pedidos
    WHERE id = p_pedido_id
      AND status IN ('a_caminho_coleta', 'confirmado', 'pronto', 'no_estabelecimento')
  ) THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Status invalido para check-in');
  END IF;

  IF p_lat IS NOT NULL AND p_lng IS NOT NULL THEN
    SELECT e.latitude, e.longitude INTO v_estab_lat, v_estab_lng
      FROM public.pedidos p2
      JOIN public.estabelecimentos e ON e.id = p2.estabelecimento_id
     WHERE p2.id = p_pedido_id;
    IF v_estab_lat IS NOT NULL THEN
      v_dist := ROUND((111045 * degrees(acos(LEAST(1.0,
        cos(radians(v_estab_lat)) * cos(radians(p_lat))
          * cos(radians(p_lng) - radians(v_estab_lng))
          + sin(radians(v_estab_lat)) * sin(radians(p_lat))
      ))))::numeric, 0);
    END IF;
  END IF;

  UPDATE public.pedido_logistica pl
     SET chegou_lat = p_lat,
         chegou_lng = p_lng,
         distancia_chegada_metros = v_dist,
         updated_at = now()
   WHERE pl.pedido_id = p_pedido_id
   RETURNING pl.codigo_coleta_balcao INTO v_codigo;

  UPDATE public.pedidos
     SET status = 'no_estabelecimento',
         chegou_estabelecimento_em = COALESCE(chegou_estabelecimento_em, now()),
         updated_at = now()
   WHERE id = p_pedido_id;

  RETURN jsonb_build_object('ok', true, 'codigo_coleta_balcao', v_codigo, 'distancia_metros', v_dist);
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_validar_codigo_balcao(
  p_pedido_id uuid,
  p_codigo text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_log record;
  v_max_tent constant integer := 5;
  v_esperado text;
BEGIN
  IF NOT public._entregador_dono_pedido(p_pedido_id) THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Pedido nao atribuido a este entregador.');
  END IF;

  SELECT * INTO v_log FROM public.pedido_logistica pl WHERE pl.pedido_id = p_pedido_id;
  SELECT COALESCE(pl.codigo_coleta_balcao, p.codigo_coleta_balcao)
    INTO v_esperado
    FROM public.pedidos p
    LEFT JOIN public.pedido_logistica pl ON pl.pedido_id = p.id
   WHERE p.id = p_pedido_id;

  IF v_esperado IS NULL OR btrim(v_esperado) = '' THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Codigo de coleta nao definido.');
  END IF;

  IF COALESCE(v_log.codigo_coleta_validado, false) THEN
    RETURN jsonb_build_object('ok', true, 'mensagem', 'Codigo ja validado');
  END IF;

  IF v_log.id IS NOT NULL AND COALESCE(v_log.codigo_coleta_tentativas, 0) >= v_max_tent THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Limite de tentativas atingido');
  END IF;

  IF v_log.id IS NOT NULL THEN
    UPDATE public.pedido_logistica
       SET codigo_coleta_tentativas = codigo_coleta_tentativas + 1, updated_at = now()
     WHERE pedido_id = p_pedido_id;
  END IF;

  IF upper(btrim(v_esperado)) <> upper(btrim(p_codigo)) THEN
    RETURN jsonb_build_object(
      'ok', false,
      'erro', 'Codigo incorreto',
      'tentativas_restantes', v_max_tent - COALESCE(v_log.codigo_coleta_tentativas, 0) - 1
    );
  END IF;

  IF v_log.id IS NOT NULL THEN
    UPDATE public.pedido_logistica
       SET codigo_coleta_validado = true,
           codigo_coleta_validado_em = now(),
           validado_por_tipo = 'entregador',
           updated_at = now()
     WHERE pedido_id = p_pedido_id;
  END IF;

  UPDATE public.pedidos
     SET status = 'coletado', coletado_em = COALESCE(coletado_em, now()), updated_at = now()
   WHERE id = p_pedido_id;

  RETURN jsonb_build_object('ok', true, 'mensagem', 'Pedido coletado com sucesso!');
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_saiu_para_cliente(p_pedido_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public._entregador_dono_pedido(p_pedido_id) THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Pedido nao atribuido a este entregador.');
  END IF;

  UPDATE public.pedidos
     SET status = 'em_entrega',
         a_caminho_cliente_em = COALESCE(a_caminho_cliente_em, now()),
         em_entrega_em = COALESCE(em_entrega_em, now()),
         updated_at = now()
   WHERE id = p_pedido_id
     AND status IN ('coletado', 'no_estabelecimento', 'a_caminho_cliente');

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Pedido precisa estar coletado primeiro');
  END IF;

  RETURN jsonb_build_object('ok', true, 'status', 'em_entrega');
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_confirmar_entrega(
  p_pedido_id uuid,
  p_codigo text,
  p_foto_path text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_pedido public.pedidos%ROWTYPE;
  v_entregador_id uuid := public.get_entregador_id();
BEGIN
  IF NOT public._entregador_dono_pedido(p_pedido_id) THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Pedido nao atribuido a este entregador.');
  END IF;

  SELECT * INTO v_pedido FROM public.pedidos WHERE id = p_pedido_id FOR UPDATE;
  IF v_pedido.status NOT IN ('em_entrega', 'a_caminho_cliente', 'coletado') THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Status invalido para confirmar entrega.');
  END IF;

  IF v_pedido.codigo_confirmacao_entrega IS NULL
     OR upper(btrim(v_pedido.codigo_confirmacao_entrega)) <> upper(btrim(COALESCE(p_codigo, ''))) THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Codigo de entrega incorreto.');
  END IF;

  UPDATE public.pedidos
     SET status = 'entregue',
         entregue_em = COALESCE(entregue_em, now()),
         updated_at = now()
   WHERE id = p_pedido_id;

  UPDATE public.entregadores
     SET status_despacho = 'livre',
         pedido_atual_id = NULL,
         ultima_entrega_em = now(),
         total_entregas = COALESCE(total_entregas, 0) + 1,
         updated_at = now()
   WHERE id = v_entregador_id;

  RETURN jsonb_build_object('ok', true, 'status', 'entregue', 'foto_path', p_foto_path);
END;
$$;

GRANT EXECUTE ON FUNCTION public.fn_checkin_estabelecimento(uuid, numeric, numeric) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_validar_codigo_balcao(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_saiu_para_cliente(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_confirmar_entrega(uuid, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_preco_unitario_produto(uuid, uuid, jsonb) TO authenticated;
