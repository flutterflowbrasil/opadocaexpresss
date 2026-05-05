
-- Remove policies antigas/conflitantes do bucket documentos-entregador
-- que usam auth.uid() como primeira pasta (incompatível com o path real: entregadorId/tipo_xxx.ext)
DROP POLICY IF EXISTS "Entregador faz upload dos proprios docs" ON storage.objects;
DROP POLICY IF EXISTS "Entregador visualiza proprios docs" ON storage.objects;
DROP POLICY IF EXISTS "Entregador deleta proprios docs" ON storage.objects;

-- Garante que a policy de INSERT correta (que usa entregadores.id) está presente
-- Já foi criada pela migration anterior. Apenas confirma que não há duplicatas.
-- As policies vigentes corretas são:
--   "Entregador envia arquivos proprios"   → INSERT usando entregadores.id
--   "Entregador le arquivos proprios"      → SELECT usando entregadores.id
--   "Entregador atualiza arquivos proprios" → UPDATE usando entregadores.id
--   "Admin gerencia documentos entregador"  → ALL para admins
;
