import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/suporte_adm_repository.dart';
import '../models/suporte_adm_models.dart';
import 'suporte_adm_state.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final suporteAdmRepositoryProvider = Provider<SuporteAdmRepository>((ref) {
  return SuporteAdmRepository(Supabase.instance.client);
});

final suporteAdmControllerProvider = StateNotifierProvider.autoDispose<
    SuporteAdmController, SuporteAdmState>(
  (ref) => SuporteAdmController(ref.watch(suporteAdmRepositoryProvider)),
);

// ── Controller ────────────────────────────────────────────────────────────────

class SuporteAdmController extends StateNotifier<SuporteAdmState> {
  final SuporteAdmRepository _repo;

  SuporteAdmController(this._repo) : super(const SuporteAdmState()) {
    fetch();
  }

  /// Carrega chamados, notificações e avaliações em paralelo.
  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _repo.buscarChamados(),
        _repo.buscarNotificacoes(),
        _repo.buscarAvaliacoes(),
      ]);
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        chamados: results[0] as List<SupporteChamado>,
        notificacoes: results[1] as List<NotificacaoFila>,
        avaliacoes: results[2] as List<Avaliacao>,
        lastSync: DateTime.now(),
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('[SuporteAdmController] fetch erro: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao carregar dados de suporte. Tente novamente.',
      );
    }
  }

  /// Salva resposta do admin + notifica usuário.
  Future<void> responderChamado({
    required String chamadoId,
    required String status,
    required String prioridade,
    required String resposta,
    String? usuarioId,
  }) async {
    final adminId = Supabase.instance.client.auth.currentUser?.id ?? '';
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _repo.responderChamado(
        chamadoId: chamadoId,
        status: status,
        prioridade: prioridade,
        resposta: resposta,
        adminId: adminId,
      );
      if (usuarioId != null && usuarioId.isNotEmpty) {
        await _repo.notificarUsuario(
          usuarioId: usuarioId,
          chamadoId: chamadoId,
        );
      }
      if (!mounted) return;
      // Atualização otimista no estado local
      final updatedChamados = state.chamados.map((c) {
        if (c.id != chamadoId) return c;
        return c.copyWith(
          status: status,
          prioridade: prioridade,
          respostaSuporte: resposta,
          respondidoPor: adminId,
          respondidoEm: DateTime.now(),
          resolvidoEm: status == 'resolvido' ? DateTime.now() : c.resolvidoEm,
        );
      }).toList();
      state = state.copyWith(
        clearSaving: true,
        chamados: updatedChamados,
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('[SuporteAdmController] responderChamado erro: $e');
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Erro ao salvar resposta. Tente novamente.',
      );
    }
  }

  // ── Navegação e filtros ────────────────────────────────────────────────────

  void setAba(String aba) => state = state.copyWith(abaAtiva: aba);

  void setSearch(String v) => state = state.copyWith(search: v);

  void setFiltroStatus(String v) => state = state.copyWith(filtroStatus: v);

  void setFiltroPrioridade(String v) =>
      state = state.copyWith(filtroPrioridade: v);

  void setFiltroTipo(String v) => state = state.copyWith(filtroTipo: v);

  void clearError() => state = state.copyWith(clearError: true);
}
