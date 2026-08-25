import 'package:flutter_test/flutter_test.dart';
import 'package:padoca_express/features/cliente/carrinho/opcoes_selecionadas_codec.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/produtos/models/produto_model.dart'
    as admin;
import 'package:padoca_express/features/estabelecimento/dashboard/produtos/models/produto_preco_tamanho_model.dart';
import 'package:padoca_express/features/estabelecimento/models/produto_model.dart';
import 'package:padoca_express/features/estabelecimento/models/produto_opcao_model.dart';

void main() {
  test('pizza: preço unitário = tamanho + adicionais', () {
    final opcoes = [
      OpcoesSelecionadasCodec.grupoToJson(
        ProdutoOpcaoModel(
          id: 'borda',
          nome: 'Borda',
          tipo: 'unica',
          obrigatorio: false,
          minimo: 0,
          maximo: 1,
          itens: [
            ProdutoOpcaoItemModel(
              id: 'catupiry',
              nome: 'Catupiry',
              precoAdicional: 8,
            ),
          ],
        ),
        [
          ProdutoOpcaoItemModel(
            id: 'catupiry',
            nome: 'Catupiry',
            precoAdicional: 8,
          ),
        ],
      ),
    ];
    expect(
      precoUnitarioComAdicionais(precoBase: 42, opcoesSelecionadas: opcoes),
      50,
    );
  });

  test('hambúrguer/esfirra: preço unitário = base + adicionais', () {
    final opcoes = [
      {
        'id': 'extras',
        'nome': 'Extras',
        'itens': [
          {'id': 'bacon', 'nome': 'Bacon', 'preco': 4.5},
          {'id': 'ovo', 'nome': 'Ovo', 'preco': 2.5},
        ],
      }
    ];
    expect(
      precoUnitarioComAdicionais(
        precoBase: 18,
        opcoesSelecionadas: opcoes.cast<Map<String, dynamic>>(),
      ),
      25,
    );
  });

  test('cliente ProdutoModel.precoMinimo usa menor tamanho ativo', () {
    final produto = ProdutoModel(
      id: 'pizza-1',
      estabelecimentoId: 'e1',
      nome: 'Pizza calabresa',
      preco: 0,
      isAtivo: true,
      permiteObservacoes: true,
      precosTamanhos: const [
        ProdutoPrecoTamanhoModel(
          id: 'p',
          produtoId: 'pizza-1',
          nomeTamanho: 'P',
          preco: 32,
        ),
        ProdutoPrecoTamanhoModel(
          id: 'g',
          produtoId: 'pizza-1',
          nomeTamanho: 'G',
          preco: 52,
        ),
      ],
    );
    expect(produto.temVariacoesDePreco, isTrue);
    expect(produto.precoMinimo, 32);
  });

  test('admin ProdutoModel.precoMinimo ignora tamanho inativo', () {
    final produto = admin.ProdutoModel(
      id: 'pizza-1',
      estabelecimentoId: 'e1',
      nome: 'Pizza calabresa',
      preco: 0,
      precosTamanhos: const [
        ProdutoPrecoTamanhoModel(
          id: 'p',
          produtoId: 'pizza-1',
          nomeTamanho: 'P',
          preco: 32,
        ),
        ProdutoPrecoTamanhoModel(
          id: 'm',
          produtoId: 'pizza-1',
          nomeTamanho: 'M',
          preco: 0,
          ativo: false,
        ),
      ],
    );
    expect(produto.temVariacoesDePreco, isTrue);
    expect(produto.precoMinimo, 32);
  });
}
