const _docTipos = [
  'selfie',
  'cnh_frente',
  'cnh_verso',
  'identidade_frente',
  'identidade_verso',
  'veiculo',
];

class EntregadorKycInfo {
  final String
      status; // pendente | processando | revisao_manual | aprovado | reprovado
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
      observacaoAdmin:
          clearObs ? null : (observacaoAdmin ?? this.observacaoAdmin),
      revisadoEm: revisadoEm ?? this.revisadoEm,
    );
  }
}

class EntregadorDocumentoInfo {
  final String tipo;
  final String status;
  final String? storagePath;
  final String? signedUrl;
  final String? motivoRejeicao;
  final DateTime? revisadoEm;

  const EntregadorDocumentoInfo({
    required this.tipo,
    required this.status,
    this.storagePath,
    this.signedUrl,
    this.motivoRejeicao,
    this.revisadoEm,
  });

  factory EntregadorDocumentoInfo.fromJson(Map<String, dynamic> json) {
    return EntregadorDocumentoInfo(
      tipo: (json['tipo'] as String?) ?? '',
      status: (json['status_validacao'] as String?) ?? 'pendente',
      storagePath: json['url'] as String?,
      signedUrl: json['signed_url'] as String?,
      motivoRejeicao: json['motivo_rejeicao'] as String?,
      revisadoEm: json['revisado_em'] != null
          ? DateTime.tryParse(json['revisado_em'] as String)
          : null,
    );
  }

  EntregadorDocumentoInfo copyWith({
    String? status,
    String? signedUrl,
    String? motivoRejeicao,
    DateTime? revisadoEm,
    bool clearMotivo = false,
  }) {
    return EntregadorDocumentoInfo(
      tipo: tipo,
      status: status ?? this.status,
      storagePath: storagePath,
      signedUrl: signedUrl ?? this.signedUrl,
      motivoRejeicao:
          clearMotivo ? null : (motivoRejeicao ?? this.motivoRejeicao),
      revisadoEm: revisadoEm ?? this.revisadoEm,
    );
  }
}

class EntregadorEnderecoInfo {
  final String? id;
  final String cep;
  final String logradouro;
  final String numero;
  final String? complemento;
  final String bairro;
  final String cidade;
  final String estado;

  const EntregadorEnderecoInfo({
    this.id,
    required this.cep,
    required this.logradouro,
    required this.numero,
    this.complemento,
    required this.bairro,
    required this.cidade,
    required this.estado,
  });

  factory EntregadorEnderecoInfo.fromJson(Map<String, dynamic> json) {
    return EntregadorEnderecoInfo(
      id: json['id'] as String?,
      cep: (json['cep'] as String?) ?? '',
      logradouro: (json['logradouro'] as String?) ??
          (json['address'] as String?) ??
          '',
      numero: (json['numero'] as String?) ??
          (json['addressNumber'] as String?) ??
          '',
      complemento: json['complemento'] as String? ?? json['complement'] as String?,
      bairro: (json['bairro'] as String?) ??
          (json['province'] as String?) ??
          '',
      cidade: _asString(json['cidade']).isNotEmpty
          ? _asString(json['cidade'])
          : _asString(json['city']),
      estado: ((json['estado'] as String?) ?? (json['state'] as String?) ?? '')
          .toUpperCase(),
    );
  }

