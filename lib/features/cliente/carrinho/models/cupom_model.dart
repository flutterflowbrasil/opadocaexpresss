// lib/features/cliente/carrinho/models/cupom_model.dart

class CupomModel {
  final String id;
  final String? estabelecimentoId;
  final String codigo;
  final String? descricao;
  final String tipo; // 'percentual' | 'valor_fixo' | 'entrega_gratis'
  final double valor;
  final double valorMinimoPedido;
  final int? limiteUsos;
  final int usosAtuais;
  final int? limiteUsosPorCliente;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final bool ativo;

  const CupomModel({
    required this.id,
    this.estabelecimentoId,
    required this.codigo,
    this.descricao,
    required this.tipo,
    required this.valor,
    required this.valorMinimoPedido,
    this.limiteUsos,
    required this.usosAtuais,
    this.limiteUsosPorCliente,
    this.dataInicio,
    this.dataFim,
    required this.ativo,
  });

  factory CupomModel.fromJson(Map<String, dynamic> json) {
    return CupomModel(
      id: json['id'] as String,
      estabelecimentoId: json['estabelecimento_id'] as String?,
      codigo: json['codigo'] as String,
      descricao: json['descricao'] as String?,
      tipo: json['tipo'] as String? ?? 'valor_fixo',
      valor: double.tryParse(json['valor']?.toString() ?? '0') ?? 0,
      valorMinimoPedido:
          double.tryParse(json['valor_minimo_pedido']?.toString() ?? '0') ?? 0,
      limiteUsos: json['limite_usos'] as int?,
      usosAtuais: json['usos_atuais'] as int? ?? 0,
      limiteUsosPorCliente: json['limite_usos_por_cliente'] as int?,
      dataInicio: json['data_inicio'] != null
          ? DateTime.tryParse(json['data_inicio'] as String)
          : null,
      dataFim: json['data_fim'] != null
          ? DateTime.tryParse(json['data_fim'] as String)
          : null,
      ativo: json['ativo'] as bool? ?? true,
    );
  }

  /// Calcula o valor de desconto a ser subtraído do total.
  /// Tipos: 'percentual', 'valor_fixo', 'entrega_gratis'.
  double calcularDesconto(double subtotalProdutos, {double taxaEntrega = 0}) {
    switch (tipo) {
      case 'percentual':
        return subtotalProdutos * (valor / 100);
      case 'valor_fixo':
        return valor.clamp(0, subtotalProdutos);
      case 'entrega_gratis':
        return taxaEntrega;
      default:
        return 0;
    }
  }

  String get labelDesconto {
    switch (tipo) {
      case 'percentual':
        return '${valor.toStringAsFixed(0)}% off';
      case 'valor_fixo':
        return '- R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
      case 'entrega_gratis':
        return 'Frete grátis 🎉';
      default:
        return tipo;
    }
  }
}
