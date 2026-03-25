/// Modelo imutável que representa um endereço de entrega do cliente,
/// mapeado para a tabela `enderecos_clientes` do Supabase.
class EnderecoCliente {
  final String? id;
  final String? clienteId;
  final String? apelido;
  final String cep;
  final String logradouro;
  final String numero;
  final String? complemento;
  final String bairro;
  final String cidade;
  final String estado;
  final double latitude;
  final double longitude;
  final String? pontoReferencia;
  final String? instrucoes;
  final bool isPadrao;
  final DateTime? createdAt;

  const EnderecoCliente({
    this.id,
    this.clienteId,
    this.apelido,
    required this.cep,
    required this.logradouro,
    required this.numero,
    this.complemento,
    required this.bairro,
    required this.cidade,
    required this.estado,
    required this.latitude,
    required this.longitude,
    this.pontoReferencia,
    this.instrucoes,
    this.isPadrao = false,
    this.createdAt,
  });

  factory EnderecoCliente.fromJson(Map<String, dynamic> json) {
    return EnderecoCliente(
      id: json['id'] as String?,
      clienteId: json['cliente_id'] as String?,
      apelido: json['apelido'] as String?,
      cep: json['cep'] as String,
      logradouro: json['logradouro'] as String,
      numero: json['numero'] as String,
      complemento: json['complemento'] as String?,
      bairro: json['bairro'] as String,
      cidade: json['cidade'] as String,
      estado: json['estado'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      pontoReferencia: json['ponto_referencia'] as String?,
      instrucoes: json['instrucoes_entrega'] as String?,
      isPadrao: json['is_padrao'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (clienteId != null) 'cliente_id': clienteId,
      if (apelido != null) 'apelido': apelido,
      'cep': cep,
      'logradouro': logradouro,
      'numero': numero,
      if (complemento != null && complemento!.isNotEmpty)
        'complemento': complemento,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
      'latitude': latitude,
      'longitude': longitude,
      if (pontoReferencia != null && pontoReferencia!.isNotEmpty)
        'ponto_referencia': pontoReferencia,
      if (instrucoes != null && instrucoes!.isNotEmpty)
        'instrucoes_entrega': instrucoes,
      'is_padrao': isPadrao,
    };
  }

  EnderecoCliente copyWith({
    String? id,
    String? clienteId,
    String? apelido,
    String? cep,
    String? logradouro,
    String? numero,
    String? complemento,
    String? bairro,
    String? cidade,
    String? estado,
    double? latitude,
    double? longitude,
    String? pontoReferencia,
    String? instrucoes,
    bool? isPadrao,
    DateTime? createdAt,
  }) {
    return EnderecoCliente(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      apelido: apelido ?? this.apelido,
      cep: cep ?? this.cep,
      logradouro: logradouro ?? this.logradouro,
      numero: numero ?? this.numero,
      complemento: complemento ?? this.complemento,
      bairro: bairro ?? this.bairro,
      cidade: cidade ?? this.cidade,
      estado: estado ?? this.estado,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      pontoReferencia: pontoReferencia ?? this.pontoReferencia,
      instrucoes: instrucoes ?? this.instrucoes,
      isPadrao: isPadrao ?? this.isPadrao,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Formata o endereço completo em uma linha.
  String get enderecoCompleto {
    final comp = (complemento != null && complemento!.isNotEmpty)
        ? ' - $complemento'
        : '';
    return '$logradouro, $numero$comp, $bairro — $cidade/$estado';
  }

  /// Label amigável para exibir no header (rua + número).
  String get labelCurto => '$logradouro, $numero';
}
