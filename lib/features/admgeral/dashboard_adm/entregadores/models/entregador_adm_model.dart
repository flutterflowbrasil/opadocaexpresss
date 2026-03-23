const _docTipos = [
  'selfie',
  'cnh_frente',
  'cnh_verso',
  'veiculo',
  'residencia',
];

class EntregadorKycInfo {
  final String status; // pendente | processando | revisao_manual | aprovado | reprovado
  final String? fotoSelfieUrl;
  final String? observacaoAdmin;
  final DateTime? revisadoEm;

  const EntregadorKycInfo({
    required this.status,
    this.fotoSelfieUrl,
    this.observacaoAdmin,
    this.revisadoEm,
  });

  factory EntregadorKycInfo.fromJson(Map<String, dynamic> json) {
    return EntregadorKycInfo(
      status: (json['status'] as String?) ?? 'pendente',
      fotoSelfieUrl: json['foto_selfie_url'] as String?,
      observacaoAdmin: json['observacao_admin'] as String?,
      revisadoEm: json['revisado_em'] != null
          ? DateTime.tryParse(json['revisado_em'] as String)
          : null,
    );
  }

  EntregadorKycInfo copyWith({
    String? status,
    String? observacaoAdmin,
    DateTime? revisadoEm,
    bool clearObs = false,
  }) {
    return EntregadorKycInfo(
      status: status ?? this.status,
      fotoSelfieUrl: fotoSelfieUrl,
      observacaoAdmin: clearObs ? null : (observacaoAdmin ?? this.observacaoAdmin),
      revisadoEm: revisadoEm ?? this.revisadoEm,
    );
  }
}

class EntregadorAdmModel {
  final String id;
  final String usuarioId;
  final String statusCadastro;
  final String statusDespacho; // livre | aguardando_aceite | em_pedido
  final bool statusOnline;
  final String? tipoVeiculo;
  final String? veiculoModelo;
  final String? veiculoPlaca;
  final String? veiculoCor;
  final int totalEntregas;
  final int totalAvaliacoes;      // FIX #2: estava ausente
  final double avaliacaoMedia;
  final double ganhoTotal;
  final double ganhoDisponivel;   // FIX #3: estava ausente
  final String? asaasWalletId;
  final DateTime? createdAt;
  final DateTime? dataNascimento; // FIX #4: estava ausente
  final String? motivoRejeicao;
  final String? cpf;
  final String? cnhNumero;
  final String? cnhCategoria;
  final DateTime? cnhValidade;
  final String nome;
  final String? email;
  final String? telefone;
  // key = tipo doc, value = status_validacao ('pendente'|'aprovado'|'reprovado'|null=não enviado)
  final Map<String, String?> docs;
  final EntregadorKycInfo? selfieRevisao;

  static const docTotal = 5;
  static const docTipos = _docTipos;

  const EntregadorAdmModel({
    required this.id,
    required this.usuarioId,
    required this.statusCadastro,
    required this.statusDespacho,
    required this.statusOnline,
    this.tipoVeiculo,
    this.veiculoModelo,
    this.veiculoPlaca,
    this.veiculoCor,
    required this.totalEntregas,
    required this.totalAvaliacoes,
    required this.avaliacaoMedia,
    required this.ganhoTotal,
    required this.ganhoDisponivel,
    this.asaasWalletId,
    this.createdAt,
    this.dataNascimento,
    this.motivoRejeicao,
    this.cpf,
    this.cnhNumero,
    this.cnhCategoria,
    this.cnhValidade,
    required this.nome,
    this.email,
    this.telefone,
    required this.docs,
    this.selfieRevisao,
  });

  bool get cnhVencida =>
      cnhValidade != null && cnhValidade!.isBefore(DateTime.now());

  /// Quantidade de docs que foram enviados (status != null)
  int get docCount => docs.values.where((v) => v != null).length;

  /// True se doc foi enviado, independente do status de validação
  bool docEnviado(String tipo) => docs[tipo] != null;

  bool get selfiePendente =>
      selfieRevisao?.status == 'revisao_manual' ||
      (selfieRevisao == null && docEnviado('selfie'));

