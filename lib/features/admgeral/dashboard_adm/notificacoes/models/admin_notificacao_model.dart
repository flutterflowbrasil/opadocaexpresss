enum AdminNotificacaoPrioridade { urgente, atencao, info }

enum AdminNotificacaoTipo {
  cadastroPendente,
  chamadoUrgente,
  documentoPendente,
  pushFalhou,
  entregadorOnline,
  pushPendente,
}

class AdminNotificacaoModel {
  final String id;
  final AdminNotificacaoTipo tipo;
  final AdminNotificacaoPrioridade prioridade;
  final String titulo;
  final String descricao;
  final DateTime criadoEm;
  final String? entidadeId;
  final String? entidadeTipo;
  final String? rota; // 'entregadores' | 'estabelecimentos' | 'suporte' etc.

  const AdminNotificacaoModel({
    required this.id,
    required this.tipo,
    required this.prioridade,
    required this.titulo,
    required this.descricao,
    required this.criadoEm,
    this.entidadeId,
    this.entidadeTipo,
    this.rota,
  });

  String get iconLabel {
    return switch (tipo) {
      AdminNotificacaoTipo.cadastroPendente => '🧑‍💼',
      AdminNotificacaoTipo.chamadoUrgente => '🚨',
      AdminNotificacaoTipo.documentoPendente => '📄',
      AdminNotificacaoTipo.pushFalhou => '❌',
      AdminNotificacaoTipo.entregadorOnline => '🟢',
      AdminNotificacaoTipo.pushPendente => '🔔',
    };
  }

  String get tempoRelativo {
    final diff = DateTime.now().difference(criadoEm);
    if (diff.inMinutes < 1) return 'agora mesmo';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    return 'há ${diff.inDays}d';
  }
}
