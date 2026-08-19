-- Push de oferta de despacho com despacho_id + pedido_id no payload OneSignal.
-- O trigger trg_notif_despacho era referenciado mas nao existia nas migrations.

CREATE OR REPLACE FUNCTION public.trg_notif_despacho()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_usuario uuid;
  v_estab text;
  v_taxa numeric;
  v_timeout text;
BEGIN
  IF NEW.status IS DISTINCT FROM 'aguardando' THEN
    RETURN NEW;
  END IF;

  SELECT e.usuario_id INTO v_usuario
    FROM public.entregadores e
   WHERE e.id = NEW.entregador_id;

  IF v_usuario IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT COALESCE(est.nome_fantasia, est.razao_social, 'Estabelecimento'),
         p.taxa_entrega
    INTO v_estab, v_taxa
    FROM public.pedidos p
    LEFT JOIN public.estabelecimentos est ON est.id = p.estabelecimento_id
   WHERE p.id = NEW.pedido_id;

  SELECT valor INTO v_timeout
    FROM public.plataforma_configuracoes
   WHERE chave = 'tempo_resposta_seg'
   LIMIT 1;

  PERFORM public.enfileirar_notificacao(
    v_usuario,
    'despacho_nova_oferta',
    'despacho',
    NEW.id,
    jsonb_build_object(
      'estabelecimento', COALESCE(v_estab, 'Estabelecimento'),
      'distancia_km', COALESCE(round(NEW.distancia_km::numeric, 1)::text, '0'),
      'tempo_resposta', COALESCE(v_timeout, '30')
    ),
    jsonb_build_object(
      'despacho_id', NEW.id,
      'pedido_id', NEW.pedido_id,
      'valor_entrega', COALESCE(v_taxa, 0),
      'distancia_km', COALESCE(NEW.distancia_km, 0)
    )
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notif_despacho ON public.despacho_pedidos;
CREATE TRIGGER trg_notif_despacho
  AFTER INSERT ON public.despacho_pedidos
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_notif_despacho();
