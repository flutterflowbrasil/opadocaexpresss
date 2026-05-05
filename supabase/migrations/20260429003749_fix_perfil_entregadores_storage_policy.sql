
-- Adiciona policy de SELECT público para a pasta perfil_entregadores no bucket imagens
-- (necessário para exibir a foto de perfil do entregador no app)
DROP POLICY IF EXISTS "Perfil entregadores: visualização pública" ON storage.objects;

CREATE POLICY "Perfil entregadores: visualização pública"
ON storage.objects
FOR SELECT
TO public
USING (
  bucket_id = 'imagens'
  AND (storage.foldername(name))[1] = 'perfil_entregadores'
);

-- Adiciona policy de INSERT/UPDATE explícita para perfil_entregadores
-- A policy imagens_upload_autenticado já cobre INSERT genérico,
-- mas a imagens_update_proprio_usuario exige uid() no name — o novo path usa userId, então está OK.
-- Esta policy adiciona cobertura explícita de DELETE para o entregador deletar sua própria foto.
DROP POLICY IF EXISTS "Perfil entregadores: deletar própria" ON storage.objects;

CREATE POLICY "Perfil entregadores: deletar própria"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'imagens'
  AND (storage.foldername(name))[1] = 'perfil_entregadores'
  AND auth.uid() IS NOT NULL
);
;
