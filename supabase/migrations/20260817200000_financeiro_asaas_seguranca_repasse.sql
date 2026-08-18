-- Financeiro Asaas: config unificada, validacao admin, repasse pos-entrega, estorno.

-- ── Colunas de repasse ──────────────────────────────────────────────────────
ALTER TABLE public.pedidos
  ADD COLUMN IF NOT EXISTS repasse_processado boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS repasse_processado_em timestamptz,
  ADD COLUMN IF NOT EXISTS estorno_solicitado_em timestamptz;

ALTER TABLE public.splits_pagamento
  ADD COLUMN IF NOT EXISTS repasse_estab_processado boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS repasse_entregador_processado boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS asaas_transfer_ids jsonb NOT NULL DEFAULT '{}'::jsonb;

CREATE UNIQUE INDEX IF NOT EXISTS asaas_eventos_financeiros_operacao_pedido_uidx
  ON public.asaas_eventos_financeiros (pedido_id, evento)
  WHERE pedido_id IS NOT NULL AND evento IN ('REPASSE_PEDIDO', 'ESTORNO_PEDIDO');

-- ── Config keys (fonte unica) ───────────────────────────────────────────────
UPDATE public.plataforma_configuracoes
   SET valor = 'false'
 WHERE chave = 'split_automatico_ativo'
   AND secao = 'financeiro';

INSERT INTO public.plataforma_configuracoes (secao, chave, valor, tipo, label, descricao, editavel) VALUES
  ('financeiro', 'percentual_comissao_estabelecimento', '6', 'number', 'Comissao plataforma (%)', 'Percentual sobre subtotal de produtos.', true),
  ('financeiro', 'teto_comissao_mensal', '408', 'number', 'Teto comissao mensal (R$)', 'Teto de comissao por estabelecimento/mes.', true),
  ('financeiro', 'taxa_minima_plataforma', '1.00', 'number', 'Taxa minima plataforma (R$)', 'Piso de comissao por pedido.', true),
  ('financeiro', 'taxa_transacao_gateway', '0', 'number', 'Taxa gateway (%)', 'Informativo/deducao interna Asaas.', true),
  ('financeiro', 'modo_repasse', 'pos_entrega', 'string', 'Modo de repasse', 'checkout_imediato | pos_coleta | pos_entrega', true),
  ('financeiro', 'repasse_estabelecimento_pct', '100', 'number', 'Repasse estabelecimento (%)', 'Percentual liberado no evento de repasse.', true),
  ('financeiro', 'repasse_entregador_pct', '100', 'number', 'Repasse entregador (%)', 'Percentual da taxa de entrega ao entregador.', true),
  ('financeiro', 'retencao_temporaria_ativa', 'false', 'boolean', 'Retencao temporaria ativa', 'Segura repasse ate prazo configurado.', true),
  ('financeiro', 'retencao_temporaria_horas', '0', 'number', 'Retencao (horas)', 'Horas apos entrega antes do repasse.', true),
  ('financeiro', 'exigir_subconta_homologada', 'true', 'boolean', 'Exigir subconta homologada', 'Bloqueia checkout se estab sem KYC Asaas.', true),
  ('financeiro', 'estorno_automatico_ativo', 'true', 'boolean', 'Estorno automatico', 'Estorna pagamento confirmado ao cancelar pedido.', true),
  ('entrega', 'entrega_base_km', '5', 'number', 'Km base entrega', 'Km incluidos na taxa base.', true),
  ('entrega', 'entrega_base_valor', '8.50', 'number', 'Valor base entrega (R$)', 'Taxa fixa ate base_km.', true),
  ('entrega', 'entrega_valor_km_excedente', '1.60', 'number', 'R$ por km extra', 'Valor por km acima da base.', true)
ON CONFLICT (secao, chave) DO NOTHING;

UPDATE public.plataforma_configuracoes
   SET editavel = false,
       descricao = COALESCE(descricao, '') || ' [DEPRECATED — usar percentual_comissao_estabelecimento]'
 WHERE chave IN ('split_estabelecimento_pct', 'split_plataforma_pct');

