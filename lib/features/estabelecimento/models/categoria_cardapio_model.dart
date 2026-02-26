class CategoriaCardapioModel {
  final String id;
  final String estabelecimentoId;
  final String nome;
  final String? descricao;
  final int ordemExibicao;
  final bool ativa;

  CategoriaCardapioModel({
    required this.id,
    required this.estabelecimentoId,
    required this.nome,
    this.descricao,
    required this.ordemExibicao,
    required this.ativa,
  });

  factory CategoriaCardapioModel.fromJson(Map<String, dynamic> json) {
    return CategoriaCardapioModel(
      id: json['id'] as String,
      estabelecimentoId: json['estabelecimento_id'] as String,
      nome: json['nome'] as String,
      descricao: json['descricao'] as String?,
      ordemExibicao: json['ordem_exibicao'] ?? 0,
      ativa: json['ativa'] ?? true,
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
    };
  }
}
