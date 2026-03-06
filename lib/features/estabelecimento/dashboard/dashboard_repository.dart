import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:padoca_express/core/supabase/supabase_config.dart';

class DashboardRepository {
  final SupabaseClient _supabase;

  DashboardRepository(this._supabase);

  Future<Map<String, dynamic>?> getEstabelecimentoLogado() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('estabelecimentos')
          .select(
              'id, razao_social, nome_fantasia, avaliacao_media, status_aberto')
          .eq('usuario_id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateStoreStatus(String estabelecimentoId, bool isAberta,
      {String? motivoFechamento}) async {
    try {
      final updateData = <String, dynamic>{
        'status_aberto': isAberta,
      };

      // Se houvesse uma coluna para motivo, adicionaríamos aqui.
      // O SQL não mostrou uma coluna clara para "motivo_fechamento",
      // então por enquanto eu vou apenas mudar o status.

      await _supabase
          .from('estabelecimentos')
          .update(updateData)
          .eq('id', estabelecimentoId);
      return true;
    } catch (e) {
      print('Erro ao atualizar status da loja: $e');
      return false;
    }
  }

  /// Busca as métricas consolidadas (Vendas, KPIs, Ranking e Funil) de uma única vez
  /// reduzindo chamadas N+1 e aggregando dados no Dart.
  Future<Map<String, dynamic>> getDashboardMetrics(
      String estabelecimentoId, DateTime dataInicio, DateTime dataFim) async {
    final isoInicio = dataInicio.toUtc().toIso8601String();
    final isoFim = dataFim.toUtc().toIso8601String();

    // 1. Calculate previous period
    final duration = dataFim.difference(dataInicio);
    final prevInicio = dataInicio.subtract(duration);
    final prevFim = dataFim.subtract(duration);
    final isoPrevInicio = prevInicio.toUtc().toIso8601String();
    final isoPrevFim = prevFim.toUtc().toIso8601String();

    try {
      // 2. Fetch Current Period Orders
      final responsePedidos = await _supabase
          .from('pedidos')
          .select('id, total, status, created_at, cliente_id')
          .eq('estabelecimento_id', estabelecimentoId)
          .gte('created_at', isoInicio)
          .lte('created_at', isoFim);

      final pedidos = List<Map<String, dynamic>>.from(responsePedidos);

      // 3. Fetch Previous Period Orders
      final responsePrevPedidos = await _supabase
          .from('pedidos')
          .select('id, total, status')
          .eq('estabelecimento_id', estabelecimentoId)
          .gte('created_at', isoPrevInicio)
          .lte('created_at', isoPrevFim);

      final prevPedidos = List<Map<String, dynamic>>.from(responsePrevPedidos);

      // --- Current Period Aggregation ---
      double vendasTotal = 0.0;
      int ativos = 0;
      int pendentes = 0,
          confirmados = 0,
          preparando = 0,
          prontos = 0,
          emEntrega = 0,
          entregues = 0;

      Map<String, double> vendasPorDia = {};
      final uniqueClients = <String>{};

      // Define grouping based on duration (if today <= 24h, group by hour, else day)
      final isHoje = duration.inHours <= 24;

      for (var p in pedidos) {
        final status = p['status'] as String;
        final totalStr = p['total'];
        final total = (totalStr is num) ? totalStr.toDouble() : 0.0;
        final dateStr = p['created_at'] as String;
        final parsedDate = DateTime.parse(dateStr).toLocal();

        String chartKey;
        if (isHoje) {
          chartKey = "${parsedDate.hour}h";
        } else {
          chartKey =
              "${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}";
        }

        if (p['cliente_id'] != null) {
          uniqueClients.add(p['cliente_id'].toString());
        }

        // Se o pedido não foi cancelado, ele conta para o faturamento (Vendas e Gráfico)
        final isCancelado = status == 'cancelado_cliente' ||
            status == 'cancelado_estab' ||
            status == 'cancelado_sistema';

        if (!isCancelado) {
          vendasTotal += total;
          vendasPorDia[chartKey] = (vendasPorDia[chartKey] ?? 0.0) + total;
        }

        if (status == 'pendente') {
          pendentes++;
        } else if (status == 'aceito' || status == 'confirmado') {
          confirmados++;
        } else if (status == 'preparando') {
          preparando++;
        } else if (status == 'pronto' || status == 'aguardando_entregador') {
          prontos++;
        } else if (status == 'em_entrega') {
          emEntrega++;
        } else if (status == 'entregue') {
          entregues++;
        }

        if (!isCancelado && status != 'entregue') {
          ativos++;
        }
      }

      int totalValidos = pedidos.length -
          (pedidos
              .where((p) => p['status']?.contains('cancelado') == true)
              .length);
      double ticketMedio = totalValidos > 0 ? vendasTotal / totalValidos : 0.0;

      // --- Previous Period Aggregation ---
      double prevVendasTotal = 0.0;
      int prevTotalValidos = 0;

      for (var p in prevPedidos) {
        final status = p['status'] as String;
        final totalStr = p['total'];
        final total = (totalStr is num) ? totalStr.toDouble() : 0.0;

        final isCancelado = status == 'cancelado_cliente' ||
            status == 'cancelado_estab' ||
            status == 'cancelado_sistema';

        if (!isCancelado) {
          prevVendasTotal += total;
          prevTotalValidos++;
        }
      }

      double prevTicketMedio =
          prevTotalValidos > 0 ? prevVendasTotal / prevTotalValidos : 0.0;
      int totalPrevPedidos = prevPedidos.length;

      // Deltas
      double deltaVendas = prevVendasTotal > 0
          ? ((vendasTotal - prevVendasTotal) / prevVendasTotal) * 100
          : (vendasTotal > 0 ? 100.0 : 0.0);
      int deltaPedidos = pedidos.length - totalPrevPedidos;
      double deltaTicket = prevTicketMedio > 0
          ? ((ticketMedio - prevTicketMedio) / prevTicketMedio) * 100
          : (ticketMedio > 0 ? 100.0 : 0.0);

      // --- Customers (Donut) ---
      int clientesNovos = 0;
      int clientesRecorrentes = 0;

      if (uniqueClients.isNotEmpty) {
        // Find if these clients had any orders before ISO inicio
        final responseHistorico = await _supabase
            .from('pedidos')
            .select('cliente_id, id')
            .eq('estabelecimento_id', estabelecimentoId)
            .inFilter('cliente_id', uniqueClients.toList())
            .lt('created_at', isoInicio);

        final historico = List<Map<String, dynamic>>.from(responseHistorico);
        final clientesComHIstorico =
            historico.map((e) => e['cliente_id'].toString()).toSet();

        for (var c in uniqueClients) {
          if (clientesComHIstorico.contains(c)) {
            clientesRecorrentes++;
          } else {
            clientesNovos++;
          }
        }
      }

      // --- Ranking ---
      // Collect valid pedido IDs to filter itens_pedido
      final validPedidoIds = pedidos
          .where((p) {
            final status = p['status'] as String;
            return !status.startsWith('cancelado');
          })
          .map((p) => p['id'].toString())
          .toList();

      List<Map<String, dynamic>> ranking =
          await _getMaisVendidos(validPedidoIds);

      return {
        'vendasTotal': vendasTotal,
        'pedidosAtivos': ativos,
        'ticketMedio': ticketMedio,
        'totalPedidos': pedidos.length,
        'pendentes': pendentes,
        'confirmados': confirmados,
        'preparando': preparando,
        'prontos': prontos,
        'emEntrega': emEntrega,
        'entregues': entregues,
        'vendasPorDia': vendasPorDia,
        'ranking': ranking,
        'clientesUnicos': uniqueClients.length,
        'clientesNovos': clientesNovos,
        'clientesRecorrentes': clientesRecorrentes,
        'deltaVendas': double.parse(deltaVendas.toStringAsFixed(1)),
        'deltaPedidos': deltaPedidos,
        'deltaTicket': double.parse(deltaTicket.toStringAsFixed(1)),
      };
    } catch (e) {
      throw Exception('Erro ao carregar métricas do dashboard: $e');
    }
  }

