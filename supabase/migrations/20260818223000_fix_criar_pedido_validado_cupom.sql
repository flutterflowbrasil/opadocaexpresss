-- Corrige 55000: record "v_cupom" is not assigned yet
-- Checkout sem cupom acessava v_cupom.id em RECORD nao inicializado.

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
  v_cupom_id uuid := NULL;
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
    v_cupom_id := v_cupom.id;
  END IF;

  v_financeiro := public.calcular_financeiro_pedido(
    v_subtotal,
    v_distancia,
    p_estabelecimento_id,
    0,
    v_taxa_servico
  );

  IF v_cupom_id IS NOT NULL THEN
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
    v_cupom_id,
    NULLIF(left(btrim(COALESCE(p_observacao_geral, '')), 500), '')
  )
  RETURNING id INTO v_pedido_id;

  IF v_cupom_id IS NOT NULL THEN
    INSERT INTO public.cupons_usos (cupom_id, cliente_id, pedido_id)
    VALUES (v_cupom_id, v_cliente_id, v_pedido_id);
    UPDATE public.cupons
       SET usos_atuais = COALESCE(usos_atuais, 0) + 1
     WHERE id = v_cupom_id;
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
