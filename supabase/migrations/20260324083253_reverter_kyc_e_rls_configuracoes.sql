
-- 1. Restaurar registros da seção kyc que foram deletados
INSERT INTO public.plataforma_configuracoes (secao, chave, valor, tipo, label, descricao, editavel)
VALUES
  ('kyc', 'score_liveness_minimo', '0.85',  'number',  'Score mínimo de liveness (KYC)',  'Score mínimo para aprovação automática. Abaixo disso vai para revisão manual.', true),
  ('kyc', 'kyc_provider_ativo',    'manual','string',   'Provider KYC ativo',              'manual | idwall | unico. Atualmente: processo manual de selfie.',              true),
  ('kyc', 'exige_cnh_valida',      'true',  'boolean',  'Exigir CNH válida',               'Se ativado, entregadores com CNH vencida não podem ser aprovados.',             true),
  ('kyc', 'documentos_obrigatorios','selfie,cnh_frente,cnh_verso,veiculo,residencia','string','Documentos obrigatórios','Lista separada por vírgula dos documentos necessários para aprovação.',true)
ON CONFLICT (secao, chave) DO NOTHING;

-- 2. Reverter RLS: remover policies criadas e restaurar a original
DROP POLICY IF EXISTS "config_select_autenticado" ON public.plataforma_configuracoes;
DROP POLICY IF EXISTS "config_escrita_admin"       ON public.plataforma_configuracoes;

CREATE POLICY "config_somente_admin"
  ON public.plataforma_configuracoes
  FOR ALL
  USING (public.is_admin())
  WITH CHECK (public.is_admin());
;
