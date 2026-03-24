// ── Modelos brutos ─────────────────────────────────────────────────────────────

class PedidoResumo {
  final String id;
  final String status;
  final String? pagamentoStatus;
  final String? pagamentoMetodo;
  final double subtotalProdutos;
  final double taxaEntrega;
  final double taxaServicApp;
  final double descontoCupom;
  final double total;
  final bool splitProcessado;
  final String? entregadorId;
  final DateTime createdAt;

  const PedidoResumo({
    required this.id,
    required this.status,
    this.pagamentoStatus,
    this.pagamentoMetodo,
    this.subtotalProdutos = 0,
    this.taxaEntrega = 0,
    this.taxaServicApp = 0,
    this.descontoCupom = 0,
    this.total = 0,
    this.splitProcessado = false,
    this.entregadorId,
    required this.createdAt,
  });

  factory PedidoResumo.fromMap(Map<String, dynamic> m) => PedidoResumo(
        id: m['id'] as String,
        status: m['status'] as String? ?? '',
        pagamentoStatus: m['pagamento_status'] as String?,
        pagamentoMetodo: m['pagamento_metodo'] as String?,
        subtotalProdutos: (m['subtotal_produtos'] as num?)?.toDouble() ?? 0,
        taxaEntrega: (m['taxa_entrega'] as num?)?.toDouble() ?? 0,
        taxaServicApp: (m['taxa_servico_app'] as num?)?.toDouble() ?? 0,
        descontoCupom: (m['desconto_cupom'] as num?)?.toDouble() ?? 0,
        total: (m['total'] as num?)?.toDouble() ?? 0,
        splitProcessado: m['split_processado'] as bool? ?? false,
        entregadorId: m['entregador_id'] as String?,
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}

class UsuarioResumo {
  final String id;
  final String tipoUsuario;
  final String status;
  final bool emailVerificado;
  final bool telefoneVerificado;
  final DateTime createdAt;

  const UsuarioResumo({
    required this.id,
    required this.tipoUsuario,
    required this.status,
    this.emailVerificado = false,
    this.telefoneVerificado = false,
    required this.createdAt,
  });

  factory UsuarioResumo.fromMap(Map<String, dynamic> m) => UsuarioResumo(
        id: m['id'] as String,
        tipoUsuario: m['tipo_usuario'] as String? ?? 'cliente',
        status: m['status'] as String? ?? 'ativo',
        emailVerificado: m['email_verificado'] as bool? ?? false,
        telefoneVerificado: m['telefone_verificado'] as bool? ?? false,
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}

class EntregadorResumo {
  final String id;
  final String statusCadastro;
  final String tipoVeiculo;
  final int totalEntregas;
  final double avaliacaoMedia;
  final double ganhosTotal;
  final bool statusOnline;
  final String? usuarioId;

  const EntregadorResumo({
    required this.id,
    required this.statusCadastro,
    this.tipoVeiculo = 'moto',
    this.totalEntregas = 0,
    this.avaliacaoMedia = 0,
    this.ganhosTotal = 0,
    this.statusOnline = false,
    this.usuarioId,
  });

  factory EntregadorResumo.fromMap(Map<String, dynamic> m) => EntregadorResumo(
        id: m['id'] as String,
        statusCadastro: m['status_cadastro'] as String? ?? 'pendente',
        tipoVeiculo: m['tipo_veiculo'] as String? ?? 'moto',
        totalEntregas: (m['total_entregas'] as num?)?.toInt() ?? 0,
        avaliacaoMedia: (m['avaliacao_media'] as num?)?.toDouble() ?? 0,
        ganhosTotal: (m['ganhos_total'] as num?)?.toDouble() ?? 0,
        statusOnline: m['status_online'] as bool? ?? false,
        usuarioId: m['usuario_id'] as String?,
      );
}

class EstabelecimentoResumo {
  final String id;
  final String nomeFantasia;
  final String statusCadastro;
  final int totalPedidos;
  final double faturamentoTotal;
  final double avaliacaoMedia;
  final DateTime? createdAt;

  const EstabelecimentoResumo({
    required this.id,
    required this.nomeFantasia,
    required this.statusCadastro,
    this.totalPedidos = 0,
    this.faturamentoTotal = 0,
    this.avaliacaoMedia = 0,
    this.createdAt,
  });

  factory EstabelecimentoResumo.fromMap(Map<String, dynamic> m) =>
      EstabelecimentoResumo(
        id: m['id'] as String,
        nomeFantasia: m['nome_fantasia'] as String? ?? 'Estabelecimento',
        statusCadastro: m['status_cadastro'] as String? ?? 'pendente',
        totalPedidos: (m['total_pedidos'] as num?)?.toInt() ?? 0,
        faturamentoTotal: (m['faturamento_total'] as num?)?.toDouble() ?? 0,
        avaliacaoMedia: (m['avaliacao_media'] as num?)?.toDouble() ?? 0,
        createdAt: m['created_at'] != null
            ? DateTime.tryParse(m['created_at'] as String)
            : null,
      );
}

class AvaliacaoResumo {
  final String id;
  final double? notaEstabelecimento;
  final double? notaEntregador;
  final DateTime createdAt;

