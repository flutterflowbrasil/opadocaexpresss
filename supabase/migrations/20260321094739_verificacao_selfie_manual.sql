
-- ================================================================
-- VERIFICAÇÃO MANUAL POR SELFIE
-- Adapta entregador_kyc para processo manual sem IDwall
-- Adiciona 'selfie' como tipo de documento em entregador_documentos
-- ================================================================

-- 1. Adapta entregador_kyc para suportar revisão manual
--    Mantém a estrutura para futura migração para IDwall
ALTER TABLE public.entregador_kyc
  ALTER COLUMN provider SET DEFAULT 'manual',
  DROP CONSTRAINT IF EXISTS entregador_kyc_provider_check;

ALTER TABLE public.entregador_kyc
  ADD CONSTRAINT entregador_kyc_provider_check
  CHECK (provider IN ('idwall','unico','aws','manual'));

-- Remove a obrigatoriedade de score_liveness (não existe no processo manual)
-- Já é nullable, apenas garantimos

-- Adiciona campo para observacao do admin na revisão manual
ALTER TABLE public.entregador_kyc
  ADD COLUMN IF NOT EXISTS observacao_admin text,
  ADD COLUMN IF NOT EXISTS revisado_por uuid REFERENCES public.usuarios(id),
  ADD COLUMN IF NOT EXISTS revisado_em timestamp with time zone;

-- 2. Adiciona 'selfie' como tipo válido em entregador_documentos
--    (já existe no schema atualizado mas vamos garantir)
ALTER TABLE public.entregador_documentos
  DROP CONSTRAINT IF EXISTS entregador_documentos_tipo_check;

ALTER TABLE public.entregador_documentos
  ADD CONSTRAINT entregador_documentos_tipo_check
  CHECK (tipo IN ('cnh_frente','cnh_verso','veiculo','residencia','selfie'));

-- 3. Atualiza RLS: admin pode atualizar entregador_kyc (revisão manual)
DROP POLICY IF EXISTS "kyc_update_admin" ON public.entregador_kyc;

CREATE POLICY "kyc_update_admin"
ON public.entregador_kyc FOR UPDATE
USING (is_admin());

-- Admin pode inserir KYC manualmente (sem Edge Function)
DROP POLICY IF EXISTS "kyc_insert_admin" ON public.entregador_kyc;

CREATE POLICY "kyc_insert_admin"
ON public.entregador_kyc FOR INSERT
WITH CHECK (is_admin());

-- Entregador pode inserir próprio KYC (para enviar a selfie)
DROP POLICY IF EXISTS "kyc_insert_entregador" ON public.entregador_kyc;

CREATE POLICY "kyc_insert_entregador"
ON public.entregador_kyc FOR INSERT
WITH CHECK (
  entregador_id = get_entregador_id()
  AND get_tipo_usuario() = 'entregador'
);

-- Remove a policy que bloqueava tudo (substituída pelas acima)
DROP POLICY IF EXISTS "kyc_insert_bloqueado" ON public.entregador_kyc;

-- 4. Função helper para o admin aprovar/rejeitar selfie manualmente
CREATE OR REPLACE FUNCTION public.revisar_selfie_entregador(
  p_entregador_id uuid,
  p_status        text,  -- 'aprovado' ou 'reprovado'
  p_observacao    text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Só admin pode chamar
  IF NOT is_admin() THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'sem_permissao');
  END IF;

  IF p_status NOT IN ('aprovado', 'reprovado') THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'status_invalido');
  END IF;

  -- Atualiza o registro KYC
  UPDATE public.entregador_kyc SET
    status          = p_status,
    observacao_admin = p_observacao,
    revisado_por    = auth.uid(),
    revisado_em     = NOW(),
    updated_at      = NOW()
  WHERE entregador_id = p_entregador_id
    AND provider = 'manual'
  ;

  -- Se não existe ainda, cria
  IF NOT FOUND THEN
    INSERT INTO public.entregador_kyc (
      entregador_id, provider, status,
      observacao_admin, revisado_por, revisado_em
    ) VALUES (
      p_entregador_id, 'manual', p_status,
      p_observacao, auth.uid(), NOW()
    );
  END IF;

  RETURN jsonb_build_object('ok', true, 'status', p_status);
END;
$$;
;