  /// Busca os itens mais vendidos dado uma lista de IDs de pedidos válidos
  Future<List<Map<String, dynamic>>> _getMaisVendidos(
      List<String> pedidoIds) async {
    if (pedidoIds.isEmpty) return [];

    try {
      final res = await _supabase
          .from('itens_pedido')
          .select('quantidade, total, produto_id, produtos(nome, preco)')
          .inFilter('pedido_id', pedidoIds);

      final List itens = List<Map<String, dynamic>>.from(res);

      Map<String, Map<String, dynamic>> aggregates = {};

      for (var item in itens) {
        String pId = item['produto_id'].toString();
        var prod = item['produtos'];
        if (prod == null) continue;

        int qtd = (item['quantidade'] as num).toInt();
        double lineTotal = (item['total'] as num).toDouble();

        if (aggregates.containsKey(pId)) {
          aggregates[pId]!['vendidos'] += qtd;
          aggregates[pId]!['receita'] += lineTotal;
        } else {
          aggregates[pId] = {
            'nome': prod['nome'] ?? 'Desconhecido',
            'preco': (prod['preco'] as num?)?.toDouble() ?? 0.0,
            'foto': '📦',
            'vendidos': qtd,
            'receita': lineTotal,
          };
        }
      }

      var list = aggregates.values.toList();
      list.sort(
          (a, b) => (b['vendidos'] as int).compareTo(a['vendidos'] as int));
      return list.take(5).toList();
    } catch (e) {
      // Fallback silencioso — ranking não bloqueia o Dashboard
      return [];
    }
  }

  // Toggles the store status
  Future<void> toggleStatusLoja(String estabelecimentoId, bool isOpen) async {
    await _supabase
        .from('estabelecimentos')
        .update({'is_aberto': isOpen}).eq('id', estabelecimentoId);
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return DashboardRepository(supabase);
});
