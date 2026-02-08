-- ==========================================
-- PADOCA EXPRESS - MULTIESTABELECIMENTO (CORRIGIDO)
-- ==========================================

-- Habilitar extensões
create extension if not exists "uuid-ossp";

-- ==========================================
-- FUNÇÕES AUXILIARES (PRIMEIRO - USADAS NAS RLS)
-- ==========================================

-- Verifica se usuário é admin global
create or replace function public.is_admin_global()
returns boolean as $$
begin
  return exists (
    select 1 from public.usuarios 
    where id = auth.uid() 
    and tipo_usuario = 'admin'
  );
end;
$$ language plpgsql security definer;

-- Verifica se usuário é proprietário do estabelecimento
create or replace function public.is_proprietario_estabelecimento(estabelecimento_uuid uuid)
returns boolean as $$
begin
  return exists (
    select 1 from public.estabelecimentos e
    where e.id = estabelecimento_uuid
    and e.usuario_id = auth.uid()
  );
end;
$$ language plpgsql security definer;

-- Verifica se usuário é admin do estabelecimento (qualquer nível ativo)
create or replace function public.is_admin_estabelecimento(estabelecimento_uuid uuid)
returns boolean as $$
begin
  return exists (
    select 1 from public.administradores_estabelecimento ae
    where ae.estabelecimento_id = estabelecimento_uuid
    and ae.usuario_id = auth.uid()
    and ae.ativo = true
    and ae.convite_pendente = false
  );
end;
$$ language plpgsql security definer;

-- Verifica permissão específica no estabelecimento
create or replace function public.tem_permissao_estabelecimento(
  estabelecimento_uuid uuid, 
  permissao text
)
returns boolean as $$
declare
  user_permissoes jsonb;
begin
  -- Proprietário tem todas as permissões
  if public.is_proprietario_estabelecimento(estabelecimento_uuid) then
    return true;
  end if;
  
  -- Verifica permissão específica no JSON
  select permissoes into user_permissoes
  from public.administradores_estabelecimento
  where estabelecimento_id = estabelecimento_uuid
  and usuario_id = auth.uid()
  and ativo = true
  and convite_pendente = false;
  
  return coalesce(user_permissoes->>permissao, 'false')::boolean;
end;
$$ language plpgsql security definer;

