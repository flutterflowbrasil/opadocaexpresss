// Models da tela Suporte — painel admin

// ── SupporteChamado ───────────────────────────────────────────────────────────

class SupporteChamado {
  final String id;
  final String? usuarioId;
  final String? entregadorId;
  final String? pedidoId;
  final String categoria;        // pagamento|entrega|cliente|tecnico|outro
  final String descricao;
  final String status;           // aberto|em_atendimento|resolvido|fechado
  final String? respostaSuporte;
  final String? tipoSolicitante; // cliente|entregador|estabelecimento|admin
  final String prioridade;       // baixa|normal|alta|urgente
  final String? respondidoPor;
  final DateTime? respondidoEm;
  final DateTime? resolvidoEm;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Enriquecidos via join com usuarios
  final String? solicitanteNome;
  final String? solicitanteEmail;

  const SupporteChamado({
    required this.id,
    required this.categoria,
    required this.descricao,
    required this.status,
    required this.prioridade,
    required this.createdAt,
    required this.updatedAt,
    this.usuarioId,
    this.entregadorId,
    this.pedidoId,
    this.respostaSuporte,
    this.tipoSolicitante,
    this.respondidoPor,
    this.respondidoEm,
    this.resolvidoEm,
    this.solicitanteNome,
    this.solicitanteEmail,
  });

  factory SupporteChamado.fromJson(Map<String, dynamic> json) {
    // Extrai nome e email via join usuarios
    String? nome;
    String? email;
    final usuarioData = json['usuarios'];
    if (usuarioData is Map) {
      nome = usuarioData['nome_completo_fantasia'] as String?;
      email = usuarioData['email'] as String?;
    }

    return SupporteChamado(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String?,
      entregadorId: json['entregador_id'] as String?,
      pedidoId: json['pedido_id'] as String?,
      categoria: json['categoria'] as String? ?? 'outro',
      descricao: json['descricao'] as String? ?? '',
      status: json['status'] as String? ?? 'aberto',
      respostaSuporte: json['resposta_suporte'] as String?,
      tipoSolicitante: json['tipo_solicitante'] as String?,
      prioridade: json['prioridade'] as String? ?? 'normal',
      respondidoPor: json['respondido_por'] as String?,
      respondidoEm: json['respondido_em'] != null
          ? DateTime.tryParse(json['respondido_em'] as String)
          : null,
      resolvidoEm: json['resolvido_em'] != null
          ? DateTime.tryParse(json['resolvido_em'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      solicitanteNome: nome,
      solicitanteEmail: email,
    );
  }

  SupporteChamado copyWith({
    String? status,
    String? prioridade,
    String? respostaSuporte,
    String? respondidoPor,
    DateTime? respondidoEm,
    DateTime? resolvidoEm,
  }) {
    return SupporteChamado(
      id: id,
      usuarioId: usuarioId,
      entregadorId: entregadorId,
      pedidoId: pedidoId,
      categoria: categoria,
      descricao: descricao,
      status: status ?? this.status,
      respostaSuporte: respostaSuporte ?? this.respostaSuporte,
      tipoSolicitante: tipoSolicitante,
      prioridade: prioridade ?? this.prioridade,
      respondidoPor: respondidoPor ?? this.respondidoPor,
      respondidoEm: respondidoEm ?? this.respondidoEm,
      resolvidoEm: resolvidoEm ?? this.resolvidoEm,
      createdAt: createdAt,
      updatedAt: updatedAt,
      solicitanteNome: solicitanteNome,
      solicitanteEmail: solicitanteEmail,
    );
  }
}

// ── NotificacaoFila ───────────────────────────────────────────────────────────

class NotificacaoFila {
  final String id;
  final String usuarioId;
  final String evento;
  final String titulo;
  final String corpo;
  final String status; // pendente|processando|enviado|falhou|ignorado
  final int tentativas;
  final int maxTentativas;
  final String? erroCodigo;
  final String? erroDetalhe;
  final DateTime createdAt;

  const NotificacaoFila({
    required this.id,
    required this.usuarioId,
    required this.evento,
    required this.titulo,
    required this.corpo,
    required this.status,
    required this.tentativas,
    required this.maxTentativas,
    required this.createdAt,
    this.erroCodigo,
    this.erroDetalhe,
  });

  factory NotificacaoFila.fromJson(Map<String, dynamic> json) {
    return NotificacaoFila(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String? ?? '',
      evento: json['evento'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      corpo: json['corpo'] as String? ?? '',
      status: json['status'] as String? ?? 'pendente',
      tentativas: (json['tentativas'] as num?)?.toInt() ?? 0,
      maxTentativas: (json['max_tentativas'] as num?)?.toInt() ?? 3,
      erroCodigo: json['erro_codigo'] as String?,
      erroDetalhe: json['erro_detalhe'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

// ── Avaliacao ─────────────────────────────────────────────────────────────────

class Avaliacao {
  final String id;
  final String pedidoId;
  final String clienteId;
  final String estabelecimentoId;
  final String? entregadorId;
  final double? notaEstabelecimento;
  final double? notaEntregador;
  final String? comentarioEstabelecimento;
  final String? comentarioEntregador;
  final DateTime createdAt;

  // Enriquecidos via join
  final String? clienteNome;
  final String? estabNome;

  const Avaliacao({
    required this.id,
    required this.pedidoId,
    required this.clienteId,
    required this.estabelecimentoId,
    required this.createdAt,
    this.entregadorId,
    this.notaEstabelecimento,
    this.notaEntregador,
    this.comentarioEstabelecimento,
    this.comentarioEntregador,
    this.clienteNome,
    this.estabNome,
  });

  factory Avaliacao.fromJson(Map<String, dynamic> json) {
    // Extrai nome do cliente via join clientes → usuarios
    String? clienteNome;
    final clienteData = json['clientes'];
    if (clienteData is Map) {
      final usuarioData = clienteData['usuarios'];
      if (usuarioData is Map) {
        clienteNome = usuarioData['nome_completo_fantasia'] as String?;
      }
    }

    // Extrai nome do estabelecimento
    String? estabNome;
    final estabData = json['estabelecimentos'];
    if (estabData is Map) {
      estabNome = estabData['nome_fantasia'] as String?;
    }

    return Avaliacao(
      id: json['id'] as String,
      pedidoId: json['pedido_id'] as String,
      clienteId: json['cliente_id'] as String,
      estabelecimentoId: json['estabelecimento_id'] as String,
      entregadorId: json['entregador_id'] as String?,
      notaEstabelecimento: (json['nota_estabelecimento'] as num?)?.toDouble(),
      notaEntregador: (json['nota_entregador'] as num?)?.toDouble(),
      comentarioEstabelecimento: json['comentario_estabelecimento'] as String?,
      comentarioEntregador: json['comentario_entregador'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      clienteNome: clienteNome,
      estabNome: estabNome,
    );
  }
}
