
-- ================================================================
-- AUDITORIA — CORREÇÃO DE POLICIES DUPLICADAS E BUGS
-- ================================================================

-- ----------------------------------------------------------------
-- 1. USUARIOS — remover policies antigas sobrepostas
-- ----------------------------------------------------------------
DROP POLICY IF EXISTS "Usuário vê próprio registro"      ON public.usuarios;
DROP POLICY IF EXISTS "Usuário atualiza próprio registro" ON public.usuarios;
DROP POLICY IF EXISTS "Sistema insere usuário"            ON public.usuarios;
DROP POLICY IF EXISTS "Admin global faz tudo"             ON public.usuarios;
-- Mantém: usuarios_select, usuarios_update_proprio,
--         usuarios_update_admin, usuarios_delete_bloqueado

-- ----------------------------------------------------------------
-- 2. CLIENTES — remover policies antigas sobrepostas
-- ----------------------------------------------------------------
DROP POLICY IF EXISTS "Cliente vê próprio perfil"      ON public.clientes;
DROP POLICY IF EXISTS "Cliente atualiza próprio perfil" ON public.clientes;
DROP POLICY IF EXISTS "Sistema insere cliente"          ON public.clientes;
DROP POLICY IF EXISTS "Admin global faz tudo"           ON public.clientes;
-- Mantém: clientes_select, clientes_update_proprio, clientes_insert_proprio

-- ----------------------------------------------------------------
-- 3. ENTREGADORES — remover policies antigas sobrepostas
-- ----------------------------------------------------------------
DROP POLICY IF EXISTS "Entregador vê próprio perfil"             ON public.entregadores;
DROP POLICY IF EXISTS "Estabelecimentos veem entregadores aprovados" ON public.entregadores;
DROP POLICY IF EXISTS "Entregador atualiza próprio perfil"       ON public.entregadores;
DROP POLICY IF EXISTS "Admin global faz tudo"                    ON public.entregadores;
-- Mantém: entregadores_select, entregadores_update_proprio,
--         entregadores_update_admin, entregadores_insert_proprio

-- ----------------------------------------------------------------
-- 4. ESTABELECIMENTOS — remover policies antigas sobrepostas
-- ----------------------------------------------------------------
DROP POLICY IF EXISTS "Clientes veem estabelecimentos disponíveis"    ON public.estabelecimentos;
DROP POLICY IF EXISTS "Entregadores veem estabelecimentos"            ON public.estabelecimentos;
DROP POLICY IF EXISTS "Proprietário e admins veem estabelecimento"    ON public.estabelecimentos;
DROP POLICY IF EXISTS "Proprietário e admins atualizam estabelecimento" ON public.estabelecimentos;
DROP POLICY IF EXISTS "Admin global faz tudo"                         ON public.estabelecimentos;
-- Mantém: estabelecimentos_select, estabelecimentos_update_proprio,
--         estabelecimentos_update_admin, estabelecimentos_insert_proprio

-- ----------------------------------------------------------------
-- 5. PEDIDOS — remover policies antigas sobrepostas
-- ----------------------------------------------------------------
DROP POLICY IF EXISTS "Cliente vê próprios pedidos"      ON public.pedidos;
DROP POLICY IF EXISTS "Entregador vê pedidos atribuídos" ON public.pedidos;
DROP POLICY IF EXISTS "Estabelecimento vê pedidos dele"  ON public.pedidos;
DROP POLICY IF EXISTS "Cliente cria pedido"              ON public.pedidos;
DROP POLICY IF EXISTS "Entregador atualiza pedido"       ON public.pedidos;
DROP POLICY IF EXISTS "Estabelecimento atualiza pedido"  ON public.pedidos;
DROP POLICY IF EXISTS "Admin global faz tudo"            ON public.pedidos;
-- Mantém: pedidos_select, pedidos_insert_cliente, pedidos_update

