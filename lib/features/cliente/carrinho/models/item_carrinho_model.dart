import 'package:padoca_express/features/estabelecimento/models/produto_model.dart';

class ItemCarrinhoModel {
  final String? id;
  final ProdutoModel produto;
  final int quantidade;
  final double precoBaseProduto;
  final double precoUnitario;
  final List<Map<String, dynamic>> opcoesSelecionadas;
  final String? observacao;

  ItemCarrinhoModel({
    this.id,
    required this.produto,
    required this.quantidade,
    double? precoBaseProduto,
    double? precoUnitario,
    List<Map<String, dynamic>>? opcoesSelecionadas,
    this.observacao,
  })  : precoBaseProduto = precoBaseProduto ?? produto.precoAtual,
        precoUnitario = precoUnitario ?? produto.precoAtual,
        opcoesSelecionadas = opcoesSelecionadas ?? const [];

  ItemCarrinhoModel copyWith({
    String? id,
    ProdutoModel? produto,
    int? quantidade,
    double? precoBaseProduto,
    double? precoUnitario,
    List<Map<String, dynamic>>? opcoesSelecionadas,
    String? observacao,
    bool clearObservacao = false,
  }) {
    return ItemCarrinhoModel(
      id: id ?? this.id,
      produto: produto ?? this.produto,
      quantidade: quantidade ?? this.quantidade,
      precoBaseProduto: precoBaseProduto ?? this.precoBaseProduto,
      precoUnitario: precoUnitario ?? this.precoUnitario,
      opcoesSelecionadas: opcoesSelecionadas ?? this.opcoesSelecionadas,
      observacao: clearObservacao ? null : (observacao ?? this.observacao),
    );
  }

  double get subtotal => precoUnitario * quantidade;

  bool get temOpcoesSelecionadas => opcoesSelecionadas.any((grupo) {
        final itens = grupo['itens'];
        return itens is List && itens.isNotEmpty;
      });

  factory ItemCarrinhoModel.fromJson(Map<String, dynamic> json) {
    final produtoJson = json['produto'] ?? json['produtos'];
    final produto = ProdutoModel.fromJson(produtoJson as Map<String, dynamic>);
    final opcoes = (json['opcoes_selecionadas'] as List? ?? [])
        .whereType<Map>()
        .map((opcao) => Map<String, dynamic>.from(opcao))
        .toList();

    return ItemCarrinhoModel(
      id: json['id'] as String?,
      produto: produto,
      quantidade: (json['quantidade'] as num?)?.toInt() ?? 1,
      precoBaseProduto: (json['preco_base_produto'] as num?)?.toDouble() ??
          produto.precoAtual,
      precoUnitario:
          (json['preco_unitario'] as num?)?.toDouble() ?? produto.precoAtual,
      opcoesSelecionadas: opcoes,
      observacao: json['observacao'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'produto': produto.toJson(),
      'quantidade': quantidade,
      'preco_base_produto': precoBaseProduto,
      'preco_unitario': precoUnitario,
      'opcoes_selecionadas': opcoesSelecionadas,
      'observacao': observacao,
    };
  }

  Map<String, dynamic> toPedidoSnapshot() {
    return {
      'produto_id': produto.id,
      'nome_produto': produto.nome,
      'produto_nome': produto.nome,
      'quantidade': quantidade,
      'preco_base_produto': precoBaseProduto,
      'preco_unitario_final': precoUnitario,
      'preco_unitario': precoUnitario,
      'opcoes_selecionadas': opcoesSelecionadas,
      if (observacao != null && observacao!.isNotEmpty)
        'observacao': observacao,
      'subtotal': subtotal,
    };
  }
}
