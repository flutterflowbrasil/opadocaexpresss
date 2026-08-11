-- Persiste tamanho selecionado (pizza) nos itens do carrinho remoto.

ALTER TABLE public.itens_carrinho
  ADD COLUMN IF NOT EXISTS tamanho_produto_id uuid
    REFERENCES public.produto_precos_tamanhos(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS tamanho_produto_nome text;

CREATE INDEX IF NOT EXISTS idx_itens_carrinho_tamanho
  ON public.itens_carrinho(tamanho_produto_id)
  WHERE tamanho_produto_id IS NOT NULL;

COMMENT ON COLUMN public.itens_carrinho.tamanho_produto_id IS
  'FK opcional para produto_precos_tamanhos quando o item usa preço por tamanho.';
COMMENT ON COLUMN public.itens_carrinho.tamanho_produto_nome IS
  'Snapshot do nome do tamanho para exibição no carrinho.';
