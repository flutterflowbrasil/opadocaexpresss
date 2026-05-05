
-- ============================================================
-- FLUXO DE COLETA NO BALCÃO — complemento final
-- O banco já tem:
--   ✅ status: a_caminho_coleta, no_estabelecimento, coletado, a_caminho_cliente
--   ✅ timestamps: a_caminho_coleta_em, chegou_estabelecimento_em, coletado_em, a_caminho_cliente_em
--   ✅ triggers de notificação para todos esses status
--   ✅ templates: pedido_entregador_a_caminho, pedido_entregador_chegou, pedido_coletado
-- O que falta:
--   ❌ codigo_coleta_balcao (PIN de retirada no balcão)
--   ❌ trigger que preenche os timestamps automaticamente ao mudar status
--   ❌ RLS policy que permite entregador avançar os novos status
-- ============================================================

-- ── 1. Código de coleta no balcão (diferente do código de entrega ao cliente) ──
ALTER TABLE public.pedidos
  ADD COLUMN IF NOT EXISTS codigo_coleta_balcao text;

COMMENT ON COLUMN public.pedidos.codigo_coleta_balcao IS
  'PIN de 4 dígitos para validar retirada no balcão do estabelecimento.
   Diferente de codigo_confirmacao_entrega (que é para o cliente).
   Gerado no INSERT. Exibido para o estabelecimento no painel POS.
   Entregador informa ao chegar — balcão confirma.';

-- Preenche com dígitos baseados no UUID do pedido (diferente do código de entrega)
-- Usa os últimos bytes do UUID para garantir que os dois códigos sejam diferentes
UPDATE public.pedidos
SET codigo_coleta_balcao = LPAD(
  (1000 + (
    ('x' || SUBSTR(REPLACE(id::text, '-', ''), 24, 8))::bit(32)::bigint % 9000
  ))::text,
  4, '0'
)
WHERE codigo_coleta_balcao IS NULL;

-- ── 2. Atualiza trigger de geração de código para incluir codigo_coleta_balcao ──
CREATE OR REPLACE FUNCTION public.fn_gerar_codigo_confirmacao()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Código de entrega ao cliente (baseado nos primeiros bytes do UUID)
  NEW.codigo_confirmacao_entrega := LPAD(
    (1000 + (
      ('x' || SUBSTR(NEW.id::text, 1, 8))::bit(32)::bigint % 9000
    ))::text,
    4, '0'
  );

  -- Código de coleta no balcão (baseado nos bytes finais do UUID — diferente)
  NEW.codigo_coleta_balcao := LPAD(
    (1000 + (
      ('x' || SUBSTR(REPLACE(NEW.id::text, '-', ''), 24, 8))::bit(32)::bigint % 9000
    ))::text,
    4, '0'
  );

  RETURN NEW;
END;
$$;

-- ── 3. Trigger que preenche timestamps ao mudar status ───────────────────────
CREATE OR REPLACE FUNCTION public.fn_timestamps_status_pedido()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF OLD.status = NEW.status THEN RETURN NEW; END IF;

  CASE NEW.status
    WHEN 'a_caminho_coleta'   THEN NEW.a_caminho_coleta_em      := COALESCE(NEW.a_caminho_coleta_em,      now());
    WHEN 'no_estabelecimento' THEN NEW.chegou_estabelecimento_em := COALESCE(NEW.chegou_estabelecimento_em, now());
    WHEN 'coletado'           THEN NEW.coletado_em               := COALESCE(NEW.coletado_em,               now());
    WHEN 'a_caminho_cliente'  THEN NEW.a_caminho_cliente_em      := COALESCE(NEW.a_caminho_cliente_em,      now());
    WHEN 'em_entrega'         THEN NEW.em_entrega_em             := COALESCE(NEW.em_entrega_em,             now());
    WHEN 'entregue'           THEN NEW.entregue_em               := COALESCE(NEW.entregue_em,               now());
    WHEN 'confirmado'         THEN NEW.confirmado_em             := COALESCE(NEW.confirmado_em,             now());
    WHEN 'preparando'         THEN NEW.preparando_em             := COALESCE(NEW.preparando_em,             now());
    WHEN 'pronto'             THEN NEW.pronto_em                 := COALESCE(NEW.pronto_em,                 now());
    WHEN 'cancelado_cliente',
         'cancelado_estab',
         'cancelado_sistema'  THEN NEW.cancelado_em              := COALESCE(NEW.cancelado_em,              now());
    ELSE NULL;
  END CASE;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_timestamps_status ON public.pedidos;
CREATE TRIGGER trg_timestamps_status
  BEFORE UPDATE OF status ON public.pedidos
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_timestamps_status_pedido();

-- ── 4. Templates de notificação para os novos status (se não existirem) ──────
INSERT INTO public.notificacao_templates (evento, titulo, corpo, canal_android)
VALUES
  ('pedido_entregador_a_caminho', '🛵 Entregador a caminho!',
   '{{entregador}} está indo buscar seu pedido no {{estabelecimento}}.', 'pedidos'),
  ('pedido_entregador_chegou', '📍 Entregador chegou!',
   '{{entregador}} chegou ao balcão. Prepare o pedido para retirada.', 'pedidos'),
  ('pedido_coletado', '📦 Pedido coletado!',
   'Seu pedido foi retirado por {{entregador}} e está a caminho!', 'pedidos'),
  ('pedido_a_caminho_cliente', '🚀 Pedido a caminho!',
   '{{entregador}} saiu para entregar. Tempo estimado: {{tempo_estimado}} min.', 'pedidos')
ON CONFLICT (evento) DO UPDATE SET
  titulo       = EXCLUDED.titulo,
  corpo        = EXCLUDED.corpo,
  canal_android = EXCLUDED.canal_android,
  ativo        = true;

-- ── 5. RLS — entregador pode avançar os status de coleta do seu pedido ────────
DROP POLICY IF EXISTS "Entregador avança status de coleta" ON public.pedidos;
CREATE POLICY "Entregador avança status de coleta"
  ON public.pedidos
  FOR UPDATE
  TO authenticated
  USING (
    entregador_id = get_entregador_id()
    AND get_tipo_usuario() = 'entregador'
    AND status IN (
      'confirmado', 'a_caminho_coleta', 'no_estabelecimento',
      'coletado', 'a_caminho_cliente', 'em_entrega'
    )
  )
  WITH CHECK (
    status IN (
      'a_caminho_coleta', 'no_estabelecimento',
      'coletado', 'a_caminho_cliente', 'em_entrega', 'entregue'
    )
  );

-- ── 6. Índice para o novo código ──────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_pedidos_codigo_coleta_balcao
  ON public.pedidos (codigo_coleta_balcao)
  WHERE status NOT IN ('cancelado_cliente', 'cancelado_estab', 'cancelado_sistema');
;
