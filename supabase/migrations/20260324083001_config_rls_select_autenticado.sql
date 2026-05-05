
-- Remove a policy única que bloqueava SELECT para não-admins
DROP POLICY IF EXISTS "config_somente_admin" ON public.plataforma_configuracoes;

-- SELECT: qualquer usuário autenticado pode ler
-- (o painel só é acessado por admin na prática)
CREATE POLICY "config_select_autenticado"
  ON public.plataforma_configuracoes
  FOR SELECT
  USING (auth.role() = 'authenticated');

-- INSERT / UPDATE / DELETE: somente admin
CREATE POLICY "config_escrita_admin"
  ON public.plataforma_configuracoes
  FOR ALL
  USING (public.is_admin())
  WITH CHECK (public.is_admin());
;
