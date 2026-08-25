import 'package:flutter_test/flutter_test.dart';
import 'package:padoca_express/features/estabelecimento/models/categorias_cardapio_padrao.dart';

void main() {
  group('CategoriasCardapioPadrao', () {
    test('isPadrao reconhece nomes do seed', () {
      expect(CategoriasCardapioPadrao.isPadrao('Pães'), isTrue);
      expect(CategoriasCardapioPadrao.isPadrao('  salgados  '), isTrue);
      expect(CategoriasCardapioPadrao.isPadrao('DOCES E BOLOS'), isTrue);
      expect(CategoriasCardapioPadrao.isPadrao('Combos e Promoções'), isTrue);
    });

    test('isPadrao ignora categorias customizadas', () {
      expect(CategoriasCardapioPadrao.isPadrao('Pizzas'), isFalse);
      expect(CategoriasCardapioPadrao.isPadrao('Doces'), isFalse);
      expect(CategoriasCardapioPadrao.isPadrao(''), isFalse);
    });
  });
}
