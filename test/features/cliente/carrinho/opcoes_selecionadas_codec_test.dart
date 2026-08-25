import 'package:flutter_test/flutter_test.dart';
import 'package:padoca_express/features/cliente/carrinho/opcoes_selecionadas_codec.dart';
import 'package:padoca_express/features/estabelecimento/models/produto_opcao_model.dart';

void main() {
  final bacon = ProdutoOpcaoItemModel(
    id: 'item-bacon',
    nome: 'Bacon',
    precoAdicional: 4.5,
  );
  final cheddar = ProdutoOpcaoItemModel(
    id: 'item-cheddar',
    nome: 'Cheddar',
    precoAdicional: 3,
  );
  final grupo = ProdutoOpcaoModel(
    id: 'grupo-extras',
    nome: 'Adicionais',
    tipo: 'multipla',
    obrigatorio: false,
    minimo: 0,
    maximo: 3,
    itens: [bacon, cheddar],
  );

  test('serializa id/nome canônicos e chaves legadas', () {
    final json = OpcoesSelecionadasCodec.grupoToJson(grupo, [bacon]);
    expect(json['id'], 'grupo-extras');
    expect(json['nome'], 'Adicionais');
    expect(json['grupo_id'], 'grupo-extras');
    expect(json['grupo_nome'], 'Adicionais');
    final item = (json['itens'] as List).first as Map;
    expect(item['id'], 'item-bacon');
    expect(item['item_id'], 'item-bacon');
    expect(item['nome'], 'Bacon');
    expect(item['preco'], 4.5);
  });

  test('fromSelecoes omite grupos vazios', () {
    final result = OpcoesSelecionadasCodec.fromSelecoes(
      grupos: [grupo],
      selecoes: {'grupo-extras': []},
      grupoKey: (g) => g.id ?? g.nome,
    );
    expect(result, isEmpty);
  });

  test('somaAdicionais e precoUnitarioComAdicionais', () {
    final opcoes = OpcoesSelecionadasCodec.fromSelecoes(
      grupos: [grupo],
      selecoes: {
        'grupo-extras': [bacon, cheddar],
      },
      grupoKey: (g) => g.id ?? g.nome,
    );
    expect(OpcoesSelecionadasCodec.somaAdicionais(opcoes), 7.5);
    expect(
      precoUnitarioComAdicionais(
        precoBase: 22,
        opcoesSelecionadas: opcoes,
      ),
      29.5,
    );
  });

  test('nomeGrupo aceita formato novo e legado', () {
    expect(OpcoesSelecionadasCodec.nomeGrupo({'nome': 'Molhos'}), 'Molhos');
    expect(
      OpcoesSelecionadasCodec.nomeGrupo({'grupo_nome': 'Extras'}),
      'Extras',
    );
  });
}
