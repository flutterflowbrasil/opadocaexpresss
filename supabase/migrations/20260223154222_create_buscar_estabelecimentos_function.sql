
CREATE OR REPLACE FUNCTION public.buscar_estabelecimentos(termo text)
RETURNS TABLE (
  id              uuid,
  razao_social    text,
  descricao       text,
  logo_url        text,
  banner_url      text,
  avaliacao_media numeric,
  status_aberto   boolean,
  config_entrega  jsonb,
  endereco        jsonb,
  categoria_nome  text,
  relevancia      int
)
LANGUAGE sql
STABLE
AS $$
  SELECT DISTINCT
    e.id,
    e.razao_social,
    e.descricao,
    e.logo_url,
    e.banner_url,
    e.avaliacao_media,
    e.status_aberto,
    e.config_entrega,
    e.endereco,
    ce.nome AS categoria_nome,
    CASE
      -- Maior relevância: nome do estabelecimento bate
      WHEN e.razao_social ILIKE '%' || termo || '%' THEN 3
      -- Relevância média: categoria do estabelecimento bate
      WHEN ce.nome ILIKE '%' || termo || '%' THEN 2
      -- Menor relevância: produto ou categoria do produto bate
      ELSE 1
    END AS relevancia
  FROM public.estabelecimentos e
  LEFT JOIN public.categorias_estabelecimento ce
    ON e.categoria_estabelecimento_id = ce.id
  LEFT JOIN public.produtos p
    ON p.estabelecimento_id = e.id AND p.disponivel = true
  LEFT JOIN public.categorias c
    ON p.categoria_id = c.id
  WHERE
    e.razao_social    ILIKE '%' || termo || '%'
    OR e.descricao    ILIKE '%' || termo || '%'
    OR ce.nome        ILIKE '%' || termo || '%'
    OR p.nome         ILIKE '%' || termo || '%'
    OR p.descricao    ILIKE '%' || termo || '%'
    OR c.nome         ILIKE '%' || termo || '%'
  ORDER BY relevancia DESC, e.avaliacao_media DESC
$$;

-- Permissão para usuários autenticados e anônimos chamarem via RPC
GRANT EXECUTE ON FUNCTION public.buscar_estabelecimentos(text) TO authenticated, anon;
;
