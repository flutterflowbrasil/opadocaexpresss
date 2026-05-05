
-- ================================================================
-- TABELA: plataforma_configuracoes
-- Centraliza todas as configurações globais do sistema.
-- Padrão key-value com agrupamento por seção.
-- Só admin pode ler/escrever (RLS).
-- ================================================================
CREATE TABLE IF NOT EXISTS public.plataforma_configuracoes (
  id          uuid        NOT NULL DEFAULT uuid_generate_v4(),
  secao       text        NOT NULL,          -- 'financeiro', 'despacho', 'entrega', 'saques', 'kyc', 'notificacoes', 'sistema'
  chave       text        NOT NULL,          -- ex: 'split_estabelecimento_pct'
  valor       text        NOT NULL,          -- sempre string, converter no client/backend
  tipo        text        NOT NULL DEFAULT 'string'
              CHECK (tipo IN ('string','number','boolean','json')),
  label       text        NOT NULL,          -- nome legível para o admin
  descricao   text,                          -- tooltip explicativo
  editavel    boolean     NOT NULL DEFAULT true,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  updated_by  uuid        REFERENCES public.usuarios(id),
  CONSTRAINT plataforma_configuracoes_pkey PRIMARY KEY (id),
  CONSTRAINT plataforma_configuracoes_secao_chave_unique UNIQUE (secao, chave)
);

-- Trigger updated_at
CREATE OR REPLACE FUNCTION public.set_plataforma_config_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;

DROP TRIGGER IF EXISTS trg_plataforma_config_updated_at ON public.plataforma_configuracoes;
CREATE TRIGGER trg_plataforma_config_updated_at
  BEFORE UPDATE ON public.plataforma_configuracoes
  FOR EACH ROW EXECUTE FUNCTION public.set_plataforma_config_updated_at();

-- RLS — somente admin pode acessar
ALTER TABLE public.plataforma_configuracoes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "config_somente_admin"
  ON public.plataforma_configuracoes
  FOR ALL
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ================================================================
-- DADOS INICIAIS — Configurações padrão da plataforma
-- ================================================================
INSERT INTO public.plataforma_configuracoes (secao, chave, valor, tipo, label, descricao) VALUES

-- FINANCEIRO / SPLITS
('financeiro', 'split_estabelecimento_pct',  '85',    'number',  'Repasse ao estabelecimento (%)',    'Percentual do subtotal de produtos repassado ao estabelecimento. Padrão: 85%.'),
('financeiro', 'split_plataforma_pct',        '5',     'number',  'Comissão da plataforma (%)',        'Percentual do subtotal de produtos retido pela Ôpadoca Express. Padrão: 5%.'),
('financeiro', 'split_entregador_taxa_full',  'true',  'boolean', 'Entregador recebe 100% da taxa',   'Se verdadeiro, entregador recebe 100% da taxa de entrega. Padrão: ativado.'),
('financeiro', 'taxa_servico_app_pct',        '5',     'number',  'Taxa de serviço do app (%)',        'Percentual cobrado do cliente sobre o subtotal. Vai para a plataforma.'),

-- SAQUES
('saques', 'saque_valor_minimo',             '10',    'number',  'Valor mínimo de saque (R$)',        'Entregador precisa ter ao menos este valor disponível para solicitar saque.'),
('saques', 'saque_limite_diario',            '3',     'number',  'Limite de saques por dia',          'Máximo de saques que um entregador pode solicitar por dia.'),
('saques', 'saque_tarifa_fixa',              '0',     'number',  'Tarifa por saque (R$)',             'Valor cobrado por saque. 0 = gratuito. Pode ser absorvido pela plataforma.'),
('saques', 'saque_pix_instantaneo',          'true',  'boolean', 'PIX instantâneo',                  'Se ativado, saque processado em até 10 segundos via Asaas Transfer API.'),

-- ENTREGA
('entrega', 'taxa_entrega_fixa_padrao',       '5.00',  'number',  'Taxa de entrega padrão (R$)',       'Taxa padrão aplicada quando o estabelecimento não configurou a própria.'),
('entrega', 'taxa_por_km',                    '1.00',  'number',  'Taxa adicional por km (R$)',        'Valor cobrado por km acima do raio mínimo.'),
('entrega', 'raio_maximo_km',                 '10',    'number',  'Raio máximo de entrega (km)',       'Distância máxima permitida para entregas na plataforma.'),
('entrega', 'pedido_minimo',                  '15.00', 'number',  'Pedido mínimo (R$)',                'Valor mínimo de produtos para que o pedido seja aceito.'),
('entrega', 'entrega_gratis_acima_de',        '50.00', 'number',  'Frete grátis acima de (R$)',        'Pedidos com subtotal acima deste valor têm frete grátis. 0 = desativado.'),
('entrega', 'tempo_medio_preparo_min',        '30',    'number',  'Tempo médio de preparo (min)',      'Tempo estimado padrão de preparo dos pedidos.'),
('entrega', 'tempo_maximo_entrega_min',       '60',    'number',  'Tempo máximo de entrega (min)',     'SLA máximo de entrega. Acima disso o pedido pode ser cancelado automaticamente.'),

