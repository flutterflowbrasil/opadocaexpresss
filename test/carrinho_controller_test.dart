import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:padoca_express/features/cliente/carrinho/controllers/carrinho_controller.dart';
import 'package:padoca_express/features/estabelecimento/models/produto_model.dart';
import 'package:padoca_express/features/cliente/home/models/estabelecimento_model.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Deve adicionar produto e calcular o total e subtotais corretamente',
      () async {
    final controller = CarrinhoController();

    final estab = EstabelecimentoModel(
      id: 'estab_1',
      nome: 'Padoca Teste',
      avaliacaoMedia: 5.0,
      totalAvaliacoes: 10,
      statusAberto: true,
      configEntrega: {'taxa_entrega_fixa': 5.0},
    );

    final produto = ProdutoModel(
      id: 'prod_1',
      estabelecimentoId: 'estab_1',
      nome: 'Pão de Queijo',
      preco: 2.50,
      isAtivo: true,
      permiteObservacoes: false,
    );

    controller.adicionarProduto(produto, 2, estabelecimento: estab);

    final state = controller.state;
    expect(state.itens.length, 1);
    expect(state.itens.first.quantidade, 2);

    // Subtotal: 2 * 2.50 = 5.00
    expect(state.valorTotalProdutos, 5.00);

    // Total (subtotal + taxa entrega): 5.00 + 5.00 = 10.00
    expect(state.valorTotal, 10.00);
  });

  test('Deve atualizar a quantidade e refletir no valor total', () async {
    final controller = CarrinhoController();

    final estab = EstabelecimentoModel(
      id: 'estab_1',
      nome: 'Padoca Teste',
      avaliacaoMedia: 5.0,
      totalAvaliacoes: 10,
      statusAberto: true,
      configEntrega: {'taxa_entrega_fixa': 5.0},
    );

    final produto = ProdutoModel(
      id: 'prod_1',
      estabelecimentoId: 'estab_1',
      nome: 'Pão de Queijo',
      preco: 2.50,
      isAtivo: true,
      permiteObservacoes: false,
    );

    controller.adicionarProduto(produto, 2, estabelecimento: estab);
    controller.atualizarQuantidade(produto, 4);

    final state = controller.state;

    // Subtotal: 4 * 2.50 = 10.00
    expect(state.valorTotalProdutos, 10.00);

    // Total (subtotal + taxa entrega): 10.00 + 5.00 = 15.00
    expect(state.valorTotal, 15.00);
  });

  test('Deve esvaziar carrinho e remover estabelecimento', () async {
    final controller = CarrinhoController();

    final estab = EstabelecimentoModel(
      id: 'estab_1',
      nome: 'Padoca Teste',
      avaliacaoMedia: 5.0,
      totalAvaliacoes: 10,
      statusAberto: true,
      configEntrega: {'taxa_entrega_fixa': 5.0},
    );

    final produto = ProdutoModel(
      id: 'prod_1',
      estabelecimentoId: 'estab_1',
      nome: 'Pão de Queijo',
      preco: 2.50,
      isAtivo: true,
      permiteObservacoes: false,
    );

    controller.adicionarProduto(produto, 2, estabelecimento: estab);
    controller.removerProduto(produto);

    final state = controller.state;

    expect(state.itens.isEmpty, true);
    expect(state.estabelecimento, isNull);
    expect(state.valorTotalProdutos, 0.0);
    expect(state.valorTotal, 0.0);
  });
}
