
-- Função 1: buscar padarias próximas por coordenadas (Haversine)
CREATE OR REPLACE FUNCTION buscar_padarias_proximas(
  lat       DOUBLE PRECISION,
  lng       DOUBLE PRECISION,
  raio_km   DOUBLE PRECISION DEFAULT 20,
  limite    INT DEFAULT 10
)
RETURNS TABLE (
  id                    uuid,
  razao_social          text,
  descricao             text,
  logo_url              text,
  banner_url            text,
  avaliacao_media       numeric,
  total_avaliacoes      integer,
  status_aberto         boolean,
  config_entrega        jsonb,
  endereco              jsonb,
  latitude              numeric,
  longitude             numeric,
  categoria             text,
  distancia_km          double precision
) AS $$
  SELECT
    e.id,
    COALESCE(e.razao_social, 'Estabelecimento') AS razao_social,
    e.descricao,
    e.logo_url,
    e.banner_url,
    COALESCE(e.avaliacao_media, 5.0)            AS avaliacao_media,
    COALESCE(e.total_avaliacoes, 0)             AS total_avaliacoes,
    COALESCE(e.status_aberto, false)            AS status_aberto,
    e.config_entrega,
    e.endereco,
    e.latitude,
    e.longitude,
    ce.nome                                     AS categoria,
    (6371 * acos(
      LEAST(1.0,
        cos(radians(lat)) * cos(radians(e.latitude::double precision))
        * cos(radians(e.longitude::double precision) - radians(lng))
        + sin(radians(lat)) * sin(radians(e.latitude::double precision))
      )
    )) AS distancia_km
  FROM public.estabelecimentos e
  LEFT JOIN public.categorias_estabelecimento ce
    ON ce.id = e.categoria_estabelecimento_id
  WHERE
    e.latitude  IS NOT NULL
    AND e.longitude IS NOT NULL
    AND e.status_cadastro = 'aprovado'
    AND (6371 * acos(
      LEAST(1.0,
        cos(radians(lat)) * cos(radians(e.latitude::double precision))
        * cos(radians(e.longitude::double precision) - radians(lng))
        + sin(radians(lat)) * sin(radians(e.latitude::double precision))
      )
    )) <= raio_km
  ORDER BY distancia_km ASC
  LIMIT limite;
$$ LANGUAGE sql STABLE;

-- Função 2: fallback — melhores avaliados (sem localização)
CREATE OR REPLACE FUNCTION buscar_melhores_avaliadas(
  limite INT DEFAULT 10
)
RETURNS TABLE (
  id                    uuid,
  razao_social          text,
  descricao             text,
  logo_url              text,
  banner_url            text,
  avaliacao_media       numeric,
  total_avaliacoes      integer,
  status_aberto         boolean,
  config_entrega        jsonb,
  endereco              jsonb,
  latitude              numeric,
  longitude             numeric,
  categoria             text,
  distancia_km          double precision
) AS $$
  SELECT
    e.id,
    COALESCE(e.razao_social, 'Estabelecimento') AS razao_social,
    e.descricao,
    e.logo_url,
    e.banner_url,
    COALESCE(e.avaliacao_media, 5.0)            AS avaliacao_media,
    COALESCE(e.total_avaliacoes, 0)             AS total_avaliacoes,
    COALESCE(e.status_aberto, false)            AS status_aberto,
    e.config_entrega,
    e.endereco,
    e.latitude,
    e.longitude,
    ce.nome                                     AS categoria,
    NULL::double precision                      AS distancia_km
  FROM public.estabelecimentos e
  LEFT JOIN public.categorias_estabelecimento ce
    ON ce.id = e.categoria_estabelecimento_id
  WHERE e.status_cadastro = 'aprovado'
  ORDER BY e.avaliacao_media DESC NULLS LAST, e.total_avaliacoes DESC
  LIMIT limite;
$$ LANGUAGE sql STABLE;
;
