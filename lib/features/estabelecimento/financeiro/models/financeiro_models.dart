class PedidoFinanceiro {
  final String id;
  final String numeroPedido;
  final String status; // entregue, cancelado, etc
  final double total;
  final double subtotalProdutos;
  final double taxaEntrega;
  final double taxaServicoApp;
  final double descontoCupom;
  final String? pagamentoMetodo;
  final String? pagamentoStatus;
  final DateTime createdAt;

  PedidoFinanceiro({
    required this.id,
    required this.numeroPedido,
    required this.status,
    required this.total,
    required this.subtotalProdutos,
    required this.taxaEntrega,
    required this.taxaServicoApp,
    required this.descontoCupom,
    this.pagamentoMetodo,
    this.pagamentoStatus,
    required this.createdAt,
  });

  factory PedidoFinanceiro.fromJson(Map<String, dynamic> json) {
    return PedidoFinanceiro(
      id: json['id'] as String,
      numeroPedido: json['numero_pedido']?.toString() ?? '',
      status: json['status'] as String? ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      subtotalProdutos: (json['subtotal_produtos'] as num?)?.toDouble() ?? 0.0,
      taxaEntrega: (json['taxa_entrega'] as num?)?.toDouble() ?? 0.0,
      taxaServicoApp: (json['taxa_servico_app'] as num?)?.toDouble() ?? 0.0,
      descontoCupom: (json['desconto_cupom'] as num?)?.toDouble() ?? 0.0,
      pagamentoMetodo: json['pagamento_metodo'] as String?,
      pagamentoStatus: json['pagamento_status'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

class SplitFinanceiro {
  final String id;
  final String status;
  final double estabelecimentoValor;
  final double entregadorValorTotal;
  final double plataformaValor;
  final double valorTotal;
  final String? numeroPedido;

  SplitFinanceiro({
    required this.id,
    required this.status,
    required this.estabelecimentoValor,
    required this.entregadorValorTotal,
    required this.plataformaValor,
    required this.valorTotal,
    this.numeroPedido,
  });

  factory SplitFinanceiro.fromJson(Map<String, dynamic> json) {
    // Se houve inner join, o num_pedido vem no map 'pedidos'
    String? numPedido;
    if (json['pedidos'] != null && json['pedidos'] is Map) {
      numPedido = json['pedidos']['numero_pedido']?.toString();
    }

    return SplitFinanceiro(
      id: json['id'] as String,
      status: json['status'] as String? ?? '',
      estabelecimentoValor:
          (json['estabelecimento_valor'] as num?)?.toDouble() ?? 0.0,
      entregadorValorTotal:
          (json['entregador_valor_total'] as num?)?.toDouble() ?? 0.0,
      plataformaValor: (json['plataforma_valor'] as num?)?.toDouble() ?? 0.0,
      valorTotal: (json['valor_total'] as num?)?.toDouble() ?? 0.0,
      numeroPedido: numPedido,
    );
  }
}

class EstabelecimentoFinanceiro {
  final String id;
  final String nomeFantasia;
  final double faturamentoTotal;
  final int totalPedidos;
  final Map<String, dynamic>? dadosBancarios;

  EstabelecimentoFinanceiro({
    required this.id,
    required this.nomeFantasia,
    required this.faturamentoTotal,
    required this.totalPedidos,
    this.dadosBancarios,
  });

  factory EstabelecimentoFinanceiro.fromJson(Map<String, dynamic> json) {
    return EstabelecimentoFinanceiro(
      id: json['id'] as String,
      nomeFantasia: json['nome_fantasia'] as String? ?? '',
      faturamentoTotal: (json['faturamento_total'] as num?)?.toDouble() ?? 0.0,
      totalPedidos: (json['total_pedidos'] as num?)?.toInt() ?? 0,
      dadosBancarios: json['dados_bancarios'] as Map<String, dynamic>?,
    );
  }
}
