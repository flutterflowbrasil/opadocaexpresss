import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/cupons/cupons_controller.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/cupons/data/cupons_repository.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/cupons/models/cupom_model.dart';

class MockCuponsRepository extends Mock implements CuponsRepository {}

class FakeCupomModel extends Fake implements CupomModel {}

void main() {
  late MockCuponsRepository mockRepository;
  late CuponsController controller;
  late String estabelecimentoId;

  setUpAll(() {
    registerFallbackValue(FakeCupomModel());
  });

  setUp(() {
    mockRepository = MockCuponsRepository();
    estabelecimentoId = 'estab-123';

    when(() => mockRepository.fetchCupons(estabelecimentoId))
        .thenAnswer((_) async => []);

    controller = CuponsController(mockRepository, estabelecimentoId);
  });

  group('CuponsController Tests |', () {
    final cupomBase = CupomModel(
      id: 'cupom-1',
      estabelecimentoId: 'estab-123',
      codigo: 'PROMO10',
      tipo: 'percentual',
      valor: 10.0,
      valorMinimoPedido: 0,
      ativo: true,
      usosAtuais: 0,
      limiteUsosPorCliente: 1,
      dataInicio: DateTime.now().subtract(const Duration(days: 1)),
    );

    test('Deve iniciar carregando os cupons e populando o state', () async {
      when(() => mockRepository.fetchCupons(estabelecimentoId))
          .thenAnswer((_) async => [cupomBase]);

      final newController = CuponsController(mockRepository, estabelecimentoId);
      await Future.delayed(Duration.zero);

      expect(newController.state.isLoading, false);
      expect(newController.state.cupons.length, 1);
      expect(newController.state.cupons.first.codigo, 'PROMO10');
    });

    test('Deve filtrar cupons pelo status "ativo" e "inativo"', () async {
      when(() => mockRepository.fetchCupons(estabelecimentoId))
          .thenAnswer((_) async => [
                cupomBase,
                cupomBase.copyWith(
                    id: 'cupom-2', codigo: 'INATIVO', ativo: false),
              ]);

      final newController = CuponsController(mockRepository, estabelecimentoId);
      await Future.delayed(Duration.zero);

      expect(newController.state.cupons.length, 2);

      newController.setFiltroStatus('ativo');
      expect(newController.state.filtrados.length, 1);
      expect(newController.state.filtrados.first.codigo, 'PROMO10');

      newController.setFiltroStatus('inativo');
      expect(newController.state.filtrados.length, 1);
      expect(newController.state.filtrados.first.codigo, 'INATIVO');
    });

    test('Deve filtrar cupons por pesquisa de texto', () async {
      when(() => mockRepository.fetchCupons(estabelecimentoId))
          .thenAnswer((_) async => [
                cupomBase,
                cupomBase.copyWith(
                    id: 'cupom-2',
                    codigo: 'NATAL20',
                    descricao: 'Promo especial de natal'),
              ]);

      final newController = CuponsController(mockRepository, estabelecimentoId);
      await Future.delayed(Duration.zero);

      newController.setPesquisa('natal');
      expect(newController.state.filtrados.length, 1);
      expect(newController.state.filtrados.first.codigo, 'NATAL20');
    });

    test('Deve criar cupom com sucesso e atualizar o state em memoria',
        () async {
      final novoCupomRequisicao =
          cupomBase.copyWith(id: 'cupom-novo', codigo: 'NOVO');

      when(() => mockRepository.criarCupom(any()))
          .thenAnswer((_) async => novoCupomRequisicao);

      final result = await controller.criarCupom(novoCupomRequisicao);

      expect(result, true);
      expect(controller.state.cupons.first.codigo, 'NOVO');
      expect(controller.state.isSaving, false);
      verify(() => mockRepository.criarCupom(any())).called(1);
    });

    test('Deve excluir cupom atualizar state (Remover item da lista)',
        () async {
      when(() => mockRepository.fetchCupons(estabelecimentoId))
          .thenAnswer((_) async => [cupomBase]);

      final newController = CuponsController(mockRepository, estabelecimentoId);
      await Future.delayed(Duration.zero);

      when(() => mockRepository.excluirCupom('cupom-1'))
          .thenAnswer((_) async {});

      await newController.excluirCupom('cupom-1');

      expect(newController.state.cupons.isEmpty, true);
      verify(() => mockRepository.excluirCupom('cupom-1')).called(1);
    });
  });
}
