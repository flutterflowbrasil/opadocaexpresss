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
  final List<String> categoriaPrincipalIds;
  final List<String> categoriaPrincipalNomes;
  final String? categoriaCardapioId;
  final String tipoProduto;
  final bool ativo;
  final int ordemExibicao;
  final String? slug;
  final int? pesoGramas;
  final bool permiteObservacao;

  // ── Última Mordida ──────────────────────────────────────────────────────
  final bool ultimaMordida;
  final DateTime? ultimaMordidaAtivadoEm;
  final DateTime? ultimaMordidaExpiraEm;
  final double? ultimaMordidaDescontoPct;
  final double? ultimaMordidaPreco;
  final String? ultimaMordidaChamada;
  final String? ultimaMordidaOrigem;

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
    this.categoriaPrincipalIds = const [],
    this.categoriaPrincipalNomes = const [],
    this.categoriaCardapioId,
    this.tipoProduto = 'simples',
    this.ativo = true,
    this.ordemExibicao = 0,
    this.slug,
    this.pesoGramas,
    this.permiteObservacao = true,
    this.categoriaCardapioNome,
    this.ultimaMordida = false,
    this.ultimaMordidaAtivadoEm,
    this.ultimaMordidaExpiraEm,
    this.ultimaMordidaDescontoPct,
    this.ultimaMordidaPreco,
    this.ultimaMordidaChamada,
    this.ultimaMordidaOrigem,
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
    List<String>? categoriaPrincipalIds,
    List<String>? categoriaPrincipalNomes,
    String? categoriaCardapioId,
    String? tipoProduto,
    bool? ativo,
    int? ordemExibicao,
    String? slug,
    int? pesoGramas,
    bool? permiteObservacao,
    String? categoriaCardapioNome,
    bool? ultimaMordida,
    DateTime? ultimaMordidaAtivadoEm,
    DateTime? ultimaMordidaExpiraEm,
    double? ultimaMordidaDescontoPct,
    double? ultimaMordidaPreco,
    String? ultimaMordidaChamada,
    String? ultimaMordidaOrigem,
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
      categoriaPrincipalIds:
          categoriaPrincipalIds ?? this.categoriaPrincipalIds,
      categoriaPrincipalNomes:
          categoriaPrincipalNomes ?? this.categoriaPrincipalNomes,
      categoriaCardapioId: categoriaCardapioId ?? this.categoriaCardapioId,
      tipoProduto: tipoProduto ?? this.tipoProduto,
      ativo: ativo ?? this.ativo,
      ordemExibicao: ordemExibicao ?? this.ordemExibicao,
      slug: slug ?? this.slug,
      pesoGramas: pesoGramas ?? this.pesoGramas,
      permiteObservacao: permiteObservacao ?? this.permiteObservacao,
      categoriaCardapioNome: categoriaCardapioNome ?? this.categoriaCardapioNome,
      ultimaMordida: ultimaMordida ?? this.ultimaMordida,
      ultimaMordidaAtivadoEm: ultimaMordidaAtivadoEm ?? this.ultimaMordidaAtivadoEm,
      ultimaMordidaExpiraEm: ultimaMordidaExpiraEm ?? this.ultimaMordidaExpiraEm,
      ultimaMordidaDescontoPct: ultimaMordidaDescontoPct ?? this.ultimaMordidaDescontoPct,
      ultimaMordidaPreco: ultimaMordidaPreco ?? this.ultimaMordidaPreco,
      ultimaMordidaChamada: ultimaMordidaChamada ?? this.ultimaMordidaChamada,
      ultimaMordidaOrigem: ultimaMordidaOrigem ?? this.ultimaMordidaOrigem,
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
      categoriaPrincipalIds:
          _parseCategoriasPrincipais(json, field: 'categoria_id'),
      categoriaPrincipalNomes: _parseCategoriasPrincipais(json, field: 'nome'),
      categoriaCardapioId: json['categoria_cardapio_id'] as String?,
      tipoProduto: json['tipo_produto'] as String? ?? 'simples',
      ativo: json['ativo'] as bool? ?? true,
      ordemExibicao: json['ordem_exibicao'] as int? ?? 0,
      slug: json['slug'] as String?,
      pesoGramas: json['peso_gramas'] as int?,
      permiteObservacao: json['permite_observacao'] as bool? ?? true,
      // Se houver um inner join no campo 'categorias_cardapio'
      categoriaCardapioNome: json['categorias_cardapio']?['nome'] as String?,
      ultimaMordida: json['ultima_mordida'] as bool? ?? false,
      ultimaMordidaAtivadoEm: json['ultima_mordida_ativado_em'] != null
          ? DateTime.tryParse(json['ultima_mordida_ativado_em'] as String)
          : null,
      ultimaMordidaExpiraEm: json['ultima_mordida_expira_em'] != null
          ? DateTime.tryParse(json['ultima_mordida_expira_em'] as String)
          : null,
      ultimaMordidaDescontoPct:
          (json['ultima_mordida_desconto_pct'] as num?)?.toDouble(),
      ultimaMordidaPreco: (json['ultima_mordida_preco'] as num?)?.toDouble(),
      ultimaMordidaChamada: json['ultima_mordida_chamada'] as String?,
      ultimaMordidaOrigem: json['ultima_mordida_origem'] as String?,
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
      'categoria_id': (categoriaId?.isEmpty ?? false) ? null : categoriaId,
      'categoria_cardapio_id': (categoriaCardapioId?.isEmpty ?? false) ? null : categoriaCardapioId,
      'tipo_produto': tipoProduto,
      'ativo': ativo,
      'ordem_exibicao': ordemExibicao,
      'slug': slug,
      'peso_gramas': pesoGramas,
      'permite_observacao': permiteObservacao,
    };
  }

  static List<String> _parseCategoriasPrincipais(
    Map<String, dynamic> json, {
    required String field,
  }) {
    final raw = json['produto_categorias_estabelecimento'];
    if (raw is! List) return const [];

    return raw
        .map((item) {
          if (item is! Map<String, dynamic>) return null;
          if (field == 'categoria_id') return item['categoria_id'] as String?;

          final categoria = item['categorias_estabelecimento'];
          if (categoria is Map<String, dynamic>) {
            return categoria['nome'] as String?;
          }
          return null;
        })
        .whereType<String>()
        .toList();
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


  /// Verifica se o produto permite a promocao Ultima Mordida.
  ///
  /// Bloqueado por CATEGORIA (Bebidas, Paes, Molhos, Combos) e tambem
  /// por NOME DO PRODUTO: produtos sem categoria tambem sao bloqueados.
  bool get permiteUltimaMordida {
    // 1. Verificacao por CATEGORIA
    final nomeCat = categoriaCardapioNome?.toLowerCase() ?? '';
    final nomesCatPrincipais =
        categoriaPrincipalNomes.map((n) => n.toLowerCase()).join(' ');

    const categoriasExcluidas = [
      'bebida', 'refrigerante', 'suco', 'agua', 'cafe',
      'energetico', 'cerveja', 'long neck', 'chopp', 'drink', 'coquetel',
      'pao', 'paes',
      'molho', 'adicional', 'extra', 'complemento',
      'doce', 'bala', 'chiclete', 'confeito',
      'gelo', 'talher', 'embalagem', 'descartavel',
      'combo', 'kit', 'marmita', 'prato', 'executivo',
      'porcao', 'compartilhavel', 'promoc', 'pedido',
    ];

    for (final excluido in categoriasExcluidas) {
      if (nomeCat.contains(excluido) || nomesCatPrincipais.contains(excluido)) {
        return false;
      }
    }

    // 2. Verificacao por NOME DO PRODUTO
    final nomeProd = nome.toLowerCase();

    const termosBebidas = [
      'coca', 'pepsi', 'guarana', 'sprite', 'fanta', 'suco', 'agua',
      'energetico', 'red bull', 'monster', 'cerveja', 'chopp', 'heineken',
      'brahma', 'skol', 'itaipava', 'caipirinha', 'drink', 'coquetel',
      'limonada', 'milkshake', 'shake', 'vitamina', 'cafe', 'cappuccino',
      'espresso', 'smoothie', 'isotonico', 'refrigerante', '350ml', '600ml',
    ];

    const termosPaes = [
      'pao', 'paes', 'baguete', 'ciabatta', 'bisnaguinha', 'croissant',
      'torrada', 'broa', 'paozinho',
    ];

    for (final t in termosBebidas) {
      if (nomeProd.contains(t)) return false;
    }
    for (final t in termosPaes) {
      if (nomeProd.contains(t)) return false;
    }

    return true;
  }

  /// Verifica se a categoria do produto permite adicionar observações.
  /// Remove categorias industriais, molhos, pães, etc.
  bool get aceitaObservacaoCategoria {
    if (!permiteObservacao) return false;
    
    final nomeCat = categoriaCardapioNome?.toLowerCase() ?? '';
    
    // Categorias que NÃO devem aceitar observações no carrinho
    final List<String> categoriasExcluidas = [
      'bebida', 'refrigerante', 'suco', 'água', 'agua', 'energético', 'energetico', 'cerveja', 'long neck',
      'molho', 'adicional', 'ketchup', 'maionese',
      'bala', 'chocolate', 'doce', 'embalado', 'pronto',
      'pão', 'pao', 'pães', 'paes',
    ];

    for (final excluido in categoriasExcluidas) {
      if (nomeCat.contains(excluido)) {
        return false;
      }
    }

    return true;
  }
}
