
-- =============================================
-- RLS POLICIES: tabela carrinhos
-- =============================================

-- Cliente gerencia o próprio carrinho (SELECT, INSERT, UPDATE, DELETE)
CREATE POLICY "cliente_gerencia_proprio_carrinho"
ON carrinhos
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM clientes c
    WHERE c.id = carrinhos.cliente_id
      AND c.usuario_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM clientes c
    WHERE c.id = carrinhos.cliente_id
      AND c.usuario_id = auth.uid()
  )
);

-- Admin global tem acesso total
CREATE POLICY "admin_global_carrinhos"
ON carrinhos
FOR ALL
USING (is_admin_global());

-- =============================================
-- RLS POLICIES: tabela cupons_usos
-- =============================================

-- Cliente vê e registra seus próprios usos de cupom
CREATE POLICY "cliente_gerencia_proprios_cupons_usos"
ON cupons_usos
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM clientes c
    WHERE c.id = cupons_usos.cliente_id
      AND c.usuario_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM clientes c
    WHERE c.id = cupons_usos.cliente_id
      AND c.usuario_id = auth.uid()
  )
);

-- Estabelecimento vê usos dos seus cupons
CREATE POLICY "estabelecimento_ve_usos_de_cupons"
ON cupons_usos
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM cupons cup
    JOIN administradores_estabelecimento ae ON ae.estabelecimento_id = cup.estabelecimento_id
    WHERE cup.id = cupons_usos.cupom_id
      AND ae.usuario_id = auth.uid()
      AND ae.ativo = true
  )
);

-- Admin global tem acesso total
CREATE POLICY "admin_global_cupons_usos"
ON cupons_usos
FOR ALL
USING (is_admin_global());
;
