-- Pagamentos Asaas: flag servidor, RPC loja aberta, revokes, pos_coleta, retencao, URL worker.

-- ── Flag: pagamentos online (bloqueio só no servidor) ───────────────────────
INSERT INTO public.plataforma_configuracoes (secao, chave, valor, tipo, label, descricao, editavel)
VALUES (
  'financeiro',
  'pagamentos_online_ativos',
  'true',
  'boolean',
  'Pagamentos online (Pix/cartao)',
  'Desligue enquanto a chave Asaas nao estiver valida. Dinheiro no balcao continua.',
  true
)
ON CONFLICT (secao, chave) DO NOTHING;

-- ── Loja aberta (usada no checkout do cliente) ──────────────────────────────
CREATE OR REPLACE FUNCTION public.verificar_estabelecimento_aberto(estab_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT e.status_aberto FROM public.estabelecimentos e WHERE e.id = estab_id),
    false
  );
$$;

REVOKE ALL ON FUNCTION public.verificar_estabelecimento_aberto(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.verificar_estabelecimento_aberto(uuid) TO authenticated, service_role;

-- ── Bloqueio Pix/cartao se flag desligada ───────────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_bloquear_pagamento_offline()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_flag text;
BEGIN
  IF NEW.pagamento_metodo IN ('pix', 'cartao_credito', 'cartao_debito') THEN
    SELECT valor INTO v_flag
      FROM public.plataforma_configuracoes
     WHERE chave = 'pagamentos_online_ativos'
     ORDER BY secao
     LIMIT 1;
    IF lower(coalesce(v_flag, 'true')) IN ('false', '0', 'nao', 'off') THEN
      RAISE EXCEPTION 'Pagamentos temporariamente indisponiveis.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_bloquear_pagamento_offline ON public.pedidos;
CREATE TRIGGER trg_bloquear_pagamento_offline
  BEFORE INSERT ON public.pedidos
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_bloquear_pagamento_offline();

-- ── Ledger legado: nao inflar saldo interno ─────────────────────────────────
REVOKE ALL ON FUNCTION public.incrementar_saldo_entregador(uuid, numeric) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.incrementar_saldo_entregador(uuid, numeric) TO service_role;

DROP POLICY IF EXISTS "entregador_saques_insert_owner" ON public.entregador_saques;
DROP POLICY IF EXISTS "saques_insert_proprio" ON public.entregador_saques;

-- ── Retencao: agenda em vez de skip permanente ──────────────────────────────
ALTER TABLE public.pedidos
  ADD COLUMN IF NOT EXISTS repasse_liberar_em timestamptz;

-- ── URL do worker via vault (fallback projeto atual) ────────────────────────
CREATE OR REPLACE FUNCTION public.fn_functions_base_url()
RETURNS text
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, vault
AS $$
DECLARE
  v_url text;
BEGIN
  SELECT decrypted_secret INTO v_url
    FROM vault.decrypted_secrets
   WHERE name IN ('supabase_functions_base_url', 'supabase_url')
   ORDER BY CASE name WHEN 'supabase_functions_base_url' THEN 0 ELSE 1 END
   LIMIT 1;
  IF v_url IS NULL OR length(trim(v_url)) = 0 THEN
    v_url := 'https://blibxmylxcrztfhvllkj.supabase.co';
  END IF;
  RETURN rtrim(trim(v_url), '/');
END;
$$;

REVOKE ALL ON FUNCTION public.fn_functions_base_url() FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.fn_disparar_repasse_pedido(p_pedido_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, vault, net
AS $$
DECLARE
  v_secret text;
  v_base text;
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

  v_base := public.fn_functions_base_url();

  PERFORM net.http_post(
    url := v_base || '/functions/v1/asaas-liberar-repasse-pedido',
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
  v_base text;
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

  v_base := public.fn_functions_base_url();

  PERFORM net.http_post(
    url := v_base || '/functions/v1/asaas-estornar-pagamento',
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

-- ── pos_coleta: dispara repasse ao coletar ──────────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_repasse_on_pedido_status()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_modo text;
BEGIN
  IF NEW.status IS NOT DISTINCT FROM OLD.status THEN
    RETURN NEW;
  END IF;
  IF NEW.status <> 'coletado' THEN
    RETURN NEW;
  END IF;

  v_modo := COALESCE((public.fn_get_config_financeira()->>'modo_repasse'), 'pos_entrega');
  IF v_modo = 'pos_coleta' AND COALESCE(NEW.pagamento_status, '') = 'confirmado' THEN
    PERFORM public.fn_disparar_repasse_pedido(NEW.id);
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_repasse_on_pedido_status ON public.pedidos;
CREATE TRIGGER trg_repasse_on_pedido_status
  AFTER UPDATE OF status ON public.pedidos
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_repasse_on_pedido_status();

-- ── Job: libera repasses cuja retencao ja venceu ────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_processar_repasses_pendentes()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row record;
  v_n integer := 0;
BEGIN
  FOR v_row IN
    SELECT id
      FROM public.pedidos
     WHERE COALESCE(repasse_processado, false) = false
       AND pagamento_status = 'confirmado'
       AND asaas_payment_id IS NOT NULL
       AND repasse_liberar_em IS NOT NULL
       AND repasse_liberar_em <= now()
     ORDER BY repasse_liberar_em
     LIMIT 50
  LOOP
    PERFORM public.fn_disparar_repasse_pedido(v_row.id);
    v_n := v_n + 1;
  END LOOP;
  RETURN v_n;
END;
$$;

REVOKE ALL ON FUNCTION public.fn_processar_repasses_pendentes() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.fn_processar_repasses_pendentes() TO service_role;

-- Inclui flag no JSON financeiro
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
         'split_automatico_ativo',
         'pagamentos_online_ativos'
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
    'pagamentos_online_ativos', COALESCE((v_cfg->>'pagamentos_online_ativos')::boolean, true),
    'compensacao_antes_coleta', COALESCE((v_cfg->>'compensacao_antes_coleta')::numeric, 2),
    'compensacao_apos_coleta_pct', COALESCE((v_cfg->>'compensacao_apos_coleta_pct')::numeric, 50),
    'entrega_base_km', COALESCE((v_cfg->>'entrega_base_km')::numeric, 5),
    'entrega_base_valor', COALESCE((v_cfg->>'entrega_base_valor')::numeric, 8.5),
    'entrega_valor_km_excedente', COALESCE((v_cfg->>'entrega_valor_km_excedente')::numeric, 1.6)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.fn_get_config_financeira() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.fn_get_config_financeira() TO service_role, postgres;
