class CategoriaEstabelecimentoModel {
  final String id;
  final String nome;
  final String? icone;
  final bool ativa;
  final String? imagemUrl;
  final String slug;
  final int ordemExibicao;

  const CategoriaEstabelecimentoModel({
    required this.id,
    required this.nome,
    this.icone,
    required this.ativa,
    this.imagemUrl,
    required this.slug,
    required this.ordemExibicao,
  });

  factory CategoriaEstabelecimentoModel.fromJson(Map<String, dynamic> json) {
    return CategoriaEstabelecimentoModel(
      id: json['id'] as String,
      nome: json['nome'] as String,
      icone: json['icone'] as String?,
      ativa: (json['ativa'] as bool?) ?? true,
      imagemUrl: json['imagem_url'] as String?,
      slug: json['slug'] as String,
      ordemExibicao: (json['ordem_exibicao'] as int?) ?? 0,
    );
  }
}
