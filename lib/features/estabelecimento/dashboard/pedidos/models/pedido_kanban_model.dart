import 'package:flutter/foundation.dart';

@immutable
class PedidoProdutoItemModel {
  final int q;
  final String n;
  final double p;

  const PedidoProdutoItemModel({
    required this.q,
    required this.n,
    required this.p,
  });

  factory PedidoProdutoItemModel.fromJson(Map<String, dynamic> json) {
    String nome = 'Item Sem Nome';
    double preco = 0.0;
    int qtd = json['quantidade'] ?? 1;

    if (json['produto'] != null && json['produto'] is Map) {
      nome = json['produto']['nome'] ?? nome;
      preco = double.tryParse(
              (json['preco_unitario'] ?? json['produto']['preco'] ?? '0')
                  .toString()) ??
          0.0;
    }

    return PedidoProdutoItemModel(q: qtd, n: nome, p: preco);
  }
}

@immutable
class PedidoKanbanModel {
  final String id;
  final int numero;
  final String cliente;
  final String tel;
  final List<PedidoProdutoItemModel> itens;
  final double total;
  final double tx;
  final String pgto;
  final String status;
  final DateTime at;
  final String end;
  final String? codigoColeta;

  const PedidoKanbanModel({
    required this.id,
    required this.numero,
    required this.cliente,
    required this.tel,
    required this.itens,
    required this.total,
    required this.tx,
    required this.pgto,
    required this.status,
    required this.at,
    required this.end,
    this.codigoColeta,
  });

  factory PedidoKanbanModel.fromJson(Map<String, dynamic> json) {
    // Parser do Cliente
    String nomeCliente = 'Cliente Padrão';
    String telefone = 'N/I';

    if (json['clientes'] != null && json['clientes'] is Map) {
      final userMap = json['clientes']['usuarios'];
      if (userMap != null) {
        nomeCliente =
            userMap['nome_completo_fantasia'] ?? userMap['nome'] ?? nomeCliente;
        telefone = userMap['telefone'] ?? telefone;
      }
    }

    // Parser dos Itens
    List<PedidoProdutoItemModel> listItens = [];
    final rawItens = json['itens'];
    if (rawItens != null && rawItens is List) {
      for (var row in rawItens) {
        if (row is Map<String, dynamic>) {
          listItens.add(PedidoProdutoItemModel.fromJson(row));
        }
      }
    }

    // Pagamento
    String pgtoStr = json['pagamento_metodo'] ?? 'Dinheiro';
    if (pgtoStr == 'cartao_credito') pgtoStr = 'credito';
    if (pgtoStr == 'cartao_debito') pgtoStr = 'debito';

    // Endereco
    String enderecoStr = 'Não informado';
    if (json['endereco_entrega_snapshot'] != null &&
        json['endereco_entrega_snapshot'] is Map) {
      final endJson = json['endereco_entrega_snapshot'];
      enderecoStr =
          "${endJson['logradouro'] ?? ''}, ${endJson['numero'] ?? ''} - ${endJson['bairro'] ?? ''}";
    }

    return PedidoKanbanModel(
      id: json['id'] as String,
      numero: json['numero_pedido'] as int? ?? 0,
      cliente: nomeCliente,
      tel: telefone,
      itens: listItens,
      total: _parseToDouble(json['total']),
      tx: _parseToDouble(json['taxa_entrega']),
      pgto: pgtoStr,
      status: json['status'] as String? ?? 'pendente',
      at: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      end: enderecoStr,
      codigoColeta: json['codigo_coleta_balcao'] as String?,
    );
  }

  PedidoKanbanModel copyWith({
    String? status,
    String? codigoColeta,
  }) {
    return PedidoKanbanModel(
      id: id,
      numero: numero,
      cliente: cliente,
      tel: tel,
      itens: itens,
      total: total,
      tx: tx,
      pgto: pgto,
      status: status ?? this.status,
      at: at,
      end: end,
      codigoColeta: codigoColeta ?? this.codigoColeta,
    );
  }

  static double _parseToDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is int) return val.toDouble();
    if (val is double) return val;
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }
}
