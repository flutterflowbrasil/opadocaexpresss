
-- ================================================================
-- Ajusta entregador_kyc para processo 100% manual (sem IDwall)
-- provider padrão = 'manual', score_liveness não usado
-- Admin analisa selfie + documentos e aprova/rejeita manualmente
-- ================================================================

-- Garante que o provider padrão seja 'manual'
ALTER TABLE public.entregador_kyc
  ALTER COLUMN provider SET DEFAULT 'manual';

-- score_liveness não faz sentido no processo manual — torna nullable
-- (já era nullable, mas documentamos com comentário)
COMMENT ON COLUMN public.entregador_kyc.score_liveness IS
  'Não utilizado no processo manual. Reservado para KYC automático futuro (IDwall/Unico).';

COMMENT ON COLUMN public.entregador_kyc.token_externo IS
  'Não utilizado no processo manual. Reservado para token de sessão IDwall/Unico futuro.';

COMMENT ON TABLE public.entregador_kyc IS
  'Verificação de identidade do entregador. Atualmente processo manual: admin analisa selfie + documentos. KYC automático (IDwall) planejado para versão futura.';

-- Garante que 'selfie' está no tipo de entregador_documentos (já existe, mas reforça)
-- A selfie é armazenada em entregador_documentos.tipo = 'selfie'
-- E também espelhada em entregador_kyc.foto_selfie_url para acesso rápido pelo admin

COMMENT ON COLUMN public.entregador_kyc.foto_selfie_url IS
  'URL da selfie enviada pelo entregador. Armazenada no bucket documentos-entregador (privado). Admin acessa via URL assinada para análise manual.';

COMMENT ON COLUMN public.entregador_kyc.observacao_admin IS
  'Observação do admin ao revisar selfie manualmente. Campo livre para anotações internas.';
;
