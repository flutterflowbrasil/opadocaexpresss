import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/config_adm_repository.dart';
import 'config_adm_state.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final configAdmRepositoryProvider = Provider<ConfigAdmRepository>((ref) {
  return ConfigAdmRepository(Supabase.instance.client);
});

final configAdmControllerProvider = StateNotifierProvider.autoDispose<
    ConfigAdmController, ConfigAdmState>(
  (ref) => ConfigAdmController(ref.watch(configAdmRepositoryProvider))..fetch(),
);

// ── Controller ────────────────────────────────────────────────────────────────

class ConfigAdmController extends StateNotifier<ConfigAdmState> {
  final ConfigAdmRepository _repo;

  ConfigAdmController(this._repo) : super(const ConfigAdmState());

  // ── Leitura ──────────────────────────────────────────────────────────────────

  Future<void> fetch() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final configs = await _repo.buscarConfigs();
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        configs: configs,
        lastSync: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[ConfigAdmController] fetch erro: $e');
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Não foi possível carregar as configurações.',
      );
    }
  }

  // ── Modificações locais ───────────────────────────────────────────────────────

  /// Registra uma alteração local (não persiste no banco ainda).
  ///
  /// Segurança:
  /// - Ignora silenciosamente se o campo tiver `editavel == false`.
  /// - Se o novo valor for igual ao original, desfaz a modificação local.
  void setValor(String chave, String novoValor) {
    final original = state.configs.where((c) => c.chave == chave).firstOrNull;
    if (original == null) return;
    if (!original.editavel) return; // campo somente leitura — ignora

    final mods = Map<String, String>.of(state.modificacoes);
    if (novoValor == original.valor) {
      mods.remove(chave); // desfaz a modificação
    } else {
      mods[chave] = novoValor;
    }
    state = state.copyWith(modificacoes: mods);
  }

  void descartarModificacoes() => state = state.copyWith(modificacoes: {});

  void setAba(String aba) => state = state.copyWith(abaSelecionada: aba);

  // ── Persistência ──────────────────────────────────────────────────────────────

  /// Persiste as modificações no banco.
  ///
  /// Camadas de segurança:
  /// 1. Filtra apenas chaves com `editavel == true` (defesa dupla).
  /// 2. Requer sessão ativa — sem session, aborta sem erro visível.
  /// 3. RLS do Supabase rejeita qualquer update de não-admin.
  /// 4. Registra `updated_by` = UUID do admin autenticado.
  Future<void> salvar() async {
    if (!state.temModificacoes || state.isSaving) return;

    // Filtra somente chaves editáveis (defesa dupla além da UI)
    final editaveis = Map<String, String>.fromEntries(
      state.modificacoes.entries.where((e) {
        final cfg = state.configs.where((c) => c.chave == e.key).firstOrNull;
        return cfg?.editavel == true;
      }),
    );
    if (editaveis.isEmpty) return;

    // Requer sessão ativa
    final adminId = Supabase.instance.client.auth.currentUser?.id;
    if (adminId == null) return;

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _repo.salvarModificacoes(
        modificacoes: editaveis,
        adminId: adminId,
      );
      if (!mounted) return;

      // Aplica as alterações nos configs locais (evita re-fetch)
      final updated = state.configs.map((c) {
        final novoValor = editaveis[c.chave];
        return novoValor != null ? c.copyWith(valor: novoValor) : c;
      }).toList();

      state = state.copyWith(
        isSaving: false,
        configs: updated,
        modificacoes: {},
        lastSync: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[ConfigAdmController] salvar erro: $e');
      if (!mounted) return;
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Erro ao salvar configurações. Verifique sua conexão.',
      );
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}
