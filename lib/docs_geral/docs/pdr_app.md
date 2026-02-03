# 📘 PDR - Project Design Record
## Padoca Express - Sistema de Delivery para Padarias

**Versão:** 1.0  
**Data:** 03/02/2026  
**Status:** Em desenvolvimento  
**Autor:** Equipe Padoca Express

---

## 📋 Sumário

1. [Visão Geral](#1-visão-geral)
2. [Arquitetura do Sistema](#2-arquitetura-do-sistema)
3. [Requisitos Funcionais](#3-requisitos-funcionais)
4. [Requisitos Não-Funcionais](#4-requisitos-não-funcionais)
5. [Modelo de Dados](#5-modelo-de-dados)
6. [Fluxos de Negócio](#6-fluxos-de-negócio)
7. [Integrações](#7-integrações)
8. [Segurança](#8-segurança)
9. [UI/UX](#9-uiux)
10. [Plano de Testes](#10-plano-de-testes)
11. [Deploy e Infraestrutura](#11-deploy-e-infraestrutura)
12. [Cronograma](#12-cronograma)

---

## 1. Visão Geral

### 1.1 Descrição do Produto

O **Padoca Express** é um aplicativo de delivery especializado em padarias, conectando clientes, entregadores e estabelecimentos em uma única plataforma. O diferencial está no sistema de split de pagamento automatizado via Asaas, garantindo que entregadores recebam sua taxa de entrega instantaneamente.

### 1.2 Objetivos

- Facilitar pedidos de padaria com entrega rápida
- Garantir remuneração justa e instantânea para entregadores
- Oferecer gestão completa para estabelecimentos
- Automatizar divisão de pagamentos sem intermediação manual

### 1.3 Público-Alvo

| Persona | Descrição | Necessidade |
|---------|-----------|-------------|
| **Cliente** | Pessoas 25-45 anos, classe média, valorizam praticidade | Pedir café da manhã/pães sem sair de casa |
| **Entregador** | Motoboys/ciclistas, buscam renda extra flexível | Receber por entrega de forma transparente |
| **Estabelecimento** | Padarias pequenas/médias, sem sistema próprio | Vender online sem investir em tecnologia |

### 1.4 Tecnologias Principais

| Camada | Tecnologia | Justificativa |
|--------|-----------|---------------|
| Frontend | Flutter | Single codebase, performance nativa |
| Backend | Supabase | Auth, database realtime, storage |
| Pagamentos | Asaas | Split de pagamento nativo, PIX |
| Maps | Google Maps | Tracking em tempo real |
| Notificações | Firebase | Push notifications gratuitas |

---

## 2. Arquitetura do Sistema

### 2.1 Diagrama de Arquitetura
┌─────────────────────────────────────────────────────────────┐
│                      CLIENTE (Flutter)                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Cliente   │  │ Entregador  │  │  Estabelecimento    │  │
│  │    App      │  │    App      │  │       App           │  │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘  │
└─────────┼────────────────┼────────────────────┼─────────────┘
│                │                    │
└────────────────┴────────────────────┘
│
┌──────▼──────┐
│   Supabase  │
│  ┌─────────┐│
│  │  Auth   ││
│  │  Postgres││
│  │ Realtime ││
│  │ Storage  ││
│  └─────────┘│
└──────┬──────┘
│
┌────────────────┼────────────────┐
│                │                │
┌─────▼─────┐   ┌─────▼─────┐   ┌─────▼─────┐
│   Asaas   │   │  Firebase │   │   Google  │
│ Pagamentos│   │  Cloud    │   │   Maps    │
│  (Split)  │   │Messaging  │   │    API    │
└───────────┘   └───────────┘   └───────────┘
Copy

### 2.2 Padrão Arquitetural

**Clean Architecture + MVVM**
lib/
├── core/              # Camada de infraestrutura
├── features/          # Camada de apresentação (MVVM)
│   └── [feature]/
│       ├── data/      # Repositories, datasources
│       ├── domain/    # Entities, usecases
│       └── presentation/ # Views, ViewModels
└── shared/            # Camada de domínio compartilhado
Copy

### 2.3 Comunicação entre Camadas
View (UI) → ViewModel → UseCase → Repository → DataSource → API/DB
↑___________________________________________________________|
(Stream/Response)
Copy

### 2.4 Gestão de Estado

- **Riverpod** para injeção de dependência e estado global
- **StateNotifier** para estados complexos
- **FutureProvider** para operações async simples

---

## 3. Requisitos Funcionais

### 3.1 Módulo de Autenticação (RF-001 a RF-010)

| ID | Descrição | Prioridade |
|----|-----------|------------|
| RF-001 | Splash screen com verificação de termos | Alta |
| RF-002 | Aceite de termos de uso obrigatório | Alta |
| RF-003 | Seleção de tipo de usuário (Cliente/Entregador/Estabelecimento) | Alta |
| RF-004 | Cadastro com dados específicos por tipo | Alta |
| RF-005 | Login com e-mail/senha | Alta |
| RF-006 | Recuperação de senha | Média |
| RF-007 | Logout seguro | Alta |
| RF-008 | Persistência de sessão | Alta |
| RF-009 | Validação de documentos (CNH para entregador, CNPJ para estabelecimento) | Alta |
| RF-010 | Upload de foto de perfil | Média |

### 3.2 Módulo Cliente (RF-011 a RF-030)

| ID | Descrição | Prioridade |
|----|-----------|------------|
| RF-011 | Home com estabelecimentos próximos | Alta |
| RF-012 | Busca por nome/categoria | Alta |
| RF-013 | Filtro por distância/tempo/avalização | Média |
| RF-014 | Visualização de cardápio completo | Alta |
| RF-015 | Adicionar itens ao carrinho com opções | Alta |
| RF-016 | Carrinho persistente | Alta |
| RF-017 | Múltiplos endereços de entrega | Alta |
| RF-018 | Cálculo automático de taxa de entrega por distância | Alta |
| RF-019 | Checkout com resumo do pedido | Alta |
| RF-020 | Pagamento via PIX (Asaas) | Alta |
| RF-021 | Pagamento via Cartão de Crédito | Média |
| RF-022 | Aplicação de cupons de desconto | Baixa |
| RF-023 | Acompanhamento em tempo real do pedido | Alta |
| RF-024 | Visualização de localização do entregador no mapa | Alta |
| RF-025 | Chat com entregador | Média |
| RF-026 | Histórico de pedidos | Alta |
| RF-027 | Recompra de pedido anterior | Média |
| RF-028 | Avaliação de pedido (estabelecimento e entregador) | Alta |
| RF-029 | Lista de favoritos | Baixa |
| RF-030 | Notificações push de status do pedido | Alta |

### 3.3 Módulo Entregador (RF-031 a RF-050)

| ID | Descrição | Prioridade |
|----|-----------|------------|
| RF-031 | Dashboard com ganhos do dia | Alta |
| RF-032 | Toggle online/offline | Alta |
| RF-033 | Recebimento de notificações de novas entregas | Alta |
| RF-034 | Aceite/recusa de entrega | Alta |
| RF-035 | Mapa com rota otimizada até o estabelecimento | Alta |
| RF-036 | Mapa com rota até o cliente | Alta |
| RF-037 | Atualização de localização em tempo real (a cada 10s) | Alta |
| RF-038 | Confirmação de retirada no estabelecimento | Alta |
| RF-039 | Confirmação de entrega ao cliente | Alta |
| RF-040 | Upload de foto comprovante de entrega | Média |
| RF-041 | Histórico de entregas realizadas | Alta |
| RF-042 | Detalhamento de ganhos por período | Alta |
| RF-043 | Carteira virtual com saldo disponível | Alta |
| RF-044 | Saque para conta bancária | Alta |
| RF-045 | Split automático: recebe taxa de entrega integral | Alta |
| RF-046 | Visualização de avaliações recebidas | Média |
| RF-047 | Configuração de raio de atuação | Média |
| RF-048 | Configuração de horários disponíveis | Baixa |
| RF-049 | Suporte/Reportar problema | Média |
| RF-050 | Indicador de distância total da rota | Média |

### 3.4 Módulo Estabelecimento (RF-051 a RF-075)

| ID | Descrição | Prioridade |
|----|-----------|------------|
| RF-051 | Dashboard com vendas do dia | Alta |
| RF-052 | Gráfico de vendas por período | Média |
| RF-053 | Gerenciamento de status (aberto/fechado) | Alta |
| RF-054 | Cadastro de produtos com fotos | Alta |
| RF-055 | Categorias de produtos personalizáveis | Alta |
| RF-056 | Opções e variações de produtos (tamanho, sabor) | Alta |
| RF-057 | Controle de disponibilidade (esconder quando acabar) | Alta |
| RF-058 | Recebimento de pedidos em tempo real | Alta |
| RF-059 | Confirmação/rejeição de pedidos | Alta |
| RF-060 | Timer de preparo com alertas | Alta |
| RF-061 | Notificação quando entregador chegar | Alta |
| RF-062 | Impressão de comanda | Baixa |
| RF-063 | Histórico de vendas detalhado | Alta |
| RF-064 | Relatório financeiro com split detalhado | Alta |
| RF-065 | Recebe % do valor dos produtos (configurável) | Alta |
| RF-066 | Configuração de taxa de entrega | Alta |
| RF-067 | Configuração de tempo médio de preparo | Alta |
| RF-068 | Configuração de raio de entrega | Alta |
| RF-069 | Configuração de horário de funcionamento | Alta |
| RF-070 | Gerenciamento de múltiplos usuários (funcionários) | Baixa |
| RF-071 | Resposta a avaliações de clientes | Média |
| RF-072 | Promoções e cupons | Baixa |
| RF-073 | Dados bancários para recebimento | Alta |
| RF-074 | Extrato de repasses Asaas | Alta |
| RF-075 | Suporte prioritário | Média |

### 3.5 Módulo Administrativo (RF-076 a RF-085)

| ID | Descrição | Prioridade |
|----|-----------|------------|
| RF-076 | Painel de controle geral | Média |
| RF-077 | Aprovação de cadastros de estabelecimentos | Alta |
| RF-078 | Aprovação de cadastros de entregadores | Alta |
| RF-079 | Gestão de comissões da plataforma | Alta |
| RF-080 | Relatórios financeiros consolidados | Média |
| RF-081 | Suporte a usuários | Média |
| RF-082 | Configuração de taxas globais | Alta |
| RF-083 | Gestão de cupons promocionais | Baixa |
| RF-084 | Monitoramento de entregas em andamento | Média |
| RF-085 | Auditoria de transações | Alta |

---

## 4. Requisitos Não-Funcionais

### 4.1 Performance

| ID | Descrição | Métrica |
|----|-----------|---------|
| RNF-001 | Tempo de carregamento inicial | < 3 segundos |
| RNF-002 | Tempo de resposta de API | < 500ms |
| RNF-003 | Atualização de localização do entregador | < 10 segundos |
| RNF-004 | Suporte a 1000 usuários simultâneos | Sem degradação |
| RNF-005 | Cache de imagens | 7 dias |

### 4.2 Segurança

| ID | Descrição | Implementação |
|----|-----------|---------------|
| RNF-006 | Criptografia de dados sensíveis | AES-256 |
| RNF-007 | HTTPS em todas as comunicações | SSL/TLS 1.3 |
| RNF-008 | Tokens JWT com expiração | 24 horas |
| RNF-009 | Rate limiting | 100 req/min por IP |
| RNF-010 | Sanitização de inputs | Validação server-side |
| RNF-011 | Auditoria de ações | Logs em Supabase |
| RNF-012 | Backup automático | Diário |

### 4.3 Disponibilidade

| ID | Descrição | Meta |
|----|-----------|------|
| RNF-013 | Uptime do sistema | 99.9% |
| RNF-014 | RTO (Recovery Time Objective) | 4 horas |
| RNF-015 | RPO (Recovery Point Objective) | 1 hora |

### 4.4 Usabilidade

| ID | Descrição | Critério |
|----|-----------|----------|
| RNF-016 | Interface responsiva | Mobile-first |
| RNF-017 | Acessibilidade | WCAG 2.1 AA |
| RNF-018 | Suporte a modo escuro | Sim |
| RNF-019 | Idiomas | Português (BR) |
| RNF-020 | Offline capability | Cache de dados essenciais |

### 4.5 Escalabilidade

| ID | Descrição | Estratégia |
|----|-----------|------------|
| RNF-021 | Escalabilidade horizontal | Supabase auto-scale |
| RNF-022 | CDN para assets | Cloudflare |
| RNF-023 | Database sharding | Quando atingir 1M usuários |

---

## 5. Modelo de Dados

### 5.1 Diagrama ER Simplificado
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│   profiles  │       │   pedidos   │       │   produtos  │
├─────────────┤       ├─────────────┤       ├─────────────┤
│ id (PK)     │◄──────┤ id (PK)     │       │ id (PK)     │
│ tipo        │       │ cliente_id  │       │ estab_id (FK)│
│ nome        │       │ entreg_id (FK)◄─────┤ nome        │
│ email       │       │ estab_id (FK)◄──────┤ preco       │
│ asaas_wallet├───────┤ status      │       │ categoria   │
└─────────────┘       │ total       │       └─────────────┘
│ created_at  │
└──────┬──────┘
│
┌──────▼──────┐
│pagamento_splits
├─────────────┤
│ id (PK)     │
│ pedido_id(FK)│
│ entreg_wallet│
│ entreg_valor │ ◄── Split do entregador
│ estab_wallet │
│ estab_valor  │ ◄── Split do estabelecimento
│ plat_valor   │ ◄── Comissão plataforma
└─────────────┘
Copy

### 5.2 Dicionário de Dados

#### Tabela: `profiles`

| Campo | Tipo | Descrição | Restrições |
|-------|------|-----------|------------|
| id | uuid | ID do usuário (auth) | PK, FK auth.users |
| tipo_usuario | text | Tipo de conta | CHECK: cliente, entregador, estabelecimento |
| nome | text | Nome completo | NOT NULL |
| email | text | E-mail | NOT NULL, UNIQUE |
| telefone | text | Celular | - |
| cpf_cnpj | text | Documento | UNIQUE por tipo |
| foto_url | text | URL da foto | - |
| status | text | Status da conta | DEFAULT: ativo |
| asaas_customer_id | text | ID cliente Asaas | - |
| asaas_wallet_id | text | ID carteira split | - |
| asaas_account_id | text | ID subconta | - |
| created_at | timestamptz | Criação | DEFAULT now() |
| updated_at | timestamptz | Atualização | AUTO |

#### Tabela: `pedidos`

| Campo | Tipo | Descrição | Restrições |
|-------|------|-----------|------------|
| id | uuid | ID do pedido | PK |
| cliente_id | uuid | Quem comprou | FK profiles |
| estabelecimento_id | uuid | Onde comprou | FK estabelecimentos |
| entregador_id | uuid | Quem entrega | FK profiles |
| status | text | Status atual | CHECK: 7 status definidos |
| itens | jsonb | Lista de produtos | NOT NULL |
| subtotal | decimal | Só produtos | NOT NULL |
| taxa_entrega | decimal | Frete | NOT NULL |
| taxa_servico | decimal | % do app | DEFAULT 0 |
| desconto | decimal | Cupom | DEFAULT 0 |
| total | decimal | Valor final | NOT NULL |
| endereco_entrega | jsonb | Endereço snapshot | NOT NULL |
| distancia_km | decimal | Distância calculada | - |
| asaas_payment_id | text | ID pagamento | - |
| pagamento_status | text | Status Asaas | DEFAULT: pendente |
| created_at | timestamptz | Criação | DEFAULT now() |

#### Tabela: `pagamento_splits`

| Campo | Tipo | Descrição | Restrições |
|-------|------|-----------|------------|
| id | uuid | ID do split | PK |
| pedido_id | uuid | Pedido relacionado | FK pedidos |
| valor_total | decimal | Valor total | NOT NULL |
| estabelecimento_wallet_id | text | Wallet Asaas | NOT NULL |
| estabelecimento_percentual | decimal | % acordada | DEFAULT 85.00 |
| estabelecimento_valor | decimal | Valor líquido | NOT NULL |
| entregador_wallet_id | text | Wallet Asaas | NOT NULL |
| entregador_recebe_taxa_entrega | boolean | Recebe frete? | DEFAULT true |
| entregador_percentual_extra | decimal | % extra | DEFAULT 0 |
| entregador_valor | decimal | Valor total | NOT NULL |
| plataforma_valor | decimal | Comissão app | NOT NULL |
| status | text | Status split | DEFAULT: pendente |
| asaas_split_response | jsonb | Resposta API | - |

---

## 6. Fluxos de Negócio

### 6.1 Fluxo de Pedido Completo
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│ CLIENTE │    │  APP    │    │  SUPABASE │   │  ASAAS  │    │ENTREGADOR│
└────┬────┘    └────┬────┘    └────┬────┘    └────┬────┘    └────┬────┘
│              │              │              │              │
│ 1. Faz pedido │              │              │              │
│─────────────►│              │              │              │
│              │ 2. Cria pedido               │              │
│              │─────────────►│              │              │
│              │              │ 3. Retorna pedido_id         │
│              │◄─────────────│              │              │
│              │              │              │              │
│              │ 4. Cria cobrança Asaas       │              │
│              │─────────────────────────────►│              │
│              │              │              │ 5. Retorna payment_id │
│              │◄─────────────────────────────│              │
│              │              │              │              │
│ 6. Mostra QR PIX             │              │              │
│◄─────────────│              │              │              │
│              │              │              │              │
│ 7. Cliente paga PIX          │              │              │
│─────────────►│              │              │              │
│              │ 8. Webhook Asaas notifica    │              │
│              │◄─────────────────────────────│              │
│              │              │              │              │
│              │ 9. Atualiza status=pago      │              │
│              │─────────────►│              │              │
│              │              │ 10. Notifica estabelecimento │
│              │              │─────────────►│ (push)       │
│              │              │              │              │
│              │              │ 11. Notifica entregadores    │
│              │              │──────────────┼─────────────►│
│              │              │              │              │
│              │              │◄─────────────┼──────────────│
│              │              │ 12. Entregador aceita        │
│              │              │              │              │
│              │              │ 13. Atualiza entregador_id   │
│              │              │              │              │
│              │ 14. Mostra rota até estab    │              │
│              │◄─────────────┼──────────────┼──────────────│
│              │              │              │              │
│              │              │ ... (entrega)               │
│              │              │              │              │
│              │              │ 20. Marca entregue           │
│              │              │◄─────────────┼──────────────│
│              │              │              │              │
│ 21. Notifica cliente         │              │              │
│◄─────────────┼──────────────┼──────────────┼──────────────│
│              │              │              │              │
│ 22. Avalia   │              │              │              │
│─────────────►│              │              │              │
│              │              │              │              │
Copy

### 6.2 Fluxo de Split de Pagamento
Pedido: R
50,00├─Subtotal(produtos):R
 
 40,00
├─ Taxa entrega: R
8,00└─Taxaapp:R
 
 2,00 (5%)
SPLIT AUTOMÁTICO ASAAS:
├─ Estabelecimento (85% de R40):R  34,00 → Wallet do estabelecimento
├─ Entregador (taxa entrega R8):R  8,00 → Wallet do entregador
└─ Padoca Express (resto): R$ 8,00 → Wallet master
Copy

---

## 7. Integrações

### 7.1 Asaas (Pagamentos)

| Endpoint | Uso | Documentação |
|----------|-----|--------------|
| POST /customers | Criar cliente pagador | [Asaas Docs](https://docs.asaas.com) |
| POST /payments | Criar cobrança | - |
| POST /payments/{id}/split | Configurar split | - |
| POST /accounts | Criar subconta (wallet) | - |
| GET /payments/{id} | Consultar status | - |

**Configuração de Split:**
```json
{
  "split": [
    {
      "walletId": "wallet_estabelecimento",
      "percentualValue": 85.00
    },
    {
      "walletId": "wallet_entregador",
      "fixedValue": 8.00
    }
  ]
}
7.2 Google Maps
Table
Copy
API	Uso	Custo
Maps SDK	Mapa interativo	$7/1000 loads
Directions API	Rota otimizada	$5/1000 requests
Distance Matrix	Calcular distância/tempo	$5/1000 elements
Geocoding	Converter endereço em coordenadas	$5/1000 requests
Estratégia de Custo:
Cache de rotas calculadas (24h)
Limitar cálculos a cada 500m de movimento do entregador
Usar modo "driving" com traffic
7.3 Firebase
Table
Copy
Serviço	Uso	Configuração
Cloud Messaging	Push notifications	Canal: "padoca_express"
Crashlytics	Monitoramento de erros	Ativado em release
Analytics	Métricas de uso	Eventos customizados
8. Segurança
8.1 Autenticação
JWT tokens com expiração de 24h
Refresh tokens automáticos
Row Level Security (RLS) no Supabase
Senhas: mínimo 8 caracteres, 1 maiúscula, 1 número
8.2 Autorização (RLS Policies)
sql
Copy
-- Exemplo: Entregador só vê entregas atribuídas a ele
CREATE POLICY "Entregador vê próprias entregas"
ON pedidos FOR SELECT
USING (auth.uid() = entregador_id);

-- Exemplo: Estabelecimento só edita próprios produtos
CREATE POLICY "Dono edita produtos"
ON produtos FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM estabelecimentos e
    WHERE e.id = produtos.estabelecimento_id
    AND e.profile_id = auth.uid()
  )
);
8.3 Proteção de Dados
Table
Copy
Dado	Proteção	Onde
Senhas	bcrypt	Supabase Auth
CPF/CNPJ	Máscara na UI, criptografado no DB	AES-256
Dados bancários	Tokenização Asaas	Asaas (PCI compliant)
Localização em tempo real	Expira em 24h	Supabase (TTL)
9. UI/UX
9.1 Paleta de Cores
Table
Copy
Cor	Hex	Uso
Laranja Primário	#FF6B35	Botões, destaques, marca
Laranja Escuro	#E55A2B	Hover/pressed states
Verde Água	#2EC4B6	Sucesso, confirmação
Amarelo Queijo	#FFBF69	Avisos, promoções
Vermelho	#E71D36	Erros, cancelamentos
Cinza Escuro	#1A1A1A	Texto principal
Cinza Médio	#666666	Texto secundário
Cinza Claro	#F7F7F7	Background
9.2 Tipografia
Table
Copy
Estilo	Tamanho	Peso	Uso
H1	32px	Bold	Títulos de tela
H2	24px	SemiBold	Subtítulos
H3	20px	SemiBold	Cards headers
Body	16px	Regular	Texto geral
Caption	14px	Regular	Labels, hints
Small	12px	Regular	Timestamps, metadados
9.3 Componentes Principais
PrimaryButton: Laranja, 56px altura, border-radius 12px
SecondaryButton: Branco com borda laranja
InputField: Background cinza claro, border-radius 12px
Card: Branco, sombra suave, border-radius 16px
BottomNav: 3-5 itens, ícones outline/filled
9.4 Telas Principais
Table
Copy
Tela	Descrição	Prioridade
Splash	Logo animada, verificação inicial	Alta
Termos	Scroll longo, checkbox obrigatório	Alta
SelectUserType	3 cards grandes com ícones	Alta
Login	Email/senha, esqueci senha	Alta
Register	Form dinâmico por tipo	Alta
Home Cliente	Busca, categorias, lista estabelecimentos	Alta
Restaurante	Cardápio, carrinho flutuante	Alta
Checkout	Resumo, endereço, pagamento	Alta
Mapa Entregador	Fullscreen map, card pedido bottom	Alta
Dashboard Estab	Gráficos, pedidos pendentes	Alta
10. Plano de Testes
10.1 Tipos de Teste
Table
Copy
Tipo	Ferramenta	Cobertura
Unit	flutter_test	ViewModels, UseCases
Widget	flutter_test	Componentes isolados
Integration	integration_test	Fluxos completos
E2E	Patrol	Cenários críticos
10.2 Cenários Críticos
Table
Copy
ID	Cenário	Tipo	Prioridade
CT-001	Cliente faz pedido completo até pagamento	E2E	Alta
CT-002	Entregador aceita e completa entrega	E2E	Alta
CT-003	Split de pagamento processa corretamente	Integration	Alta
CT-004	Cálculo de distância e taxa de entrega	Unit	Alta
CT-005	Atualização de localização em tempo real	Integration	Alta
CT-006	Offline: cache de dados essenciais	Integration	Média
CT-007	Cancelamento de pedido e estorno	E2E	Alta
11. Deploy e Infraestrutura
11.1 Ambientes
Table
Copy
Ambiente	URL	Banco	Asaas
Dev	localhost	Supabase local	Sandbox
Staging	app-staging.padoca.com	Supabase project-staging	Sandbox
Prod	app.padoca.com	Supabase project-prod	Produção
11.2 CI/CD Pipeline
yaml
Copy
# .github/workflows/flutter.yml
name: Flutter CI/CD

on:
  push:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test

  build-android:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build apk --release
      - run: flutter build appbundle --release

  build-ios:
    needs: test
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build ios --release --no-codesign
11.3 Lojas
Table
Copy
Plataforma	Conta	Previsão
Google Play	Criar conta dev ($25)	Semana 8
App Store	Criar conta dev ($99/ano)	Semana 8
12. Cronograma
Fase 1: Fundação (Semanas 1-2)
Table
Copy
Semana	Entregáveis
1	Setup projeto, arquitetura, banco de dados, autenticação básica
2	Splash, termos, seleção tipo, cadastros por tipo
Fase 2: Core (Semanas 3-5)
Table
Copy
Semana	Entregáveis
3	Home cliente, busca, cardápio, carrinho
4	Checkout, integração Asaas, pagamento PIX
5	Dashboard entregador, aceite de entregas
Fase 3: Logística (Semanas 6-7)
Table
Copy
Semana	Entregáveis
6	Google Maps, tracking em tempo real, rotas
7	Dashboard estabelecimento, gestão de pedidos
Fase 4: Polimento (Semana 8)
Table
Copy
Semana	Entregáveis
8	Testes, bug fixes, otimizações, deploy nas lojas
📎 Anexos
A. Glossário
Table
Copy
Termo	Definição
Split	Divisão automática de pagamento entre partes
Wallet	Carteira virtual Asaas para recebimento
RLS	Row Level Security - controle de acesso por linha
Snapshot	Cópia dos dados no momento do evento
B. Contatos
Table
Copy
Função	Responsável	Contato
Tech Lead	[Nome]	[Email]
Product Owner	[Nome]	[Email]
Designer	[Nome]	[Email]
C. Referências
Flutter Documentation
Supabase Documentation
Asaas API Documentation
Material Design 3
Histórico de Versões
Table
Copy
Versão	Data	Autor	Alterações
1.0	03/02/2026	Equipe	Versão inicial
Documento confidencial - Padoca Express © 2026
Copy

---

**Para salvar:**

1. Crie a pasta: `mkdir -p docs`
2. Crie o arquivo: `docs/PDR.md`
3. Cole todo o conteúdo acima
4. Salve

**Me avise quando salvar e digite PRÓXIMO** para criarmos o **GoRouter** e a tela de **Termos de Uso**.