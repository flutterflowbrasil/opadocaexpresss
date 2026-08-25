import 'package:flutter_test/flutter_test.dart';
import 'package:padoca_express/features/estabelecimento/models/produto_opcao_model.dart';

void main() {
  test('isEscolhaUnica para tipo unica', () {
    final opcao = ProdutoOpcaoModel(
      nome: 'Ponto da carne',
      tipo: 'unica',
      obrigatorio: true,
      minimo: 1,
      maximo: 1,
      itens: [
        ProdutoOpcaoItemModel(nome: 'Mal passada'),
      ],
    );
    expect(opcao.isEscolhaUnica, isTrue);
  });

  test('isEscolhaUnica para maximo 1 mesmo se tipo multipla', () {
    final opcao = ProdutoOpcaoModel(
      nome: 'Pão',
      tipo: 'multipla',
      obrigatorio: true,
      minimo: 1,
      maximo: 1,
      itens: [
        ProdutoOpcaoItemModel(nome: 'Australiano'),
      ],
    );
    expect(opcao.isEscolhaUnica, isTrue);
  });

  test('fromJson mapeia unica e preco adicional', () {
    final opcao = ProdutoOpcaoModel.fromJson({
      'id': 'g1',
      'nome': 'Adicionais',
      'tipo': 'unica',
      'obrigatorio': true,
      'min_selecoes': 1,
      'max_selecoes': 3,
      'itens': [
        {'id': 'i1', 'nome': 'Bacon', 'preco': 4.0, 'ativo': true},
      ],
    });
    expect(opcao.tipo, 'unica');
    expect(opcao.isEscolhaUnica, isTrue);
    expect(opcao.maximo, 1);
    expect(opcao.itens.first.precoAdicional, 4.0);
  });
}
