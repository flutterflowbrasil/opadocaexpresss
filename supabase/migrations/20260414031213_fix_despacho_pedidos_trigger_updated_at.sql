
-- A tabela despacho_pedidos não tem coluna updated_at.
-- O trigger trg_despacho_pedidos_updated_at chama set_updated_at()
-- que tenta NEW.updated_at = NOW() → erro em todo UPDATE → aceite falha.
DROP TRIGGER IF EXISTS trg_despacho_pedidos_updated_at ON public.despacho_pedidos;
;
