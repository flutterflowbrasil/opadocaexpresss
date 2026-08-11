import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padoca_express/features/cliente/carrinho/controllers/carrinho_controller.dart';
import 'package:padoca_express/features/estabelecimento/models/produto_model.dart';
import 'package:padoca_express/features/cliente/home/models/estabelecimento_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:padoca_express/features/cliente/carrinho/data/cupom_repository.dart';

class MockCupomRepository extends Mock implements CupomRepository {}
void main() {
  setUp(() {
    // A1: Mock do FlutterSecureStorage (carrinho migrado de SharedPreferences)
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('Deve adicionar produto e calcular o total e subtotais corretamente',
      () async {
    final mockCupomRepo = MockCupomRepository();
    final controller = CarrinhoController(mockCupomRepo);

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
    final mockCupomRepo = MockCupomRepository();
    final controller = CarrinhoController(mockCupomRepo);

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
    final mockCupomRepo = MockCupomRepository();
    final controller = CarrinhoController(mockCupomRepo);

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

  test('Deve tratar variações de tamanho como itens separados e cobrar pelo preço da variação', () async {
    final mockCupomRepo = MockCupomRepository();
    final controller = CarrinhoController(mockCupomRepo);

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
      nome: 'Pizza',
      preco: 10.00, // Preço normal ignorado
      isAtivo: true,
      permiteObservacoes: false,
    );

    // Adiciona pizza pequena
    controller.adicionarProduto(produto, 1, 
      estabelecimento: estab, 
      tamanhoProdutoId: 't1', 
      tamanhoProdutoNome: 'Pequena', 
      precoBaseProduto: 30.0,
      precoUnitario: 30.0);
      
    // Adiciona pizza grande
    controller.adicionarProduto(produto, 1, 
      estabelecimento: estab, 
      tamanhoProdutoId: 't2', 
      tamanhoProdutoNome: 'Grande', 
      precoBaseProduto: 50.0,
      precoUnitario: 50.0);

    final state = controller.state;
    expect(state.itens.length, 2); // Devem ser itens separados
    expect(state.valorTotalProdutos, 80.0); // 30 + 50 = 80
    expect(state.valorTotal, 85.0); // 80 + 5 (taxa) = 85
  });
}
