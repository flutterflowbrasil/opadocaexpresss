
-- ============================================================
-- TABELA: usuarios
-- ============================================================
ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "usuarios_select"              ON public.usuarios;
DROP POLICY IF EXISTS "usuarios_update_proprio"      ON public.usuarios;
DROP POLICY IF EXISTS "usuarios_update_admin"        ON public.usuarios;
DROP POLICY IF EXISTS "usuarios_delete_bloqueado"    ON public.usuarios;

CREATE POLICY "usuarios_select"
ON public.usuarios FOR SELECT
USING (
  id = auth.uid()
  OR is_admin()
);

CREATE POLICY "usuarios_update_proprio"
ON public.usuarios FOR UPDATE
USING (id = auth.uid())
WITH CHECK (
  tipo_usuario = (
    SELECT tipo_usuario FROM public.usuarios WHERE id = auth.uid()
  )
  AND status = (
    SELECT status FROM public.usuarios WHERE id = auth.uid()
  )
);

CREATE POLICY "usuarios_update_admin"
ON public.usuarios FOR UPDATE
USING (is_admin());

CREATE POLICY "usuarios_delete_bloqueado"
ON public.usuarios FOR DELETE
USING (false);


-- ============================================================
-- TABELA: entregadores
-- ============================================================
ALTER TABLE public.entregadores ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "entregadores_select"          ON public.entregadores;
DROP POLICY IF EXISTS "entregadores_update_proprio"  ON public.entregadores;
DROP POLICY IF EXISTS "entregadores_update_admin"    ON public.entregadores;
DROP POLICY IF EXISTS "entregadores_insert_proprio"  ON public.entregadores;

CREATE POLICY "entregadores_select"
ON public.entregadores FOR SELECT
USING (
  usuario_id = auth.uid()
  OR is_admin()
);

CREATE POLICY "entregadores_update_proprio"
ON public.entregadores FOR UPDATE
USING (usuario_id = auth.uid())
WITH CHECK (
  status_cadastro = (
    SELECT status_cadastro FROM public.entregadores WHERE usuario_id = auth.uid()
  )
  AND asaas_wallet_id IS NOT DISTINCT FROM (
    SELECT asaas_wallet_id FROM public.entregadores WHERE usuario_id = auth.uid()
  )
  AND score_fila IS NOT DISTINCT FROM (
    SELECT score_fila FROM public.entregadores WHERE usuario_id = auth.uid()
  )
);

CREATE POLICY "entregadores_update_admin"
ON public.entregadores FOR UPDATE
USING (is_admin());

CREATE POLICY "entregadores_insert_proprio"
ON public.entregadores FOR INSERT
WITH CHECK (usuario_id = auth.uid());


-- ============================================================
-- TABELA: estabelecimentos
-- ============================================================
ALTER TABLE public.estabelecimentos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "estabelecimentos_select"         ON public.estabelecimentos;
DROP POLICY IF EXISTS "estabelecimentos_update_proprio" ON public.estabelecimentos;
DROP POLICY IF EXISTS "estabelecimentos_update_admin"   ON public.estabelecimentos;
DROP POLICY IF EXISTS "estabelecimentos_insert_proprio" ON public.estabelecimentos;

CREATE POLICY "estabelecimentos_select"
ON public.estabelecimentos FOR SELECT
USING (
  usuario_id = auth.uid()
  OR is_admin()
  OR (
    status_cadastro = 'aprovado'
    AND get_tipo_usuario() = 'cliente'
  )
);

CREATE POLICY "estabelecimentos_update_proprio"
ON public.estabelecimentos FOR UPDATE
USING (usuario_id = auth.uid())
WITH CHECK (
  status_cadastro = (
    SELECT status_cadastro FROM public.estabelecimentos WHERE usuario_id = auth.uid()
  )
  AND asaas_wallet_id IS NOT DISTINCT FROM (
    SELECT asaas_wallet_id FROM public.estabelecimentos WHERE usuario_id = auth.uid()
  )
);

CREATE POLICY "estabelecimentos_update_admin"
ON public.estabelecimentos FOR UPDATE
USING (is_admin());

CREATE POLICY "estabelecimentos_insert_proprio"
ON public.estabelecimentos FOR INSERT
WITH CHECK (usuario_id = auth.uid());
;
