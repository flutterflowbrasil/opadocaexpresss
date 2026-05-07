class EstabDocumentoInfo {
  final String tipo;
  final String status;
  final String? storagePath;
  final String? signedUrl;
  final String? motivoRejeicao;
  final DateTime? validadoEm;

  const EstabDocumentoInfo({
    required this.tipo,
    required this.status,
    this.storagePath,
    this.signedUrl,
    this.motivoRejeicao,
    this.validadoEm,
  });

  factory EstabDocumentoInfo.fromJson(Map<String, dynamic> json) {
    return EstabDocumentoInfo(
      tipo: (json['tipo'] as String?) ?? '',
      status: (json['status_validacao'] as String?) ?? 'pendente',
      storagePath: json['url'] as String?,
      signedUrl: json['signed_url'] as String?,
      motivoRejeicao: json['motivo_rejeicao'] as String?,
      validadoEm: json['validado_em'] != null
          ? DateTime.tryParse(json['validado_em'] as String)
          : null,
    );
  }

  EstabDocumentoInfo copyWith({
    String? status,
    String? signedUrl,
    String? motivoRejeicao,
    DateTime? validadoEm,
    bool clearMotivo = false,
  }) {
    return EstabDocumentoInfo(
      tipo: tipo,
      status: status ?? this.status,
      storagePath: storagePath,
      signedUrl: signedUrl ?? this.signedUrl,
      motivoRejeicao:
          clearMotivo ? null : (motivoRejeicao ?? this.motivoRejeicao),
      validadoEm: validadoEm ?? this.validadoEm,
    );
  }
}

class EstabAsaasInfo {
  final String? accountId;
  final String? walletId;
  final String? statusConta;
  final String? onboardingUrl;
  final String? motivoRejeicao;
  final DateTime? ultimaSincronizacao;

  const EstabAsaasInfo({
    this.accountId,
    this.walletId,
    this.statusConta,
    this.onboardingUrl,
    this.motivoRejeicao,
    this.ultimaSincronizacao,
  });

  factory EstabAsaasInfo.fromJson(Map<String, dynamic> json) {
    return EstabAsaasInfo(
      accountId: json['asaas_account_id'] as String?,
      walletId: json['asaas_wallet_id'] as String?,
      statusConta: json['status_conta'] as String?,
      onboardingUrl: json['onboarding_url'] as String?,
      motivoRejeicao: json['motivo_rejeicao'] as String?,
      ultimaSincronizacao: json['ultima_sincronizacao'] != null
          ? DateTime.tryParse(json['ultima_sincronizacao'] as String)
          : null,
    );
  }
}

class EstabAdmModel {
  final String id;
  final String nomeFantasia;
  final String razaoSocial;
  final String? cnpj;
  final String statusCadastro;
  final bool statusAberto;
  final double? faturamentoTotal;
  final int? totalPedidos;
  final double avaliacaoMedia;
  final int totalAvaliacoes;
  final DateTime? createdAt;
  final String? responsavelNome;
  final String? responsavelCpf;
  final String? telefoneComercial;
  final String? emailComercial;
  final String? asaasAccountId;
  final String? asaasWalletId;
  final EstabAsaasInfo? asaasInfo;
  final String? motivoSuspensao;
  final bool destaque;
  final Map<String, dynamic>? documentos;
  final Map<String, String?> docs;
  final Map<String, EstabDocumentoInfo> documentosRevisao;
  final Map<String, dynamic>? dadosBancarios;
  final int? tempoMedioEntregaMin;
  final String? categoriaId;

  const EstabAdmModel({
    required this.id,
    required this.nomeFantasia,
    required this.razaoSocial,
    this.cnpj,
    required this.statusCadastro,
    required this.statusAberto,
    this.faturamentoTotal,
    this.totalPedidos,
    required this.avaliacaoMedia,
    required this.totalAvaliacoes,
    this.createdAt,
    this.responsavelNome,
    this.responsavelCpf,
    this.telefoneComercial,
    this.emailComercial,
    this.asaasAccountId,
    this.asaasWalletId,
    this.asaasInfo,
    this.motivoSuspensao,
    required this.destaque,
    this.documentos,
    this.docs = const {},
    this.documentosRevisao = const {},
    this.dadosBancarios,
    this.tempoMedioEntregaMin,
    this.categoriaId,
  });

  bool get usaCnh => documentosRevisao.keys.any(
        (tipo) => tipo.startsWith('cnh_responsavel'),
      );

  List<String> get docTiposObrigatorios => [
        if (usaCnh) ...[
          'cnh_responsavel_frente',
          'cnh_responsavel_verso',
        ] else ...[
          'identidade_responsavel_frente',
          'identidade_responsavel_verso',
        ],
        'comprovante_endereco',
      ];

