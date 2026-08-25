-- Aceita opcoes_selecionadas no formato canônico (id/nome) e no legado
-- (grupo_id/grupo_nome/item_id). Preço = base (tamanho ou produto) + extras.

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
  v_grupo_id text;
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
    v_grupo_nome := COALESCE(NULLIF(v_grupo->>'nome', ''), NULLIF(v_grupo->>'grupo_nome', ''), '');
    v_grupo_id := COALESCE(NULLIF(v_grupo->>'id', ''), NULLIF(v_grupo->>'grupo_id', ''), '');
    FOR v_item IN SELECT * FROM jsonb_array_elements(COALESCE(v_grupo->'itens', '[]'::jsonb))
    LOOP
      v_item_nome := COALESCE(NULLIF(v_item->>'nome', ''), '');
      v_item_id := COALESCE(NULLIF(v_item->>'id', ''), NULLIF(v_item->>'item_id', ''), '');
      v_preco := 0;
      SELECT COALESCE(
        (i->>'preco')::numeric,
        (i->>'preco_adicional')::numeric,
        0
      ) INTO v_preco
      FROM jsonb_array_elements(COALESCE(v_produto.opcoes, '[]'::jsonb)) g
      CROSS JOIN LATERAL jsonb_array_elements(COALESCE(g->'itens', '[]'::jsonb)) i
      WHERE (
          (v_grupo_id <> '' AND COALESCE(g->>'id', '') = v_grupo_id)
          OR (v_grupo_nome <> '' AND COALESCE(g->>'nome', '') = v_grupo_nome)
        )
        AND (
          (v_item_id <> '' AND COALESCE(i->>'id', '') = v_item_id)
          OR (v_item_nome <> '' AND COALESCE(i->>'nome', '') = v_item_nome)
        )
      LIMIT 1;

      v_extras := v_extras + COALESCE(v_preco, 0);
    END LOOP;
  END LOOP;

  RETURN ROUND(COALESCE(v_base, 0) + COALESCE(v_extras, 0), 2);
END;
$$;