-- ==========================================
-- 1. TABELA DE USUÁRIOS (Auth Centralizada)
-- ==========================================
create table public.usuarios (
  id uuid references auth.users on delete cascade primary key,
  
  -- Dados básicos (comuns a todos)
  email text not null unique,
  telefone text,
  -- REMOVIDO: senha_hash (gerenciado pelo Supabase Auth)
  
  -- Tipo de conta (define para qual tabela específica irá)
  tipo_usuario text not null check (tipo_usuario in ('cliente', 'entregador', 'estabelecimento', 'admin')),
  
  -- Status geral
  status text default 'ativo', -- ativo, pendente, bloqueado, suspenso
  
  -- Controle de acesso
  email_verificado boolean default false,
  telefone_verificado boolean default false,
  ultimo_login timestamp with time zone,
  
  -- Dados de criação
  created_at timestamp with time zone default timezone('utc'::text, now()),
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

-- RLS Usuários
alter table public.usuarios enable row level security;

create policy "Admin global faz tudo" on public.usuarios for all using (public.is_admin_global());
create policy "Usuário vê próprio registro" on public.usuarios for select using (auth.uid() = id or public.is_admin_global());
create policy "Sistema insere usuário" on public.usuarios for insert with check (auth.uid() = id or public.is_admin_global());
create policy "Usuário atualiza próprio registro" on public.usuarios for update using (auth.uid() = id or public.is_admin_global());

-- ==========================================
-- 2. TABELA DE CLIENTES
-- ==========================================
create table public.clientes (
  id uuid default uuid_generate_v4() primary key,
  usuario_id uuid references public.usuarios(id) on delete cascade unique,
  
  -- Dados pessoais
  nome_completo text not null,
  cpf text unique,
  data_nascimento date,
  foto_perfil_url text,
  
  -- Preferências
  preferencias jsonb default '{
    "notificacoes_email": true,
    "notificacoes_push": true,
    "tema": "sistema"
  }',
  
  -- Estatísticas
  total_pedidos integer default 0,
  valor_total_gasto decimal(10,2) default 0,
  
  created_at timestamp with time zone default timezone('utc'::text, now()),
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

-- RLS Clientes
alter table public.clientes enable row level security;

create policy "Admin global faz tudo" on public.clientes for all using (public.is_admin_global());
create policy "Cliente vê próprio perfil" on public.clientes for select using (exists (select 1 from public.usuarios u where u.id = auth.uid() and u.id = clientes.usuario_id) or public.is_admin_global());
create policy "Cliente atualiza próprio perfil" on public.clientes for update using (exists (select 1 from public.usuarios u where u.id = auth.uid() and u.id = clientes.usuario_id) or public.is_admin_global());

-- ==========================================
-- 3. TABELA DE ENTREGADORES
-- ==========================================
create table public.entregadores (
  id uuid default uuid_generate_v4() primary key,
  usuario_id uuid references public.usuarios(id) on delete cascade unique,
  
  -- Dados pessoais
  nome_completo text not null,
  cpf text unique not null,
  data_nascimento date,
  foto_perfil_url text,
  
  -- Documentação
  cnh_numero text unique,
  cnh_categoria text, -- A, B, AB, etc
  cnh_validade date,
  cnh_foto_url text,
  
  -- Veículo
  tipo_veiculo text check (tipo_veiculo in ('moto', 'carro', 'bicicleta', 'van')),
  veiculo_placa text,
  veiculo_modelo text,
  veiculo_cor text,
  veiculo_ano integer,
  veiculo_foto_url text,
  
  -- Dados bancários (para saque)
  dados_bancarios jsonb default '{
    "banco": null,
    "agencia": null,
    "conta": null,
    "tipo_conta": null,
    "pix_chave": null
  }',
  
  -- Configurações Asaas (SPLIT)
  asaas_wallet_id text, -- Carteira para receber split
  asaas_account_id text, -- ID da subconta Asaas
  
  -- Status operacional
  status_cadastro text default 'pendente', -- pendente, em_analise, aprovado, rejeitado
  status_online boolean default false,
  motivo_rejeicao text,
  
  -- Configurações de trabalho
  raio_atuacao_km integer default 10,
  aceita_pedidos_automaticamente boolean default false,
  
  -- Localização em tempo real (atualizada pelo app)
  localizacao_atual jsonb, -- {lat: x, lng: y, atualizado_em: timestamp, precisao_metros: x}
  
  -- Estatísticas
  total_entregas integer default 0,
  avaliacao_media decimal(3,2) default 5.0,
  total_avaliacoes integer default 0,
  ganhos_total decimal(10,2) default 0,
  ganhos_disponiveis decimal(10,2) default 0, -- Saldo atual
  
  created_at timestamp with time zone default timezone('utc'::text, now()),
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

-- RLS Entregadores
alter table public.entregadores enable row level security;

create policy "Admin global faz tudo" on public.entregadores for all using (public.is_admin_global());
create policy "Entregador vê próprio perfil" on public.entregadores for select using (exists (select 1 from public.usuarios u where u.id = auth.uid() and u.id = entregadores.usuario_id) or public.is_admin_global());
create policy "Entregador atualiza próprio perfil" on public.entregadores for update using (exists (select 1 from public.usuarios u where u.id = auth.uid() and u.id = entregadores.usuario_id) or public.is_admin_global());
create policy "Estabelecimentos veem entregadores aprovados" on public.entregadores for select using (status_cadastro = 'aprovado' and exists (select 1 from public.usuarios u where u.id = auth.uid() and u.tipo_usuario = 'estabelecimento') or public.is_admin_global());

-- ==========================================
-- 4. TABELA DE ESTABELECIMENTOS (Multiestabelecimento)
-- ==========================================
create table public.estabelecimentos (
  id uuid default uuid_generate_v4() primary key,
  usuario_id uuid references public.usuarios(id) on delete cascade,
  
  -- Dados comerciais
  nome_fantasia text not null,
  razao_social text,
  cnpj text unique,
  inscricao_estadual text,
  inscricao_municipal text,
  
  -- Categoria principal
  categoria text not null, -- padaria, confeitaria, cafeteria, mercado, etc
  subcategorias text[], -- ['pães', 'bolos', 'cafés', 'salgados']
  
  -- Descrição e mídia
  descricao text,
  logo_url text,
  banner_url text,
  fotos_estabelecimento text[], -- Array de URLs
  
  -- Contato
  telefone_comercial text,
  whatsapp text,
  email_comercial text,
  
  -- Endereço físico (para cálculo de distância)
  endereco jsonb not null, -- {cep, logradouro, numero, complemento, bairro, cidade, estado, latitude, longitude}
  
  -- Horário de funcionamento
  horario_funcionamento jsonb default '{
    "seg": {"aberto": true, "inicio": "06:00", "fim": "20:00"},
    "ter": {"aberto": true, "inicio": "06:00", "fim": "20:00"},
    "qua": {"aberto": true, "inicio": "06:00", "fim": "20:00"},
    "qui": {"aberto": true, "inicio": "06:00", "fim": "20:00"},
    "sex": {"aberto": true, "inicio": "06:00", "fim": "20:00"},
    "sab": {"aberto": true, "inicio": "07:00", "fim": "19:00"},
    "dom": {"aberto": false}
  }',
  
  -- Configurações de entrega
  config_entrega jsonb default '{
    "taxa_entrega_fixa": 5.00,
    "taxa_por_km": 2.00,
    "raio_maximo_km": 8,
    "tempo_medio_preparo_min": 30,
    "pedido_minimo": 15.00,
    "gratis_acima_de": 50.00
  }',
  
  -- Configurações Asaas (SPLIT)
  asaas_wallet_id text, -- Carteira para receber split
  asaas_account_id text, -- ID da subconta Asaas
  
  -- Status
  status_cadastro text default 'pendente', -- pendente, em_analise, aprovado, suspenso, bloqueado
  status_aberto boolean default false, -- Se está aceitando pedidos agora
  motivo_suspensao text,
  
  -- Documentação
  documentos jsonb default '{
    "comprovante_endereco": null,
    "contrato_social": null,
    "alvara_funcionamento": null
  }',
  
  -- Estatísticas
  total_pedidos integer default 0,
  faturamento_total decimal(10,2) default 0,
  avaliacao_media decimal(3,2) default 5.0,
  total_avaliacoes integer default 0,
  
  -- Configurações avançadas
  config_avancada jsonb default '{
    "tempo_minimo_entrega_min": 15,
    "tempo_maximo_entrega_min": 60,
    "intervalo_atualizacao_estoque_min": 5,
    "aceita_agendamento": false,
    "tempo_antecedencia_agendamento_min": 60
  }',
  
  created_at timestamp with time zone default timezone('utc'::text, now()),
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

