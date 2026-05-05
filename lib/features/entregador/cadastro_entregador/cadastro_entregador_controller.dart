import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cadastro_entregador_state.dart';
export 'cadastro_entregador_state.dart';

class CadastroEntregadorController extends StateNotifier<CadastroEntregadorState> {
  CadastroEntregadorController() : super(CadastroEntregadorState());

  void updateForm({
    String? nomeCompleto,
    String? telefone,
    String? cpf,
    String? dataNascimento,
    String? placaVeiculo,
    String? dadosPagamentoAsaas,
    String? email,
    String? senha,
    String? confirmarSenha,
    bool? acceptedTerms,
  }) {
    state = state.copyWith(
      nomeCompleto: nomeCompleto ?? state.nomeCompleto,
      telefone: telefone ?? state.telefone,
      cpf: cpf ?? state.cpf,
      dataNascimento: dataNascimento ?? state.dataNascimento,
      placaVeiculo: placaVeiculo ?? state.placaVeiculo,
      dadosPagamentoAsaas: dadosPagamentoAsaas ?? state.dadosPagamentoAsaas,
      email: email ?? state.email,
      senha: senha ?? state.senha,
      confirmarSenha: confirmarSenha ?? state.confirmarSenha,
      acceptedTerms: acceptedTerms ?? state.acceptedTerms,
    );
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }
}

final cadastroEntregadorProvider =
    StateNotifierProvider.autoDispose<CadastroEntregadorController, CadastroEntregadorState>((ref) {
  return CadastroEntregadorController();
});