-- ── fn_get_config_financeira ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_get_config_financeira()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cfg jsonb := '{}'::jsonb;
BEGIN
  SELECT COALESCE(jsonb_object_agg(chave, valor), '{}'::jsonb)
    INTO v_cfg
  FROM (
    SELECT DISTINCT ON (chave) chave, valor
    FROM public.plataforma_configuracoes
    WHERE secao IN ('financeiro', 'cancelamento', 'entrega')
       OR chave IN (
         'percentual_comissao_estabelecimento',
         'teto_comissao_mensal',
         'taxa_servico_app_pct',
         'split_automatico_ativo'
       )
    ORDER BY chave, secao
  ) s;

  RETURN jsonb_build_object(
    'percentual_comissao_estabelecimento', COALESCE((v_cfg->>'percentual_comissao_estabelecimento')::numeric, 6),
    'teto_comissao_mensal', COALESCE((v_cfg->>'teto_comissao_mensal')::numeric, 408),
    'taxa_servico_app_pct', COALESCE((v_cfg->>'taxa_servico_app_pct')::numeric, 5),
    'taxa_minima_plataforma', COALESCE((v_cfg->>'taxa_minima_plataforma')::numeric, 1),
    'modo_repasse', COALESCE(v_cfg->>'modo_repasse', 'pos_entrega'),
    'split_automatico_ativo', COALESCE((v_cfg->>'split_automatico_ativo')::boolean, false),
    'repasse_estabelecimento_pct', COALESCE((v_cfg->>'repasse_estabelecimento_pct')::numeric, 100),
    'repasse_entregador_pct', COALESCE((v_cfg->>'repasse_entregador_pct')::numeric, 100),
    'retencao_temporaria_ativa', COALESCE((v_cfg->>'retencao_temporaria_ativa')::boolean, false),
    'retencao_temporaria_horas', COALESCE((v_cfg->>'retencao_temporaria_horas')::numeric, 0),
    'exigir_subconta_homologada', COALESCE((v_cfg->>'exigir_subconta_homologada')::boolean, true),
    'estorno_automatico_ativo', COALESCE((v_cfg->>'estorno_automatico_ativo')::boolean, true),
    'compensacao_antes_coleta', COALESCE((v_cfg->>'compensacao_antes_coleta')::numeric, 2),
    'compensacao_apos_coleta_pct', COALESCE((v_cfg->>'compensacao_apos_coleta_pct')::numeric, 50),
    'entrega_base_km', COALESCE((v_cfg->>'entrega_base_km')::numeric, 5),
    'entrega_base_valor', COALESCE((v_cfg->>'entrega_base_valor')::numeric, 8.5),
    'entrega_valor_km_excedente', COALESCE((v_cfg->>'entrega_valor_km_excedente')::numeric, 1.6)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.fn_get_config_financeira() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.fn_get_config_financeira() TO service_role;

-- ── fn_validar_config_financeira ────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_validar_config_financeira()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  v_num numeric;
  v_outra numeric;
BEGIN
  IF NEW.secao NOT IN ('financeiro', 'cancelamento', 'entrega') THEN
    RETURN NEW;
  END IF;

  IF NEW.valor ~ '^-?[0-9]+(\.[0-9]+)?$' THEN
    v_num := NEW.valor::numeric;
  END IF;

  CASE
    WHEN NEW.chave = 'percentual_comissao_estabelecimento' THEN
      IF v_num IS NULL OR v_num < 0 OR v_num > 30 THEN
        RAISE EXCEPTION 'percentual_comissao_estabelecimento deve estar entre 0 e 30';
      END IF;
    WHEN NEW.chave = 'taxa_servico_app_pct' THEN
      IF v_num IS NULL OR v_num < 0 OR v_num > 20 THEN
        RAISE EXCEPTION 'taxa_servico_app_pct deve estar entre 0 e 20';
      END IF;
    WHEN NEW.chave IN ('repasse_estabelecimento_pct', 'repasse_entregador_pct', 'compensacao_apos_coleta_pct') THEN
      IF v_num IS NULL OR v_num < 0 OR v_num > 100 THEN
        RAISE EXCEPTION '% deve estar entre 0 e 100', NEW.chave;
      END IF;
    WHEN NEW.chave IN (
      'teto_comissao_mensal', 'taxa_minima_plataforma', 'entrega_base_valor',
      'entrega_valor_km_excedente', 'entrega_base_km', 'retencao_temporaria_horas',
      'compensacao_antes_coleta'
    ) THEN
      IF v_num IS NULL OR v_num < 0 THEN
        RAISE EXCEPTION '% deve ser >= 0', NEW.chave;
      END IF;
    WHEN NEW.chave = 'modo_repasse' THEN
      IF NEW.valor NOT IN ('checkout_imediato', 'pos_coleta', 'pos_entrega') THEN
        RAISE EXCEPTION 'modo_repasse invalido';
      END IF;
    ELSE
      NULL;
  END CASE;

  IF NEW.chave IN ('percentual_comissao_estabelecimento', 'taxa_servico_app_pct') THEN
    SELECT COALESCE(valor::numeric, 0) INTO v_outra
      FROM public.plataforma_configuracoes
     WHERE chave = CASE NEW.chave
           WHEN 'percentual_comissao_estabelecimento' THEN 'taxa_servico_app_pct'
           ELSE 'percentual_comissao_estabelecimento'
         END
     LIMIT 1;
    IF (NEW.valor::numeric + COALESCE(v_outra, 0)) > 50 THEN
      RAISE EXCEPTION 'Soma comissao + taxa_servico_app nao pode exceder 50%%';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validar_config_financeira ON public.plataforma_configuracoes;
CREATE TRIGGER trg_validar_config_financeira
  BEFORE INSERT OR UPDATE OF valor ON public.plataforma_configuracoes
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_validar_config_financeira();

-- ── calcular_financeiro_pedido ──────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.calcular_financeiro_pedido(
  p_subtotal_produtos numeric,
  p_distancia_km numeric,
  p_estabelecimento_id uuid,
  p_desconto numeric DEFAULT 0,
  p_taxa_servico_app numeric DEFAULT 0
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cfg jsonb;
  v_comissao_pct numeric := 0.06;
  v_teto_mensal numeric := 408.00;
  v_taxa_minima numeric := 1.00;
  v_repasse_ent_pct numeric := 100;
  v_base_km numeric := 5.00;
  v_base_valor numeric := 8.50;
  v_km_excedente numeric := 1.60;
  v_usado_mes numeric := 0;
  v_comissao_bruta numeric := 0;
  v_comissao numeric := 0;
  v_taxa_entrega numeric := 0;
  v_entregador numeric := 0;
  v_estabelecimento numeric := 0;
  v_total numeric := 0;
BEGIN
  v_cfg := public.fn_get_config_financeira();
  v_comissao_pct := COALESCE((v_cfg->>'percentual_comissao_estabelecimento')::numeric, 6) / 100;
  v_teto_mensal := COALESCE((v_cfg->>'teto_comissao_mensal')::numeric, 408);
  v_taxa_minima := COALESCE((v_cfg->>'taxa_minima_plataforma')::numeric, 1);
  v_repasse_ent_pct := COALESCE((v_cfg->>'repasse_entregador_pct')::numeric, 100);
  v_base_km := COALESCE((v_cfg->>'entrega_base_km')::numeric, 5);
  v_base_valor := COALESCE((v_cfg->>'entrega_base_valor')::numeric, 8.5);
  v_km_excedente := COALESCE((v_cfg->>'entrega_valor_km_excedente')::numeric, 1.6);

  SELECT COALESCE(SUM(sp.plataforma_valor), 0)
    INTO v_usado_mes
  FROM public.splits_pagamento sp
  WHERE sp.estabelecimento_id = p_estabelecimento_id
    AND sp.created_at >= date_trunc('month', now())
    AND sp.created_at < date_trunc('month', now()) + interval '1 month';

  v_taxa_entrega := round(
    CASE
      WHEN COALESCE(p_distancia_km, 0) <= v_base_km THEN v_base_valor
      ELSE v_base_valor + ((COALESCE(p_distancia_km, 0) - v_base_km) * v_km_excedente)
    END,
    2
  );

  v_comissao_bruta := round(COALESCE(p_subtotal_produtos, 0) * v_comissao_pct, 2);
  v_comissao := GREATEST(
    LEAST(v_comissao_bruta, GREATEST(v_teto_mensal - v_usado_mes, 0)),
    CASE WHEN COALESCE(p_subtotal_produtos, 0) > 0 THEN LEAST(v_taxa_minima, COALESCE(p_subtotal_produtos, 0)) ELSE 0 END
  );
  v_estabelecimento := round(COALESCE(p_subtotal_produtos, 0) - v_comissao, 2);
  v_entregador := round(v_taxa_entrega * (v_repasse_ent_pct / 100), 2);
  v_total := round(
    GREATEST(
      COALESCE(p_subtotal_produtos, 0) + v_taxa_entrega + COALESCE(p_taxa_servico_app, 0) - COALESCE(p_desconto, 0),
      0
    ),
    2
  );

  RETURN jsonb_build_object(
    'subtotal_produtos', round(COALESCE(p_subtotal_produtos, 0), 2),
    'taxa_entrega', v_taxa_entrega,
    'taxa_servico_app', round(COALESCE(p_taxa_servico_app, 0), 2),
    'desconto', round(COALESCE(p_desconto, 0), 2),
    'comissao_plataforma', v_comissao,
    'comissao_plataforma_bruta', v_comissao_bruta,
    'comissao_teto_mensal', v_teto_mensal,
    'comissao_usada_mes', v_usado_mes,
    'estabelecimento_valor', v_estabelecimento,
    'entregador_valor', v_entregador,
    'valor_total', v_total,
    'modo_repasse', v_cfg->>'modo_repasse',
    'split_automatico_ativo', (v_cfg->>'split_automatico_ativo')::boolean
  );
END;
$$;

-- ── Hardening subcontas + GPS cliente ───────────────────────────────────────
DROP POLICY IF EXISTS "asaas_subcontas_owner_select" ON public.asaas_subcontas;

DROP POLICY IF EXISTS "rastreamento_read" ON public.rastreamento_entregadores;
CREATE POLICY "rastreamento_read"
ON public.rastreamento_entregadores
FOR SELECT
USING (
  entregador_id IN (SELECT id FROM public.entregadores WHERE usuario_id = auth.uid())
  OR pedido_id IN (
    SELECT p.id
    FROM public.pedidos p
    JOIN public.clientes c ON c.id = p.cliente_id
    WHERE c.usuario_id = auth.uid()
      AND p.status = ANY (ARRAY[
        'confirmado','preparando','pronto','a_caminho_coleta',
        'no_estabelecimento','coletado','a_caminho_cliente','em_entrega'
      ]::text[])
  )
  OR public.is_admin()
);

-- ── Protege colunas de repasse ──────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_proteger_colunas_financeiras_pedido()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF auth.role() = 'service_role' THEN
    RETURN NEW;
  END IF;

  IF NEW.subtotal_produtos IS DISTINCT FROM OLD.subtotal_produtos
     OR NEW.taxa_entrega IS DISTINCT FROM OLD.taxa_entrega
     OR NEW.taxa_servico_app IS DISTINCT FROM OLD.taxa_servico_app
     OR NEW.desconto_cupom IS DISTINCT FROM OLD.desconto_cupom
     OR NEW.total IS DISTINCT FROM OLD.total
     OR NEW.pagamento_status IS DISTINCT FROM OLD.pagamento_status
     OR NEW.pagamento_metodo IS DISTINCT FROM OLD.pagamento_metodo
     OR NEW.split_processado IS DISTINCT FROM OLD.split_processado
     OR NEW.financeiro_processado IS DISTINCT FROM OLD.financeiro_processado
     OR NEW.asaas_payment_id IS DISTINCT FROM OLD.asaas_payment_id
     OR NEW.asaas_invoice_url IS DISTINCT FROM OLD.asaas_invoice_url
     OR NEW.valor_liquido IS DISTINCT FROM OLD.valor_liquido
     OR NEW.taxa_asaas IS DISTINCT FROM OLD.taxa_asaas
     OR NEW.taxa_plataforma_calculada IS DISTINCT FROM OLD.taxa_plataforma_calculada
     OR NEW.repasse_processado IS DISTINCT FROM OLD.repasse_processado
     OR NEW.repasse_processado_em IS DISTINCT FROM OLD.repasse_processado_em
     OR NEW.estorno_solicitado_em IS DISTINCT FROM OLD.estorno_solicitado_em
     OR NEW.cliente_id IS DISTINCT FROM OLD.cliente_id
     OR NEW.estabelecimento_id IS DISTINCT FROM OLD.estabelecimento_id
  THEN
    RAISE EXCEPTION 'Colunas financeiras e de pagamento sao imutaveis pelo app.'
      USING ERRCODE = '42501';
  END IF;

  RETURN NEW;
END;
$$;

-- ── Disparo repasse/estorno via pg_net ──────────────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_disparar_repasse_pedido(p_pedido_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, vault, net
AS $$
DECLARE
  v_secret text;
BEGIN
  SELECT decrypted_secret INTO v_secret
    FROM vault.decrypted_secrets
   WHERE name = 'finance_worker_secret'
   LIMIT 1;

  IF v_secret IS NULL OR length(v_secret) = 0 THEN
    SELECT decrypted_secret INTO v_secret
      FROM vault.decrypted_secrets
     WHERE name = 'push_worker_secret'
     LIMIT 1;
  END IF;

  IF v_secret IS NULL OR length(v_secret) = 0 THEN
    RAISE WARNING 'worker secret ausente no vault — repasse nao disparado';
    RETURN;
  END IF;

  PERFORM net.http_post(
    url := 'https://blibxmylxcrztfhvllkj.supabase.co/functions/v1/asaas-liberar-repasse-pedido',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-worker-secret', v_secret
    ),
    body := jsonb_build_object('pedido_id', p_pedido_id)
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_disparar_estorno_pedido(p_pedido_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, vault, net
AS $$
DECLARE
  v_secret text;
  v_cfg jsonb;
BEGIN
  v_cfg := public.fn_get_config_financeira();
  IF NOT COALESCE((v_cfg->>'estorno_automatico_ativo')::boolean, true) THEN
    RETURN;
  END IF;

  SELECT decrypted_secret INTO v_secret
    FROM vault.decrypted_secrets
   WHERE name = 'finance_worker_secret'
   LIMIT 1;

  IF v_secret IS NULL OR length(v_secret) = 0 THEN
    SELECT decrypted_secret INTO v_secret
      FROM vault.decrypted_secrets
     WHERE name = 'push_worker_secret'
     LIMIT 1;
  END IF;

  IF v_secret IS NULL OR length(v_secret) = 0 THEN
    RAISE WARNING 'worker secret ausente no vault — estorno nao disparado';
    RETURN;
  END IF;

  PERFORM net.http_post(
    url := 'https://blibxmylxcrztfhvllkj.supabase.co/functions/v1/asaas-estornar-pagamento',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-worker-secret', v_secret
    ),
    body := jsonb_build_object('pedido_id', p_pedido_id)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.fn_disparar_repasse_pedido(uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fn_disparar_estorno_pedido(uuid) FROM PUBLIC, anon, authenticated;

-- ── fn_confirmar_entrega: dispara repasse ───────────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_confirmar_entrega(
  p_pedido_id uuid,
  p_codigo text,
  p_foto_path text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_pedido public.pedidos%ROWTYPE;
  v_entregador_id uuid := public.get_entregador_id();
BEGIN
  IF NOT public._entregador_dono_pedido(p_pedido_id) THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Pedido nao atribuido a este entregador.');
  END IF;

  SELECT * INTO v_pedido FROM public.pedidos WHERE id = p_pedido_id FOR UPDATE;
  IF v_pedido.status NOT IN ('em_entrega', 'a_caminho_cliente', 'coletado') THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Status invalido para confirmar entrega.');
  END IF;

  IF v_pedido.codigo_confirmacao_entrega IS NULL
     OR upper(btrim(v_pedido.codigo_confirmacao_entrega)) <> upper(btrim(COALESCE(p_codigo, ''))) THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Codigo de entrega incorreto.');
  END IF;

  UPDATE public.pedidos
     SET status = 'entregue',
         entregue_em = COALESCE(entregue_em, now()),
         updated_at = now()
   WHERE id = p_pedido_id;

  UPDATE public.entregadores
     SET status_despacho = 'livre',
         pedido_atual_id = NULL,
         ultima_entrega_em = now(),
         total_entregas = COALESCE(total_entregas, 0) + 1,
         updated_at = now()
   WHERE id = v_entregador_id;

  PERFORM public.fn_disparar_repasse_pedido(p_pedido_id);

  RETURN jsonb_build_object('ok', true, 'status', 'entregue', 'foto_path', p_foto_path);
END;
$$;

-- ── Cancelamento estab: dispara estorno se pago ─────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_atualizar_status_pedido_estab(
  p_pedido_id uuid,
  p_novo_status text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_pedido public.pedidos%ROWTYPE;
  v_permitido boolean := false;
BEGIN
  IF NOT public._estab_dono_pedido(p_pedido_id) AND NOT public.is_admin() THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Pedido nao pertence a este estabelecimento.');
  END IF;

  SELECT * INTO v_pedido FROM public.pedidos WHERE id = p_pedido_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Pedido nao encontrado.');
  END IF;

  v_permitido := CASE v_pedido.status
    WHEN 'pendente' THEN p_novo_status IN ('confirmado', 'cancelado_estab')
    WHEN 'confirmado' THEN p_novo_status IN ('preparando', 'cancelado_estab')
    WHEN 'preparando' THEN p_novo_status IN ('pronto', 'cancelado_estab')
    WHEN 'pronto' THEN p_novo_status IN ('cancelado_estab')
    ELSE false
  END;

  IF NOT v_permitido THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Transicao de status nao permitida.',
      'status_atual', v_pedido.status, 'novo_status', p_novo_status);
  END IF;

  UPDATE public.pedidos
     SET status = p_novo_status, updated_at = now()
   WHERE id = p_pedido_id;

  IF p_novo_status = 'cancelado_estab'
     AND v_pedido.pagamento_status IN ('confirmado', 'aguardando_pagamento')
     AND v_pedido.asaas_payment_id IS NOT NULL THEN
    PERFORM public.fn_disparar_estorno_pedido(p_pedido_id);
  END IF;

  RETURN jsonb_build_object('ok', true, 'status', p_novo_status);
END;
$$;
