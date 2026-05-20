CREATE TABLE IF NOT EXISTS public.produto_categorias_estabelecimento (
  produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
  categoria_id uuid NOT NULL REFERENCES public.categorias_estabelecimento(id) ON DELETE CASCADE,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  PRIMARY KEY (produto_id, categoria_id)
);

CREATE INDEX IF NOT EXISTS idx_produto_categorias_estabelecimento_categoria
  ON public.produto_categorias_estabelecimento(categoria_id);

CREATE INDEX IF NOT EXISTS idx_produto_categorias_estabelecimento_produto
  ON public.produto_categorias_estabelecimento(produto_id);

ALTER TABLE public.produto_categorias_estabelecimento ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "produto_categorias_select" ON public.produto_categorias_estabelecimento;
DROP POLICY IF EXISTS "produto_categorias_insert_proprio" ON public.produto_categorias_estabelecimento;
DROP POLICY IF EXISTS "produto_categorias_delete_proprio" ON public.produto_categorias_estabelecimento;

CREATE POLICY "produto_categorias_select"
ON public.produto_categorias_estabelecimento FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM public.produtos p
    WHERE p.id = produto_id
      AND (
        p.ativo = true
        OR p.estabelecimento_id = get_estabelecimento_id()
        OR is_admin()
      )
  )
);

CREATE POLICY "produto_categorias_insert_proprio"
ON public.produto_categorias_estabelecimento FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.produtos p
    WHERE p.id = produto_id
      AND (
        p.estabelecimento_id = get_estabelecimento_id()
        OR is_admin()
      )
  )
);

CREATE POLICY "produto_categorias_delete_proprio"
ON public.produto_categorias_estabelecimento FOR DELETE
USING (
  EXISTS (
    SELECT 1
    FROM public.produtos p
    WHERE p.id = produto_id
      AND (
        p.estabelecimento_id = get_estabelecimento_id()
        OR is_admin()
      )
  )
);;
