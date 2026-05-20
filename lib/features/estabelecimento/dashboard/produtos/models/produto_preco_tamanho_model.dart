// ============================================================
// produto_preco_tamanho_model.dart
// Modelo para tamanhos/preços de pizza (produto_precos_tamanhos)
// ============================================================

class ProdutoPrecoTamanhoModel {
  final String id;
  final String produtoId;
  final String nomeTamanho;
  final double preco;
  final int ordem;
  final bool ativo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProdutoPrecoTamanhoModel({
    required this.id,
    required this.produtoId,
    required this.nomeTamanho,
    required this.preco,
    this.ordem = 0,
    this.ativo = true,
    this.createdAt,
    this.updatedAt,
  });

  factory ProdutoPrecoTamanhoModel.fromJson(Map<String, dynamic> json) {
    return ProdutoPrecoTamanhoModel(
      id: json['id'] as String,
      produtoId: json['produto_id'] as String,
      nomeTamanho: json['nome_tamanho'] as String,
      preco: (json['preco'] as num).toDouble(),
      ordem: (json['ordem'] as int?) ?? 0,
      ativo: (json['ativo'] as bool?) ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'produto_id': produtoId,
      'nome_tamanho': nomeTamanho,
      'preco': preco,
      'ordem': ordem,
      'ativo': ativo,
    };
    if (id.isNotEmpty) map['id'] = id;
    return map;
  }

  ProdutoPrecoTamanhoModel copyWith({
    String? id,
    String? produtoId,
    String? nomeTamanho,
    double? preco,
    int? ordem,
    bool? ativo,
  }) {
    return ProdutoPrecoTamanhoModel(
      id: id ?? this.id,
      produtoId: produtoId ?? this.produtoId,
      nomeTamanho: nomeTamanho ?? this.nomeTamanho,
      preco: preco ?? this.preco,
      ordem: ordem ?? this.ordem,
      ativo: ativo ?? this.ativo,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ProdutoPrecoTamanhoModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
