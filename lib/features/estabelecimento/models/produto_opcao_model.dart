class ProdutoOpcaoItemModel {
  final String nome;
  final double? precoAdicional;

  ProdutoOpcaoItemModel({
    required this.nome,
    this.precoAdicional,
  });

  factory ProdutoOpcaoItemModel.fromJson(Map<String, dynamic> json) {
    return ProdutoOpcaoItemModel(
      nome: json['nome'] as String,
      precoAdicional: json['preco_adicional'] != null
          ? (json['preco_adicional'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'preco_adicional': precoAdicional,
    };
  }
}

class ProdutoOpcaoModel {
  final String nome;
  final bool obrigatorio;
  final int minimo;
  final int maximo;
  final List<ProdutoOpcaoItemModel> itens;

  ProdutoOpcaoModel({
    required this.nome,
    required this.obrigatorio,
    required this.minimo,
    required this.maximo,
    required this.itens,
  });

  factory ProdutoOpcaoModel.fromJson(Map<String, dynamic> json) {
    var itensList = json['itens'] as List? ?? [];
    return ProdutoOpcaoModel(
      nome: json['nome'] as String,
      obrigatorio: json['obrigatorio'] as bool? ?? false,
      minimo: json['minimo'] as int? ?? 0,
      maximo: json['maximo'] as int? ?? 1,
      itens: itensList
          .map((i) => ProdutoOpcaoItemModel.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'obrigatorio': obrigatorio,
      'minimo': minimo,
      'maximo': maximo,
      'itens': itens.map((i) => i.toJson()).toList(),
    };
  }
}
