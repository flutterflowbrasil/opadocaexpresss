import 'package:padoca_express/features/cliente/categorias/models/categoria_estabelecimento_model.dart';
import 'categoria_cardapio_model.dart';

/// Infere a seção do cardápio (`categorias_cardapio`) a partir da categoria
/// principal da plataforma (`categorias_estabelecimento`).
class CategoriaCardapioInferencia {
  CategoriaCardapioInferencia._();

  static const _slugParaCardapio = {
    'pizza': 'Salgados',
    'lanches': 'Lanches',
    'hamburguer': 'Lanches',
    'hamburgueres': 'Lanches',
    'salgados': 'Salgados',
    'pasteis': 'Salgados',
    'pastel': 'Salgados',
    'esfirra': 'Salgados',
    'esfirras': 'Salgados',
    'bolos-tortas': 'Doces e Bolos',
    'bolos': 'Doces e Bolos',
    'doces': 'Doces e Bolos',
    'paes': 'Pães',
    'pao': 'Pães',
    'bebidas': 'Bebidas',
    'bebida': 'Bebidas',
    'combos': 'Combos e Promoções',
    'promocoes': 'Combos e Promoções',
  };

  static String? inferirId({
    required List<String> categoriaPrincipalIds,
    required List<CategoriaEstabelecimentoModel> principais,
    required List<CategoriaCardapioModel> cardapio,
  }) {
    if (categoriaPrincipalIds.isEmpty || cardapio.isEmpty) return null;

    for (final catId in categoriaPrincipalIds) {
      CategoriaEstabelecimentoModel? principal;
      for (final c in principais) {
        if (c.id == catId) {
          principal = c;
          break;
        }
      }
      if (principal == null) continue;

      final slug = principal.slug.toLowerCase();
      final nomeAlvo = _slugParaCardapio[slug] ??
          _slugParaCardapio[slug.split('-').first];

      if (nomeAlvo != null) {
        for (final c in cardapio) {
          if (c.ativa && c.nome.toLowerCase() == nomeAlvo.toLowerCase()) {
            return c.id;
          }
        }
      }

      final nomePrincipal = principal.nome.toLowerCase();
      for (final c in cardapio) {
        if (!c.ativa) continue;
        final nomeCardapio = c.nome.toLowerCase();
        if (nomeCardapio.contains(nomePrincipal) ||
            nomePrincipal.contains(nomeCardapio)) {
          return c.id;
        }
      }
    }

    return null;
  }
}
