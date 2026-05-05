
-- ─────────────────────────────────────────────────────────────────────────────
-- Função: insere categorias padrão para um estabelecimento recém-criado
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION fn_seed_categorias_cardapio_padrao()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.categorias_cardapio
    (estabelecimento_id, nome, descricao, ordem_exibicao, ativa)
  VALUES
    (NEW.id, 'Pães',               'Pães fresquinhos e especiais',          1, true),
    (NEW.id, 'Salgados',           'Salgados assados e fritos',             2, true),
    (NEW.id, 'Doces e Bolos',      'Bolos, tortas e doces artesanais',      3, true),
    (NEW.id, 'Bebidas',            'Sucos, cafés, refrigerantes e mais',    4, true),
    (NEW.id, 'Lanches',            'Sanduíches e combos rápidos',           5, true),
    (NEW.id, 'Combos e Promoções', 'Ofertas especiais e combos do dia',     6, true);

  RETURN NEW;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- Trigger: dispara após cada novo estabelecimento inserido
-- ─────────────────────────────────────────────────────────────────────────────
DROP TRIGGER IF EXISTS trg_seed_categorias_cardapio ON public.estabelecimentos;

CREATE TRIGGER trg_seed_categorias_cardapio
  AFTER INSERT ON public.estabelecimentos
  FOR EACH ROW
  EXECUTE FUNCTION fn_seed_categorias_cardapio_padrao();

-- ─────────────────────────────────────────────────────────────────────────────
-- Retroativo: semeia categorias para estabelecimentos que ainda não têm nenhuma
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO public.categorias_cardapio
  (estabelecimento_id, nome, descricao, ordem_exibicao, ativa)
SELECT
  e.id,
  categoria.nome,
  categoria.descricao,
  categoria.ordem,
  true
FROM public.estabelecimentos e
CROSS JOIN (
  VALUES
    ('Pães',               'Pães fresquinhos e especiais',          1),
    ('Salgados',           'Salgados assados e fritos',             2),
    ('Doces e Bolos',      'Bolos, tortas e doces artesanais',      3),
    ('Bebidas',            'Sucos, cafés, refrigerantes e mais',    4),
    ('Lanches',            'Sanduíches e combos rápidos',           5),
    ('Combos e Promoções', 'Ofertas especiais e combos do dia',     6)
) AS categoria(nome, descricao, ordem)
WHERE NOT EXISTS (
  SELECT 1 FROM public.categorias_cardapio cc
  WHERE cc.estabelecimento_id = e.id
);
;
