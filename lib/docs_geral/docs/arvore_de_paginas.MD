## Estrutura de páginas

lib/
├── core/                          # Coisas globais usadas em todo app
│   ├── constants/                 # AppConstants, cores, strings
│   ├── errors/                    # Tratamento de erros
│   ├── router/                    # GoRouter config
│   ├── theme/                     # Tema do app
│   ├── usecases/                  # Casos de uso genéricos
│   └── utils/                     # Helpers, formatadores
│
├── features/                      # CADA funcionalidade separada
│   ├── auth/                      # Login, cadastro, esqueci senha
│   │   ├── data/                  # Repositories, datasources
│   │   ├── domain/                # Entities, usecases
│   │   └── presentation/          # Views, viewmodels
│   │
│   ├── onboarding/                # Termos, seleção tipo usuário
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── cliente/                   # Fluxo completo do cliente
│   │   ├── home/
│   │   ├── busca/
│   │   ├── restaurante/
│   │   ├── carrinho/
│   │   ├── checkout/
│   │   ├── pedidos/
│   │   └── perfil/
│   │
│   ├── entregador/                # Fluxo do entregador
│   │   ├── dashboard/
│   │   ├── entregas/
│   │   ├── mapa/
│   │   ├── carteira/              # Onde vê ganhos (split)
│   │   └── perfil/
│   │
│   └── estabelecimento/           # Fluxo do estabelecimento
│       ├── dashboard/
│       ├── cardapio/
│       ├── pedidos/
│       ├── financeiro/            # Recebe split aqui
│       └── perfil/
│
├── shared/                        # Widgets e models compartilhados
│   ├── models/                    # UserModel, PedidoModel, etc
│   ├── widgets/                   # Buttons, inputs, cards reusáveis
│   └── services/                  # AsaasService, NotificationService
│
└── main.dart