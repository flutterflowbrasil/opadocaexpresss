
-- 1. Criar bucket privado para documentos sensíveis
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'documentos-entregador',
  'documentos-entregador',
  false,
  5242880,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
);

-- 2. Policy: Entregador faz upload dos próprios documentos
CREATE POLICY "Entregador faz upload dos proprios docs"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'documentos-entregador'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- 3. Policy: Entregador visualiza seus docs / Admin visualiza todos
CREATE POLICY "Entregador visualiza proprios docs"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'documentos-entregador'
    AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR EXISTS (
        SELECT 1 FROM public.usuarios
        WHERE id = auth.uid()
        AND tipo_usuario IN ('admin', 'estabelecimento')
      )
    )
  );

-- 4. Policy: Apenas o próprio entregador pode deletar seus docs
CREATE POLICY "Entregador deleta proprios docs"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'documentos-entregador'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
;
