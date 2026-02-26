import 'package:padoca_express/features/estabelecimento/models/produto_model.dart';

class ItemCarrinhoModel {
  final ProdutoModel produto;
  final int quantidade;
  final String? observacao;

  ItemCarrinhoModel({
    required this.produto,
    required this.quantidade,
    this.observacao,
  });

  ItemCarrinhoModel copyWith({
    ProdutoModel? produto,
    int? quantidade,
    String? observacao,
  }) {
    return ItemCarrinhoModel(
      produto: produto ?? this.produto,
      quantidade: quantidade ?? this.quantidade,
      observacao: observacao ?? this.observacao,
    );
  }

  double get subtotal => produto.precoAtual * quantidade;

  factory ItemCarrinhoModel.fromJson(Map<String, dynamic> json) {
    return ItemCarrinhoModel(
      produto: ProdutoModel.fromJson(json['produto'] as Map<String, dynamic>),
      quantidade: json['quantidade'] as int,
      observacao: json['observacao'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'produto': produto.toJson(),
      'quantidade': quantidade,
      'observacao': observacao,
    };
  }
}
