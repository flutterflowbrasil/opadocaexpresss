class EstabelecimentoModel {
  final String id;
  final String nome; // mapeado de razao_social ou nome fantasia
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
  final String? categoriaId;

  EstabelecimentoModel({
    required this.id,
    required this.nome,
    this.descricao,
    this.logoUrl,
    this.bannerUrl,
    required this.avaliacaoMedia,
    required this.totalAvaliacoes,
    required this.statusAberto,
    this.latitude,
    this.longitude,
    this.configEntrega,
    this.endereco,
    this.categoriaId,
  });

  factory EstabelecimentoModel.fromJson(Map<String, dynamic> json) {
    return EstabelecimentoModel(
      id: json['id'] as String,
      nome: json['razao_social'] ?? 'Estabelecimento',
      descricao: json['descricao'] as String?,
      logoUrl: json['logo_url'] as String?,
      bannerUrl: json['banner_url'] as String?,
      avaliacaoMedia: (json['avaliacao_media'] as num?)?.toDouble() ?? 5.0,
      totalAvaliacoes: (json['total_avaliacoes'] as num?)?.toInt() ?? 0,
      statusAberto: json['status_aberto'] == true,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      configEntrega: json['config_entrega'] as Map<String, dynamic>?,
      endereco: json['endereco'] as Map<String, dynamic>?,
      categoriaId: json['categoria_estabelecimento_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'razao_social': nome,
      'descricao': descricao,
      'logo_url': logoUrl,
      'banner_url': bannerUrl,
      'avaliacao_media': avaliacaoMedia,
      'total_avaliacoes': totalAvaliacoes,
      'status_aberto': statusAberto,
      'latitude': latitude,
      'longitude': longitude,
      'config_entrega': configEntrega,
      'endereco': endereco,
      'categoria_estabelecimento_id': categoriaId,
    };
  }

  /// Helper provisório para exibição do tempo de entrega
  String get tempoMedioFormatado {
    final tempo = configEntrega?['tempo_medio_minutos'];
    if (tempo == null) return '30-45 min';
    return '$tempo min';
  }

  String get taxaEntregaFormatada {
    final taxa = configEntrega?['taxa_entrega_fixa'];
    if (taxa == null) return 'Consultar';
    final valor = double.tryParse(taxa.toString()) ?? 0.0;
    if (valor == 0) return 'Grátis';
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String? get bairro => endereco?['bairro'] as String?;
  String? get cidade => endereco?['cidade'] as String?;
}
