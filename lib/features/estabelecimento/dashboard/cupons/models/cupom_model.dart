class CupomModel {
  final String id;
  final String estabelecimentoId;
  final String codigo;
  final String? descricao;
  final String tipo; // percentual, valor_fixo, entrega_gratis
  final double valor;
  final double valorMinimoPedido;
  final int? limiteUsos;
  final int usosAtuais;
  final int limiteUsosPorCliente;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final bool ativo;

  CupomModel({
    required this.id,
    required this.estabelecimentoId,
    required this.codigo,
    this.descricao,
    required this.tipo,
    required this.valor,
    required this.valorMinimoPedido,
    this.limiteUsos,
    this.usosAtuais = 0,
    required this.limiteUsosPorCliente,
    this.dataInicio,
    this.dataFim,
    required this.ativo,
  });

  factory CupomModel.fromJson(Map<String, dynamic> json) {
    return CupomModel(
      id: json['id'],
      estabelecimentoId: json['estabelecimento_id'] ?? '',
      codigo: json['codigo'] ?? '',
      descricao: json['descricao'],
      tipo: json['tipo'] ?? 'percentual',
      valor: (json['valor'] as num?)?.toDouble() ?? 0.0,
      valorMinimoPedido:
          (json['valor_minimo_pedido'] as num?)?.toDouble() ?? 0.0,
      limiteUsos: json['limite_usos'] as int?,
      usosAtuais: json['usos_atuais'] as int? ?? 0,
      limiteUsosPorCliente: json['limite_usos_por_cliente'] as int? ?? 1,
      dataInicio: json['data_inicio'] != null
          ? DateTime.parse(json['data_inicio']).toLocal()
          : null,
      dataFim: json['data_fim'] != null
          ? DateTime.parse(json['data_fim']).toLocal()
          : null,
      ativo: json['ativo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson({bool isUpdate = false}) {
    final map = {
      'codigo': codigo,
      'descricao': descricao,
      'tipo': tipo,
      'valor': valor,
      'valor_minimo_pedido': valorMinimoPedido,
      'limite_usos': limiteUsos,
      'limite_usos_por_cliente': limiteUsosPorCliente,
      'data_inicio': dataInicio?.toUtc().toIso8601String(),
      'data_fim': dataFim?.toUtc().toIso8601String(),
      'ativo': ativo,
    };

    if (!isUpdate) {
      map['estabelecimento_id'] = estabelecimentoId;
      map['usos_atuais'] = usosAtuais;
    }

    return map;
  }

  CupomModel copyWith({
    String? id,
    String? estabelecimentoId,
    String? codigo,
    String? descricao,
    String? tipo,
    double? valor,
    double? valorMinimoPedido,
    int? limiteUsos,
    int? usosAtuais,
    int? limiteUsosPorCliente,
    DateTime? dataInicio,
    DateTime? dataFim,
    bool? ativo,
  }) {
    return CupomModel(
      id: id ?? this.id,
      estabelecimentoId: estabelecimentoId ?? this.estabelecimentoId,
      codigo: codigo ?? this.codigo,
      descricao: descricao ?? this.descricao,
      tipo: tipo ?? this.tipo,
      valor: valor ?? this.valor,
      valorMinimoPedido: valorMinimoPedido ?? this.valorMinimoPedido,
      limiteUsos: limiteUsos ?? this.limiteUsos,
      usosAtuais: usosAtuais ?? this.usosAtuais,
      limiteUsosPorCliente: limiteUsosPorCliente ?? this.limiteUsosPorCliente,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      ativo: ativo ?? this.ativo,
    );
  }
}
