
-- ══════════════════════════════════════════════════════════════════════
-- MIGRATION: Controle de adicionais por categoria + tamanhos de pizza
-- ══════════════════════════════════════════════════════════════════════

-- ── 1. Adicionar campos de permissão nas categorias principais ────────
ALTER TABLE categorias_estabelecimento
  ADD COLUMN IF NOT EXISTS permite_adicionais boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS permite_multiplos_precos boolean NOT NULL DEFAULT false;

-- ── 2. Configurar categorias que PERMITEM adicionais ─────────────────
UPDATE categorias_estabelecimento
SET permite_adicionais = true
WHERE slug IN ('lanches', 'bolos-tortas', 'pasteis', 'salgados', 'pizza');

-- ── 3. Pizza: também permite múltiplos preços ─────────────────────────
UPDATE categorias_estabelecimento
SET permite_multiplos_precos = true
WHERE slug = 'pizza';

-- ── 4. Criar tabela de tamanhos/preços para pizza ─────────────────────
CREATE TABLE IF NOT EXISTS produto_precos_tamanhos (
  id              uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  produto_id      uuid          NOT NULL REFERENCES produtos(id) ON DELETE CASCADE,
  nome_tamanho    text          NOT NULL,
  preco           numeric(10,2) NOT NULL CHECK (preco >= 0),
  ordem           integer       NOT NULL DEFAULT 0,
  ativo           boolean       NOT NULL DEFAULT true,
  created_at      timestamptz   NOT NULL DEFAULT now(),
  updated_at      timestamptz   NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_produto_tamanho_unique
  ON produto_precos_tamanhos(produto_id, nome_tamanho);

CREATE INDEX IF NOT EXISTS idx_produto_tamanho_produto
  ON produto_precos_tamanhos(produto_id);

CREATE INDEX IF NOT EXISTS idx_produto_tamanho_ativo
  ON produto_precos_tamanhos(produto_id, ativo);

-- ── 5. Trigger: updated_at automático em produto_precos_tamanhos ──────
CREATE OR REPLACE FUNCTION fn_set_updated_at_tamanhos()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_tamanhos_updated_at ON produto_precos_tamanhos;
CREATE TRIGGER trg_tamanhos_updated_at
  BEFORE UPDATE ON produto_precos_tamanhos
  FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at_tamanhos();

-- ── 6. RLS na nova tabela ─────────────────────────────────────────────
ALTER TABLE produto_precos_tamanhos ENABLE ROW LEVEL SECURITY;

-- Lojista pode gerenciar tamanhos dos seus próprios produtos (usuario_id)
CREATE POLICY "lojista_manage_tamanhos"
  ON produto_precos_tamanhos
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM produtos p
      JOIN estabelecimentos e ON e.id = p.estabelecimento_id
      WHERE p.id = produto_precos_tamanhos.produto_id
        AND e.usuario_id = auth.uid()
    )
  );

-- Cliente pode ler tamanhos ativos de produtos disponíveis
CREATE POLICY "cliente_read_tamanhos"
  ON produto_precos_tamanhos
  FOR SELECT
  USING (
    ativo = true
    AND EXISTS (
      SELECT 1 FROM produtos p
      WHERE p.id = produto_precos_tamanhos.produto_id
        AND p.disponivel = true
        AND p.ativo = true
    )
  );

-- ── 7. Trigger backend: limpar opcoes quando categoria não permite ─────
CREATE OR REPLACE FUNCTION fn_limpar_opcoes_por_categoria()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_permite boolean;
BEGIN
  IF NEW.categoria_id IS DISTINCT FROM OLD.categoria_id THEN
    SELECT permite_adicionais INTO v_permite
    FROM categorias_estabelecimento
    WHERE id = NEW.categoria_id;

    IF v_permite IS NOT TRUE THEN
      NEW.opcoes = '[]'::jsonb;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_limpar_opcoes_categoria ON produtos;
CREATE TRIGGER trg_limpar_opcoes_categoria
  BEFORE UPDATE OF categoria_id ON produtos
  FOR EACH ROW EXECUTE FUNCTION fn_limpar_opcoes_por_categoria();

-- ── 8. Trigger backend: desativar tamanhos quando categoria não permite
CREATE OR REPLACE FUNCTION fn_limpar_tamanhos_por_categoria()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_permite_multiplos boolean;
BEGIN
  IF NEW.categoria_id IS DISTINCT FROM OLD.categoria_id THEN
    SELECT permite_multiplos_precos INTO v_permite_multiplos
    FROM categorias_estabelecimento
    WHERE id = NEW.categoria_id;

    IF v_permite_multiplos IS NOT TRUE THEN
      UPDATE produto_precos_tamanhos
      SET ativo = false
      WHERE produto_id = NEW.id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_limpar_tamanhos_categoria ON produtos;
CREATE TRIGGER trg_limpar_tamanhos_categoria
  BEFORE UPDATE OF categoria_id ON produtos
  FOR EACH ROW EXECUTE FUNCTION fn_limpar_tamanhos_por_categoria();
