
-- ============================================================
-- Tabela: asaas_subcontas
-- Armazena walletId e apiKey de cada subconta Asaas
-- ============================================================
CREATE TABLE public.asaas_subcontas (
  id               uuid NOT NULL DEFAULT uuid_generate_v4(),
  entidade_tipo    text NOT NULL CHECK (entidade_tipo IN ('estabelecimento', 'entregador')),
  entidade_id      uuid NOT NULL,
  asaas_account_id text NOT NULL UNIQUE,
  asaas_wallet_id  text NOT NULL UNIQUE,
  asaas_api_key    text NOT NULL,
  status_conta     text NOT NULL DEFAULT 'pending'
                   CHECK (status_conta IN ('pending', 'active', 'blocked', 'rejected')),
  dados_comerciais jsonb DEFAULT '{}',
  created_at       timestamp with time zone DEFAULT now(),
  updated_at       timestamp with time zone DEFAULT now(),
  CONSTRAINT asaas_subcontas_pkey PRIMARY KEY (id)
);

CREATE INDEX idx_asaas_subcontas_entidade
  ON public.asaas_subcontas (entidade_tipo, entidade_id);

-- RLS
ALTER TABLE public.asaas_subcontas ENABLE ROW LEVEL SECURITY;

CREATE POLICY "asaas_subcontas_bloqueado_usuarios"
  ON public.asaas_subcontas FOR SELECT
  USING (false);

CREATE POLICY "asaas_subcontas_admin_select"
  ON public.asaas_subcontas FOR SELECT
  USING (is_admin_global());

CREATE POLICY "asaas_subcontas_insert_bloqueado"
  ON public.asaas_subcontas FOR INSERT
  WITH CHECK (false);

CREATE POLICY "asaas_subcontas_update_bloqueado"
  ON public.asaas_subcontas FOR UPDATE
  USING (false);

CREATE POLICY "asaas_subcontas_delete_bloqueado"
  ON public.asaas_subcontas FOR DELETE
  USING (false);

-- ============================================================
-- Tabela: asaas_webhooks_log
-- Auditoria e idempotência de eventos recebidos do Asaas
-- ============================================================
CREATE TABLE public.asaas_webhooks_log (
  id              uuid NOT NULL DEFAULT uuid_generate_v4(),
  evento          text NOT NULL,
  asaas_event_id  text UNIQUE,
  payload         jsonb NOT NULL,
  processado      boolean DEFAULT false,
  processado_em   timestamp with time zone,
  erro            text,
  created_at      timestamp with time zone DEFAULT now(),
  CONSTRAINT asaas_webhooks_log_pkey PRIMARY KEY (id)
);

CREATE INDEX idx_webhooks_log_event_id ON public.asaas_webhooks_log (asaas_event_id);
CREATE INDEX idx_webhooks_log_evento   ON public.asaas_webhooks_log (evento);
CREATE INDEX idx_webhooks_log_created  ON public.asaas_webhooks_log (created_at DESC);

-- RLS
ALTER TABLE public.asaas_webhooks_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "webhooks_log_select_admin"
  ON public.asaas_webhooks_log FOR SELECT
  USING (is_admin_global());

CREATE POLICY "webhooks_log_insert_bloqueado"
  ON public.asaas_webhooks_log FOR INSERT
  WITH CHECK (false);

CREATE POLICY "webhooks_log_update_bloqueado"
  ON public.asaas_webhooks_log FOR UPDATE
  USING (false);

CREATE POLICY "webhooks_log_delete_bloqueado"
  ON public.asaas_webhooks_log FOR DELETE
  USING (false);
;
