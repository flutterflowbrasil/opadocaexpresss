DROP POLICY IF EXISTS "Entregadores podem ver pedidos prontos" ON pedidos;
CREATE POLICY "Entregadores podem ver pedidos prontos"
ON pedidos FOR SELECT
TO public
USING (
  status = 'pronto' 
  AND entregador_id IS NULL 
  AND get_tipo_usuario() = 'entregador'
);

DROP POLICY IF EXISTS "Entregadores podem aceitar pedidos prontos" ON pedidos;
CREATE POLICY "Entregadores podem aceitar pedidos prontos"
ON pedidos FOR UPDATE
TO public
USING (
  status = 'pronto' 
  AND entregador_id IS NULL 
  AND get_tipo_usuario() = 'entregador'
)
WITH CHECK (
  status = 'em_entrega' 
  AND entregador_id = get_entregador_id()
);;
