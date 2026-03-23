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
  final String? motivoSuspensao;
  final bool destaque;
  final Map<String, dynamic>? documentos;
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
    this.motivoSuspensao,
    required this.destaque,
    this.documentos,
    this.dadosBancarios,
    this.tempoMedioEntregaMin,
    this.categoriaId,
  });

  factory EstabAdmModel.fromJson(Map<String, dynamic> json) {
    return EstabAdmModel(
      id: json['id'] as String,
      nomeFantasia: (json['nome_fantasia'] ?? json['razao_social'] ?? '') as String,
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
      motivoSuspensao: json['motivo_suspensao'] as String?,
      destaque: (json['destaque'] ?? false) as bool,
      documentos: json['documentos'] as Map<String, dynamic>?,
      dadosBancarios: json['dados_bancarios'] as Map<String, dynamic>?,
      tempoMedioEntregaMin: json['tempo_medio_entrega_min'] as int?,
      categoriaId: json['categoria_estabelecimento_id'] as String?,
    );
  }

  EstabAdmModel copyWith({
    String? statusCadastro,
    String? motivoSuspensao,
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
      motivoSuspensao: clearMotivo ? null : (motivoSuspensao ?? this.motivoSuspensao),
      destaque: destaque,
      documentos: documentos,
      dadosBancarios: dadosBancarios,
      tempoMedioEntregaMin: tempoMedioEntregaMin,
      categoriaId: categoriaId,
    );
  }
}
