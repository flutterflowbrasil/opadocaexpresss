-- ── Habilitar extensão PostGIS (se ainda não estiver) ─────────────────────
CREATE EXTENSION IF NOT EXISTS postgis;

-- ── Função para atualizar o campo geo (PostGIS Point) ──────────────────────
CREATE OR REPLACE FUNCTION update_endereco_geo(
  p_endereco_id UUID,
  p_lat         DOUBLE PRECISION,
  p_lng         DOUBLE PRECISION
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE enderecos_clientes
  SET
    geo        = ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326),
    updated_at = NOW()
  WHERE id = p_endereco_id;
END;
$$;

-- ── Índice espacial GiST no campo geo ──────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_enderecos_clientes_geo
  ON enderecos_clientes USING GIST (geo);

-- ── Índice em cliente_id (FK lookup) ───────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_enderecos_clientes_cliente_id
  ON enderecos_clientes (cliente_id);

-- ── Índice em is_padrao (filtro frequente) ─────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_enderecos_clientes_padrao
  ON enderecos_clientes (cliente_id, is_padrao);
;
