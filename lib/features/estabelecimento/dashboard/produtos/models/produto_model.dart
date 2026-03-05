class ProdutoModel {
  final String id;
  final String estabelecimentoId;
  final String nome;
  final String? descricao;
  final double preco;
  final double? precoPromocional;
  final double? custoEstimado;
  final String? fotoPrincipalUrl;
  final List<String> fotosAdicionais;
  final bool disponivel;
  final bool destaque;
  final List<dynamic>
      opcoes; // Pode ser mapeado como List<OpcaoProdutoModel> no futuro
  final bool controleEstoque;
  final int? quantidadeEstoque;
  final int tempoPreparoAdicionalMin;
  final int totalVendidos;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? categoriaId;
  final String? categoriaCardapioId;
  final String tipoProduto;
  final bool ativo;
  final int ordemExibicao;
  final String? slug;
  final int? pesoGramas;
  final bool permiteObservacao;

  // Campo auxiliar para uso dinâmico em listagens
  final String? categoriaCardapioNome;

  const ProdutoModel({
    required this.id,
    required this.estabelecimentoId,
    required this.nome,
    this.descricao,
    required this.preco,
    this.precoPromocional,
    this.custoEstimado,
    this.fotoPrincipalUrl,
    this.fotosAdicionais = const [],
    this.disponivel = true,
    this.destaque = false,
    this.opcoes = const [],
    this.controleEstoque = false,
    this.quantidadeEstoque,
    this.tempoPreparoAdicionalMin = 0,
    this.totalVendidos = 0,
    this.createdAt,
    this.updatedAt,
    this.categoriaId,
    this.categoriaCardapioId,
    this.tipoProduto = 'simples',
    this.ativo = true,
    this.ordemExibicao = 0,
    this.slug,
    this.pesoGramas,
    this.permiteObservacao = true,
    this.categoriaCardapioNome,
  });

  ProdutoModel copyWith({
    String? id,
    String? estabelecimentoId,
    String? nome,
    String? descricao,
    double? preco,
    double? precoPromocional,
    double? custoEstimado,
    String? fotoPrincipalUrl,
    List<String>? fotosAdicionais,
    bool? disponivel,
    bool? destaque,
    List<dynamic>? opcoes,
    bool? controleEstoque,
    int? quantidadeEstoque,
    int? tempoPreparoAdicionalMin,
    int? totalVendidos,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoriaId,
    String? categoriaCardapioId,
    String? tipoProduto,
    bool? ativo,
    int? ordemExibicao,
    String? slug,
    int? pesoGramas,
    bool? permiteObservacao,
    String? categoriaCardapioNome,
  }) {
    return ProdutoModel(
      id: id ?? this.id,
      estabelecimentoId: estabelecimentoId ?? this.estabelecimentoId,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      preco: preco ?? this.preco,
      precoPromocional: precoPromocional ?? this.precoPromocional,
      custoEstimado: custoEstimado ?? this.custoEstimado,
      fotoPrincipalUrl: fotoPrincipalUrl ?? this.fotoPrincipalUrl,
      fotosAdicionais: fotosAdicionais ?? this.fotosAdicionais,
      disponivel: disponivel ?? this.disponivel,
      destaque: destaque ?? this.destaque,
      opcoes: opcoes ?? this.opcoes,
      controleEstoque: controleEstoque ?? this.controleEstoque,
      quantidadeEstoque: quantidadeEstoque ?? this.quantidadeEstoque,
      tempoPreparoAdicionalMin:
          tempoPreparoAdicionalMin ?? this.tempoPreparoAdicionalMin,
      totalVendidos: totalVendidos ?? this.totalVendidos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoriaId: categoriaId ?? this.categoriaId,
      categoriaCardapioId: categoriaCardapioId ?? this.categoriaCardapioId,
      tipoProduto: tipoProduto ?? this.tipoProduto,
      ativo: ativo ?? this.ativo,
      ordemExibicao: ordemExibicao ?? this.ordemExibicao,
      slug: slug ?? this.slug,
      pesoGramas: pesoGramas ?? this.pesoGramas,
      permiteObservacao: permiteObservacao ?? this.permiteObservacao,
      categoriaCardapioNome:
          categoriaCardapioNome ?? this.categoriaCardapioNome,
    );
  }

  factory ProdutoModel.fromJson(Map<String, dynamic> json) {
    return ProdutoModel(
      id: json['id'] as String,
      estabelecimentoId: json['estabelecimento_id'] as String,
      nome: json['nome'] as String,
      descricao: json['descricao'] as String?,
      preco: (json['preco'] as num).toDouble(),
      precoPromocional: (json['preco_promocional'] as num?)?.toDouble(),
      custoEstimado: (json['custo_estimado'] as num?)?.toDouble(),
      fotoPrincipalUrl: json['foto_principal_url'] as String?,
      fotosAdicionais: (json['fotos_adicionais'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      disponivel: json['disponivel'] as bool? ?? true,
      destaque: json['destaque'] as bool? ?? false,
      opcoes: json['opcoes'] as List<dynamic>? ?? [],
      controleEstoque: json['controle_estoque'] as bool? ?? false,
      quantidadeEstoque: json['quantidade_estoque'] as int?,
      tempoPreparoAdicionalMin:
          json['tempo_preparo_adicional_min'] as int? ?? 0,
      totalVendidos: json['total_vendidos'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      categoriaId: json['categoria_id'] as String?,
      categoriaCardapioId: json['categoria_cardapio_id'] as String?,
      tipoProduto: json['tipo_produto'] as String? ?? 'simples',
      ativo: json['ativo'] as bool? ?? true,
      ordemExibicao: json['ordem_exibicao'] as int? ?? 0,
      slug: json['slug'] as String?,
      pesoGramas: json['peso_gramas'] as int?,
      permiteObservacao: json['permite_observacao'] as bool? ?? true,
      // Se houver um inner join no campo 'categorias_cardapio'
      categoriaCardapioNome: json['categorias_cardapio']?['nome'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'estabelecimento_id': estabelecimentoId,
      'nome': nome,
      'descricao': descricao,
      'preco': preco,
      'preco_promocional': precoPromocional,
      'custo_estimado': custoEstimado,
      'foto_principal_url': fotoPrincipalUrl,
      'fotos_adicionais': fotosAdicionais,
      'disponivel': disponivel,
      'destaque': destaque,
      'opcoes': opcoes,
      'controle_estoque': controleEstoque,
      'quantidade_estoque': quantidadeEstoque,
      'tempo_preparo_adicional_min': tempoPreparoAdicionalMin,
      'total_vendidos': totalVendidos,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'categoria_id': categoriaId,
      'categoria_cardapio_id': categoriaCardapioId,
      'tipo_produto': tipoProduto,
      'ativo': ativo,
      'ordem_exibicao': ordemExibicao,
      'slug': slug,
      'peso_gramas': pesoGramas,
      'permite_observacao': permiteObservacao,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProdutoModel &&
        other.id == id &&
        other.estabelecimentoId == estabelecimentoId &&
        other.nome == nome &&
        other.preco == preco &&
        other.ativo == ativo &&
        other.disponivel == disponivel &&
        other.destaque == destaque &&
        other.categoriaCardapioId == categoriaCardapioId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        estabelecimentoId.hashCode ^
        nome.hashCode ^
        preco.hashCode ^
        ativo.hashCode ^
        disponivel.hashCode ^
        destaque.hashCode ^
        categoriaCardapioId.hashCode;
  }
}