  factory EntregadorAdmModel.fromJson(Map<String, dynamic> json) {
    final usuarioJson = json['usuarios'] as Map<String, dynamic>?;

    // Monta docs: key=tipo, value=status_validacao ou null se não enviado
    final docsArr = (json['entregador_documentos'] as List?) ?? [];
    final docs = <String, String?>{};
    for (final tipo in _docTipos) {
      final found = docsArr.cast<Map>().where((d) => d['tipo'] == tipo).firstOrNull;
      docs[tipo] = found != null ? (found['status_validacao'] as String?) ?? 'pendente' : null;
    }

    // FIX #1: filtra KYC com provider='manual' — o review manual do admin
    final kycArr = (json['entregador_kyc'] as List?) ?? [];
    final kycManual = kycArr.cast<Map<String, dynamic>>()
        .where((k) => k['provider'] == 'manual')
        .firstOrNull;
    final EntregadorKycInfo? kycInfo =
        kycManual != null ? EntregadorKycInfo.fromJson(kycManual) : null;

    return EntregadorAdmModel(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      statusCadastro: (json['status_cadastro'] as String?) ?? 'pendente',
      statusDespacho: (json['status_despacho'] as String?) ?? 'livre', // FIX #5
      statusOnline: (json['status_online'] as bool?) ?? false,
      tipoVeiculo: json['tipo_veiculo'] as String?,
      veiculoModelo: json['veiculo_modelo'] as String?,
      veiculoPlaca: json['veiculo_placa'] as String?,
      veiculoCor: json['veiculo_cor'] as String?,
      totalEntregas: (json['total_entregas'] as int?) ?? 0,
      totalAvaliacoes: (json['total_avaliacoes'] as int?) ?? 0, // FIX #2
      avaliacaoMedia: (json['avaliacao_media'] as num?)?.toDouble() ?? 0.0,
      ganhoTotal: (json['ganhos_total'] as num?)?.toDouble() ?? 0.0,
      ganhoDisponivel: (json['ganhos_disponiveis'] as num?)?.toDouble() ?? 0.0, // FIX #3
      asaasWalletId: json['asaas_wallet_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      dataNascimento: json['data_nascimento'] != null // FIX #4
          ? DateTime.tryParse(json['data_nascimento'] as String)
          : null,
      motivoRejeicao: json['motivo_rejeicao'] as String?,
      cpf: json['cpf'] as String?,
      cnhNumero: json['cnh_numero'] as String?,
      cnhCategoria: json['cnh_categoria'] as String?,
      cnhValidade: json['cnh_validade'] != null
          ? DateTime.tryParse(json['cnh_validade'] as String)
          : null,
      nome: (usuarioJson?['nome_completo_fantasia'] as String?) ?? '—',
      email: usuarioJson?['email'] as String?,
      telefone: usuarioJson?['telefone'] as String?,
      docs: docs,
      selfieRevisao: kycInfo,
    );
  }

  EntregadorAdmModel copyWith({
    String? statusCadastro,
    String? motivoRejeicao,
    EntregadorKycInfo? selfieRevisao,
    bool clearMotivo = false,
    bool clearSelfie = false,
  }) {
    return EntregadorAdmModel(
      id: id,
      usuarioId: usuarioId,
      statusCadastro: statusCadastro ?? this.statusCadastro,
      statusDespacho: statusDespacho,
      statusOnline: statusOnline,
      tipoVeiculo: tipoVeiculo,
      veiculoModelo: veiculoModelo,
      veiculoPlaca: veiculoPlaca,
      veiculoCor: veiculoCor,
      totalEntregas: totalEntregas,
      totalAvaliacoes: totalAvaliacoes,
      avaliacaoMedia: avaliacaoMedia,
      ganhoTotal: ganhoTotal,
      ganhoDisponivel: ganhoDisponivel,
      asaasWalletId: asaasWalletId,
      createdAt: createdAt,
      dataNascimento: dataNascimento,
      motivoRejeicao: clearMotivo ? null : (motivoRejeicao ?? this.motivoRejeicao),
      cpf: cpf,
      cnhNumero: cnhNumero,
      cnhCategoria: cnhCategoria,
      cnhValidade: cnhValidade,
      nome: nome,
      email: email,
      telefone: telefone,
      docs: docs,
      selfieRevisao:
          clearSelfie ? null : (selfieRevisao ?? this.selfieRevisao),
    );
  }
}
