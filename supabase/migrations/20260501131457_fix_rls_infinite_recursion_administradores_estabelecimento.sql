
-- =============================================================================
-- FIX: Infinite recursion in RLS policies for administradores_estabelecimento
-- 
-- Root cause: Multiple policies call functions (is_admin_estabelecimento,
-- can_manage_estabelecimento) that query the same table, triggering the RLS
-- policies again in an infinite loop.
--
-- Solution: Mark these helper functions as SECURITY DEFINER so they bypass
-- RLS when making their internal queries, breaking the recursion.
-- =============================================================================

-- 1. Fix: is_admin_estabelecimento
-- This function queries administradores_estabelecimento directly.
-- Making it SECURITY DEFINER bypasses RLS on the internal query.
CREATE OR REPLACE FUNCTION public.is_admin_estabelecimento(estabelecimento_uuid uuid)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.administradores_estabelecimento ae
    WHERE ae.estabelecimento_id = estabelecimento_uuid
      AND ae.usuario_id = auth.uid()
      AND ae.ativo = true
      AND ae.convite_pendente = false
  );
END;
$$;

-- 2. Fix: can_manage_estabelecimento
-- This function also queries administradores_estabelecimento directly.
CREATE OR REPLACE FUNCTION public.can_manage_estabelecimento(p_estabelecimento_id uuid)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN (
    EXISTS (
      SELECT 1
      FROM public.estabelecimentos e
      WHERE e.id = p_estabelecimento_id
        AND e.usuario_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1
      FROM public.administradores_estabelecimento ae
      WHERE ae.estabelecimento_id = p_estabelecimento_id
        AND ae.usuario_id = auth.uid()
        AND COALESCE(ae.ativo, false) = true
        AND COALESCE(ae.convite_pendente, false) = false
    )
  );
END;
$$;

-- 3. Fix: Rewrite the self-referencing policy "administradores_estabelecimento_manage_admin"
-- The WITH CHECK and USING clauses had inline subqueries on the same table.
-- Replace them to call can_manage_estabelecimento() which is now SECURITY DEFINER.
DROP POLICY IF EXISTS "administradores_estabelecimento_manage_admin" ON public.administradores_estabelecimento;

CREATE POLICY "administradores_estabelecimento_manage_admin"
ON public.administradores_estabelecimento
AS PERMISSIVE
FOR ALL
TO authenticated
USING (
  is_admin()
  OR can_manage_estabelecimento(estabelecimento_id)
)
WITH CHECK (
  is_admin()
  OR can_manage_estabelecimento(estabelecimento_id)
);

-- 4. Also ensure is_admin_global is SECURITY DEFINER (it queries usuarios, which is safe,
-- but good practice to keep consistent).
CREATE OR REPLACE FUNCTION public.is_admin_global()
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE id = auth.uid()
      AND tipo_usuario = 'admin'
  );
END;
$$;
;
