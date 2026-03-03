import 'package:intl/intl.dart';

class PedidoClienteModel {
  final String id;
  final int? numeroPedido;
  final double total;
  final String status;
  final DateTime createdAt;
  final String? pagamentoMetodo;

  // Dados do Estabelecimento (via Join)
  final String? estabelecimentoNome;
  final String? estabelecimentoLogoUrl;

  // Itens (via JSONB)
  final List<dynamic> itensJson;

  PedidoClienteModel({
    required this.id,
    this.numeroPedido,
    required this.total,
    required this.status,
    required this.createdAt,
    this.pagamentoMetodo,
    this.estabelecimentoNome,
    this.estabelecimentoLogoUrl,
    required this.itensJson,
  });

  factory PedidoClienteModel.fromJson(Map<String, dynamic> json) {
    // Tratamento de segurança para o join com estabelecimentos
    final estabData = json['estabelecimentos'];
    String? nomeFantasia;
    String? logoUrl;

    if (estabData != null && estabData is Map) {
      nomeFantasia = estabData['nome_fantasia'] as String?;
      logoUrl = estabData['logo_url'] as String?;
    }

    // Tratamento dos itens em JSONB
    List<dynamic> itensList = [];
    if (json['itens'] != null) {
      itensList = json['itens'] as List<dynamic>;
    }

    return PedidoClienteModel(
      id: json['id'] as String,
      numeroPedido: int.tryParse(json['numero_pedido']?.toString() ?? ''),
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      status: json['status'] as String? ?? 'pendente',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      pagamentoMetodo: json['pagamento_metodo'] as String?,
      estabelecimentoNome: nomeFantasia,
      estabelecimentoLogoUrl: logoUrl,
      itensJson: itensList,
    );
  }

  // Helpers para a UI
  String get dataFormatada {
    final hoje = DateTime.now();
    final isHoje = createdAt.year == hoje.year &&
        createdAt.month == hoje.month &&
        createdAt.day == hoje.day;

    if (isHoje) {
      return 'Hoje, ${DateFormat('HH:mm').format(createdAt)}';
    } else {
      return '${DateFormat('dd MMM').format(createdAt)}, ${DateFormat('HH:mm').format(createdAt)}';
    }
  }

  int get quantidadeTotalItens {
    int total = 0;
    for (var item in itensJson) {
      if (item is Map) {
        final qtd = int.tryParse(item['quantidade']?.toString() ?? '1') ?? 1;
        total += qtd;
      }
    }
    return total;
  }

  String get resumoItensText {
    if (itensJson.isEmpty) return 'Nenhum item';

    List<String> nomes = [];
    for (var i = 0; i < itensJson.length && i < 2; i++) {
      var item = itensJson[i];
      if (item is Map && item['produto_nome'] != null) {
        String q = item['quantidade']?.toString() ?? '1';
        nomes.add("${q}x ${item['produto_nome']}");
      } else if (item is Map && item['nome'] != null) {
        String q = item['quantidade']?.toString() ?? '1';
        nomes.add("${q}x ${item['nome']}");
      }
    }

    String resumo = nomes.join(', ');
    if (itensJson.length > 2) {
      resumo += '...';
    }
    return resumo.isEmpty ? 'Itens do pedido' : resumo;
  }

  String get statusDisplay {
    switch (status) {
      case 'pendente':
        return 'aguardando';
      case 'confirmado':
        return 'preparando';
      case 'preparando':
        return 'preparando';
      case 'pronto':
        return 'pronto';
      case 'em_entrega':
        return 'a caminho';
      case 'entregue':
        return 'entregue';
      case 'cancelado_cliente':
      case 'cancelado_estab':
      case 'cancelado_sistema':
        return 'cancelado';
      default:
        return status;
    }
  }

  bool get isAtivo {
    return status != 'entregue' && !status.startsWith('cancelado');
  }
}
