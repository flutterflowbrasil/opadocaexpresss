
ALTER TABLE public.pedidos
ADD COLUMN IF NOT EXISTS observacao_geral TEXT;

COMMENT ON COLUMN public.pedidos.observacao_geral IS 'Observação geral do pedido inserida pelo cliente no carrinho (ex: troco, portão, instruções de entrega).';
;
