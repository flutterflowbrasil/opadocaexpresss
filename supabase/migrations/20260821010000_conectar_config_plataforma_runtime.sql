-- Liga chaves de plataforma_configuracoes ao runtime (entrega, cupons, cancelamento, despacho, view publica).
-- Nao altera a formula de comissao Asaas (entrega_base_* ja precifica o checkout).

-- ── Helpers ─────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_cfg_valor(p_chave text, p_default text DEFAULT NULL)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT valor FROM public.plataforma_configuracoes WHERE chave = p_chave LIMIT 1),
    p_default
  );
$$;

CREATE OR REPLACE FUNCTION public.fn_cfg_bool(p_chave text, p_default boolean DEFAULT true)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT CASE lower(COALESCE(public.fn_cfg_valor(p_chave, CASE WHEN p_default THEN 'true' ELSE 'false' END), ''))
    WHEN 'false' THEN false
    WHEN '0' THEN false
    WHEN 'nao' THEN false
    WHEN 'off' THEN false
    ELSE COALESCE(p_default, true)
  END;
$$;

CREATE OR REPLACE FUNCTION public.fn_cfg_num(p_chave text, p_default numeric DEFAULT 0)
RETURNS numeric
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(NULLIF(public.fn_cfg_valor(p_chave, p_default::text), '')::numeric, p_default);
$$;

