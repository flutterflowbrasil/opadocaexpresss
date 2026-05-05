
-- ============================================================
-- TABELA: suporte_chamados
-- ============================================================
ALTER TABLE public.suporte_chamados ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "suporte_select"         ON public.suporte_chamados;
DROP POLICY IF EXISTS "suporte_insert_proprio" ON public.suporte_chamados;
DROP POLICY IF EXISTS "suporte_update_admin"   ON public.suporte_chamados;

CREATE POLICY "suporte_select"
ON public.suporte_chamados FOR SELECT
USING (
  entregador_id = get_entregador_id()
  OR is_admin()
);

CREATE POLICY "suporte_insert_proprio"
ON public.suporte_chamados FOR INSERT
WITH CHECK (
  entregador_id = get_entregador_id()
  AND get_tipo_usuario() = 'entregador'
);

CREATE POLICY "suporte_update_admin"
ON public.suporte_chamados FOR UPDATE
USING (is_admin());


-- ============================================================
-- TABELA: avaliacoes
-- ============================================================
ALTER TABLE public.avaliacoes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "avaliacoes_select"         ON public.avaliacoes;
DROP POLICY IF EXISTS "avaliacoes_insert_cliente" ON public.avaliacoes;
DROP POLICY IF EXISTS "avaliacoes_update_estab"   ON public.avaliacoes;

CREATE POLICY "avaliacoes_select"
ON public.avaliacoes FOR SELECT
USING (
  cliente_id        = (SELECT id FROM public.clientes WHERE usuario_id = auth.uid())
  OR estabelecimento_id = get_estabelecimento_id()
  OR entregador_id      = get_entregador_id()
  OR is_admin()
);

CREATE POLICY "avaliacoes_insert_cliente"
ON public.avaliacoes FOR INSERT
WITH CHECK (
  cliente_id = (SELECT id FROM public.clientes WHERE usuario_id = auth.uid())
  AND get_tipo_usuario() = 'cliente'
);

CREATE POLICY "avaliacoes_update_estab"
ON public.avaliacoes FOR UPDATE
USING (estabelecimento_id = get_estabelecimento_id());


-- ============================================================
-- TABELA: clientes
-- ============================================================
ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "clientes_select"         ON public.clientes;
DROP POLICY IF EXISTS "clientes_update_proprio" ON public.clientes;
DROP POLICY IF EXISTS "clientes_insert_proprio" ON public.clientes;

CREATE POLICY "clientes_select"
ON public.clientes FOR SELECT
USING (
  usuario_id = auth.uid()
  OR is_admin()
);

CREATE POLICY "clientes_update_proprio"
ON public.clientes FOR UPDATE
USING (usuario_id = auth.uid())
WITH CHECK (
  pontos_fidelidade = (
    SELECT pontos_fidelidade FROM public.clientes WHERE usuario_id = auth.uid()
  )
  AND total_pedidos = (
    SELECT total_pedidos FROM public.clientes WHERE usuario_id = auth.uid()
  )
);

CREATE POLICY "clientes_insert_proprio"
ON public.clientes FOR INSERT
WITH CHECK (usuario_id = auth.uid());


-- ============================================================
-- TABELA: dispositivos_push
-- ============================================================
ALTER TABLE public.dispositivos_push ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "push_select_proprio" ON public.dispositivos_push;
DROP POLICY IF EXISTS "push_insert_proprio" ON public.dispositivos_push;
DROP POLICY IF EXISTS "push_update_proprio" ON public.dispositivos_push;

CREATE POLICY "push_select_proprio"
ON public.dispositivos_push FOR SELECT
USING (usuario_id = auth.uid() OR is_admin());

CREATE POLICY "push_insert_proprio"
ON public.dispositivos_push FOR INSERT
WITH CHECK (usuario_id = auth.uid());

CREATE POLICY "push_update_proprio"
ON public.dispositivos_push FOR UPDATE
USING (usuario_id = auth.uid());


-- ============================================================
-- TABELA: notificacoes_fila — só Edge Function insere
-- ============================================================
ALTER TABLE public.notificacoes_fila ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "notif_fila_select"           ON public.notificacoes_fila;
DROP POLICY IF EXISTS "notif_fila_insert_bloqueado" ON public.notificacoes_fila;

CREATE POLICY "notif_fila_select"
ON public.notificacoes_fila FOR SELECT
USING (usuario_id = auth.uid() OR is_admin());

CREATE POLICY "notif_fila_insert_bloqueado"
ON public.notificacoes_fila FOR INSERT
WITH CHECK (false);


-- ============================================================
-- TABELA: cupons
-- ============================================================
ALTER TABLE public.cupons ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "cupons_select_publico" ON public.cupons;
DROP POLICY IF EXISTS "cupons_insert_estab"   ON public.cupons;
DROP POLICY IF EXISTS "cupons_update_estab"   ON public.cupons;

CREATE POLICY "cupons_select_publico"
ON public.cupons FOR SELECT
USING (
  ativo = true
  OR get_estabelecimento_id() IS NOT NULL
  OR is_admin()
);

CREATE POLICY "cupons_insert_estab"
ON public.cupons FOR INSERT
WITH CHECK (
  estabelecimento_id = get_estabelecimento_id()
  OR (estabelecimento_id IS NULL AND is_admin())
);

CREATE POLICY "cupons_update_estab"
ON public.cupons FOR UPDATE
USING (
  estabelecimento_id = get_estabelecimento_id()
  OR is_admin()
);


-- ============================================================
-- TABELA: produtos
-- ============================================================
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "produtos_select_publico" ON public.produtos;
DROP POLICY IF EXISTS "produtos_insert_proprio" ON public.produtos;
DROP POLICY IF EXISTS "produtos_update_proprio" ON public.produtos;

CREATE POLICY "produtos_select_publico"
ON public.produtos FOR SELECT
USING (
  ativo = true
  OR estabelecimento_id = get_estabelecimento_id()
  OR is_admin()
);

CREATE POLICY "produtos_insert_proprio"
ON public.produtos FOR INSERT
WITH CHECK (estabelecimento_id = get_estabelecimento_id());

CREATE POLICY "produtos_update_proprio"
ON public.produtos FOR UPDATE
USING (
  estabelecimento_id = get_estabelecimento_id()
  OR is_admin()
);


-- ============================================================
-- TABELA: entregador_localizacao_atual
-- ============================================================
ALTER TABLE public.entregador_localizacao_atual ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "localizacao_select"         ON public.entregador_localizacao_atual;
DROP POLICY IF EXISTS "localizacao_upsert_proprio" ON public.entregador_localizacao_atual;
DROP POLICY IF EXISTS "localizacao_update_proprio" ON public.entregador_localizacao_atual;

CREATE POLICY "localizacao_select"
ON public.entregador_localizacao_atual FOR SELECT
USING (
  entregador_id = get_entregador_id()
  OR is_admin()
  OR EXISTS (
    SELECT 1 FROM public.pedidos p
    WHERE p.entregador_id     = entregador_id
      AND p.estabelecimento_id = get_estabelecimento_id()
      AND p.status             = 'em_entrega'
  )
);

CREATE POLICY "localizacao_upsert_proprio"
ON public.entregador_localizacao_atual FOR INSERT
WITH CHECK (entregador_id = get_entregador_id());

CREATE POLICY "localizacao_update_proprio"
ON public.entregador_localizacao_atual FOR UPDATE
USING (entregador_id = get_entregador_id());
;
