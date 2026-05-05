
-- ================================================================
-- SUPORTE CHAMADOS — Expansão completa
-- 1. Torna entregador_id opcional (era NOT NULL)
-- 2. Adiciona usuario_id (qualquer tipo: cliente, estab, entregador, admin)
-- 3. Adiciona prioridade (baixa / normal / alta / urgente)
-- 4. Adiciona respondido_por (admin que respondeu)
-- 5. Adiciona atualizado_em
-- ================================================================

-- 1. Torna entregador_id opcional
ALTER TABLE public.suporte_chamados
  ALTER COLUMN entregador_id DROP NOT NULL;

-- 2. Adiciona usuario_id — FK para qualquer tipo de usuário
ALTER TABLE public.suporte_chamados
  ADD COLUMN IF NOT EXISTS usuario_id uuid REFERENCES public.usuarios(id),
  ADD COLUMN IF NOT EXISTS tipo_solicitante text
    CHECK (tipo_solicitante IN ('cliente','entregador','estabelecimento','admin')),
  ADD COLUMN IF NOT EXISTS prioridade text NOT NULL DEFAULT 'normal'
    CHECK (prioridade IN ('baixa','normal','alta','urgente')),
  ADD COLUMN IF NOT EXISTS respondido_por uuid REFERENCES public.usuarios(id),
  ADD COLUMN IF NOT EXISTS respondido_em timestamp with time zone,
  ADD COLUMN IF NOT EXISTS updated_at timestamp with time zone NOT NULL DEFAULT now();

-- 3. Índices para performance
CREATE INDEX IF NOT EXISTS idx_suporte_usuario_id   ON public.suporte_chamados(usuario_id);
CREATE INDEX IF NOT EXISTS idx_suporte_status        ON public.suporte_chamados(status);
CREATE INDEX IF NOT EXISTS idx_suporte_prioridade    ON public.suporte_chamados(prioridade);
CREATE INDEX IF NOT EXISTS idx_suporte_created_at    ON public.suporte_chamados(created_at DESC);

-- 4. Trigger updated_at
CREATE OR REPLACE FUNCTION public.set_suporte_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;

DROP TRIGGER IF EXISTS trg_suporte_updated_at ON public.suporte_chamados;
CREATE TRIGGER trg_suporte_updated_at
  BEFORE UPDATE ON public.suporte_chamados
  FOR EACH ROW EXECUTE FUNCTION public.set_suporte_updated_at();

-- 5. Comentários para documentação
COMMENT ON COLUMN public.suporte_chamados.usuario_id IS
  'Qualquer tipo de usuário pode abrir chamado: cliente, entregador, estabelecimento ou admin';
COMMENT ON COLUMN public.suporte_chamados.entregador_id IS
  'Mantido para compatibilidade. Preferir usuario_id em novos registros.';
COMMENT ON COLUMN public.suporte_chamados.prioridade IS
  'baixa | normal | alta | urgente — definido pelo app ou pelo admin';
COMMENT ON COLUMN public.suporte_chamados.respondido_por IS
  'ID do admin que respondeu o chamado';
;
