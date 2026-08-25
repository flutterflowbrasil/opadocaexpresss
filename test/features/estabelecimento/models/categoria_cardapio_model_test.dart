import 'package:flutter_test/flutter_test.dart';
import 'package:padoca_express/features/estabelecimento/models/categoria_cardapio_model.dart';

void main() {
  test('isCategoriaPadrao delega para CategoriasCardapioPadrao', () {
    final padrao = CategoriaCardapioModel(
      id: '1',
      estabelecimentoId: 'est',
      nome: 'Bebidas',
      ordemExibicao: 1,
      ativa: true,
    );
    final custom = CategoriaCardapioModel(
      id: '2',
      estabelecimentoId: 'est',
      nome: 'Especiais da Casa',
      ordemExibicao: 2,
      ativa: true,
    );

    expect(padrao.isCategoriaPadrao, isTrue);
    expect(custom.isCategoriaPadrao, isFalse);
  });
}
