import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/usuarios_adm_repository.dart';
import 'usuarios_adm_state.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final usuariosAdmRepositoryProvider = Provider<UsuariosAdmRepository>((ref) {
  return UsuariosAdmRepository(Supabase.instance.client);
});

final usuariosAdmControllerProvider =
    StateNotifierProvider.autoDispose<UsuariosAdmController, UsuariosAdmState>((ref) {
  final repository = ref.watch(usuariosAdmRepositoryProvider);
  return UsuariosAdmController(repository);
});

// ── Controller ────────────────────────────────────────────────────────────────

class UsuariosAdmController extends StateNotifier<UsuariosAdmState> {
  final UsuariosAdmRepository _repository;

  UsuariosAdmController(this._repository)
      : super(const UsuariosAdmState()) {
    fetch();
  }

  /// Carrega usuários do banco e atualiza o state.
  Future<void> fetch() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final usuarios = await _repository.fetchUsuarios();
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        usuarios: usuarios,
        lastSync: DateTime.now(),
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Não foi possível carregar os usuários. Verifique sua conexão.',
      );
    }
  }

  /// Executa uma ação de moderação: suspender | banir | reativar.
  /// Usa optimistic update — reverte em caso de erro.
  Future<void> executarAcao(String acao, String userId) async {
    // Regra de negócio: admin não pode ser suspenso/banido
    final usuario = state.usuarios.firstWhere((u) => u.id == userId);
    if (usuario.isAdmin && acao != 'reativar') return;

    final statusMap = {
      'suspender': 'suspenso',
      'banir': 'banido',
      'reativar': 'ativo',
    };
    final novoStatus = statusMap[acao];
    if (novoStatus == null) return;

    // Optimistic update
    final estadoAnterior = state.usuarios;
    state = state.copyWith(
      isSubmitting: true,
      usuarios: state.usuarios
          .map((u) => u.id == userId ? u.copyWith(status: novoStatus) : u)
          .toList(),
    );

    try {
      await _repository.atualizarStatus(userId, novoStatus);
      if (!mounted) return;
      state = state.copyWith(isSubmitting: false);
    } catch (e) {
      // Reverte em caso de erro
      if (!mounted) return;
      state = state.copyWith(
        isSubmitting: false,
        usuarios: estadoAnterior,
        errorMessage: 'Erro ao atualizar status. Tente novamente.',
      );
    }
  }

  void setBusca(String termo) {
    state = state.copyWith(termoBusca: termo);
  }

  void setFiltroTipo(String tipo) {
    state = state.copyWith(filtroTipo: tipo);
  }

  void setFiltroStatus(String status) {
    state = state.copyWith(filtroStatus: status);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
