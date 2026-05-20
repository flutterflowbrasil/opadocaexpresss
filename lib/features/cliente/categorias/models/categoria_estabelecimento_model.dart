class CategoriaEstabelecimentoModel {
  final String id;
  final String nome;
  final String? icone;
  final bool ativa;
  final String? imagemUrl;
  final String slug;
  final int ordemExibicao;

  /// Se true, produtos desta categoria podem ter adicionais/opções configurados.
  final bool permiteAdicionais;

  /// Se true, produtos desta categoria podem ter múltiplos preços (tamanhos).
  /// Atualmente exclusivo para Pizza.
  final bool permiteMultiplosPrecos;

  const CategoriaEstabelecimentoModel({
    required this.id,
    required this.nome,
    this.icone,
    required this.ativa,
    this.imagemUrl,
    required this.slug,
    required this.ordemExibicao,
    this.permiteAdicionais = false,
    this.permiteMultiplosPrecos = false,
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
      permiteAdicionais: (json['permite_adicionais'] as bool?) ?? false,
      permiteMultiplosPrecos: (json['permite_multiplos_precos'] as bool?) ?? false,
    );
  }
}