-- ----------------------------------------------------------------
-- 6. PRODUTOS — remover policies antigas sobrepostas
-- ----------------------------------------------------------------
DROP POLICY IF EXISTS "Clientes veem produtos disponíveis"      ON public.produtos;
DROP POLICY IF EXISTS "Estabelecimento gerencia próprios produtos" ON public.produtos;
DROP POLICY IF EXISTS "Admin global faz tudo"                   ON public.produtos;
-- Mantém: produtos_select_publico, produtos_insert_proprio, produtos_update_proprio

-- ----------------------------------------------------------------
-- 7. AVALIACOES — remover policy duplicada de INSERT e SELECT
-- ----------------------------------------------------------------
DROP POLICY IF EXISTS "avaliacoes_read"   ON public.avaliacoes;
DROP POLICY IF EXISTS "avaliacoes_insert" ON public.avaliacoes;
-- Mantém: avaliacoes_select, avaliacoes_insert_cliente, avaliacoes_update_estab

-- ----------------------------------------------------------------
-- 8. CUPONS — remover SELECT duplicado (cupons_read vs cupons_select_publico)
-- ----------------------------------------------------------------
DROP POLICY IF EXISTS "cupons_read" ON public.cupons;
-- Mantém: cupons_select_publico, cupons_insert_estab, cupons_update_estab, cupons_manage

-- ----------------------------------------------------------------
-- 9. SPLITS_PAGAMENTO — remover SELECTs antigos redundantes
-- ----------------------------------------------------------------
DROP POLICY IF EXISTS "Admin global vê tudo"                ON public.splits_pagamento;
DROP POLICY IF EXISTS "Cliente vê split do próprio pedido"  ON public.splits_pagamento;
DROP POLICY IF EXISTS "Entregador vê split próprio"         ON public.splits_pagamento;
DROP POLICY IF EXISTS "Estabelecimento vê split próprio"    ON public.splits_pagamento;
DROP POLICY IF EXISTS "Apenas sistema gerencia splits"      ON public.splits_pagamento;
-- Mantém: splits_select, splits_insert_bloqueado, splits_update_bloqueado

-- ----------------------------------------------------------------
-- 10. NOTIFICACOES_FILA — remover SELECT duplicado
-- ----------------------------------------------------------------
DROP POLICY IF EXISTS "notif_fila_own" ON public.notificacoes_fila;
-- Mantém: notif_fila_select, notif_fila_insert_bloqueado

-- ----------------------------------------------------------------
-- 11. ENTREGADOR_DOCUMENTOS — remover SELECT duplicado
-- ----------------------------------------------------------------
DROP POLICY IF EXISTS "entregador_documentos: admin lê todos" ON public.entregador_documentos;
DROP POLICY IF EXISTS "entregador_documentos: próprio"        ON public.entregador_documentos;
-- Mantém: docs_select, docs_insert_proprio,
--         docs_update_bloqueado_cliente, docs_update_admin

-- ----------------------------------------------------------------
-- 12. ENTREGADOR_KYC — remover SELECT duplicado
-- ----------------------------------------------------------------
DROP POLICY IF EXISTS "entregador_kyc: admin lê todos" ON public.entregador_kyc;
DROP POLICY IF EXISTS "entregador_kyc: próprio"        ON public.entregador_kyc;
-- Mantém: kyc_select, kyc_insert_bloqueado, kyc_update_bloqueado

-- ----------------------------------------------------------------
-- 13. ENTREGADOR_SAQUES — remover duplicados
-- ----------------------------------------------------------------
DROP POLICY IF EXISTS "entregador_saques: inserção própria" ON public.entregador_saques;
DROP POLICY IF EXISTS "entregador_saques: leitura própria"  ON public.entregador_saques;
-- Mantém: saques_select, saques_insert_proprio, saques_update_bloqueado

-- ----------------------------------------------------------------
-- 14. ENTREGADOR_SALDOS — remover ALL antiga que permitia UPDATE
-- ----------------------------------------------------------------
DROP POLICY IF EXISTS "entregador_saldos: próprio" ON public.entregador_saldos;
-- Mantém: saldos_select, saldos_update_bloqueado, saldos_insert_bloqueado

