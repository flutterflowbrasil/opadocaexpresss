
-- ============================================================
-- ÚLTIMA MORDIDA — Ôpadoca Express
-- ============================================================
-- Produto que está na prateleira há um tempo e precisa ser
-- vendido. Exibido em destaque especial no app do cliente.
-- O estabelecimento ativa manualmente OU o sistema sugere
-- automaticamente com base no tempo sem venda.
-- ============================================================

-- ── 1. Campos na tabela produtos ─────────────────────────────────────────────
ALTER TABLE public.produtos
  -- Flag principal: está em modo "Última Mordida"?
  ADD COLUMN IF NOT EXISTS ultima_mordida              boolean     NOT NULL DEFAULT false,

  -- Quando foi ativado (manual ou automático)
  ADD COLUMN IF NOT EXISTS ultima_mordida_ativado_em   timestamptz,

  -- Quando expira automaticamente (null = não expira sozinho)
  ADD COLUMN IF NOT EXISTS ultima_mordida_expira_em    timestamptz,

  -- Desconto opcional aplicado enquanto em Última Mordida
  -- Percentual de 0 a 100. NULL = sem desconto adicional
  ADD COLUMN IF NOT EXISTS ultima_mordida_desconto_pct numeric(5,2)
    CHECK (ultima_mordida_desconto_pct IS NULL
        OR (ultima_mordida_desconto_pct >= 0 AND ultima_mordida_desconto_pct <= 100)),

  -- Preço com desconto calculado (gerado automaticamente)
  -- Atualizado por trigger quando desconto_pct muda
  ADD COLUMN IF NOT EXISTS ultima_mordida_preco        numeric(10,2),

  -- Motivo/chamada de venda (ex: "Última fatia de torta!")
  -- Se null, o app usa o nome do produto
  ADD COLUMN IF NOT EXISTS ultima_mordida_chamada      text,

  -- Quem ativou: 'manual' (estabelecimento) ou 'automatico' (sistema)
  ADD COLUMN IF NOT EXISTS ultima_mordida_origem       text
    CHECK (ultima_mordida_origem IN ('manual', 'automatico'));

COMMENT ON COLUMN public.produtos.ultima_mordida IS
  'Produto em destaque especial: está na prateleira há tempo e precisa ser vendido.';
COMMENT ON COLUMN public.produtos.ultima_mordida_desconto_pct IS
  'Desconto percentual aplicado enquanto em Última Mordida (0-100). NULL = sem desconto.';
COMMENT ON COLUMN public.produtos.ultima_mordida_preco IS
  'Preço final com desconto da Última Mordida. Calculado automaticamente.';
COMMENT ON COLUMN public.produtos.ultima_mordida_chamada IS
  'Texto de destaque exibido no app. Ex: "Última fatia de torta!". NULL usa o nome do produto.';