  static String _asString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return '';
  }

  static EntregadorEnderecoInfo? tryParse(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return null;
    final info = EntregadorEnderecoInfo.fromJson(json);
    if (info.cep.isEmpty &&
        info.logradouro.isEmpty &&
        info.bairro.isEmpty &&
        info.cidade.isEmpty) {
      return null;
    }
    return info;
  }

  Map<String, dynamic> toJson() {
    return {
      'cep': cep.replaceAll(RegExp(r'\D'), ''),
      'logradouro': logradouro.trim(),
      'numero': numero.trim(),
      if (complemento != null && complemento!.trim().isNotEmpty)
        'complemento': complemento!.trim(),
      'bairro': bairro.trim(),
      'cidade': cidade.trim(),
      'estado': estado.trim().toUpperCase(),
    };
  }

  bool get isComplete =>
      cep.replaceAll(RegExp(r'\D'), '').length == 8 &&
      logradouro.trim().isNotEmpty &&
      numero.trim().isNotEmpty &&
      bairro.trim().isNotEmpty &&
      cidade.trim().isNotEmpty &&
      estado.trim().length == 2;

  String get completo {
    final comp = complemento != null && complemento!.trim().isNotEmpty
        ? ' - ${complemento!.trim()}'
        : '';
    return '$logradouro, $numero$comp, $bairro - $cidade/$estado';
  }

  @override
  bool operator ==(Object other) {
    return other is EntregadorEnderecoInfo &&
        other.id == id &&
        other.cep == cep &&
        other.logradouro == logradouro &&
        other.numero == numero &&
        other.complemento == complemento &&
        other.bairro == bairro &&
        other.cidade == cidade &&
        other.estado == estado;
  }

  @override
  int get hashCode => Object.hash(
        id,
        cep,
        logradouro,
        numero,
        complemento,
        bairro,
        cidade,
        estado,
      );
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
  final int totalAvaliacoes; // FIX #2: estava ausente
  final double avaliacaoMedia;
  final double ganhoTotal;
  final double ganhoDisponivel; // FIX #3: estava ausente
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
  final EntregadorEnderecoInfo? endereco;
  // key = tipo doc, value = status_validacao ('pendente'|'aprovado'|'reprovado'|null=não enviado)
  final Map<String, String?> docs;
  final Map<String, EntregadorDocumentoInfo> documentos;
  final EntregadorKycInfo? selfieRevisao;

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
    this.endereco,
    required this.docs,
    this.documentos = const {},
    this.selfieRevisao,
  });

  bool get cnhVencida =>
      cnhValidade != null && cnhValidade!.isBefore(DateTime.now());

  bool get usaCnh => tipoVeiculo == 'moto' || tipoVeiculo == 'carro';

  List<String> get docTiposVisiveis => [
        if (usaCnh) ...[
          'cnh_frente',
          'cnh_verso'
        ] else ...[
          'identidade_frente',
          'identidade_verso'
        ],
        'selfie',
      ];

  List<String> get docTiposObrigatorios => docTiposVisiveis;

  int get docTotal => docTiposObrigatorios.length;

  /// Quantidade de docs obrigatórios que foram enviados (status != null)
  int get docCount =>
      docTiposObrigatorios.where((tipo) => docs[tipo] != null).length;

  int get docApprovedCount =>
      docTiposObrigatorios.where((tipo) => docs[tipo] == 'aprovado').length;

  bool get docsObrigatoriosAprovados => docApprovedCount == docTotal;

  bool docObrigatorio(String tipo) => docTiposObrigatorios.contains(tipo);

  /// True se doc foi enviado, independente do status de validação
  bool docEnviado(String tipo) => docs[tipo] != null;

  bool get selfiePendente =>
      selfieRevisao?.status == 'revisao_manual' ||
      (selfieRevisao == null && docEnviado('selfie'));

  bool get temCarteiraAsaas => (asaasWalletId ?? '').trim().isNotEmpty;

  factory EntregadorAdmModel.fromJson(Map<String, dynamic> json) {
    final usuarioJson = json['usuarios'] as Map<String, dynamic>?;
    final enderecosArr = (json['entregador_enderecos'] as List?) ?? [];
    final enderecoRel = enderecosArr.cast<Map>().firstOrNull;
    final enderecoJson = enderecoRel != null
        ? enderecoRel.cast<String, dynamic>()
        : (json['endereco'] is Map
            ? (json['endereco'] as Map).cast<String, dynamic>()
            : null);
    final enderecoParsed = EntregadorEnderecoInfo.tryParse(enderecoJson);

    // Monta docs: key=tipo, value=status_validacao ou null se não enviado
    final docsArr = (json['entregador_documentos'] as List?) ?? [];
    final docs = <String, String?>{};
    final documentos = <String, EntregadorDocumentoInfo>{};
    Map? selfieDoc;
    for (final tipo in _docTipos) {
      final found =
          docsArr.cast<Map>().where((d) => d['tipo'] == tipo).firstOrNull;
      docs[tipo] = found != null
          ? (found['status_validacao'] as String?) ?? 'pendente'
          : null;
      if (found != null) {
        documentos[tipo] =
            EntregadorDocumentoInfo.fromJson(found.cast<String, dynamic>());
      }
      if (tipo == 'selfie') selfieDoc = found;
    }

    // FIX #1: filtra KYC com provider='manual' — o review manual do admin
    final kycArr = (json['entregador_kyc'] as List?) ?? [];
    final kycManual = kycArr
        .cast<Map<String, dynamic>>()
        .where((k) => k['provider'] == 'manual')
        .firstOrNull;
    final selfieStatus = selfieDoc?['status_validacao'] as String?;
    final EntregadorKycInfo? kycInfo =
        selfieDoc != null && selfieStatus == 'pendente'
            ? EntregadorKycInfo(
                status: 'revisao_manual',
                fotoSelfieUrl:
                    (selfieDoc?['signed_url'] ?? selfieDoc?['url']) as String?,
              )
            : kycManual != null
                ? EntregadorKycInfo.fromJson(kycManual)
                : selfieDoc != null
                    ? EntregadorKycInfo(
                        status: 'revisao_manual',
                        fotoSelfieUrl: (selfieDoc?['signed_url'] ??
                            selfieDoc?['url']) as String?,
                      )
                    : null;

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
      ganhoDisponivel:
          (json['ganhos_disponiveis'] as num?)?.toDouble() ?? 0.0, // FIX #3
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
      endereco: enderecoParsed,
      docs: docs,
      documentos: documentos,
      selfieRevisao: kycInfo,
    );
  }

  EntregadorAdmModel copyWith({
    String? statusCadastro,
    String? motivoRejeicao,
    Map<String, String?>? docs,
    Map<String, EntregadorDocumentoInfo>? documentos,
    EntregadorKycInfo? selfieRevisao,
    EntregadorEnderecoInfo? endereco,
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
      motivoRejeicao:
          clearMotivo ? null : (motivoRejeicao ?? this.motivoRejeicao),
      cpf: cpf,
      cnhNumero: cnhNumero,
      cnhCategoria: cnhCategoria,
      cnhValidade: cnhValidade,
      nome: nome,
      email: email,
      telefone: telefone,
      endereco: endereco ?? this.endereco,
      docs: docs ?? this.docs,
      documentos: documentos ?? this.documentos,
      selfieRevisao: clearSelfie ? null : (selfieRevisao ?? this.selfieRevisao),
    );
  }
}
