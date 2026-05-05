
CREATE OR REPLACE FUNCTION public.incrementar_saldo_entregador(
  p_entregador_id uuid,
  p_valor         numeric
) RETURNS void AS $$
BEGIN
  UPDATE public.entregador_saldos
  SET
    saldo_disponivel = saldo_disponivel + p_valor,
    updated_at       = now()
  WHERE entregador_id = p_entregador_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
;