  int get docTotal => docTiposObrigatorios.length;

  int get docEnviadosCount =>
      docTiposObrigatorios.where((tipo) => docs[tipo] != null).length;

  int get docApprovedCount =>
      docTiposObrigatorios.where((tipo) => docs[tipo] == 'aprovado').length;

  bool get docsObrigatoriosAprovados => docApprovedCount == docTotal;

  bool docEnviado(String tipo) => docs[tipo] != null;

  factory EstabAdmModel.fromJson(Map<String, dynamic> json) {
    final docsArr = (json['estabelecimento_documentos'] as List?) ?? [];
    final docs = <String, String?>{};
    final documentosRevisao = <String, EstabDocumentoInfo>{};
    for (final raw in docsArr.cast<Map>()) {
      final doc = EstabDocumentoInfo.fromJson(raw.cast<String, dynamic>());
      if (doc.tipo.isEmpty) continue;
      docs[doc.tipo] = doc.status;
      documentosRevisao[doc.tipo] = doc;
    }
    final asaasRows = (json['asaas_subcontas'] as List?) ?? [];
    final asaasJson =
        asaasRows.isNotEmpty ? asaasRows.cast<Map>().first : null;

    return EstabAdmModel(
      id: json['id'] as String,
      nomeFantasia:
          (json['nome_fantasia'] ?? json['razao_social'] ?? '') as String,
      razaoSocial: (json['razao_social'] ?? '') as String,
      cnpj: json['cnpj'] as String?,
      statusCadastro: (json['status_cadastro'] ?? 'pendente') as String,
      statusAberto: (json['status_aberto'] ?? false) as bool,
      faturamentoTotal: (json['faturamento_total'] as num?)?.toDouble(),
      totalPedidos: json['total_pedidos'] as int?,
      avaliacaoMedia: (json['avaliacao_media'] as num?)?.toDouble() ?? 0.0,
      totalAvaliacoes: (json['total_avaliacoes'] as int?) ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      responsavelNome: json['responsavel_nome'] as String?,
      responsavelCpf: json['responsavel_cpf'] as String?,
      telefoneComercial: json['telefone_comercial'] as String?,
      emailComercial: json['email_comercial'] as String?,
      asaasAccountId: json['asaas_account_id'] as String?,
      asaasWalletId: json['asaas_wallet_id'] as String?,
      asaasInfo: asaasJson != null
          ? EstabAsaasInfo.fromJson(asaasJson.cast<String, dynamic>())
          : null,
      motivoSuspensao: json['motivo_suspensao'] as String?,
      destaque: (json['destaque'] ?? false) as bool,
      documentos: json['documentos'] as Map<String, dynamic>?,
      docs: docs,
      documentosRevisao: documentosRevisao,
      dadosBancarios: json['dados_bancarios'] as Map<String, dynamic>?,
      tempoMedioEntregaMin: json['tempo_medio_entrega_min'] as int?,
      categoriaId: json['categoria_estabelecimento_id'] as String?,
    );
  }

  EstabAdmModel copyWith({
    String? statusCadastro,
    String? motivoSuspensao,
    Map<String, String?>? docs,
    Map<String, EstabDocumentoInfo>? documentosRevisao,
    bool clearMotivo = false,
  }) {
    return EstabAdmModel(
      id: id,
      nomeFantasia: nomeFantasia,
      razaoSocial: razaoSocial,
      cnpj: cnpj,
      statusCadastro: statusCadastro ?? this.statusCadastro,
      statusAberto: statusAberto,
      faturamentoTotal: faturamentoTotal,
      totalPedidos: totalPedidos,
      avaliacaoMedia: avaliacaoMedia,
      totalAvaliacoes: totalAvaliacoes,
      createdAt: createdAt,
      responsavelNome: responsavelNome,
      responsavelCpf: responsavelCpf,
      telefoneComercial: telefoneComercial,
      emailComercial: emailComercial,
      asaasAccountId: asaasAccountId,
      asaasWalletId: asaasWalletId,
      asaasInfo: asaasInfo,
      motivoSuspensao:
          clearMotivo ? null : (motivoSuspensao ?? this.motivoSuspensao),
      destaque: destaque,
      documentos: documentos,
      docs: docs ?? this.docs,
      documentosRevisao: documentosRevisao ?? this.documentosRevisao,
      dadosBancarios: dadosBancarios,
      tempoMedioEntregaMin: tempoMedioEntregaMin,
      categoriaId: categoriaId,
    );
  }
}
