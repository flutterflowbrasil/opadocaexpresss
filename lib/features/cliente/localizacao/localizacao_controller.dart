import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'endereco_model.dart';
import 'localizacao_repository.dart';
import 'localizacao_state.dart';

// ── Provider do Repository ────────────────────────────────────────────────────
final localizacaoRepositoryProvider = Provider<LocalizacaoRepository>((ref) {
  return LocalizacaoRepository(Supabase.instance.client);
});

// ── Provider do Controller ────────────────────────────────────────────────────
/// autoDispose: evita memory leak ao sair da tela/modal.
final localizacaoControllerProvider =
    StateNotifierProvider.autoDispose<LocalizacaoController, LocalizacaoState>(
  (ref) => LocalizacaoController(ref.read(localizacaoRepositoryProvider)),
);

// ── Controller ────────────────────────────────────────────────────────────────
class LocalizacaoController extends StateNotifier<LocalizacaoState> {
  final LocalizacaoRepository _repository;

  LocalizacaoController(this._repository) : super(const LocalizacaoState());

  // ── Carregar endereços do cliente ─────────────────────────────────────────
  Future<void> carregarEnderecos() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final enderecos = await _repository.buscarEnderecos();
      state = state.copyWith(isLoading: false, enderecos: enderecos);
    } catch (e) {
      debugPrint('[LocalizacaoController] carregarEnderecos erro: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Não foi possível carregar seus endereços. Tente novamente.',
      );
    }
  }

  // ── Salvar novo endereço ──────────────────────────────────────────────────
  Future<EnderecoCliente?> salvar(EnderecoCliente endereco) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final saved = await _repository.salvarEndereco(endereco);
      if (saved != null) {
        state = state.copyWith(
          isSubmitting: false,
          enderecos: [saved, ...state.enderecos],
        );
      } else {
        state = state.copyWith(
          isSubmitting: false,
          error: 'Não foi possível salvar o endereço. Tente novamente.',
        );
      }
      return saved;
    } catch (e) {
      debugPrint('[LocalizacaoController] salvar erro: $e');
      state = state.copyWith(
        isSubmitting: false,
        error: 'Ocorreu um erro ao salvar. Verifique sua conexão.',
      );
      return null;
    }
  }

  // ── Atualizar endereço existente ─────────────────────────────────────────
  Future<EnderecoCliente?> atualizar(EnderecoCliente endereco) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final updated = await _repository.atualizarEndereco(endereco);
      if (updated != null) {
        state = state.copyWith(
          isSubmitting: false,
          enderecos: state.enderecos
              .map((e) => e.id == updated.id ? updated : e)
              .toList(),
        );
      } else {
        state = state.copyWith(
          isSubmitting: false,
          error: 'Não foi possível atualizar o endereço. Tente novamente.',
        );
      }
      return updated;
    } catch (e) {
      debugPrint('[LocalizacaoController] atualizar erro: $e');
      state = state.copyWith(
        isSubmitting: false,
        error: 'Ocorreu um erro ao atualizar. Verifique sua conexão.',
      );
      return null;
    }
  }

  // ── Definir padrão ────────────────────────────────────────────────────────
  Future<void> definirPadrao(String enderecoId) async {
    try {
      await _repository.definirPadrao(enderecoId);
      // Atualiza lista local
      final atualizados = state.enderecos.map((e) {
        return e.copyWith(isPadrao: e.id == enderecoId);
      }).toList();
      state = state.copyWith(enderecos: atualizados);
    } catch (e) {
      debugPrint('[LocalizacaoController] definirPadrao erro: $e');
      state = state.copyWith(
        error: 'Não foi possível definir o endereço padrão.',
      );
    }
  }

  // ── Excluir endereço ──────────────────────────────────────────────────────
  Future<void> excluir(String enderecoId) async {
    try {
      await _repository.excluirEndereco(enderecoId);
      state = state.copyWith(
        enderecos: state.enderecos.where((e) => e.id != enderecoId).toList(),
      );
    } catch (e) {
      debugPrint('[LocalizacaoController] excluir erro: $e');
      state = state.copyWith(
        error: 'Não foi possível excluir o endereço.',
      );
    }
  }

  /// Limpa o erro atual do estado.
  void limparErro() => state = state.copyWith(clearError: true);
}
