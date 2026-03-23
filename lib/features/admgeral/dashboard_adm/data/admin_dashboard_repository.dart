import 'package:supabase_flutter/supabase_flutter.dart';

enum DashboardPeriod { hoje, semana, mes, ano }

extension DashboardPeriodX on DashboardPeriod {
  String get label {
    switch (this) {
      case DashboardPeriod.hoje:
        return 'Hoje';
      case DashboardPeriod.semana:
        return '7 dias';
      case DashboardPeriod.mes:
        return 'Mês';
      case DashboardPeriod.ano:
        return 'Ano';
    }
  }

  /// Data de início do período atual (UTC — bate com timestamps do Supabase).
  DateTime get startDate {
    final now = DateTime.now().toUtc();
    switch (this) {
      case DashboardPeriod.hoje:
        return DateTime.utc(now.year, now.month, now.day);
      case DashboardPeriod.semana:
        return DateTime.utc(now.year, now.month, now.day)
            .subtract(const Duration(days: 7));
      case DashboardPeriod.mes:
        return DateTime.utc(now.year, now.month, 1);
      case DashboardPeriod.ano:
        return DateTime.utc(now.year, 1, 1);
    }
  }

  /// Data de início do período ANTERIOR ao atual (para calcular deltas).
  DateTime get prevStartDate {
    final now = DateTime.now().toUtc();
    switch (this) {
      case DashboardPeriod.hoje:
        // ontem
        return DateTime.utc(now.year, now.month, now.day)
            .subtract(const Duration(days: 1));
      case DashboardPeriod.semana:
        // 7 a 14 dias atrás
        return DateTime.utc(now.year, now.month, now.day)
            .subtract(const Duration(days: 14));
      case DashboardPeriod.mes:
        // mês anterior
        final firstOfThisMonth = DateTime.utc(now.year, now.month, 1);
        return DateTime.utc(
          firstOfThisMonth.year,
          firstOfThisMonth.month - 1 == 0 ? 12 : firstOfThisMonth.month - 1,
          1,
        );
      case DashboardPeriod.ano:
        // ano anterior
        return DateTime.utc(now.year - 1, 1, 1);
    }
  }

  /// Data de fim do período ANTERIOR (exclusive — igual ao startDate atual).
  DateTime get prevEndDate => startDate;
}

class AdminDashboardRepository {
  final SupabaseClient _supabase;

  AdminDashboardRepository(this._supabase);

  /// Busca estatísticas do período atual e do período anterior em paralelo.
  Future<Map<String, dynamic>> fetchDashboardStats(DashboardPeriod period) async {
    final startIso = period.startDate.toIso8601String();
    final prevStartIso = period.prevStartDate.toIso8601String();
    final prevEndIso = period.prevEndDate.toIso8601String();

    try {
      final responses = await Future.wait([
        // 0: estabelecimentos — sem filtro de período (dados cadastrais)
        _supabase
            .from('estabelecimentos')
            .select('id, status_cadastro, status_aberto, avaliacao_media, razao_social, logo_url, created_at'),

        // 1: entregadores — sem filtro de período
        _supabase
            .from('entregadores')
            .select('id, status_cadastro, status_online, created_at'),

        // 2: usuários NO período atual
        _supabase
            .from('usuarios')
            .select('id, tipo_usuario, created_at')
            .gte('created_at', startIso),

        // 3: pedidos NO período atual
        _supabase
            .from('pedidos')
            .select('id, status, total, created_at')
            .gte('created_at', startIso)
            .order('created_at', ascending: false),

        // 4: splits NO período atual
        _supabase
            .from('splits_pagamento')
            .select('plataforma_valor, status, created_at')
            .gte('created_at', startIso),

        // 5: chamados abertos (sempre atual)
        _supabase
            .from('suporte_chamados')
            .select('id, categoria, descricao, status, created_at')
            .eq('status', 'aberto')
            .order('created_at', ascending: false)
            .limit(20),

        // 6: pedidos do PERÍODO ANTERIOR (para delta)
        _supabase
            .from('pedidos')
            .select('id, status, total, created_at')
            .gte('created_at', prevStartIso)
            .lt('created_at', prevEndIso),

        // 7: splits do PERÍODO ANTERIOR (para delta receita plataforma)
        _supabase
            .from('splits_pagamento')
            .select('plataforma_valor, created_at')
            .gte('created_at', prevStartIso)
            .lt('created_at', prevEndIso),

        // 8: usuários do PERÍODO ANTERIOR (para delta)
        _supabase
            .from('usuarios')
            .select('id, created_at')
            .gte('created_at', prevStartIso)
            .lt('created_at', prevEndIso),
      ]);

      return {
        'estabelecimentos': responses[0],
        'entregadores': responses[1],
        'usuarios': responses[2],
        'pedidos': responses[3],
        'splits': responses[4],
        'chamados': responses[5],
        'pedidos_prev': responses[6],
        'splits_prev': responses[7],
        'usuarios_prev': responses[8],
      };
    } catch (e) {
      throw Exception('Erro ao carregar dados do dashboard: $e');
    }
  }

