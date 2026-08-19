-- Nao esvaziar o carrinho no checkout: a cobranca Asaas pode falhar
-- (subconta, CPF, etc.) e o cliente precisa poder tentar de novo.

DO $$
DECLARE
  src text;
BEGIN
  src := pg_get_functiondef('public.criar_pedido_validado(uuid, uuid, text, text, text)'::regprocedure);
  src := replace(
    src,
    'DELETE FROM public.carrinhos WHERE id = v_carrinho.id;',
    '-- Carrinho permanece ate a cobranca Asaas suceder.'
  );
  IF src IS NULL OR src NOT LIKE '%Carrinho permanece ate a cobranca Asaas suceder.%' THEN
    RAISE EXCEPTION 'Nao foi possivel remover o DELETE do carrinho em criar_pedido_validado.';
  END IF;
  EXECUTE src;
END $$;

GRANT EXECUTE ON FUNCTION public.criar_pedido_validado(uuid, uuid, text, text, text) TO authenticated;