-- RLS Estabelecimentos
alter table public.estabelecimentos enable row level security;

create policy "Admin global faz tudo" on public.estabelecimentos for all using (public.is_admin_global());
create policy "Proprietário e admins veem estabelecimento" on public.estabelecimentos for select using (usuario_id = auth.uid() or public.is_admin_estabelecimento(id) or public.is_admin_global());
create policy "Proprietário e admins atualizam estabelecimento" on public.estabelecimentos for update using (usuario_id = auth.uid() or (public.is_admin_estabelecimento(id) and public.tem_permissao_estabelecimento(id, 'configuracoes_avancadas')) or public.is_admin_global());
create policy "Clientes veem estabelecimentos disponíveis" on public.estabelecimentos for select using (status_cadastro = 'aprovado' and exists (select 1 from public.usuarios u where u.id = auth.uid() and u.tipo_usuario = 'cliente') or public.is_admin_global());
create policy "Entregadores veem estabelecimentos" on public.estabelecimentos for select using (status_cadastro = 'aprovado' and exists (select 1 from public.usuarios u where u.id = auth.uid() and u.tipo_usuario = 'entregador') or public.is_admin_global());

-- ==========================================
-- 5. TABELA DE ADMINISTRADORES DO ESTABELECIMENTO (NOVA)
-- ==========================================
create table public.administradores_estabelecimento (
  id uuid default uuid_generate_v4() primary key,
  usuario_id uuid references public.usuarios(id) on delete cascade,
  estabelecimento_id uuid references public.estabelecimentos(id) on delete cascade,
  
  -- Nível de permissão
  nivel_permissao text not null default 'gerente' 
    check (nivel_permissao in ('proprietario', 'gerente', 'operador')),
  
  -- Permissões específicas (JSON para flexibilidade)
  permissoes jsonb default '{
    "gerenciar_cardapio": true,
    "gerenciar_pedidos": true,
    "gerenciar_entregadores": true,
    "ver_financeiro": true,
    "gerenciar_admins": false,
    "configuracoes_avancadas": false
  }',
  
  -- Status
  ativo boolean default true,
  convite_pendente boolean default true, -- Até aceitar convite
  
  -- Quem convidou
  convidado_por uuid references public.usuarios(id),
  
  created_at timestamp with time zone default timezone('utc'::text, now()),
  updated_at timestamp with time zone default timezone('utc'::text, now()),
  
  unique(usuario_id, estabelecimento_id)
);

