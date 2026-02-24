class PadariaModel {
  final String id;
  final String nome;
  final String? descricao;
  final String? logoUrl;
  final String? bannerUrl;
  final double avaliacaoMedia;
  final int totalAvaliacoes;
  final bool statusAberto;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? configEntrega;
  final Map<String, dynamic>? endereco;
  final String? categoria;

  const PadariaModel({
    required this.id,
    required this.nome,
    this.descricao,
    this.logoUrl,
    this.bannerUrl,
    this.avaliacaoMedia = 5.0,
    this.totalAvaliacoes = 0,
    this.statusAberto = false,
    this.latitude,
    this.longitude,
    this.configEntrega,
    this.endereco,
    this.categoria,
  });

  factory PadariaModel.fromJson(Map<String, dynamic> json) {
    return PadariaModel(
      id: json['id'] as String,
      nome: json['nome'] as String? ??
          json['nome_completo_fantasia'] as String? ??
          json['razao_social'] as String? ??
          'Padaria',
      descricao: json['descricao'] as String?,
      logoUrl: json['logo_url'] as String?,
      bannerUrl: json['banner_url'] as String?,
      avaliacaoMedia:
          double.tryParse(json['avaliacao_media']?.toString() ?? '5.0') ?? 5.0,
      totalAvaliacoes: json['total_avaliacoes'] as int? ?? 0,
      statusAberto: json['status_aberto'] as bool? ?? false,
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      configEntrega: json['config_entrega'] as Map<String, dynamic>?,
      endereco: json['endereco'] as Map<String, dynamic>?,
      categoria: json['categoria'] as String?,
    );
  }

  /// Retorna a taxa de entrega formatada
  String get taxaEntregaFormatada {
    final taxa = configEntrega?['taxa_entrega_fixa'];
    if (taxa == null) return 'Consultar';
    final valor = double.tryParse(taxa.toString()) ?? 0.0;
    if (valor == 0) return 'Grátis';
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  /// Retorna o tempo médio formatado
  String get tempoMedioFormatado {
    final tempo = configEntrega?['tempo_medio_preparo_min'];
    if (tempo == null) return '30-45 min';
    final min = int.tryParse(tempo.toString()) ?? 30;
    return '$min-${min + 15} min';
  }

  /// Retorna a cidade do endereço
  String get cidade {
    return endereco?['cidade'] as String? ?? '';
  }

  /// Retorna o bairro do endereço
  String get bairro {
    return endereco?['bairro'] as String? ?? '';
  }
}
