
-- ============================================================
-- 1. despacho_pedidos — entregador pode aceitar/recusar
-- ============================================================
CREATE POLICY "despacho_update_entregador"
  ON public.despacho_pedidos FOR UPDATE
  USING (
    entregador_id IN (
      SELECT id FROM public.entregadores WHERE usuario_id = auth.uid()
    )
    AND status = 'aguardando'
  )
  WITH CHECK (
    status IN ('aceito', 'rejeitado')
  );

-- ============================================================
-- 2. produtos — estabelecimento pode deletar produto
-- ============================================================
CREATE POLICY "produtos_delete_proprio"
  ON public.produtos FOR DELETE
  USING (
    estabelecimento_id = get_estabelecimento_id()
    OR is_admin()
  );

-- ============================================================
-- 3. config_despacho — admin global pode ver
-- ============================================================
CREATE POLICY "config_despacho_select_admin"
  ON public.config_despacho FOR SELECT
  USING (is_admin_global());

-- ============================================================
-- 4. notificacao_templates — admin pode criar/editar
-- ============================================================
CREATE POLICY "notif_templates_manage_admin"
  ON public.notificacao_templates FOR ALL
  USING (is_admin_global())
  WITH CHECK (is_admin_global());

-- ============================================================
-- 5. rastreamento_entregadores — cliente vê só pedidos ativos
-- ============================================================
DROP POLICY IF EXISTS "rastreamento_read" ON public.rastreamento_entregadores;

CREATE POLICY "rastreamento_read"
  ON public.rastreamento_entregadores FOR SELECT
  USING (
    entregador_id IN (
      SELECT id FROM public.entregadores WHERE usuario_id = auth.uid()
    )
    OR
    pedido_id IN (
      SELECT p.id
      FROM public.pedidos p
      JOIN public.clientes c ON c.id = p.cliente_id
      WHERE c.usuario_id = auth.uid()
        AND p.status IN ('confirmado', 'preparando', 'pronto', 'em_entrega')
    )
    OR is_admin()
  );

-- ============================================================
-- 6. Views seguras para splits_pagamento
-- ============================================================
CREATE OR REPLACE VIEW public.v_splits_entregador AS
  SELECT
    sp.id,
    sp.pedido_id,
    sp.entregador_taxa_entrega_valor  AS valor_taxa_entrega,
    sp.entregador_valor_total         AS valor_total_recebido,
    sp.status,
    sp.processado_em
  FROM public.splits_pagamento sp
  JOIN public.pedidos p ON p.id = sp.pedido_id
  WHERE p.entregador_id = get_entregador_id();

CREATE OR REPLACE VIEW public.v_splits_estabelecimento AS
  SELECT
    sp.id,
    sp.pedido_id,
    sp.estabelecimento_percentual,
    sp.estabelecimento_valor,
    sp.plataforma_percentual,
    sp.plataforma_valor,
    sp.valor_total,
    sp.status,
    sp.processado_em
  FROM public.splits_pagamento sp
  JOIN public.pedidos p ON p.id = sp.pedido_id
  WHERE p.estabelecimento_id = get_estabelecimento_id();

ALTER VIEW public.v_splits_entregador       SET (security_invoker = true);
ALTER VIEW public.v_splits_estabelecimento  SET (security_invoker = true);
;
