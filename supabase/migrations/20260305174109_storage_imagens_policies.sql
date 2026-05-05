
-- =============================================
-- STORAGE POLICIES: bucket imagens
-- =============================================

-- Leitura pública (bucket já é público, mas formalizamos via policy)
CREATE POLICY "imagens_public_read"
ON storage.objects FOR SELECT
USING (bucket_id = 'imagens');

-- Upload: apenas usuário autenticado, na pasta correspondente ao seu user_id
-- Estrutura esperada: imagens/{pasta}/{user_id}.{ext}
-- Ex: capa_estabelecimentos/{userId}.jpg
CREATE POLICY "imagens_upload_autenticado"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'imagens'
  AND auth.role() = 'authenticated'
  AND (
    -- Permite upload em qualquer pasta, mas o arquivo deve conter o user_id
    -- OU simplesmente que o usuário esteja autenticado (controlado pelo app)
    auth.uid() IS NOT NULL
  )
);

-- UPDATE: usuário só atualiza arquivos da sua própria pasta (baseado no nome do arquivo contendo seu user_id)
CREATE POLICY "imagens_update_proprio_usuario"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'imagens'
  AND auth.role() = 'authenticated'
  AND (
    -- Verifica se o nome do arquivo contém o user_id do usuário autenticado
    name LIKE '%' || auth.uid()::text || '%'
    OR is_admin_global()
  )
);

-- DELETE: usuário só deleta arquivos que contenham seu user_id no nome
CREATE POLICY "imagens_delete_proprio_usuario"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'imagens'
  AND (
    name LIKE '%' || auth.uid()::text || '%'
    OR is_admin_global()
  )
);
;
