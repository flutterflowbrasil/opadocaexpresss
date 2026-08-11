-- Adiciona suporte a subcategorias no cardápio
ALTER TABLE categorias_cardapio
  ADD COLUMN IF NOT EXISTS categoria_pai_id UUID REFERENCES categorias_cardapio(id) ON DELETE CASCADE;

-- Index para performance na query de subcategorias
CREATE INDEX IF NOT EXISTS idx_categorias_cardapio_pai
  ON categorias_cardapio(categoria_pai_id);

-- RLS: subcategorias seguem a mesma policy da categoria pai
-- (a tabela já tem policies de estabelecimento_id, a FK herda proteção);
