import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/produtos/controllers/produtos_controller.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/produtos/controllers/produtos_state.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/produtos/data/produtos_repository.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/produtos/models/produto_model.dart';
import 'package:padoca_express/features/estabelecimento/models/categoria_cardapio_model.dart';

// Mock class
class MockProdutosRepository extends Mock implements ProdutosRepository {}

void main() {
  late ProdutosController controller;
  late MockProdutosRepository mockRepository;

  setUp(() {
    mockRepository = MockProdutosRepository();
    controller = ProdutosController(mockRepository);
  });

  final dummyEstId = 'estab-123';

  final catPao = CategoriaCardapioModel(
    id: 'cat-1',
    estabelecimentoId: dummyEstId,
    nome: 'Pães',
    ordemExibicao: 0,
    ativa: true,
  );

  final catDoce = CategoriaCardapioModel(
    id: 'cat-2',
    estabelecimentoId: dummyEstId,
    nome: 'Doces',
    ordemExibicao: 1,
    ativa: true,
  );

  final prod1 = ProdutoModel(
    id: 'p1',
    estabelecimentoId: dummyEstId,
    nome: 'Pão Francês',
    preco: 0.50,
    categoriaCardapioId: 'cat-1',
    disponivel: true,
    ativo: true,
  );

  final prod2 = ProdutoModel(
    id: 'p2',
    estabelecimentoId: dummyEstId,
    nome: 'Bolo de Cenoura',
    preco: 15.00,
    precoPromocional: 12.00, // Promo test
    categoriaCardapioId: 'cat-2',
    disponivel: false,
    ativo: true,
  );

  final prod3 = ProdutoModel(
    id: 'p3',
    estabelecimentoId: dummyEstId,
    nome: 'Misto Quente',
    preco: 8.00,
    categoriaCardapioId: 'cat-1',
    disponivel: true,
    ativo: true,
    destaque: true,
  );

  group('ProdutosController State Tests', () {
    test('1. Deve inicializar com estado vazio/default', () {
      expect(controller.state, const ProdutosState());
      expect(controller.state.produtos, isEmpty);
      expect(controller.state.isLoading, isFalse);
    });

    test(
        '2. Deve preencher estado e anular erro após carregar dados com sucesso',
        () async {
      // Arrange
      when(() => mockRepository.fetchProdutos(dummyEstId))
          .thenAnswer((_) async => [prod1, prod2, prod3]);
      when(() => mockRepository.fetchCategorias(dummyEstId))
          .thenAnswer((_) async => [catPao, catDoce]);

      // Act
      await controller.loadDados(dummyEstId);

      // Assert
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.error, isNull);
      expect(controller.state.produtos.length, 3);
      expect(controller.state.categorias.length, 2);
      expect(controller.state.produtosFiltrados.length,
          3); // O array de filtrados deve ser = aos totais no carregamento inicial
    });

    test('3. Deve preencher campo (error) se repositório atirar exception',
        () async {
      // Arrange
      when(() => mockRepository.fetchProdutos(dummyEstId))
          .thenThrow(Exception('Falha na conexão'));
      when(() => mockRepository.fetchCategorias(dummyEstId)).thenAnswer(
          (_) async => [
                catPao
              ]); // Suponha que esse sucedeu, mas o paralelo falha globalmente

      // Act
      await controller.loadDados(dummyEstId);

      // Assert
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.error, contains('Falha na conexão'));
      expect(controller.state.produtos, isEmpty);
    });

    // Testes de FILTROS EM MEMÓRIA (TDD Essencial garantindo a lógica de busca sem bater no BD)
    group('Lógica de Filtro Local', () {
      setUp(() async {
        // Pré-carrega a lista nos testes seguintes
        when(() => mockRepository.fetchProdutos(dummyEstId))
            .thenAnswer((_) async => [prod1, prod2, prod3]);
        when(() => mockRepository.fetchCategorias(dummyEstId))
            .thenAnswer((_) async => [catPao, catDoce]);
        await controller.loadDados(dummyEstId);
      });

      test('4. Deve filtrar corretamente: Apenas da categoria Doces', () {
        controller.aplicarFiltros(categoriaId: 'cat-2');
        expect(controller.state.produtosFiltrados.length, 1);
        expect(
            controller.state.produtosFiltrados.first.nome, 'Bolo de Cenoura');
      });

      test('5. Deve filtrar corretamente: Busca Textual com Case Insensitive',
          () {
        controller.aplicarFiltros(query: 'pão');
        expect(controller.state.produtosFiltrados.length, 1);
        expect(controller.state.produtosFiltrados.first.nome, 'Pão Francês');
      });

      test(
          '6. Deve filtrar corretamente: Status dinâmicos combinados (Destaque)',
          () {
        controller.aplicarFiltros(status: 'destaque');
        expect(controller.state.produtosFiltrados.length, 1);
        expect(controller.state.produtosFiltrados.first.nome, 'Misto Quente');
      });

      test('7. Deve resetar todos os filtros', () {
        controller.aplicarFiltros(
            status: 'promo', categoriaId: 'cat-1'); // Sem resultados
        expect(controller.state.produtosFiltrados, isEmpty);

        controller.limparFiltros();
        expect(
            controller.state.produtosFiltrados.length, 3); // Voltou ao normal
        expect(controller.state.searchQuery, isNull);
        expect(controller.state.selectedStatusFilter, isNull);
      });
    });

    test('8. Optimistic UI: Alterar disponibilidade altera lista imediatamente',
        () async {
      when(() => mockRepository.fetchProdutos(dummyEstId))
          .thenAnswer((_) async => [prod1]);
      when(() => mockRepository.fetchCategorias(dummyEstId))
          .thenAnswer((_) async => [catPao]);
      when(() => mockRepository.updateDisponibilidade('p1', false))
          .thenAnswer((_) async {});

      await controller.loadDados(dummyEstId);

      // Act
      expect(controller.state.produtos.first.disponivel, isTrue); // Início
      await controller.toggleDisponibilidade('p1', true);

      // Assert
      expect(controller.state.produtos.first.disponivel, isFalse);
      verify(() => mockRepository.updateDisponibilidade('p1', false))
          .called(1); // Checa que disparou para BD
    });
  });
}