-- ----------------------------------------------------------------
-- 15. ENTREGADOR_LOCALIZACAO — remover SELECT aberto demais
--     "leitura autenticada" permite QUALQUER usuário autenticado
--     ver localização de QUALQUER entregador — bug de privacidade!
-- ----------------------------------------------------------------
DROP POLICY IF EXISTS "entregador_localizacao: leitura autenticada" ON public.entregador_localizacao_atual;
DROP POLICY IF EXISTS "entregador_localizacao: próprio (escrita)"   ON public.entregador_localizacao_atual;
-- Mantém: localizacao_select, localizacao_upsert_proprio, localizacao_update_proprio

-- ----------------------------------------------------------------
-- 16. CORRIGIR BUG CRÍTICO: localizacao_select tem self-join
--     p.entregador_id = p.entregador_id (sempre true!) em vez de
--     p.entregador_id = entregador_localizacao_atual.entregador_id
-- ----------------------------------------------------------------
DROP POLICY IF EXISTS "localizacao_select" ON public.entregador_localizacao_atual;

CREATE POLICY "localizacao_select"
ON public.entregador_localizacao_atual FOR SELECT
USING (
  entregador_id = get_entregador_id()
  OR is_admin()
  OR EXISTS (
    SELECT 1 FROM public.pedidos p
    WHERE p.entregador_id = entregador_localizacao_atual.entregador_id  -- corrigido
      AND p.estabelecimento_id = get_estabelecimento_id()
      AND p.status = 'em_entrega'
  )
);

-- ----------------------------------------------------------------
-- 17. ENTREGADOR_CONFIGURACOES — remover ALL antiga
--     (usa entregador_id_do_usuario que é alias de get_entregador_id)
-- ----------------------------------------------------------------
DROP POLICY IF EXISTS "entregador_configuracoes: próprio" ON public.entregador_configuracoes;

CREATE POLICY "entregador_configuracoes_proprio"
ON public.entregador_configuracoes FOR ALL
USING (entregador_id = get_entregador_id())
WITH CHECK (entregador_id = get_entregador_id());

-- ----------------------------------------------------------------
-- 18. ENTREGADOR_BONIFICACOES — adicionar acesso admin (faltava)
-- ----------------------------------------------------------------
DROP POLICY IF EXISTS "entregador_bonificacoes: leitura própria" ON public.entregador_bonificacoes;

CREATE POLICY "bonificacoes_select"
ON public.entregador_bonificacoes FOR SELECT
USING (
  entregador_id = get_entregador_id()
  OR is_admin()
);

-- Admin pode inserir bonificações (nenhuma policy permitia isso)
CREATE POLICY "bonificacoes_insert_admin"
ON public.entregador_bonificacoes FOR INSERT
WITH CHECK (is_admin());

-- ----------------------------------------------------------------
-- 19. SUPORTE_CHAMADOS — remover ALL antiga e o SELECT duplicado
-- ----------------------------------------------------------------
DROP POLICY IF EXISTS "suporte_chamados: próprio"    ON public.suporte_chamados;
DROP POLICY IF EXISTS "suporte_chamados: admin gerencia" ON public.suporte_chamados;
-- Mantém: suporte_select, suporte_insert_proprio, suporte_update_admin

-- ----------------------------------------------------------------
-- 20. CATEGORIAS — RLS ativo mas 0 policies = tabela inacessível!
--     Qualquer usuário autenticado precisa ler categorias de produtos
-- ----------------------------------------------------------------
CREATE POLICY "categorias_select_publico"
ON public.categorias FOR SELECT
USING (ativa = true OR is_admin());

CREATE POLICY "categorias_manage_admin"
ON public.categorias FOR ALL
USING (is_admin())
WITH CHECK (is_admin());
;
