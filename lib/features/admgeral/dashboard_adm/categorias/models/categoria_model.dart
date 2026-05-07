class CategoriaModel {
  final String id;
  final String nome;
  final String slug;
  final String? icone;
  final bool ativa;
  final int ordemExibicao;
  final String? imagemUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CategoriaModel({
    required this.id,
    required this.nome,
    required this.slug,
    this.icone,
    this.ativa = true,
    this.ordemExibicao = 0,
    this.imagemUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory CategoriaModel.fromJson(Map<String, dynamic> json) {
    return CategoriaModel(
      id: json['id'] as String,
      nome: json['nome'] as String,
      slug: json['slug'] as String,
      icone: json['icone'] as String?,
      ativa: json['ativa'] as bool? ?? true,
      ordemExibicao: json['ordem_exibicao'] as int? ?? 0,
      imagemUrl: json['imagem_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'slug': slug,
      'icone': icone,
      'ativa': ativa,
      'ordem_exibicao': ordemExibicao,
      'imagem_url': imagemUrl,
    };
  }

  CategoriaModel copyWith({
    String? id,
    String? nome,
    String? slug,
    String? icone,
    bool? ativa,
    int? ordemExibicao,
    String? imagemUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoriaModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      slug: slug ?? this.slug,
      icone: icone ?? this.icone,
      ativa: ativa ?? this.ativa,
      ordemExibicao: ordemExibicao ?? this.ordemExibicao,
      imagemUrl: imagemUrl ?? this.imagemUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
