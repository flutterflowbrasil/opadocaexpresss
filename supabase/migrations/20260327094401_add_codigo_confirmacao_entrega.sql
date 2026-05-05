
-- ── 1. Adiciona coluna simples (preenchida por trigger) ──────────────────────
ALTER TABLE public.pedidos
  ADD COLUMN IF NOT EXISTS codigo_confirmacao_entrega text;

COMMENT ON COLUMN public.pedidos.codigo_confirmacao_entrega IS
  'Código de 4 dígitos para confirmação de entrega. Gerado no INSERT. Exibido ao cliente no app; informado ao entregador na hora da entrega para confirmar recebimento.';

-- ── 2. Função que gera o código no INSERT ────────────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_gerar_codigo_confirmacao()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Gera um código de 4 dígitos (1000–9999) baseado no UUID do pedido
  -- Determinístico e único o suficiente para o contexto de entrega
  NEW.codigo_confirmacao_entrega := LPAD(
    (1000 + (
      ('x' || SUBSTR(NEW.id::text, 1, 8))::bit(32)::bigint % 9000
    ))::text,
    4, '0'
  );
  RETURN NEW;
END;
$$;

-- ── 3. Trigger: gera o código em todo novo pedido ───────────────────────────
DROP TRIGGER IF EXISTS trg_gerar_codigo_confirmacao ON public.pedidos;
CREATE TRIGGER trg_gerar_codigo_confirmacao
  BEFORE INSERT ON public.pedidos
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_gerar_codigo_confirmacao();

-- ── 4. Preenche pedidos existentes que não têm código ───────────────────────
UPDATE public.pedidos
SET codigo_confirmacao_entrega = LPAD(
  (1000 + (
    ('x' || SUBSTR(id::text, 1, 8))::bit(32)::bigint % 9000
  ))::text,
  4, '0'
)
WHERE codigo_confirmacao_entrega IS NULL;

-- ── 5. Índice para busca rápida pelo código ──────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_pedidos_codigo_confirmacao
  ON public.pedidos (codigo_confirmacao_entrega)
  WHERE status NOT IN ('cancelado_cliente', 'cancelado_estab', 'cancelado_sistema');
;