-- ── 2. Função: ativa Última Mordida num produto ───────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_ativar_ultima_mordida(
  p_produto_id    uuid,
  p_desconto_pct  numeric  DEFAULT NULL,   -- 0-100, null = sem desconto
  p_chamada       text     DEFAULT NULL,   -- texto livre, null = usa nome do produto
  p_duracao_horas integer  DEFAULT NULL,   -- null = não expira automaticamente
  p_origem        text     DEFAULT 'manual'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_preco_base  numeric;
  v_preco_final numeric;
  v_expira_em   timestamptz;
BEGIN
  SELECT preco INTO v_preco_base FROM public.produtos WHERE id = p_produto_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Produto não encontrado');
  END IF;

  -- Calcula preço com desconto
  IF p_desconto_pct IS NOT NULL AND p_desconto_pct > 0 THEN
    v_preco_final := ROUND(v_preco_base * (1 - p_desconto_pct / 100), 2);
  ELSE
    v_preco_final := v_preco_base;
  END IF;

  -- Calcula expiração se duracao_horas for informado
  IF p_duracao_horas IS NOT NULL AND p_duracao_horas > 0 THEN
    v_expira_em := now() + (p_duracao_horas || ' hours')::interval;
  END IF;

  UPDATE public.produtos SET
    ultima_mordida             = true,
    ultima_mordida_ativado_em  = now(),
    ultima_mordida_expira_em   = v_expira_em,
    ultima_mordida_desconto_pct = p_desconto_pct,
    ultima_mordida_preco       = v_preco_final,
    ultima_mordida_chamada     = p_chamada,
    ultima_mordida_origem      = COALESCE(p_origem, 'manual'),
    destaque                   = true,   -- também aparece em destaque no app
    updated_at                 = now()
  WHERE id = p_produto_id;

  RETURN jsonb_build_object(
    'ok',           true,
    'produto_id',   p_produto_id,
    'preco_original', v_preco_base,
    'preco_ultima_mordida', v_preco_final,
    'desconto_pct', p_desconto_pct,
    'expira_em',    v_expira_em
  );
END;
$$;

-- ── 3. Função: desativa Última Mordida ───────────────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_desativar_ultima_mordida(p_produto_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.produtos SET
    ultima_mordida              = false,
    ultima_mordida_ativado_em   = NULL,
    ultima_mordida_expira_em    = NULL,
    ultima_mordida_desconto_pct = NULL,
    ultima_mordida_preco        = NULL,
    ultima_mordida_chamada      = NULL,
    ultima_mordida_origem       = NULL,
    destaque                    = false,
    updated_at                  = now()
  WHERE id = p_produto_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Produto não encontrado');
  END IF;

  RETURN jsonb_build_object('ok', true);
END;
$$;

-- ── 4. Função: expira automaticamente Últimas Mordidas vencidas ──────────────
-- Chamada pela Edge Function (watchdog) ou cron externo
CREATE OR REPLACE FUNCTION public.fn_expirar_ultimas_mordidas()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE v_count integer;
BEGIN
  UPDATE public.produtos SET
    ultima_mordida              = false,
    ultima_mordida_ativado_em   = NULL,
    ultima_mordida_expira_em    = NULL,
    ultima_mordida_desconto_pct = NULL,
    ultima_mordida_preco        = NULL,
    ultima_mordida_chamada      = NULL,
    ultima_mordida_origem       = NULL,
    destaque                    = false,
    updated_at                  = now()
  WHERE ultima_mordida = true
    AND ultima_mordida_expira_em IS NOT NULL
    AND ultima_mordida_expira_em < now();

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

-- ── 5. View: produtos em Última Mordida (para o app do cliente) ───────────────
CREATE OR REPLACE VIEW public.vw_ultima_mordida AS
SELECT
  p.id,
  p.estabelecimento_id,
  p.nome,
  p.descricao,
  p.foto_principal_url,
  p.preco                       AS preco_original,
  p.ultima_mordida_preco        AS preco_ultima_mordida,
  p.ultima_mordida_desconto_pct AS desconto_pct,
  p.ultima_mordida_chamada      AS chamada,
  p.ultima_mordida_ativado_em   AS ativado_em,
  p.ultima_mordida_expira_em    AS expira_em,
  p.ultima_mordida_origem       AS origem,
  p.quantidade_estoque,
  p.slug,
  -- Tempo restante em minutos (null se não expira)
  CASE WHEN p.ultima_mordida_expira_em IS NOT NULL
    THEN GREATEST(0, EXTRACT(EPOCH FROM (p.ultima_mordida_expira_em - now())) / 60)::integer
    ELSE NULL
  END AS minutos_restantes,
  -- Tempo na prateleira desde a ativação
  EXTRACT(EPOCH FROM (now() - p.ultima_mordida_ativado_em)) / 3600 AS horas_em_destaque,
  e.nome_fantasia               AS estabelecimento_nome,
  e.slug                        AS estabelecimento_slug,
  e.latitude,
  e.longitude
FROM public.produtos p
JOIN public.estabelecimentos e ON e.id = p.estabelecimento_id
WHERE p.ultima_mordida = true
  AND p.disponivel     = true
  AND p.ativo          = true
  AND (p.ultima_mordida_expira_em IS NULL OR p.ultima_mordida_expira_em > now());

COMMENT ON VIEW public.vw_ultima_mordida IS
  'Produtos em destaque "Última Mordida" ativos e não expirados, com info de desconto e estabelecimento.';

-- ── 6. Índices ────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_produtos_ultima_mordida
  ON public.produtos (estabelecimento_id, ultima_mordida_ativado_em DESC)
  WHERE ultima_mordida = true AND disponivel = true AND ativo = true;

CREATE INDEX IF NOT EXISTS idx_produtos_ultima_mordida_expira
  ON public.produtos (ultima_mordida_expira_em)
  WHERE ultima_mordida = true AND ultima_mordida_expira_em IS NOT NULL;

-- ── 7. Notificação push quando Última Mordida é ativada ──────────────────────
-- Template para envio em broadcast para clientes próximos ao estabelecimento
INSERT INTO public.notificacao_templates (evento, titulo, corpo, canal_android)
VALUES (
  'ultima_mordida_disponivel',
  '🍰 Última Mordida disponível!',
  '{{chamada}} em {{estabelecimento}} — {{desconto}}% off! Garanta o seu.',
  'promocoes'
)
ON CONFLICT (evento) DO UPDATE SET
  titulo       = EXCLUDED.titulo,
  corpo        = EXCLUDED.corpo,
  canal_android = EXCLUDED.canal_android,
  ativo        = true;
;
