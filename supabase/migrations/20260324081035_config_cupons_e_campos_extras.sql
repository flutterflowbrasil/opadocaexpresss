
-- Seção cupons_promocoes (nova)
INSERT INTO public.plataforma_configuracoes (secao, chave, valor, tipo, label, descricao) VALUES
('cupons', 'cupons_ativos',            'true',  'boolean', 'Cupons globais ativos',          'Ativa ou desativa o uso de cupons na plataforma inteira.'),
('cupons', 'valor_minimo_padrao',      '20.00', 'number',  'Valor mínimo padrão para uso (R$)','Valor mínimo de pedido exigido para aplicar um cupom.'),
('cupons', 'limite_por_cliente',       '1',     'number',  'Limite de uso por cliente',       'Quantas vezes o mesmo cliente pode usar um cupom.'),
('cupons', 'limite_total_campanha',    '100',   'number',  'Limite total por campanha',       'Total máximo de usos de um cupom antes de ser desativado.'),
('cupons', 'permite_entrega_gratis',   'true',  'boolean', 'Permitir cupom de frete grátis',  'Permite criar cupons do tipo entrega_gratis.'),
('cupons', 'permite_percentual',       'true',  'boolean', 'Permitir cupom percentual',       'Permite criar cupons do tipo percentual (ex: 10% de desconto).'),
('cupons', 'permite_valor_fixo',       'true',  'boolean', 'Permitir cupom valor fixo',       'Permite criar cupons com desconto de valor fixo (ex: R$ 5,00).'),
-- Campos extras em sistema
('sistema', 'logs_avancados',          'false', 'boolean', 'Ativar logs avançados',           'Registra eventos detalhados de operação. Pode impactar performance.'),
('sistema', 'modo_debug',              'false', 'boolean', 'Modo debug administrativo',       'Exibe informações extras no painel admin para diagnóstico.'),
('sistema', 'permite_cadastro_estab',  'true',  'boolean', 'Permitir cadastro de estabelecimentos','Permite que novos estabelecimentos se cadastrem na plataforma.'),
('sistema', 'permite_cadastro_entregador','true','boolean','Permitir cadastro de entregadores','Permite que novos entregadores se cadastrem na plataforma.'),
-- Campos extras em financeiro
('financeiro', 'split_automatico_ativo','true', 'boolean', 'Ativar split automático',         'Processa splits automaticamente via webhook Asaas ao confirmar pagamento.'),
('financeiro', 'retencao_temporaria',  'false', 'boolean', 'Ativar retenção temporária',      'Bloqueia o saldo do entregador por X horas antes de disponibilizar para saque.'),
('financeiro', 'taxa_minima_plataforma','1.00', 'number',  'Taxa mínima da plataforma (R$)',  'Valor mínimo de comissão cobrado por pedido, independente do percentual.'),
('financeiro', 'taxa_transacao_gateway','0',    'number',  'Taxa de transação do gateway (%)', 'Percentual cobrado pelo gateway de pagamento (Asaas). Deduzido do total.'),
-- Campos extras em entrega
('entrega',  'entrega_agendada',       'false', 'boolean', 'Permitir entrega agendada',       'Permite que clientes agendem pedidos para horários futuros.'),
('entrega',  'tempo_medio_entrega_min','40',    'number',  'Tempo médio de entrega (min)',    'Estimativa exibida ao cliente no app após o pedido ser aceito.'),
-- Campos extras em notificacoes
('notificacoes', 'notif_pedidos',      'true',  'boolean', 'Notificações de pedido',          'Ativa notificações de status de pedido para clientes.'),
('notificacoes', 'notif_entregas',     'true',  'boolean', 'Notificações de entrega',         'Ativa notificações de atualizações de entrega para clientes.'),
('notificacoes', 'notif_promocoes',    'true',  'boolean', 'Notificações promocionais',       'Ativa notificações de cupons e promoções para clientes.'),
('notificacoes', 'canal_android',      'geral', 'string',  'Canal padrão Android',            'Canal FCM padrão: geral | pedidos | financeiro | sistema.'),
('notificacoes', 'som_padrao',         'default','string', 'Som padrão das notificações',     'Som padrão: default | silent | custom.')
ON CONFLICT (secao, chave) DO NOTHING;
;
