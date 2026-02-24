class ResultadoBuscaModel {
  final String id;
  final String nome;
  final String? descricao;
  final String? logoUrl;
  final String? bannerUrl;
  final double avaliacaoMedia;
  final bool statusAberto;
  final Map<String, dynamic>? configEntrega;
  final Map<String, dynamic>? endereco;
  final String? categoriaNome;
  final int relevancia;

  const ResultadoBuscaModel({
    required this.id,
    required this.nome,
    this.descricao,
    this.logoUrl,
    this.bannerUrl,
    required this.avaliacaoMedia,
    required this.statusAberto,
    this.configEntrega,
    this.endereco,
    this.categoriaNome,
    required this.relevancia,
  });

  factory ResultadoBuscaModel.fromJson(Map<String, dynamic> json) {
    return ResultadoBuscaModel(
      id: json['id'] as String,
      nome: (json['razao_social'] as String?) ?? '',
      descricao: json['descricao'] as String?,
      logoUrl: json['logo_url'] as String?,
      bannerUrl: json['banner_url'] as String?,
      avaliacaoMedia: (json['avaliacao_media'] as num?)?.toDouble() ?? 5.0,
      statusAberto: (json['status_aberto'] as bool?) ?? false,
      configEntrega: json['config_entrega'] as Map<String, dynamic>?,
      endereco: json['endereco'] as Map<String, dynamic>?,
      categoriaNome: json['categoria_nome'] as String?,
      relevancia: (json['relevancia'] as int?) ?? 1,
    );
  }

  String get bairro {
    if (endereco == null) return '';
    return (endereco!['bairro'] as String?) ?? '';
  }

  String get cidade {
    if (endereco == null) return '';
    return (endereco!['cidade'] as String?) ?? '';
  }

  String get taxaEntregaFormatada {
    if (configEntrega == null) return '';
    final taxa = configEntrega!['taxa_entrega_fixa'];
    if (taxa == null) return '';
    final taxaNum = (taxa as num).toDouble();
    if (taxaNum == 0) return 'Grátis';
    return 'R\$ ${taxaNum.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String get tempoMedioFormatado {
    if (configEntrega == null) return '30-45 min';
    final minMin = configEntrega!['tempo_minimo_entrega_min'] ??
        configEntrega!['tempo_medio_preparo_min'] ??
        20;
    final maxMin =
        configEntrega!['tempo_maximo_entrega_min'] ?? (minMin as num) + 15;
    return '$minMin-$maxMin min';
  }
}