-- DESPACHO
('despacho', 'tempo_resposta_seg',            '30',    'number',  'Tempo de resposta do entregador (s)','Segundos para o entregador aceitar ou recusar o pedido antes de expirar.'),
('despacho', 'max_tentativas',                '10',    'number',  'Máximo de tentativas de despacho',  'Quantos entregadores diferentes são acionados antes de ir para fila manual.'),
('despacho', 'raio_busca_inicial_km',         '3.0',   'number',  'Raio inicial de busca (km)',        'Raio onde o sistema busca entregadores disponíveis primeiro.'),
('despacho', 'raio_busca_expansao_km',        '1.5',   'number',  'Expansão do raio por tentativa (km)','A cada tentativa fracassada, o raio aumenta este valor.'),
('despacho', 'raio_busca_maximo_km',          '10.0',  'number',  'Raio máximo de busca (km)',         'Limite máximo de expansão do raio de busca de entregadores.'),
('despacho', 'modo_despacho_padrao',          'automatico','string','Modo de despacho padrão',          'automatico = sistema escolhe. broadcast = todos recebem. manual = admin escolhe.'),
('despacho', 'prioridade_criterio',           'hibrido','string', 'Critério de prioridade',            'distancia | avaliacao | score_fila | hibrido'),

-- CANCELAMENTOS
('cancelamento', 'compensacao_antes_coleta',  '2.00',  'number',  'Compensação cancelamento antes coleta (R$)', 'Valor pago ao entregador quando pedido é cancelado antes dele coletar.'),
('cancelamento', 'compensacao_apos_coleta_pct','50',   'number',  'Compensação após coleta (%)',       'Percentual da corrida pago ao entregador se cancelado após coleta.'),
('cancelamento', 'limite_cancelamentos_24h',  '3',     'number',  'Cancelamentos antes de suspensão',  'Entregador suspenso automaticamente por 24h após este número de cancelamentos maliciosos.'),
('cancelamento', 'cancelamentos_por_turno',   '1',     'number',  'Cancelamentos sem penalidade por turno','Entregador pode cancelar até este número por turno sem penalidade.'),

-- KYC / VERIFICAÇÃO
('kyc', 'score_liveness_minimo',              '0.85',  'number',  'Score mínimo de liveness (KYC)',    'Score mínimo para aprovação automática. Abaixo disso vai para revisão manual.'),
('kyc', 'kyc_provider_ativo',                 'manual','string',  'Provider KYC ativo',                'manual | idwall | unico. Atualmente: processo manual de selfie.'),
('kyc', 'exige_cnh_valida',                   'true',  'boolean', 'Exigir CNH válida',                 'Se ativado, entregadores com CNH vencida não podem ser aprovados.'),
('kyc', 'documentos_obrigatorios',            'selfie,cnh_frente,cnh_verso,veiculo,residencia','string','Documentos obrigatórios','Lista separada por vírgula dos documentos necessários para aprovação.'),

-- NOTIFICAÇÕES
('notificacoes', 'notif_ativa',               'true',  'boolean', 'Notificações push ativas',          'Liga/desliga o envio de notificações push para todos os usuários.'),
('notificacoes', 'notif_countdown_seg',       '30',    'number',  'Countdown notificação de pedido (s)','Tempo que o entregador tem para aceitar o pedido na notificação push.'),
('notificacoes', 'max_tentativas_push',       '3',     'number',  'Máximo de tentativas push',         'Quantas vezes o sistema tenta reenviar uma notificação com falha.'),

-- SISTEMA
('sistema', 'plataforma_nome',               'Ôpadoca Express', 'string', 'Nome da plataforma',       'Nome exibido nos e-mails e notificações.'),
('sistema', 'plataforma_ativa',              'true',  'boolean', 'Plataforma ativa',                  'Se desativado, novos pedidos são bloqueados (modo manutenção).'),
('sistema', 'modo_manutencao',               'false', 'boolean', 'Modo manutenção',                  'Exibe banner de manutenção no app. Pedidos existentes continuam processando.'),
('sistema', 'versao_minima_app',             '1.0.0', 'string',  'Versão mínima do app',             'Versão mínima aceita. Abaixo disso, usuário é forçado a atualizar.'),
('sistema', 'suporte_email',                 'suporte@opadoca.com.br','string','E-mail de suporte',   'E-mail exibido no app para contato com o suporte.'),
('sistema', 'suporte_whatsapp',              '5586999999999','string','WhatsApp de suporte',           'Número para o botão de WhatsApp no app (formato internacional sem +).'),
('sistema', 'fuso_horario',                  'America/Fortaleza','string','Fuso horário da plataforma','Fuso usado em relatórios e horários de funcionamento.')

ON CONFLICT (secao, chave) DO NOTHING;

COMMENT ON TABLE public.plataforma_configuracoes IS
  'Configurações globais da plataforma Ôpadoca Express. Editáveis pelo admin via painel.';
;