REVOKE ALL ON FUNCTION public.fn_cfg_valor(text, text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fn_cfg_bool(text, boolean) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fn_cfg_num(text, numeric) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.fn_cfg_valor(text, text) TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_cfg_bool(text, boolean) TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_cfg_num(text, numeric) TO service_role;

-- ── View publica (gates + entrega + saques). Sem secrets. ───────────────────
CREATE OR REPLACE VIEW public.v_plataforma_config_publica
WITH (security_invoker = false)
AS
SELECT chave, valor, tipo
FROM public.plataforma_configuracoes
WHERE chave IN (
  'saque_valor_minimo',
  'saque_tarifa_fixa',
  'saque_limite_diario',
  'saque_pix_instantaneo',
  'taxa_servico_app_pct',
  'tempo_resposta_seg',
  'entrega_base_km',
  'entrega_base_valor',
  'entrega_valor_km_excedente',
  'raio_maximo_km',
  'pedido_minimo',
  'entrega_gratis_acima_de',
  'permite_entrega_gratis',
  'tempo_medio_preparo_min',
  'tempo_medio_entrega_min',
  'plataforma_nome',
  'plataforma_ativa',
  'modo_manutencao',
  'versao_minima_app',
  'permite_cadastro_estab',
  'permite_cadastro_entregador',
  'suporte_email',
  'suporte_whatsapp',
  'cupons_ativos',
  'permite_percentual',
  'permite_valor_fixo',
  'valor_minimo_padrao',
  'limite_por_cliente',
  'limite_total_campanha'
);

GRANT SELECT ON public.v_plataforma_config_publica TO anon, authenticated;

-- ── Config financeira: entrega gratis entra no calc sem mudar comissao ──────
CREATE OR REPLACE FUNCTION public.fn_get_config_financeira()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cfg jsonb := '{}'::jsonb;
BEGIN
  SELECT COALESCE(jsonb_object_agg(chave, valor), '{}'::jsonb)
    INTO v_cfg
  FROM (
    SELECT DISTINCT ON (chave) chave, valor
    FROM public.plataforma_configuracoes
    WHERE secao IN ('financeiro', 'cancelamento', 'entrega', 'cupons')
       OR chave IN (
         'percentual_comissao_estabelecimento',
         'teto_comissao_mensal',
         'taxa_servico_app_pct',
         'split_automatico_ativo',
         'entrega_gratis_acima_de',
         'permite_entrega_gratis'
       )
    ORDER BY chave, secao
  ) s;

  RETURN jsonb_build_object(
    'percentual_comissao_estabelecimento', COALESCE((v_cfg->>'percentual_comissao_estabelecimento')::numeric, 6),
    'teto_comissao_mensal', COALESCE((v_cfg->>'teto_comissao_mensal')::numeric, 408),
    'taxa_servico_app_pct', COALESCE((v_cfg->>'taxa_servico_app_pct')::numeric, 5),
    'taxa_minima_plataforma', COALESCE((v_cfg->>'taxa_minima_plataforma')::numeric, 1),
    'modo_repasse', COALESCE(v_cfg->>'modo_repasse', 'pos_entrega'),
    'split_automatico_ativo', COALESCE((v_cfg->>'split_automatico_ativo')::boolean, false),
    'repasse_estabelecimento_pct', COALESCE((v_cfg->>'repasse_estabelecimento_pct')::numeric, 100),
    'repasse_entregador_pct', COALESCE((v_cfg->>'repasse_entregador_pct')::numeric, 100),
    'retencao_temporaria_ativa', COALESCE((v_cfg->>'retencao_temporaria_ativa')::boolean, false),
    'retencao_temporaria_horas', COALESCE((v_cfg->>'retencao_temporaria_horas')::numeric, 0),
    'exigir_subconta_homologada', COALESCE((v_cfg->>'exigir_subconta_homologada')::boolean, true),
    'estorno_automatico_ativo', COALESCE((v_cfg->>'estorno_automatico_ativo')::boolean, true),
    'compensacao_antes_coleta', COALESCE((v_cfg->>'compensacao_antes_coleta')::numeric, 2),
    'compensacao_apos_coleta_pct', COALESCE((v_cfg->>'compensacao_apos_coleta_pct')::numeric, 50),
    'entrega_base_km', COALESCE((v_cfg->>'entrega_base_km')::numeric, 5),
    'entrega_base_valor', COALESCE((v_cfg->>'entrega_base_valor')::numeric, 8.5),
    'entrega_valor_km_excedente', COALESCE((v_cfg->>'entrega_valor_km_excedente')::numeric, 1.6),
    'entrega_gratis_acima_de', COALESCE((v_cfg->>'entrega_gratis_acima_de')::numeric, 0),
    'permite_entrega_gratis', COALESCE((v_cfg->>'permite_entrega_gratis')::boolean, true)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.fn_get_config_financeira() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.fn_get_config_financeira() TO service_role;

CREATE OR REPLACE FUNCTION public.calcular_financeiro_pedido(
  p_subtotal_produtos numeric,
  p_distancia_km numeric,
  p_estabelecimento_id uuid,
  p_desconto numeric DEFAULT 0,
  p_taxa_servico_app numeric DEFAULT 0
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cfg jsonb;
  v_comissao_pct numeric := 0.06;
  v_teto_mensal numeric := 408.00;
  v_taxa_minima numeric := 1.00;
  v_repasse_ent_pct numeric := 100;
  v_base_km numeric := 5.00;
  v_base_valor numeric := 8.50;
  v_km_excedente numeric := 1.60;
  v_usado_mes numeric := 0;
  v_comissao_bruta numeric := 0;
  v_comissao numeric := 0;
  v_taxa_entrega numeric := 0;
  v_taxa_cliente numeric := 0;
  v_entregador numeric := 0;
  v_estabelecimento numeric := 0;
  v_total numeric := 0;
  v_gratis_acima numeric := 0;
  v_permite_gratis boolean := true;
BEGIN
  v_cfg := public.fn_get_config_financeira();
  v_comissao_pct := COALESCE((v_cfg->>'percentual_comissao_estabelecimento')::numeric, 6) / 100;
  v_teto_mensal := COALESCE((v_cfg->>'teto_comissao_mensal')::numeric, 408);
  v_taxa_minima := COALESCE((v_cfg->>'taxa_minima_plataforma')::numeric, 1);
  v_repasse_ent_pct := COALESCE((v_cfg->>'repasse_entregador_pct')::numeric, 100);
  v_base_km := COALESCE((v_cfg->>'entrega_base_km')::numeric, 5);
  v_base_valor := COALESCE((v_cfg->>'entrega_base_valor')::numeric, 8.5);
  v_km_excedente := COALESCE((v_cfg->>'entrega_valor_km_excedente')::numeric, 1.6);
  v_gratis_acima := COALESCE((v_cfg->>'entrega_gratis_acima_de')::numeric, 0);
  v_permite_gratis := COALESCE((v_cfg->>'permite_entrega_gratis')::boolean, true);

  SELECT COALESCE(SUM(sp.plataforma_valor), 0)
    INTO v_usado_mes
  FROM public.splits_pagamento sp
  WHERE sp.estabelecimento_id = p_estabelecimento_id
    AND sp.created_at >= date_trunc('month', now())
    AND sp.created_at < date_trunc('month', now()) + interval '1 month';

  v_taxa_entrega := round(
    CASE
      WHEN COALESCE(p_distancia_km, 0) <= v_base_km THEN v_base_valor
      ELSE v_base_valor + ((COALESCE(p_distancia_km, 0) - v_base_km) * v_km_excedente)
    END,
    2
  );

  v_taxa_cliente := v_taxa_entrega;
  IF v_permite_gratis AND v_gratis_acima > 0 AND COALESCE(p_subtotal_produtos, 0) >= v_gratis_acima THEN
    v_taxa_cliente := 0;
  END IF;

  v_comissao_bruta := round(COALESCE(p_subtotal_produtos, 0) * v_comissao_pct, 2);
  v_comissao := GREATEST(
    LEAST(v_comissao_bruta, GREATEST(v_teto_mensal - v_usado_mes, 0)),
    CASE WHEN COALESCE(p_subtotal_produtos, 0) > 0 THEN LEAST(v_taxa_minima, COALESCE(p_subtotal_produtos, 0)) ELSE 0 END
  );
  v_estabelecimento := round(COALESCE(p_subtotal_produtos, 0) - v_comissao, 2);
  v_entregador := round(v_taxa_entrega * (v_repasse_ent_pct / 100), 2);
  v_total := round(
    GREATEST(
      COALESCE(p_subtotal_produtos, 0) + v_taxa_cliente + COALESCE(p_taxa_servico_app, 0) - COALESCE(p_desconto, 0),
      0
    ),
    2
  );

  RETURN jsonb_build_object(
    'subtotal_produtos', round(COALESCE(p_subtotal_produtos, 0), 2),
    'taxa_entrega', v_taxa_cliente,
    'taxa_entrega_corrida', v_taxa_entrega,
    'taxa_servico_app', round(COALESCE(p_taxa_servico_app, 0), 2),
    'desconto', round(COALESCE(p_desconto, 0), 2),
    'comissao_plataforma', v_comissao,
    'comissao_plataforma_bruta', v_comissao_bruta,
    'comissao_teto_mensal', v_teto_mensal,
    'comissao_usada_mes', v_usado_mes,
    'estabelecimento_valor', v_estabelecimento,
    'entregador_valor', v_entregador,
    'valor_total', v_total,
    'modo_repasse', v_cfg->>'modo_repasse',
    'split_automatico_ativo', (v_cfg->>'split_automatico_ativo')::boolean
  );
END;
$$;

-- ── Checkout: raio, pedido minimo, cupons globais, manutencao ───────────────
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
  v_raio_max numeric;
  v_pedido_min numeric;
  v_tipo_ok boolean;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Sessao obrigatoria.');
  END IF;

  IF NOT public.fn_cfg_bool('plataforma_ativa', true)
     OR public.fn_cfg_bool('modo_manutencao', false) THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Plataforma em manutencao. Tente novamente mais tarde.');
  END IF;

  SELECT id INTO v_cliente_id FROM public.clientes WHERE usuario_id = auth.uid();
  IF v_cliente_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Perfil de cliente nao encontrado.');
  END IF;

  IF p_pagamento_metodo NOT IN ('pix', 'cartao_credito', 'cartao_debito', 'dinheiro') THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Metodo de pagamento invalido.');
  END IF;

  SELECT * INTO v_estab FROM public.estabelecimentos WHERE id = p_estabelecimento_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Estabelecimento nao encontrado.');
  END IF;

  SELECT * INTO v_endereco
    FROM public.enderecos_clientes
   WHERE id = p_endereco_entrega_id AND cliente_id = v_cliente_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Endereco nao pertence ao cliente.');
  END IF;

  SELECT * INTO v_carrinho
    FROM public.carrinhos
   WHERE cliente_id = v_cliente_id AND estabelecimento_id = p_estabelecimento_id
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

  v_pedido_min := public.fn_cfg_num('pedido_minimo', 0);
  IF v_pedido_min > 0 AND v_subtotal < v_pedido_min THEN
    RETURN jsonb_build_object(
      'ok', false,
      'erro', 'Pedido minimo da plataforma: R$ ' || to_char(v_pedido_min, 'FM999999990.00')
    );
  END IF;

  v_distancia := public.fn_distancia_km_coords(
    v_estab.latitude::double precision,
    v_estab.longitude::double precision,
    v_endereco.latitude::double precision,
    v_endereco.longitude::double precision
  );

  v_raio_max := public.fn_cfg_num('raio_maximo_km', 0);
  IF v_raio_max > 0 AND v_distancia > v_raio_max THEN
    RETURN jsonb_build_object(
      'ok', false,
      'erro', 'Endereco fora do raio maximo de entrega (' || v_raio_max::text || ' km).'
    );
  END IF;

  SELECT COALESCE(valor::numeric, 5) / 100 INTO v_taxa_pct
    FROM public.plataforma_configuracoes
   WHERE chave = 'taxa_servico_app_pct';
  v_taxa_servico := ROUND(v_subtotal * COALESCE(v_taxa_pct, 0.05), 2);

  IF p_cupom_codigo IS NOT NULL AND btrim(p_cupom_codigo) <> '' THEN
    IF NOT public.fn_cfg_bool('cupons_ativos', true) THEN
      RETURN jsonb_build_object('ok', false, 'erro', 'Cupons desativados na plataforma.');
    END IF;

    SELECT * INTO v_cupom
      FROM public.cupons
     WHERE upper(codigo) = upper(btrim(p_cupom_codigo))
       AND ativo = true
     FOR UPDATE;
    IF NOT FOUND THEN
      RETURN jsonb_build_object('ok', false, 'erro', 'Cupom nao encontrado ou inativo.');
    END IF;

    v_tipo_ok := CASE v_cupom.tipo
      WHEN 'percentual' THEN public.fn_cfg_bool('permite_percentual', true)
      WHEN 'valor_fixo' THEN public.fn_cfg_bool('permite_valor_fixo', true)
      WHEN 'entrega_gratis' THEN public.fn_cfg_bool('permite_entrega_gratis', true)
      ELSE true
    END;
    IF NOT v_tipo_ok THEN
      RETURN jsonb_build_object('ok', false, 'erro', 'Este tipo de cupom nao e permitido.');
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
    v_subtotal, v_distancia, p_estabelecimento_id, 0, v_taxa_servico
  );

  IF v_cupom_id IS NOT NULL THEN
    v_desconto := CASE v_cupom.tipo
      WHEN 'percentual' THEN ROUND(v_subtotal * v_cupom.valor / 100, 2)
      WHEN 'valor_fixo' THEN LEAST(v_cupom.valor, v_subtotal)
      WHEN 'entrega_gratis' THEN COALESCE((v_financeiro->>'taxa_entrega')::numeric, 0)
      ELSE 0
    END;
    v_financeiro := public.calcular_financeiro_pedido(
      v_subtotal, v_distancia, p_estabelecimento_id, v_desconto, v_taxa_servico
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

  -- Carrinho permanece ate a cobranca Asaas suceder.

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

-- ── Despacho: modo manual nao oferta automaticamente ────────────────────────
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
  v_modo            text;
BEGIN
  SELECT lower(COALESCE(valor, 'automatico')) INTO v_modo
    FROM public.plataforma_configuracoes
   WHERE chave = 'modo_despacho_padrao';
  IF COALESCE(v_modo, 'automatico') IN ('manual', 'off') THEN
    RAISE LOG '[despacho] modo_despacho_padrao=manual — sem oferta automatica %', p_pedido_id;
    RETURN NULL;
  END IF;

  SELECT e.latitude, e.longitude
    INTO v_estab_lat, v_estab_lng
    FROM public.pedidos p
    JOIN public.estabelecimentos e ON e.id = p.estabelecimento_id
   WHERE p.id = p_pedido_id;

  IF v_estab_lat IS NULL THEN
    RAISE WARNING '[despacho] Pedido % sem coordenadas do estabelecimento', p_pedido_id;
    RETURN NULL;
  END IF;

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

  SELECT COUNT(*) INTO v_total_tent
    FROM public.despacho_pedidos
   WHERE pedido_id = p_pedido_id;

  IF v_total_tent >= v_max_tent THEN
    UPDATE public.pedidos
       SET status = 'pronto', updated_at = now()
     WHERE id = p_pedido_id;
    RAISE WARNING '[despacho] Pedido % esgotou % tentativas, retornou para fila manual', p_pedido_id, v_max_tent;
    RETURN NULL;
  END IF;

  v_tentativa  := v_total_tent + 1;
  v_raio_atual := LEAST(v_raio_inicial + (v_raio_expansao * (v_tentativa - 1)), v_raio_maximo);

  SELECT
    e.id,
    e.usuario_id,
    e.avaliacao_media,
    e.score_fila,
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
    AND (111.045 * degrees(acos(
          LEAST(1.0, cos(radians(v_estab_lat))
            * cos(radians(e.latitude))
            * cos(radians(e.longitude) - radians(v_estab_lng))
            + sin(radians(v_estab_lat))
            * sin(radians(e.latitude))
          )
        ))) <= v_raio_atual
    AND e.id NOT IN (
      SELECT entregador_id FROM public.despacho_pedidos
       WHERE pedido_id = p_pedido_id
         AND status IN ('rejeitado', 'expirado')
    )
  ORDER BY score_final DESC
  LIMIT 1;

  IF v_entregador.id IS NULL THEN
    RAISE WARNING '[despacho] Nenhum entregador disponivel em % km para pedido %', v_raio_atual, p_pedido_id;
    RETURN NULL;
  END IF;

  UPDATE public.entregadores
     SET status_despacho = 'aguardando_aceite', updated_at = now()
   WHERE id = v_entregador.id;

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
    jsonb_build_object('raio_busca_km', v_raio_atual, 'total_candidatos', 1)
  )
  RETURNING id INTO v_despacho_id;

  RETURN v_despacho_id;
END;
$$;

-- ── Compensacao de cancelamento ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_aplicar_compensacao_cancelamento(p_pedido_id uuid)
RETURNS numeric
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_pedido public.pedidos%ROWTYPE;
  v_valor numeric := 0;
  v_antes numeric := 2;
  v_pct numeric := 50;
BEGIN
  SELECT * INTO v_pedido FROM public.pedidos WHERE id = p_pedido_id;
  IF NOT FOUND OR v_pedido.entregador_id IS NULL THEN
    RETURN 0;
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.entregador_bonificacoes
     WHERE entregador_id = v_pedido.entregador_id
       AND descricao LIKE 'Compensacao cancelamento pedido ' || p_pedido_id::text || '%'
  ) THEN
    RETURN 0;
  END IF;

  v_antes := public.fn_cfg_num('compensacao_antes_coleta', 2);
  v_pct := public.fn_cfg_num('compensacao_apos_coleta_pct', 50);

  IF v_pedido.status IN ('coletado', 'a_caminho_cliente', 'em_entrega') THEN
    v_valor := round(COALESCE(v_pedido.taxa_entrega, 0) * (v_pct / 100), 2);
  ELSE
    v_valor := round(v_antes, 2);
  END IF;

  IF v_valor <= 0 THEN
    RETURN 0;
  END IF;

  INSERT INTO public.entregador_bonificacoes (entregador_id, tipo, valor, descricao)
  VALUES (
    v_pedido.entregador_id,
    'outro',
    v_valor,
    'Compensacao cancelamento pedido ' || p_pedido_id::text
  );

  RETURN v_valor;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_cancelar_pedido_cliente(p_pedido_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cliente_id uuid;
  v_pedido public.pedidos%ROWTYPE;
  v_limite integer;
  v_usos integer;
  v_comp numeric;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Sessao obrigatoria.');
  END IF;

  SELECT id INTO v_cliente_id FROM public.clientes WHERE usuario_id = auth.uid();
  IF v_cliente_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Cliente nao encontrado.');
  END IF;

  SELECT * INTO v_pedido FROM public.pedidos WHERE id = p_pedido_id FOR UPDATE;
  IF NOT FOUND OR v_pedido.cliente_id <> v_cliente_id THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Pedido nao encontrado.');
  END IF;

  IF v_pedido.status NOT IN ('pendente', 'confirmado', 'preparando', 'pronto') THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Este pedido nao pode mais ser cancelado.');
  END IF;

  v_limite := public.fn_cfg_num('limite_cancelamentos_24h', 0)::integer;
  IF v_limite > 0 THEN
    SELECT COUNT(*) INTO v_usos
      FROM public.pedidos
     WHERE cliente_id = v_cliente_id
       AND status IN ('cancelado_cliente')
       AND COALESCE(cancelado_em, updated_at) >= now() - interval '24 hours';
    IF v_usos >= v_limite THEN
      RETURN jsonb_build_object('ok', false, 'erro', 'Limite de cancelamentos em 24h atingido.');
    END IF;
  END IF;

  v_comp := public.fn_aplicar_compensacao_cancelamento(p_pedido_id);

  UPDATE public.pedidos
     SET status = 'cancelado_cliente',
         cancelado_em = COALESCE(cancelado_em, now()),
         updated_at = now()
   WHERE id = p_pedido_id;

  IF v_pedido.pagamento_status IN ('confirmado', 'aguardando_pagamento')
     AND v_pedido.asaas_payment_id IS NOT NULL THEN
    PERFORM public.fn_disparar_estorno_pedido(p_pedido_id);
  END IF;

  RETURN jsonb_build_object('ok', true, 'status', 'cancelado_cliente', 'compensacao', v_comp);
END;
$$;

GRANT EXECUTE ON FUNCTION public.fn_cancelar_pedido_cliente(uuid) TO authenticated;

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

  IF p_novo_status = 'cancelado_estab' THEN
    PERFORM public.fn_aplicar_compensacao_cancelamento(p_pedido_id);
  END IF;

  UPDATE public.pedidos
     SET status = p_novo_status, updated_at = now()
   WHERE id = p_pedido_id;

  IF p_novo_status = 'cancelado_estab'
     AND v_pedido.pagamento_status IN ('confirmado', 'aguardando_pagamento')
     AND v_pedido.asaas_payment_id IS NOT NULL THEN
    PERFORM public.fn_disparar_estorno_pedido(p_pedido_id);
  END IF;

  RETURN jsonb_build_object('ok', true, 'status', p_novo_status);
END;
$$;

-- Helpers usados por RPCs SECURITY DEFINER do mesmo owner.
GRANT EXECUTE ON FUNCTION public.fn_cfg_valor(text, text) TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_cfg_bool(text, boolean) TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_cfg_num(text, numeric) TO service_role;

-- ── Push: max_tentativas_push na fila ───────────────────────────────────────
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
  v_max integer := 3;
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

  v_max := GREATEST(1, LEAST(10, COALESCE(public.fn_cfg_num('max_tentativas_push', 3)::integer, 3)));

  INSERT INTO public.notificacoes_fila
    (usuario_id, evento, titulo, corpo, entidade_tipo, entidade_id, dados, max_tentativas)
  VALUES
    (p_usuario_id, p_evento, v_titulo, v_corpo, p_entidade_tipo, p_entidade_id,
     COALESCE(p_dados_extra, '{}'::jsonb) || jsonb_build_object(
       'evento', p_evento,
       'canal_android', COALESCE(v_template.canal_android, 'padoca_geral'),
       'som', COALESCE(v_template.som, 'default')
     ),
     v_max)
  RETURNING id INTO v_notif_id;

  RETURN v_notif_id;
END;
$$;

REVOKE ALL ON FUNCTION public.enfileirar_notificacao(uuid, text, text, uuid, jsonb, jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.enfileirar_notificacao(uuid, text, text, uuid, jsonb, jsonb) TO service_role;

-- Recusa de oferta respeita cancelamentos_por_turno
CREATE OR REPLACE FUNCTION public.responder_despacho(
  p_despacho_id uuid,
  p_acao text,
  p_motivo text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_entregador_id uuid;
  v_despacho public.despacho_pedidos%ROWTYPE;
  v_limite integer;
  v_recusas integer;
BEGIN
  v_entregador_id := public.get_entregador_id();

  IF v_entregador_id IS NULL THEN
    RETURN jsonb_build_object(
      'ok', false, 'codigo', 'entregador_nao_encontrado',
      'mensagem', 'Entregador nao encontrado para o usuario autenticado.'
    );
  END IF;

  IF p_acao NOT IN ('aceitar', 'recusar') THEN
    RETURN jsonb_build_object(
      'ok', false, 'codigo', 'acao_invalida',
      'mensagem', 'Acao invalida para resposta de despacho.'
    );
  END IF;

  SELECT * INTO v_despacho
    FROM public.despacho_pedidos
   WHERE id = p_despacho_id AND entregador_id = v_entregador_id
   FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'ok', false, 'codigo', 'oferta_nao_encontrada',
      'mensagem', 'Oferta nao encontrada para este entregador.'
    );
  END IF;

  IF v_despacho.status <> 'aguardando' THEN
    RETURN jsonb_build_object(
      'ok', false, 'codigo', 'oferta_ja_respondida',
      'mensagem', 'Esta oferta ja foi respondida.', 'status', v_despacho.status
    );
  END IF;

  IF v_despacho.expira_em <= now() THEN
    UPDATE public.despacho_pedidos
       SET status = 'expirado', respondido_em = now()
     WHERE id = v_despacho.id AND status = 'aguardando';
    RETURN jsonb_build_object(
      'ok', false, 'codigo', 'oferta_expirada',
      'mensagem', 'O tempo para aceitar esta entrega expirou.'
    );
  END IF;

  IF p_acao = 'recusar' THEN
    v_limite := public.fn_cfg_num('cancelamentos_por_turno', 0)::integer;
    IF v_limite > 0 THEN
      SELECT COUNT(*) INTO v_recusas
        FROM public.despacho_pedidos
       WHERE entregador_id = v_entregador_id
         AND status = 'rejeitado'
         AND COALESCE(respondido_em, created_at) >= date_trunc('day', now());
      IF v_recusas >= v_limite THEN
        RETURN jsonb_build_object(
          'ok', false, 'codigo', 'limite_recusas_turno',
          'mensagem', 'Limite de recusas neste turno atingido.'
        );
      END IF;
    END IF;

    UPDATE public.despacho_pedidos
       SET status = 'rejeitado',
           respondido_em = now(),
           motivo_rejeicao = COALESCE(p_motivo, 'Recusado pelo entregador')
     WHERE id = v_despacho.id AND status = 'aguardando';

    RETURN jsonb_build_object(
      'ok', true, 'acao', 'recusar',
      'pedido_id', v_despacho.pedido_id, 'despacho_id', v_despacho.id
    );
  END IF;

  UPDATE public.pedidos
     SET entregador_id = v_entregador_id,
         status = 'a_caminho_coleta',
         updated_at = now()
   WHERE id = v_despacho.pedido_id
     AND entregador_id IS NULL
     AND status = 'pronto';

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'ok', false, 'codigo', 'pedido_indisponivel',
      'mensagem', 'Pedido indisponivel para aceite.'
    );
  END IF;

  UPDATE public.despacho_pedidos
     SET status = 'aceito', respondido_em = now()
   WHERE id = v_despacho.id AND status = 'aguardando';

  UPDATE public.entregadores
     SET status_despacho = 'em_pedido',
         pedido_atual_id = v_despacho.pedido_id,
         score_fila = GREATEST(COALESCE(score_fila, 0) - 5, 0),
         updated_at = now()
   WHERE id = v_entregador_id;

  RETURN jsonb_build_object(
    'ok', true, 'acao', 'aceitar',
    'pedido_id', v_despacho.pedido_id, 'despacho_id', v_despacho.id
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.responder_despacho(uuid, text, text) TO authenticated;
