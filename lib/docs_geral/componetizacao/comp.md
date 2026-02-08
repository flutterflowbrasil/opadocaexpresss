# Componentes Reutilizáveis

Este documento lista os componentes do projeto `Padoca Express` já criados e estabelece regras para seu reaproveitamento.

## Regras Gerais de Uso

1.  **Verifique Antes de Criar**: Antes de implementar uma nova UI, verifique se um componente existente pode ser utilizado ou adaptado.
2.  **Manter a Consistência**: Utilize os parâmetros fornecidos (cores, textos, callbacks) para manter a identidade visual do app.
3.  **Responsividade**: Os componentes foram criados pensando em responsividade; evite fixar tamanhos que quebrem em telas menores.
4.  **Temas**: A maioria dos componentes suporta modo claro e escuro (`isDark`). Certifique-se de passar este parâmetro corretamente.

---

## Lista de Componentes

### 1. CustomBottomNavigationBar

**Localização**: `lib/features/cliente/componentes/custom_bottom_navigation_bar.dart`

**Descrição**: Barra de navegação inferior padrão para a área do cliente.

**Uso**:
```dart
CustomBottomNavigationBar(
  currentIndex: _currentIndex,
  onTap: (index) => setState(() => _currentIndex = index),
)
```

**Itens**:
-   Início (Index 0)
-   Pedidos (Index 1)
-   Perfil (Index 2)

---

### 2. HomeHeader

**Localização**: `lib/features/cliente/componentes/home_header.dart`

**Descrição**: Cabeçalho da tela inicial contendo:
-   Endereço de entrega (com ícone e dropdown).
-   Botões de ação: Notificações e Sacola de Compras.
-   Barra de pesquisa.

**Parâmetros**:
-   `isDark` (bool): Define o tema.
-   `primaryColor` (Color): Cor primária (ex: ícone de localização).
-   `secondaryColor` (Color): Cor secundária (ex: texto do endereço no modo claro).
-   `cardColor` (Color): Cor de fundo da barra de pesquisa.

**Uso**:
```dart
HomeHeader(
  isDark: isDark,
  primaryColor: primaryColor,
  secondaryColor: secondaryColor,
  cardColor: cardColor,
)
```

---

### 3. PromoBanner

**Localização**: `lib/features/cliente/componentes/promo_banner.dart`

**Descrição**: Banner promocional grande com imagem de fundo, gradiente, título, subtítulo e botão de ação ("Peça agora").

**Parâmetros**:
-   `secondaryColor` (Color): Cor do texto do botão.

**Uso**:
```dart
PromoBanner(secondaryColor: secondaryColor)
```

---

### 4. CategoryItem

**Localização**: `lib/features/cliente/componentes/category_item.dart`

**Descrição**: Item circular representando uma categoria de produtos (ex: Padarias, Doces), com imagem e título abaixo.

**Parâmetros**:
-   `title` (String): Nome da categoria.
-   `imageUrl` (String): URL da imagem.
-   `isDark` (bool): Define a cor do texto.

**Uso**:
```dart
CategoryItem(
  title: 'Doces',
  imageUrl: 'https://...',
  isDark: isDark,
)
```

---

### 5. BakeryCard

**Localização**: `lib/features/cliente/componentes/bakery_card.dart`

**Descrição**: Card horizontal detalhado para exibir informações de um estabelecimento (padaria). Inclui imagem, nome, descrição, avaliação, tempo de entrega e taxa.

**Parâmetros**:
-   `name` (String): Nome da padaria.
-   `description` (String): Descrição curta.
-   `rating` (String): Avaliação (ex: "4.8").
-   `time` (String): Tempo estimado (ex: "25-35 min").
-   `fee` (String): Taxa de entrega (ex: "R$ 3,99" ou "Grátis").
-   `imageUrl` (String): URL da imagem da padaria.
-   `isDark` (bool): Ajusta bordas e cores de texto.
-   `cardColor` (Color): Cor de fundo do card.
-   `isClosed` (bool, opcional): Se `true`, aplica opacidade e destaca o texto de tempo em vermelho.

**Uso**:
```dart
BakeryCard(
  name: 'Padaria do João',
  description: 'Pães e doces...',
  rating: '4.8',
  time: '20 min',
  fee: 'Grátis',
  imageUrl: 'https://...',
  isDark: isDark,
  cardColor: cardColor,
)
```
