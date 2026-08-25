-- Permissões de adicionais para esfirra/salgados e limpeza baseada na
-- tabela de junção produto_categorias_estabelecimento (não só produtos.categoria_id).

UPDATE public.categorias_estabelecimento
SET permite_adicionais = true
WHERE slug IN ('lanches', 'bolos-tortas', 'pasteis', 'salgados', 'pizza')
   OR slug ILIKE '%esfir%'
   OR slug ILIKE '%esfiha%'
   OR nome ILIKE '%esfir%'
   OR nome ILIKE '%esfiha%';

-- Esfirra e hambúrguer: adicionais sim, tamanhos não (só pizza).
UPDATE public.categorias_estabelecimento
SET permite_multiplos_precos = true
WHERE slug = 'pizza';

UPDATE public.categorias_estabelecimento
SET permite_multiplos_precos = false
WHERE slug <> 'pizza'
  AND (slug ILIKE '%esfir%' OR slug ILIKE '%esfiha%' OR nome ILIKE '%esfir%' OR nome ILIKE '%esfiha%');

CREATE OR REPLACE FUNCTION public.fn_sincronizar_permissoes_produto(p_produto_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_permite_adicionais boolean := false;
  v_permite_tamanhos boolean := false;
BEGIN
  SELECT COALESCE(BOOL_OR(c.permite_adicionais), false),
         COALESCE(BOOL_OR(c.permite_multiplos_precos), false)
    INTO v_permite_adicionais, v_permite_tamanhos
    FROM public.produto_categorias_estabelecimento pce
    JOIN public.categorias_estabelecimento c ON c.id = pce.categoria_id
   WHERE pce.produto_id = p_produto_id;

  IF v_permite_adicionais IS NOT TRUE THEN
    UPDATE public.produtos
       SET opcoes = '[]'::jsonb
     WHERE id = p_produto_id
       AND COALESCE(opcoes, '[]'::jsonb) <> '[]'::jsonb;
  END IF;

  IF v_permite_tamanhos IS NOT TRUE THEN
    UPDATE public.produto_precos_tamanhos
       SET ativo = false
     WHERE produto_id = p_produto_id
       AND ativo = true;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_trg_sincronizar_permissoes_produto()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.fn_sincronizar_permissoes_produto(
    COALESCE(NEW.produto_id, OLD.produto_id)
  );
  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_sincronizar_permissoes_produto ON public.produto_categorias_estabelecimento;
CREATE TRIGGER trg_sincronizar_permissoes_produto
  AFTER INSERT OR UPDATE OR DELETE ON public.produto_categorias_estabelecimento
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_trg_sincronizar_permissoes_produto();

-- Mantém o caminho legado produtos.categoria_id alinhado à junção.
CREATE OR REPLACE FUNCTION public.fn_limpar_opcoes_por_categoria()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  PERFORM public.fn_sincronizar_permissoes_produto(NEW.id);
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_limpar_tamanhos_por_categoria()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  PERFORM public.fn_sincronizar_permissoes_produto(NEW.id);
  RETURN NEW;
END;
$$;