  /// Busca os dados para o gráfico de barras de receita da plataforma.
  ///
  /// Retorna uma lista de [ChartDataPoint] com data, faturamento bruto e
  /// receita da plataforma, agrupados por dia nos últimos [days] dias.
  Future<List<ChartDataPoint>> fetchChartData({int days = 7}) async {
    final now = DateTime.now().toUtc();
    final startDate = DateTime.utc(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));
    final startIso = startDate.toIso8601String();

    try {
      final results = await Future.wait([
        _supabase
            .from('pedidos')
            .select('total, status, created_at')
            .gte('created_at', startIso)
            .order('created_at', ascending: true),
        _supabase
            .from('splits_pagamento')
            .select('plataforma_valor, created_at')
            .gte('created_at', startIso)
            .order('created_at', ascending: true),
      ]);

      final pedidos = (results[0] as List).cast<Map<String, dynamic>>();
      final splits = (results[1] as List).cast<Map<String, dynamic>>();

      // Gera um map de dia → acumuladores
      final Map<DateTime, _DayAccumulator> map = {};
      for (int i = 0; i < days; i++) {
        final day = DateTime.utc(startDate.year, startDate.month, startDate.day + i);
        map[day] = _DayAccumulator();
      }

      // Agrega pedidos entregues por dia
      for (final p in pedidos) {
        if (p['status'] != 'entregue') continue;
        final raw = p['created_at'] as String?;
        if (raw == null) continue;
        final dt = DateTime.parse(raw).toUtc();
        final day = DateTime.utc(dt.year, dt.month, dt.day);
        map[day]?.bruto += (p['total'] as num?)?.toDouble() ?? 0.0;
      }

      // Agrega splits por dia
      for (final s in splits) {
        final raw = s['created_at'] as String?;
        if (raw == null) continue;
        final dt = DateTime.parse(raw).toUtc();
        final day = DateTime.utc(dt.year, dt.month, dt.day);
        map[day]?.plataforma += (s['plataforma_valor'] as num?)?.toDouble() ?? 0.0;
      }

      return map.entries
          .map((e) => ChartDataPoint(
                date: e.key,
                faturamentoBruto: e.value.bruto,
                receitaPlataforma: e.value.plataforma,
              ))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    } catch (_) {
      // Retorna lista vazia em caso de erro — o widget exibirá empty state
      return [];
    }
  }
}

class _DayAccumulator {
  double bruto = 0.0;
  double plataforma = 0.0;
}

class ChartDataPoint {
  final DateTime date;
  final double faturamentoBruto;
  final double receitaPlataforma;

  const ChartDataPoint({
    required this.date,
    required this.faturamentoBruto,
    required this.receitaPlataforma,
  });
}
