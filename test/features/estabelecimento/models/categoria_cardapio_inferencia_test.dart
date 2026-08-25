import 'package:flutter_test/flutter_test.dart';
import 'package:padoca_express/features/cliente/categorias/models/categoria_estabelecimento_model.dart';
import 'package:padoca_express/features/estabelecimento/models/categoria_cardapio_inferencia.dart';
import 'package:padoca_express/features/estabelecimento/models/categoria_cardapio_model.dart';

void main() {
  const estId = 'est-1';

  final cardapio = [
    CategoriaCardapioModel(
      id: 'cc-paes',
      estabelecimentoId: estId,
      nome: 'Pães',
      ordemExibicao: 1,
      ativa: true,
    ),
    CategoriaCardapioModel(
      id: 'cc-lanches',
      estabelecimentoId: estId,
      nome: 'Lanches',
      ordemExibicao: 2,
      ativa: true,
    ),
    CategoriaCardapioModel(
      id: 'cc-salgados',
      estabelecimentoId: estId,
      nome: 'Salgados',
      ordemExibicao: 3,
      ativa: true,
    ),
  ];

  final pizza = CategoriaEstabelecimentoModel(
    id: 'cp-pizza',
    nome: 'Pizza',
    slug: 'pizza',
    ordemExibicao: 1,
    ativa: true,
    permiteAdicionais: true,
    permiteMultiplosPrecos: true,
  );

  final lanches = CategoriaEstabelecimentoModel(
    id: 'cp-lanches',
    nome: 'Lanches',
    slug: 'lanches',
    ordemExibicao: 2,
    ativa: true,
    permiteAdicionais: true,
  );

  test('mapeia slug pizza para Salgados no cardápio', () {
    expect(
      CategoriaCardapioInferencia.inferirId(
        categoriaPrincipalIds: [pizza.id],
        principais: [pizza],
        cardapio: cardapio,
      ),
      'cc-salgados',
    );
  });

  test('mapeia slug lanches para Lanches no cardápio', () {
    expect(
      CategoriaCardapioInferencia.inferirId(
        categoriaPrincipalIds: [lanches.id],
        principais: [lanches],
        cardapio: cardapio,
      ),
      'cc-lanches',
    );
  });

  test('retorna null sem categoria principal', () {
    expect(
      CategoriaCardapioInferencia.inferirId(
        categoriaPrincipalIds: [],
        principais: [pizza],
        cardapio: cardapio,
      ),
      isNull,
    );
  });
}
