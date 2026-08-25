import 'package:padoca_express/features/estabelecimento/models/produto_opcao_model.dart';

/// Contrato canônico de `itens_carrinho.opcoes_selecionadas`.
///
/// Servidor (`fn_preco_unitario_produto`) casa grupo/item por `id`/`nome`.
/// Chaves `grupo_id`/`grupo_nome`/`item_id` são mantidas para exibição e
/// carrinhos antigos.
class OpcoesSelecionadasCodec {
  static Map<String, dynamic> grupoToJson(
    ProdutoOpcaoModel grupo,
    List<ProdutoOpcaoItemModel> itens,
  ) {
    return {
      'id': grupo.id ?? grupo.nome,
      'nome': grupo.nome,
      'grupo_id': grupo.id ?? grupo.nome,
      'grupo_nome': grupo.nome,
      'tipo': grupo.tipo,
      'itens': itens.map(itemToJson).toList(),
    };
  }

  static Map<String, dynamic> itemToJson(ProdutoOpcaoItemModel item) {
    return {
      'id': item.id ?? item.nome,
      'item_id': item.id ?? item.nome,
      'nome': item.nome,
      'preco': item.precoAdicional ?? 0,
    };
  }

  static List<Map<String, dynamic>> fromSelecoes({
    required List<ProdutoOpcaoModel> grupos,
    required Map<String, List<ProdutoOpcaoItemModel>> selecoes,
    required String Function(ProdutoOpcaoModel grupo) grupoKey,
  }) {
    final result = <Map<String, dynamic>>[];
    for (final grupo in grupos) {
      final itens = selecoes[grupoKey(grupo)] ?? const [];
      if (itens.isEmpty) continue;
      result.add(grupoToJson(grupo, itens));
    }
    return result;
  }

  static double somaAdicionais(List<Map<String, dynamic>> opcoes) {
    var total = 0.0;
    for (final grupo in opcoes) {
      final itens = grupo['itens'];
      if (itens is! List) continue;
      for (final raw in itens) {
        if (raw is! Map) continue;
        total += (raw['preco'] as num?)?.toDouble() ?? 0;
      }
    }
    return total;
  }

  static String nomeGrupo(Map<String, dynamic> grupo) {
    final nome = grupo['nome']?.toString().trim() ?? '';
    if (nome.isNotEmpty) return nome;
    final legado = grupo['grupo_nome']?.toString().trim() ?? '';
    if (legado.isNotEmpty) return legado;
    return 'Opções';
  }
}

double precoUnitarioComAdicionais({
  required double precoBase,
  required List<Map<String, dynamic>> opcoesSelecionadas,
}) {
  return precoBase + OpcoesSelecionadasCodec.somaAdicionais(opcoesSelecionadas);
}