  const AvaliacaoResumo({
    required this.id,
    this.notaEstabelecimento,
    this.notaEntregador,
    required this.createdAt,
  });

  factory AvaliacaoResumo.fromMap(Map<String, dynamic> m) => AvaliacaoResumo(
        id: m['id'] as String,
        notaEstabelecimento: (m['nota_estabelecimento'] as num?)?.toDouble(),
        notaEntregador: (m['nota_entregador'] as num?)?.toDouble(),
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}

class ChamadoResumo {
  final String id;
  final String categoria;
  final String status;
  final String prioridade;
  final DateTime createdAt;

  const ChamadoResumo({
    required this.id,
    required this.categoria,
    required this.status,
    required this.prioridade,
    required this.createdAt,
  });

  factory ChamadoResumo.fromMap(Map<String, dynamic> m) => ChamadoResumo(
        id: m['id'] as String,
        categoria: m['categoria'] as String? ?? 'outro',
        status: m['status'] as String? ?? 'aberto',
        prioridade: m['prioridade'] as String? ?? 'normal',
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}

// ── Snapshot aggregado ────────────────────────────────────────────────────────

class RelatorioSnapshot {
  final List<PedidoResumo> pedidos;
  final List<UsuarioResumo> usuarios;
  final List<EntregadorResumo> entregadores;
  final List<EstabelecimentoResumo> estabelecimentos;
  final List<AvaliacaoResumo> avaliacoes;
  final List<ChamadoResumo> chamados;

  const RelatorioSnapshot({
    this.pedidos = const [],
    this.usuarios = const [],
    this.entregadores = const [],
    this.estabelecimentos = const [],
    this.avaliacoes = const [],
    this.chamados = const [],
  });

  // ── KPIs globais ──────────────────────────────────────────────────────────

  List<PedidoResumo> get pedidosEntregues =>
      pedidos.where((p) => p.status == 'entregue').toList();

  List<PedidoResumo> get pedidosCancelados =>
      pedidos.where((p) => p.status.contains('cancelado')).toList();

  List<PedidoResumo> get pedidosPagos => pedidos
      .where((p) =>
          p.pagamentoStatus == 'pago' || p.pagamentoStatus == 'confirmed')
      .toList();

  double get receitaTotal =>
      pedidosEntregues.fold(0, (a, p) => a + p.total);

  double get plataformaTotal =>
      pedidosEntregues.fold(0, (a, p) => a + p.taxaServicApp);

  double get ticketMedio =>
      pedidosEntregues.isEmpty ? 0 : receitaTotal / pedidosEntregues.length;

  double get taxaCancelamento =>
      pedidos.isEmpty ? 0 : (pedidosCancelados.length / pedidos.length) * 100;

  double get taxaConversao => pedidos.isEmpty
      ? 0
      : (pedidosPagos.length / pedidos.length) * 100;

  double get takeRate =>
      receitaTotal > 0 ? (plataformaTotal / receitaTotal) * 100 : 5.0;

  int get totalUsuarios => usuarios.length;
  int get totalClientes =>
      usuarios.where((u) => u.tipoUsuario == 'cliente').length;
  int get totalEntregadores => entregadores.length;
  int get totalEstabs => estabelecimentos.length;
  int get entregadoresOnline =>
      entregadores.where((e) => e.statusOnline).length;
  int get entregadoresAprovados =>
      entregadores.where((e) => e.statusCadastro == 'aprovado').length;

  // ── Receita por mês ───────────────────────────────────────────────────────

  List<Map<String, dynamic>> get receitaPorMes {
    final mapa = <String, Map<String, dynamic>>{};
    for (final p in pedidos) {
      final key =
          '${p.createdAt.year}-${p.createdAt.month.toString().padLeft(2, '0')}';
      mapa.putIfAbsent(
        key,
        () => {
          'key': key,
          'mes': _mesAbrev(p.createdAt.month),
          'receita': 0.0,
          'plataforma': 0.0,
          'pedidos': 0,
          'cancelados': 0,
        },
      );
      mapa[key]!['pedidos'] = (mapa[key]!['pedidos'] as int) + 1;
      if (p.status == 'entregue') {
        mapa[key]!['receita'] =
            (mapa[key]!['receita'] as double) + p.total;
        mapa[key]!['plataforma'] =
            (mapa[key]!['plataforma'] as double) + p.taxaServicApp;
      }
      if (p.status.contains('cancelado')) {
        mapa[key]!['cancelados'] = (mapa[key]!['cancelados'] as int) + 1;
      }
    }
    final lista = mapa.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return lista.map((e) => e.value).toList();
  }

