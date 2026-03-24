class PedidoFinanceiro {
  final String id;
  final int numeroPedido;
  final String status;
  final String pagamentoStatus;
  final String pagamentoMetodo;
  final double subtotalProdutos;
  final double taxaEntrega;
  final double taxaServico;
  final double descontoCupom;
  final double total;
  final bool splitProcessado;
  final String? clienteNome;
  final String? estabNome;
  final DateTime createdAt;

  const PedidoFinanceiro({
    required this.id,
    required this.numeroPedido,
    required this.status,
    required this.pagamentoStatus,
    required this.pagamentoMetodo,
    required this.subtotalProdutos,
    required this.taxaEntrega,
    required this.taxaServico,
    required this.descontoCupom,
    required this.total,
    required this.splitProcessado,
    required this.createdAt,
    this.clienteNome,
    this.estabNome,
  });

  factory PedidoFinanceiro.fromJson(Map<String, dynamic> json) {
    // Extrai nome do cliente via join aninhado: clientes -> usuarios
    String? clienteNome;
    final clienteData = json['clientes'];
    if (clienteData is Map) {
      final usuarioData = clienteData['usuarios'];
      if (usuarioData is Map) {
        clienteNome = usuarioData['nome_completo_fantasia'] as String?;
      }
    }

    // Extrai nome do estabelecimento via join
    String? estabNome;
    final estabData = json['estabelecimentos'];
    if (estabData is Map) {
      estabNome = estabData['nome_fantasia'] as String?;
    }

    return PedidoFinanceiro(
      id: json['id'] as String,
      numeroPedido: (json['numero_pedido'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'desconhecido',
      pagamentoStatus: json['pagamento_status'] as String? ?? 'pendente',
      pagamentoMetodo: json['pagamento_metodo'] as String? ?? 'desconhecido',
      subtotalProdutos: (json['subtotal_produtos'] as num?)?.toDouble() ?? 0,
      taxaEntrega: (json['taxa_entrega'] as num?)?.toDouble() ?? 0,
      taxaServico: (json['taxa_servico_app'] as num?)?.toDouble() ?? 0,
      descontoCupom: (json['desconto_cupom'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      splitProcessado: json['split_processado'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      clienteNome: clienteNome,
      estabNome: estabNome,
    );
  }
}

class SplitPagamento {
  final String id;
  final String pedidoId;
  final double valorTotal;
  final double estabPercentual;
  final double estabValor;
  final double entregadorValor;
  final double plataformaPercentual;
  final double plataformaValor;
  final String status;
  final String? motivoFalha;
  final DateTime createdAt;
  final DateTime? processadoEm;

  const SplitPagamento({
    required this.id,
    required this.pedidoId,
    required this.valorTotal,
    required this.estabPercentual,
    required this.estabValor,
    required this.entregadorValor,
    required this.plataformaPercentual,
    required this.plataformaValor,
    required this.status,
    required this.createdAt,
    this.motivoFalha,
    this.processadoEm,
  });

  factory SplitPagamento.fromJson(Map<String, dynamic> json) {
    return SplitPagamento(
      id: json['id'] as String,
      pedidoId: json['pedido_id'] as String,
      valorTotal: (json['valor_total'] as num?)?.toDouble() ?? 0,
      estabPercentual: (json['estabelecimento_percentual'] as num?)?.toDouble() ?? 85,
      estabValor: (json['estabelecimento_valor'] as num?)?.toDouble() ?? 0,
      entregadorValor: (json['entregador_valor_total'] as num?)?.toDouble() ?? 0,
      plataformaPercentual: (json['plataforma_percentual'] as num?)?.toDouble() ?? 5,
      plataformaValor: (json['plataforma_valor'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'pendente',
      motivoFalha: json['motivo_falha'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      processadoEm: json['processado_em'] != null
          ? DateTime.parse(json['processado_em'] as String)
          : null,
    );
  }
}

class EntregadorSaque {
  final String id;
  final String entregadorId;
  final double valor;
  final String pixChave;
  final String pixTipo;
  final String status;
  final String? asaasTransferId;
  final String? motivoFalha;
  final DateTime solicitadoEm;
  final DateTime? processadoEm;

  const EntregadorSaque({
    required this.id,
    required this.entregadorId,
    required this.valor,
    required this.pixChave,
    required this.pixTipo,
    required this.status,
    required this.solicitadoEm,
    this.asaasTransferId,
    this.motivoFalha,
    this.processadoEm,
  });

  factory EntregadorSaque.fromJson(Map<String, dynamic> json) {
    return EntregadorSaque(
      id: json['id'] as String,
      entregadorId: json['entregador_id'] as String,
      valor: (json['valor'] as num?)?.toDouble() ?? 0,
      pixChave: json['pix_chave'] as String? ?? '',
      pixTipo: json['pix_tipo'] as String? ?? 'aleatoria',
      status: json['status'] as String? ?? 'pendente',
      asaasTransferId: json['asaas_transfer_id'] as String?,
      motivoFalha: json['motivo_falha'] as String?,
      solicitadoEm: DateTime.parse(json['solicitado_em'] as String),
      processadoEm: json['processado_em'] != null
          ? DateTime.parse(json['processado_em'] as String)
          : null,
    );
  }
}

class AsaasSubconta {
  final String id;
  final String entidadeTipo;
  final String entidadeId;
  final String? asaasAccountId;
  final String? asaasWalletId;
  final String statusConta;
  final DateTime createdAt;

  const AsaasSubconta({
    required this.id,
    required this.entidadeTipo,
    required this.entidadeId,
    required this.statusConta,
    required this.createdAt,
    this.asaasAccountId,
    this.asaasWalletId,
  });

  factory AsaasSubconta.fromJson(Map<String, dynamic> json) {
    return AsaasSubconta(
      id: json['id'] as String,
      entidadeTipo: json['entidade_tipo'] as String? ?? 'desconhecido',
      entidadeId: json['entidade_id'] as String,
      asaasAccountId: json['asaas_account_id'] as String?,
      asaasWalletId: json['asaas_wallet_id'] as String?,
      statusConta: json['status_conta'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
