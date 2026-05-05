
-- ============================================================
-- TABELA: pedidos
-- ============================================================
ALTER TABLE public.pedidos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "pedidos_select"          ON public.pedidos;
DROP POLICY IF EXISTS "pedidos_insert_cliente"  ON public.pedidos;
DROP POLICY IF EXISTS "pedidos_update"          ON public.pedidos;

CREATE POLICY "pedidos_select"
ON public.pedidos FOR SELECT
USING (
  cliente_id    = (SELECT id FROM public.clientes WHERE usuario_id = auth.uid())
  OR entregador_id    = get_entregador_id()
  OR estabelecimento_id = get_estabelecimento_id()
  OR is_admin()
);

CREATE POLICY "pedidos_insert_cliente"
ON public.pedidos FOR INSERT
WITH CHECK (
  cliente_id = (SELECT id FROM public.clientes WHERE usuario_id = auth.uid())
  AND get_tipo_usuario() = 'cliente'
);

CREATE POLICY "pedidos_update"
ON public.pedidos FOR UPDATE
USING (
  estabelecimento_id = get_estabelecimento_id()
  OR entregador_id   = get_entregador_id()
  OR is_admin()
);


-- ============================================================
-- TABELA: entregador_saldos — bloqueado para client
-- ============================================================
ALTER TABLE public.entregador_saldos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "saldos_select"           ON public.entregador_saldos;
DROP POLICY IF EXISTS "saldos_update_bloqueado" ON public.entregador_saldos;
DROP POLICY IF EXISTS "saldos_insert_bloqueado" ON public.entregador_saldos;

CREATE POLICY "saldos_select"
ON public.entregador_saldos FOR SELECT
USING (
  entregador_id = get_entregador_id()
  OR is_admin()
);

CREATE POLICY "saldos_update_bloqueado"
ON public.entregador_saldos FOR UPDATE
USING (false);

CREATE POLICY "saldos_insert_bloqueado"
ON public.entregador_saldos FOR INSERT
WITH CHECK (false);


-- ============================================================
-- TABELA: entregador_saques
-- ============================================================
ALTER TABLE public.entregador_saques ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "saques_select"           ON public.entregador_saques;
DROP POLICY IF EXISTS "saques_insert_proprio"   ON public.entregador_saques;
DROP POLICY IF EXISTS "saques_update_bloqueado" ON public.entregador_saques;

CREATE POLICY "saques_select"
ON public.entregador_saques FOR SELECT
USING (
  entregador_id = get_entregador_id()
  OR is_admin()
);

CREATE POLICY "saques_insert_proprio"
ON public.entregador_saques FOR INSERT
WITH CHECK (
  entregador_id = get_entregador_id()
  AND get_tipo_usuario() = 'entregador'
);

CREATE POLICY "saques_update_bloqueado"
ON public.entregador_saques FOR UPDATE
USING (false);


-- ============================================================
-- TABELA: entregador_kyc — bloqueado para client
-- ============================================================
ALTER TABLE public.entregador_kyc ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "kyc_select"           ON public.entregador_kyc;
DROP POLICY IF EXISTS "kyc_insert_bloqueado" ON public.entregador_kyc;
DROP POLICY IF EXISTS "kyc_update_bloqueado" ON public.entregador_kyc;

CREATE POLICY "kyc_select"
ON public.entregador_kyc FOR SELECT
USING (
  entregador_id = get_entregador_id()
  OR is_admin()
);

CREATE POLICY "kyc_insert_bloqueado"
ON public.entregador_kyc FOR INSERT
WITH CHECK (false);

CREATE POLICY "kyc_update_bloqueado"
ON public.entregador_kyc FOR UPDATE
USING (false);


-- ============================================================
-- TABELA: entregador_documentos
-- ============================================================
ALTER TABLE public.entregador_documentos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "docs_select"                   ON public.entregador_documentos;
DROP POLICY IF EXISTS "docs_insert_proprio"           ON public.entregador_documentos;
DROP POLICY IF EXISTS "docs_update_bloqueado_cliente" ON public.entregador_documentos;
DROP POLICY IF EXISTS "docs_update_admin"             ON public.entregador_documentos;

CREATE POLICY "docs_select"
ON public.entregador_documentos FOR SELECT
USING (
  entregador_id = get_entregador_id()
  OR is_admin()
);

CREATE POLICY "docs_insert_proprio"
ON public.entregador_documentos FOR INSERT
WITH CHECK (
  entregador_id = get_entregador_id()
  AND get_tipo_usuario() = 'entregador'
);

CREATE POLICY "docs_update_bloqueado_cliente"
ON public.entregador_documentos FOR UPDATE
USING (false);

CREATE POLICY "docs_update_admin"
ON public.entregador_documentos FOR UPDATE
USING (is_admin());


-- ============================================================
-- TABELA: splits_pagamento — bloqueado para client
-- ============================================================
ALTER TABLE public.splits_pagamento ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "splits_select"           ON public.splits_pagamento;
DROP POLICY IF EXISTS "splits_insert_bloqueado" ON public.splits_pagamento;
DROP POLICY IF EXISTS "splits_update_bloqueado" ON public.splits_pagamento;

CREATE POLICY "splits_select"
ON public.splits_pagamento FOR SELECT
USING (
  is_admin()
  OR EXISTS (
    SELECT 1 FROM public.pedidos p
    WHERE p.id = pedido_id
      AND (
        p.estabelecimento_id = get_estabelecimento_id()
        OR p.entregador_id   = get_entregador_id()
      )
  )
);

CREATE POLICY "splits_insert_bloqueado"
ON public.splits_pagamento FOR INSERT
WITH CHECK (false);

CREATE POLICY "splits_update_bloqueado"
ON public.splits_pagamento FOR UPDATE
USING (false);
;
