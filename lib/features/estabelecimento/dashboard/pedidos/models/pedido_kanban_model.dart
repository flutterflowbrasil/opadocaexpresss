import 'package:flutter/foundation.dart';

@immutable
class ClienteResumoModel {
  final String? id;
  final String nome;
  final String? fotoUrl;

  const ClienteResumoModel({
    this.id,
    required this.nome,
    this.fotoUrl,
  });

  factory ClienteResumoModel.fromJson(Map<String, dynamic> json) {
    // Quando vem de um double inner join: clientes { usuarios { nome_completo_fantasia } }
    String nomeCliente = 'Cliente Padrão';
    String? foto;

    if (json['usuarios'] != null && json['usuarios'] is Map) {
      final userMap = json['usuarios'] as Map<String, dynamic>;
      nomeCliente = userMap['nome_completo_fantasia'] ??
          userMap['nome'] ??
          'Cliente Padrão';
    } else {
      // Fallback
      nomeCliente =
          json['nome_completo_fantasia'] ?? json['nome'] ?? 'Cliente Padrão';
    }

    foto = json['foto_perfil_url'] as String?;

    return ClienteResumoModel(
      id: json['id'] as String?,
      nome: nomeCliente,
      fotoUrl: foto,
    );
  }
}

@immutable
class PedidoKanbanModel {
  final String id;
  final int? numeroPedido;
  final String status;
  final double total;
  final DateTime createdAt;
  final ClienteResumoModel cliente;
  final String itensResumo; // Ex: "2x Café, 1x Pingado"

  const PedidoKanbanModel({
    required this.id,
    this.numeroPedido,
    required this.status,
    required this.total,
    required this.createdAt,
    required this.cliente,
    required this.itensResumo,
  });

  factory PedidoKanbanModel.fromJson(Map<String, dynamic> json) {
    // Parser do Cliente (Inner Join do Supabase devolve objeto se tiver 1:1 local)
    ClienteResumoModel clienteParsed;
    if (json['clientes'] != null && json['clientes'] is Map) {
      clienteParsed =
          ClienteResumoModel.fromJson(json['clientes'] as Map<String, dynamic>);
    } else {
      clienteParsed = const ClienteResumoModel(nome: 'Cliente Excluído');
    }

    // Processamento do Resumo de Itens (Limitado a 3 itens pra caber no card)
    String construindoResumo = '';
    final rawItens = json['itens'];
    if (rawItens != null && rawItens is List) {
      int count = 0;
      for (var row in rawItens) {
        if (count >= 2) {
          construindoResumo += '...';
          break; // Stop at 2 items + ellipsis for the summary
        }
        if (row is Map) {
          final prodJson = row['produto'] as Map<String, dynamic>?;
          final prodName = prodJson?['nome'] ?? 'Item';
          final qtd = row['quantidade'] ?? 1;
          construindoResumo += '${qtd}x $prodName, ';
          count++;
        }
      }
      if (construindoResumo.endsWith(', ')) {
        construindoResumo =
            construindoResumo.substring(0, construindoResumo.length - 2);
      }
    } else {
      construindoResumo = 'Ver detalhes...';
    }

    return PedidoKanbanModel(
      id: json['id'] as String,
      numeroPedido: json['numero_pedido'] as int?,
      status: json['status'] as String? ?? 'pendente',
      total: _parseToDouble(json['total']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      cliente: clienteParsed,
      itensResumo:
          construindoResumo.isEmpty ? 'Sem itens visíveis' : construindoResumo,
    );
  }

  PedidoKanbanModel copyWith({
    String? status,
  }) {
    return PedidoKanbanModel(
      id: id,
      numeroPedido: numeroPedido,
      status: status ?? this.status,
      total: total,
      createdAt: createdAt,
      cliente: cliente,
      itensResumo: itensResumo,
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
