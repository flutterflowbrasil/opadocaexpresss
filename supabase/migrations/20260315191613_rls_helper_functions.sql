
-- ============================================================
-- HELPER FUNCTIONS — base para todas as policies de segurança
-- ============================================================

CREATE OR REPLACE FUNCTION get_tipo_usuario()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT tipo_usuario
  FROM public.usuarios
  WHERE id = auth.uid()
    AND status = 'ativo'
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE id = auth.uid()
      AND tipo_usuario = 'admin'
      AND status = 'ativo'
  );
$$;

CREATE OR REPLACE FUNCTION get_entregador_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT id FROM public.entregadores
  WHERE usuario_id = auth.uid()
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION get_estabelecimento_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT id FROM public.estabelecimentos
  WHERE usuario_id = auth.uid()
  LIMIT 1;
$$;
;