  // ── Pedidos por dia da semana ─────────────────────────────────────────────

  List<Map<String, dynamic>> get pedidosPorDia {
    const dias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    final now = DateTime.now();
    final mapa = {
      for (final d in dias) d: {'dia': d, 'pedidos': 0, 'receita': 0.0}
    };
    for (final p in pedidos) {
      if (now.difference(p.createdAt).inDays <= 7) {
        final dia = dias[p.createdAt.weekday - 1];
        mapa[dia]!['pedidos'] = (mapa[dia]!['pedidos'] as int) + 1;
        mapa[dia]!['receita'] =
            (mapa[dia]!['receita'] as double) + p.total;
      }
    }
    return dias.map((d) => mapa[d]!).toList();
  }

  // ── Distribuição método de pagamento ─────────────────────────────────────

  Map<String, int> get distMetodoPagamento {
    final m = <String, int>{'PIX': 0, 'Crédito': 0, 'Débito': 0, 'Dinheiro': 0};
    for (final p in pedidos) {
      switch (p.pagamentoMetodo?.toLowerCase()) {
        case 'pix':
          m['PIX'] = m['PIX']! + 1;
          break;
        case 'credit_card':
        case 'cartao_credito':
          m['Crédito'] = m['Crédito']! + 1;
          break;
        case 'debit_card':
        case 'cartao_debito':
          m['Débito'] = m['Débito']! + 1;
          break;
        case 'cash':
        case 'dinheiro':
          m['Dinheiro'] = m['Dinheiro']! + 1;
          break;
      }
    }
    return m;
  }

  // ── Funil de conversão ────────────────────────────────────────────────────

  List<Map<String, dynamic>> get funil {
    final total = pedidos.length;
    final pagos = pedidosPagos.length;
    final comEntregador =
        pedidos.where((p) => p.entregadorId != null).length;
    final entregues = pedidosEntregues.length;
    return [
      {
        'etapa': 'Pedidos criados',
        'valor': total,
        'pct': total > 0 ? 100 : 0,
      },
      {
        'etapa': 'Pagamentos confirmados',
        'valor': pagos,
        'pct': total > 0 ? (pagos / total * 100).round() : 0,
      },
      {
        'etapa': 'Aceitos por entregador',
        'valor': comEntregador,
        'pct': total > 0 ? (comEntregador / total * 100).round() : 0,
      },
      {
        'etapa': 'Entregues',
        'valor': entregues,
        'pct': total > 0 ? (entregues / total * 100).round() : 0,
      },
    ];
  }

  // ── Crescimento de usuários por mês ───────────────────────────────────────

  List<Map<String, dynamic>> get crescimentoUsuarios {
    final mapa = <String, Map<String, dynamic>>{};
    for (final u in usuarios) {
      final key =
          '${u.createdAt.year}-${u.createdAt.month.toString().padLeft(2, '0')}';
      mapa.putIfAbsent(
        key,
        () => {
          'key': key,
          'mes':
              '${_mesAbrev(u.createdAt.month)}/${u.createdAt.year.toString().substring(2)}',
          'clientes': 0,
          'entregadores': 0,
          'estabelecimentos': 0,
        },
      );
      switch (u.tipoUsuario) {
        case 'cliente':
          mapa[key]!['clientes'] = (mapa[key]!['clientes'] as int) + 1;
          break;
        case 'entregador':
          mapa[key]!['entregadores'] =
              (mapa[key]!['entregadores'] as int) + 1;
          break;
        case 'estabelecimento':
          mapa[key]!['estabelecimentos'] =
              (mapa[key]!['estabelecimentos'] as int) + 1;
          break;
      }
    }
    final lista = mapa.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return lista.map((e) => e.value).toList();
  }

  // ── Distribuição de notas ─────────────────────────────────────────────────

  List<Map<String, dynamic>> get distNotas => [5, 4, 3, 2, 1]
      .map((n) => {
            'nota': '$n★',
            'estab': avaliacoes
                .where((a) => a.notaEstabelecimento?.round() == n)
                .length,
            'entregador': avaliacoes
                .where((a) => a.notaEntregador?.round() == n)
                .length,
          })
      .toList();

  // ── Chamados por categoria ────────────────────────────────────────────────

  List<Map<String, dynamic>> get chamadosPorCategoria =>
      ['Pagamento', 'Entrega', 'Técnico', 'Cliente', 'Outro'].map((c) {
        final todos = chamados
            .where((ch) => ch.categoria.toLowerCase() == c.toLowerCase())
            .toList();
        final resolvidos = todos
            .where((ch) =>
                ch.status == 'resolvido' || ch.status == 'fechado')
            .length;
        return {
          'cat': c,
          'total': todos.length,
          'abertos': todos.length - resolvidos,
          'resolvidos': resolvidos,
        };
      }).toList();

  static String _mesAbrev(int month) {
    const nomes = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return nomes[month - 1];
  }
}
