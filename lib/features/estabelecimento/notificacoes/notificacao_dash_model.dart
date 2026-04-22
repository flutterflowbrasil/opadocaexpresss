// lib/features/estabelecimento/notificacoes/notificacao_dash_model.dart

enum NotifTipo { novoPedido, alerta, info }

class NotificacaoDashModel {
  final String id;
  final NotifTipo tipo;
  final String titulo;
  final String mensagem;
  final String? pedidoId;
  final String? numeroPedido;
  final DateTime criadoEm;
  bool lida;

  NotificacaoDashModel({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensagem,
    this.pedidoId,
    this.numeroPedido,
    DateTime? criadoEm,
    this.lida = false,
  }) : criadoEm = criadoEm ?? DateTime.now();

  String get rotaDestino {
    if (pedidoId != null) {
      return '/dashboard_estabelecimento/pedidos';
    }
    return '/dashboard_estabelecimento';
  }
}
