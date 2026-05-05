
-- 1. Adicionar 'selfie' como tipo de documento
ALTER TABLE public.entregador_documentos
  DROP CONSTRAINT entregador_documentos_tipo_check;

ALTER TABLE public.entregador_documentos
  ADD CONSTRAINT entregador_documentos_tipo_check
  CHECK (tipo = ANY (ARRAY[
    'cnh_frente'::text,
    'cnh_verso'::text,
    'veiculo'::text,
    'residencia'::text,
    'selfie'::text
  ]));

-- 2. Adicionar 'manual' como provider no KYC
ALTER TABLE public.entregador_kyc
  DROP CONSTRAINT entregador_kyc_provider_check;

ALTER TABLE public.entregador_kyc
  ADD CONSTRAINT entregador_kyc_provider_check
  CHECK (provider = ANY (ARRAY[
    'idwall'::text,
    'unico'::text,
    'aws'::text,
    'manual'::text
  ]));

-- 3. Adicionar campos de rastreamento de validação
ALTER TABLE public.entregador_documentos
  ADD COLUMN IF NOT EXISTS validado_por uuid
    REFERENCES public.usuarios(id);

ALTER TABLE public.entregador_documentos
  ADD COLUMN IF NOT EXISTS validado_em timestamp with time zone;
;