-- RLS Administradores Estabelecimento
alter table public.administradores_estabelecimento enable row level security;

create policy "Admin global faz tudo" on public.administradores_estabelecimento for all using (public.is_admin_global());
create policy "Proprietário gerencia admins" on public.administradores_estabelecimento for all using (exists (select 1 from public.estabelecimentos e where e.id = administradores_estabelecimento.estabelecimento_id and e.usuario_id = auth.uid()));
create policy "Admins veem lista de admins" on public.administradores_estabelecimento for select using (public.is_admin_estabelecimento(estabelecimento_id) or public.is_admin_global());

-- ==========================================
-- 6. TABELA DE ENDEREÇOS DOS CLIENTES
-- ==========================================
create table public.enderecos_clientes (
  id uuid default uuid_generate_v4() primary key,
  cliente_id uuid references public.clientes(id) on delete cascade,
  
  -- Identificação
  apelido text, -- "Casa", "Trabalho", "Casa da Mãe"
  
  -- Endereço completo
  cep text not null,
  logradouro text not null,
  numero text not null,
  complemento text,
  bairro text not null,
  cidade text not null,
  estado text not null,
  
  -- Coordenadas geográficas (ESSENCIAL para cálculo de distância)
  latitude decimal(10, 8) not null,
  longitude decimal(11, 8) not null,
  
  -- Referências
  ponto_referencia text,
  instrucoes_entrega text, -- "Campainha não funciona, ligar"
  
  -- Status
  is_padrao boolean default false,
  
  created_at timestamp with time zone default timezone('utc'::text, now()),
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

-- RLS Endereços
alter table public.enderecos_clientes enable row level security;

create policy "Admin global faz tudo" on public.enderecos_clientes for all using (public.is_admin_global());
create policy "Cliente gerencia próprios endereços" on public.enderecos_clientes for all using (exists (select 1 from public.clientes c join public.usuarios u on u.id = c.usuario_id where u.id = auth.uid() and c.id = enderecos_clientes.cliente_id) or public.is_admin_global());

-- ==========================================
-- 7. TABELA DE PRODUTOS (Por estabelecimento)
-- ==========================================
create table public.produtos (
  id uuid default uuid_generate_v4() primary key,
  estabelecimento_id uuid references public.estabelecimentos(id) on delete cascade,
  
  -- Identificação
  nome text not null,
  descricao text,
  categoria text not null, -- pães, bolos, bebidas, etc
  
  -- Preços
  preco decimal(10,2) not null,
  preco_promocional decimal(10,2),
  custo_estimado decimal(10,2), -- Para analytics do estabelecimento
  
  -- Mídia
  foto_principal_url text,
  fotos_adicionais text[],
  
  -- Configurações
  disponivel boolean default true,
  destaque boolean default false, -- Aparece em "Mais vendidos"
  
  -- Opções e variações (JSON flexível)
  opcoes jsonb default '[]',
  
  -- Estoque (controle opcional)
  controle_estoque boolean default false,
  quantidade_estoque integer,
  
  -- Preparo
  tempo_preparo_adicional_min integer default 0, -- Tempo extra além do padrão do estabelecimento
  
  -- Estatísticas
  total_vendidos integer default 0,
  
  created_at timestamp with time zone default timezone('utc'::text, now()),
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

-- RLS Produtos
alter table public.produtos enable row level security;

create policy "Admin global faz tudo" on public.produtos for all using (public.is_admin_global());
create policy "Estabelecimento gerencia próprios produtos" on public.produtos for all using (exists (select 1 from public.estabelecimentos e where e.id = produtos.estabelecimento_id and (e.usuario_id = auth.uid() or (public.is_admin_estabelecimento(e.id) and public.tem_permissao_estabelecimento(e.id, 'gerenciar_cardapio')) or public.is_admin_global())));
create policy "Clientes veem produtos disponíveis" on public.produtos for select using (disponivel = true and exists (select 1 from public.estabelecimentos e where e.id = produtos.estabelecimento_id and e.status_cadastro = 'aprovado') or public.is_admin_global());

-- ==========================================
-- 8. TABELA DE PEDIDOS (CORE DO SISTEMA)
-- ==========================================
create table public.pedidos (
  id uuid default uuid_generate_v4() primary key,
  
  -- Relacionamentos
  cliente_id uuid references public.clientes(id),
  estabelecimento_id uuid references public.estabelecimentos(id),
  entregador_id uuid references public.entregadores(id),
  endereco_entrega_id uuid references public.enderecos_clientes(id),
  
  -- Status do pedido
  status text default 'pendente' check (status in (
    'pendente', 'confirmado', 'preparando', 'pronto', 'em_entrega', 
    'entregue', 'cancelado_cliente', 'cancelado_estab', 'cancelado_sistema'
  )),
  
  -- Itens do pedido (snapshot no momento da compra)
  itens jsonb not null,
  
  -- Valores financeiros
  subtotal_produtos decimal(10,2) not null,
  taxa_entrega decimal(10,2) not null,
  taxa_servico_app decimal(10,2) not null,
  desconto_cupom decimal(10,2) default 0,
  total decimal(10,2) not null,
  
  -- Dados da entrega
  endereco_entrega_snapshot jsonb not null,
  distancia_km decimal(5,2),
  tempo_estimado_preparo_min integer,
  tempo_estimado_entrega_min integer,
  
  -- Pagamento Asaas
  asaas_payment_id text,
  asaas_invoice_url text,
  pagamento_metodo text check (pagamento_metodo in ('pix', 'cartao_credito', 'cartao_debito', 'boleto', 'dinheiro')),
  pagamento_status text default 'pendente',
  
  -- Split de pagamento (processado após confirmação)
  split_processado boolean default false,
  
  -- Tracking em tempo real
  localizacao_entregador jsonb,
  
  -- Timestamps importantes
  created_at timestamp with time zone default timezone('utc'::text, now()),
  confirmado_em timestamp with time zone,
  preparando_em timestamp with time zone,
  pronto_em timestamp with time zone,
  em_entrega_em timestamp with time zone,
  entregue_em timestamp with time zone,
  cancelado_em timestamp with time zone,
  motivo_cancelamento text,
  
  -- Avaliações
  avaliacao_cliente jsonb,
  avaliacao_entregador jsonb,
  
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

-- RLS Pedidos
alter table public.pedidos enable row level security;

create policy "Admin global faz tudo" on public.pedidos for all using (public.is_admin_global());
create policy "Cliente vê próprios pedidos" on public.pedidos for select using (exists (select 1 from public.clientes c join public.usuarios u on u.id = c.usuario_id where u.id = auth.uid() and c.id = pedidos.cliente_id) or public.is_admin_global());
create policy "Cliente cria pedido" on public.pedidos for insert with check (exists (select 1 from public.clientes c join public.usuarios u on u.id = c.usuario_id where u.id = auth.uid() and c.id = pedidos.cliente_id) or public.is_admin_global());
create policy "Estabelecimento vê pedidos dele" on public.pedidos for select using (exists (select 1 from public.estabelecimentos e where e.id = pedidos.estabelecimento_id and (e.usuario_id = auth.uid() or public.is_admin_estabelecimento(e.id) or public.is_admin_global())));
create policy "Estabelecimento atualiza pedido" on public.pedidos for update using (exists (select 1 from public.estabelecimentos e where e.id = pedidos.estabelecimento_id and (e.usuario_id = auth.uid() or (public.is_admin_estabelecimento(e.id) and public.tem_permissao_estabelecimento(e.id, 'gerenciar_pedidos')) or public.is_admin_global())));
create policy "Entregador vê pedidos atribuídos" on public.pedidos for select using (exists (select 1 from public.entregadores ent join public.usuarios u on u.id = ent.usuario_id where u.id = auth.uid() and ent.id = pedidos.entregador_id) or public.is_admin_global());
create policy "Entregador atualiza pedido" on public.pedidos for update using (exists (select 1 from public.entregadores ent join public.usuarios u on u.id = ent.usuario_id where u.id = auth.uid() and ent.id = pedidos.entregador_id) or public.is_admin_global());

-- ==========================================
-- 9. TABELA DE SPLIT DE PAGAMENTO (ASAAS)
-- ==========================================
create table public.splits_pagamento (
  id uuid default uuid_generate_v4() primary key,
  pedido_id uuid references public.pedidos(id) on delete cascade,
  
  -- Configuração do split
  valor_total decimal(10,2) not null,
  
  -- Estabelecimento (recebe % do subtotal dos produtos)
  estabelecimento_wallet_id text not null,
  estabelecimento_percentual decimal(5,2) default 85.00,
  estabelecimento_valor decimal(10,2) not null,
  
  -- Entregador (recebe taxa de entrega + % opcional)
  entregador_wallet_id text,
  entregador_recebe_taxa_entrega boolean default true,
  entregador_taxa_entrega_valor decimal(10,2),
  entregador_percentual_extra decimal(5,2) default 0,
  entregador_valor_extra decimal(10,2) default 0,
  entregador_valor_total decimal(10,2) not null,
  
  -- Padoca Express (recebe o resto)
  plataforma_percentual decimal(5,2) default 5.00,
  plataforma_valor decimal(10,2) not null,
  plataforma_taxa_transacao decimal(10,2) default 0,
  
  -- Status no Asaas
  status text default 'pendente',
  asaas_split_id text,
  asaas_response jsonb,
  
  -- Timestamps
  created_at timestamp with time zone default timezone('utc'::text, now()),
  processado_em timestamp with time zone,
  falhou_em timestamp with time zone,
  motivo_falha text,
  
  unique(pedido_id)
);

-- RLS Splits
alter table public.splits_pagamento enable row level security;

create policy "Apenas sistema gerencia splits" on public.splits_pagamento for all using (false);
create policy "Admin global vê tudo" on public.splits_pagamento for select using (public.is_admin_global());
create policy "Cliente vê split do próprio pedido" on public.splits_pagamento for select using (exists (select 1 from public.pedidos p join public.clientes c on c.id = p.cliente_id join public.usuarios u on u.id = c.usuario_id where u.id = auth.uid() and p.id = splits_pagamento.pedido_id) or public.is_admin_global());
create policy "Entregador vê split próprio" on public.splits_pagamento for select using (exists (select 1 from public.pedidos p join public.entregadores ent on ent.id = p.entregador_id join public.usuarios u on u.id = ent.usuario_id where u.id = auth.uid() and p.id = splits_pagamento.pedido_id) or public.is_admin_global());
create policy "Estabelecimento vê split próprio" on public.splits_pagamento for select using (exists (select 1 from public.pedidos p join public.estabelecimentos e on e.id = p.estabelecimento_id join public.usuarios u on u.id = e.usuario_id where u.id = auth.uid() and p.id = splits_pagamento.pedido_id) or public.is_admin_global());

-- ==========================================
-- 10. TABELA DE TERMOS ACEITOS
-- ==========================================
create table public.termos_aceitos (
  id uuid default uuid_generate_v4() primary key,
  usuario_id uuid references public.usuarios(id) on delete cascade,
  versao text not null default '1.0',
  aceito_em timestamp with time zone default timezone('utc'::text, now()),
  ip_address text,
  user_agent text,
  
  unique(usuario_id, versao)
);

-- RLS Termos
alter table public.termos_aceitos enable row level security;

create policy "Admin global faz tudo" on public.termos_aceitos for all using (public.is_admin_global());
create policy "Usuário vê próprios termos aceitos" on public.termos_aceitos for select using (auth.uid() = usuario_id or public.is_admin_global());
create policy "Usuário aceita termos" on public.termos_aceitos for insert with check (auth.uid() = usuario_id or public.is_admin_global());

-- ==========================================
-- 11. TABELA DE HISTÓRICO DE STATUS (AUDIT)
-- ==========================================
create table public.historico_status_pedido (
  id uuid default uuid_generate_v4() primary key,
  pedido_id uuid references public.pedidos(id) on delete cascade,
  status_anterior text,
  status_novo text not null,
  alterado_por uuid references public.usuarios(id),
  motivo text,
  metadata jsonb,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- RLS Histórico
alter table public.historico_status_pedido enable row level security;

create policy "Admin global faz tudo" on public.historico_status_pedido for all using (public.is_admin_global());
create policy "Envolvidos no pedido veem histórico" on public.historico_status_pedido for select using (exists (select 1 from public.pedidos p where p.id = historico_status_pedido.pedido_id and (exists (select 1 from public.clientes c join public.usuarios u on u.id = c.usuario_id where u.id = auth.uid() and c.id = p.cliente_id) or exists (select 1 from public.entregadores ent join public.usuarios u on u.id = ent.usuario_id where u.id = auth.uid() and ent.id = p.entregador_id) or exists (select 1 from public.estabelecimentos e join public.usuarios u on u.id = e.usuario_id where u.id = auth.uid() and e.id = p.estabelecimento_id))) or public.is_admin_global());

-- ==========================================
-- FUNÇÕES E TRIGGERS
-- ==========================================

-- Função para atualizar updated_at
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = timezone('utc'::text, now());
  return new;
end;
$$ language plpgsql;

-- Triggers de updated_at
create trigger handle_usuarios_updated_at before update on public.usuarios for each row execute function public.handle_updated_at();
create trigger handle_clientes_updated_at before update on public.clientes for each row execute function public.handle_updated_at();
create trigger handle_entregadores_updated_at before update on public.entregadores for each row execute function public.handle_updated_at();
create trigger handle_estabelecimentos_updated_at before update on public.estabelecimentos for each row execute function public.handle_updated_at();
create trigger handle_admin_estab_updated_at before update on public.administradores_estabelecimento for each row execute function public.handle_updated_at();
create trigger handle_enderecos_updated_at before update on public.enderecos_clientes for each row execute function public.handle_updated_at();
create trigger handle_produtos_updated_at before update on public.produtos for each row execute function public.handle_updated_at();
create trigger handle_pedidos_updated_at before update on public.pedidos for each row execute function public.handle_updated_at();

-- Função para logar mudanças de status do pedido
create or replace function public.log_status_change()
returns trigger as $$
begin
  if old.status is distinct from new.status then
    insert into public.historico_status_pedido (pedido_id, status_anterior, status_novo, alterado_por, motivo)
    values (new.id, old.status, new.status, auth.uid(),
      case 
        when new.status = 'cancelado_cliente' then 'Cancelado pelo cliente'
        when new.status = 'cancelado_estab' then 'Cancelado pelo estabelecimento'
        else null
      end
    );
  end if;
  return new;
end;
$$ language plpgsql;

create trigger trigger_log_status_change before update on public.pedidos for each row execute function public.log_status_change();

-- Função CORRIGIDA para atualizar estatísticas do entregador
create or replace function public.atualizar_stats_entregador()
returns trigger as $$
declare
  v_entregador_valor decimal(10,2);
begin
  if new.status = 'entregue' and old.status != 'entregue' then
    -- Busca o valor do split, tratando caso não exista ainda
    select coalesce(entregador_valor_total, 0) into v_entregador_valor
    from public.splits_pagamento 
    where pedido_id = new.id;
    
    -- Só atualiza se o split já foi criado
    if v_entregador_valor > 0 then
      update public.entregadores
      set 
        total_entregas = total_entregas + 1,
        ganhos_total = ganhos_total + v_entregador_valor,
        ganhos_disponiveis = ganhos_disponiveis + v_entregador_valor
      where id = new.entregador_id;
    end if;
  end if;
  return new;
end;
$$ language plpgsql;

create trigger trigger_atualizar_stats_entregador after update on public.pedidos for each row execute function public.atualizar_stats_entregador();

-- ==========================================
-- ÍNDICES PARA PERFORMANCE
-- ==========================================

-- Usuários
create index idx_usuarios_tipo on public.usuarios(tipo_usuario);
create index idx_usuarios_status on public.usuarios(status);

-- Clientes
create index idx_clientes_usuario on public.clientes(usuario_id);

-- Entregadores
create index idx_entregadores_usuario on public.entregadores(usuario_id);
create index idx_entregadores_status_cadastro on public.entregadores(status_cadastro);
create index idx_entregadores_status_online on public.entregadores(status_online) where status_online = true;
create index idx_entregadores_localizacao on public.entregadores using gin(localizacao_atual);

-- Estabelecimentos
create index idx_estabelecimentos_usuario on public.estabelecimentos(usuario_id);
create index idx_estabelecimentos_status on public.estabelecimentos(status_cadastro, status_aberto);
create index idx_estabelecimentos_categoria on public.estabelecimentos(categoria);
create index idx_estabelecimentos_localizacao on public.estabelecimentos using gin(endereco);

-- Administradores Estabelecimento
create index idx_admin_estab_usuario on public.administradores_estabelecimento(usuario_id);
create index idx_admin_estab_estabelecimento on public.administradores_estabelecimento(estabelecimento_id);
create index idx_admin_estab_ativo on public.administradores_estabelecimento(ativo, convite_pendente) where ativo = true and convite_pendente = false;

-- Endereços
create index idx_enderecos_cliente on public.enderecos_clientes(cliente_id);
create index idx_enderecos_padrao on public.enderecos_clientes(cliente_id, is_padrao) where is_padrao = true;

-- Produtos
create index idx_produtos_estabelecimento on public.produtos(estabelecimento_id);
create index idx_produtos_categoria on public.produtos(categoria);
create index idx_produtos_disponivel on public.produtos(disponivel) where disponivel = true;

-- Pedidos
create index idx_pedidos_cliente on public.pedidos(cliente_id, created_at desc);
create index idx_pedidos_entregador on public.pedidos(entregador_id, status);
create index idx_pedidos_estabelecimento on public.pedidos(estabelecimento_id, created_at desc);
create index idx_pedidos_status on public.pedidos(status);
create index idx_pedidos_pagamento on public.pedidos(pagamento_status);

-- Splits
create index idx_splits_pedido on public.splits_pagamento(pedido_id);
create index idx_splits_status on public.splits_pagamento(status);