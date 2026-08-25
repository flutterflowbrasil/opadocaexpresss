/// Nomes das categorias de cardápio criadas automaticamente pelo seed da plataforma.
/// Estabelecimentos não devem editar/excluir essas categorias via dashboard.
class CategoriasCardapioPadrao {
  CategoriasCardapioPadrao._();

  static const padraoNomes = {
    'Pães',
    'Salgados',
    'Doces e Bolos',
    'Bebidas',
    'Lanches',
    'Combos e Promoções',
  };

  static bool isPadrao(String nome) {
    final normalizado = nome.trim().toLowerCase();
    return padraoNomes.any((n) => n.toLowerCase() == normalizado);
  }
}
