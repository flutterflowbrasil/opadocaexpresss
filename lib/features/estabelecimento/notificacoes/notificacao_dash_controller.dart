// lib/features/estabelecimento/notificacoes/notificacao_dash_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notificacao_dash_model.dart';

class NotificacaoDashState {
  final List<NotificacaoDashModel> notificacoes;
  final bool somAtivo;
  final bool notifAtiva;

  const NotificacaoDashState({
    this.notificacoes = const [],
    this.somAtivo = true,
    this.notifAtiva = true,
  });

  int get naoLidas => notificacoes.where((n) => !n.lida).length;

  NotificacaoDashState copyWith({
    List<NotificacaoDashModel>? notificacoes,
    bool? somAtivo,
    bool? notifAtiva,
  }) {
    return NotificacaoDashState(
      notificacoes: notificacoes ?? this.notificacoes,
      somAtivo: somAtivo ?? this.somAtivo,
      notifAtiva: notifAtiva ?? this.notifAtiva,
    );
  }
}

class NotificacaoDashController extends StateNotifier<NotificacaoDashState> {
  NotificacaoDashController() : super(const NotificacaoDashState());

  void adicionarNotificacao(NotificacaoDashModel notif) {
    if (!state.notifAtiva) return;
    final lista = [notif, ...state.notificacoes];
    state = state.copyWith(notificacoes: lista);
  }

  void marcarComoLida(String id) {
    final lista = state.notificacoes.map((n) {
      if (n.id == id) n.lida = true;
      return n;
    }).toList();
    state = state.copyWith(notificacoes: lista);
  }

  void marcarTodasLidas() {
    final lista = state.notificacoes.map((n) {
      n.lida = true;
      return n;
    }).toList();
    state = state.copyWith(notificacoes: lista);
  }

  void remover(String id) {
    final lista = state.notificacoes.where((n) => n.id != id).toList();
    state = state.copyWith(notificacoes: lista);
  }

  void limparTodas() {
    state = state.copyWith(notificacoes: []);
  }

  void setSomAtivo(bool v) => state = state.copyWith(somAtivo: v);
  void setNotifAtiva(bool v) => state = state.copyWith(notifAtiva: v);
}

final notificacaoDashProvider =
    StateNotifierProvider<NotificacaoDashController, NotificacaoDashState>(
  (ref) => NotificacaoDashController(),
);
