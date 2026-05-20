class CategoriaCardapioModel {
  final String id;
  final String estabelecimentoId;
  final String nome;
  final String? descricao;
  final int ordemExibicao;
  final bool ativa;

  /// ID da categoria pai. Null = categoria raiz (top-level).
  final String? categoriaPaiId;

  /// Subcategorias filhas — populadas em memória após o fetch (não vêm do DB diretamente).
  final List<CategoriaCardapioModel> subcategorias;

  CategoriaCardapioModel({
    required this.id,
    required this.estabelecimentoId,
    required this.nome,
    this.descricao,
    required this.ordemExibicao,
    required this.ativa,
    this.categoriaPaiId,
    this.subcategorias = const [],
  });

  bool get isSubcategoria => categoriaPaiId != null;

  factory CategoriaCardapioModel.fromJson(Map<String, dynamic> json) {
    return CategoriaCardapioModel(
      id: json['id'] as String,
      estabelecimentoId: json['estabelecimento_id'] as String,
      nome: json['nome'] as String,
      descricao: json['descricao'] as String?,
      ordemExibicao: json['ordem_exibicao'] ?? 0,
      ativa: json['ativa'] ?? true,
      categoriaPaiId: json['categoria_pai_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'estabelecimento_id': estabelecimentoId,
      'nome': nome,
      'descricao': descricao,
      'ordem_exibicao': ordemExibicao,
      'ativa': ativa,
      'categoria_pai_id': categoriaPaiId,
    };
  }

  CategoriaCardapioModel copyWith({
    String? id,
    String? estabelecimentoId,
    String? nome,
    String? descricao,
    int? ordemExibicao,
    bool? ativa,
    String? categoriaPaiId,
    List<CategoriaCardapioModel>? subcategorias,
  }) {
    return CategoriaCardapioModel(
      id: id ?? this.id,
      estabelecimentoId: estabelecimentoId ?? this.estabelecimentoId,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      ordemExibicao: ordemExibicao ?? this.ordemExibicao,
      ativa: ativa ?? this.ativa,
      categoriaPaiId: categoriaPaiId ?? this.categoriaPaiId,
      subcategorias: subcategorias ?? this.subcategorias,
    );
  }
}
