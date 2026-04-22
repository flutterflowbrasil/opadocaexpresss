import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/estabelecimento_model.dart';
import '../data/configuracoes_repository.dart';
import 'configuracoes_state.dart';

final configuracoesControllerProvider = StateNotifierProvider.autoDispose<
    ConfiguracoesController, ConfiguracoesState>(
  (ref) {
    ref.keepAlive(); // Mantém o estado vivo para navegação instantânea
    final repository = ref.watch(configuracoesRepositoryProvider);
    final supabaseClient = Supabase.instance.client;
    return ConfiguracoesController(repository, supabaseClient);
  },
);

class ConfiguracoesController extends StateNotifier<ConfiguracoesState> {
  final ConfiguracoesRepository _repository;
  final SupabaseClient _supabaseClient;

  ConfiguracoesController(this._repository, this._supabaseClient)
      : super(const ConfiguracoesState()) {
    carregarDados();
  }

  Future<void> carregarDados() async {
    if (state.originalEstab == null) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      final estabId = await _repository.getEstabelecimentoIdByUserId(user.id);
      if (estabId == null) throw Exception('Estabelecimento não encontrado');

      final estab = await _repository.getEstabelecimento(estabId);
      state = state.copyWith(
        isLoading: false,
        originalEstab: estab,
        editedEstab: estab,
      );
    } catch (e) {
      // A3: Log interno apenas em debug, mensagem amigável para produção
      if (kDebugMode) debugPrint('Erro ao carregar configurações: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Não foi possível carregar suas configurações. Tente novamente.',
      );
    }
  }

  void updateEstabelecimento(
      EstabelecimentoModel Function(EstabelecimentoModel) update) {
    if (state.editedEstab == null) return;
    state = state.copyWith(editedEstab: update(state.editedEstab!));
  }

  void updateEndereco(EnderecoModel Function(EnderecoModel) update) {
    if (state.editedEstab == null) return;
    final newEndereco = update(state.editedEstab!.endereco);
    state = state.copyWith(
      editedEstab: state.editedEstab!.copyWith(endereco: newEndereco),
    );
  }

  void updateConfigEntrega(
      ConfigEntregaModel Function(ConfigEntregaModel) update) {
    if (state.editedEstab == null) return;
    final newConfig = update(state.editedEstab!.configEntrega);
    state = state.copyWith(
      editedEstab: state.editedEstab!.copyWith(configEntrega: newConfig),
    );
  }

  void updateDadosBancarios(
      DadosBancariosModel Function(DadosBancariosModel) update) {
    if (state.editedEstab == null) return;
    final newDados = update(state.editedEstab!.dadosBancarios);
    state = state.copyWith(
      editedEstab: state.editedEstab!.copyWith(dadosBancarios: newDados),
    );
  }

  void updateConfigAvancada(ConfigAvancadaModel update) {
    if (state.editedEstab == null) return;
    state = state.copyWith(
      editedEstab: state.editedEstab!.copyWith(configAvancada: update),
    );
  }

  void updateStatusAberto(bool isOpen) {
    if (state.editedEstab == null) return;
    state = state.copyWith(
      editedEstab: state.editedEstab!.copyWith(statusAberto: isOpen),
    );
  }

  void updateResponsavelNome(String name) {
    if (state.editedEstab == null) return;
    state = state.copyWith(
      editedEstab: state.editedEstab!.copyWith(responsavelNome: name),
    );
  }

  // C3: Validação de CPF com algoritmo de dígito verificador
  bool _validarCpf(String cpf) {
    final digits = cpf.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) return false;
    // Rejeita sequências iguais (ex: 111.111.111-11)
    if (RegExp(r'^(\d)\1{10}$').hasMatch(digits)) return false;

    // Primeiro dígito verificador
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(digits[i]) * (10 - i);
    }
    int d1 = (sum * 10 % 11) % 10;
    if (d1 != int.parse(digits[9])) return false;

    // Segundo dígito verificador
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(digits[i]) * (11 - i);
    }
    int d2 = (sum * 10 % 11) % 10;
    return d2 == int.parse(digits[10]);
  }

  void updateResponsavelCpf(String cpf) {
    if (state.editedEstab == null) return;
    if (cpf.isNotEmpty && !_validarCpf(cpf)) {
      state = state.copyWith(error: 'CPF inválido. Verifique os dígitos.');
      return;
    }
    state = state.copyWith(
      error: null,
      editedEstab: state.editedEstab!.copyWith(responsavelCpf: cpf),
    );
  }

  void updateHorarioDia(String dia, Map<String, dynamic> diaData) {
    if (state.editedEstab == null) return;
    final currentMap =
        Map<String, dynamic>.from(state.editedEstab!.horarioFuncionamento);
    currentMap[dia] = diaData;
    state = state.copyWith(
      editedEstab:
          state.editedEstab!.copyWith(horarioFuncionamento: currentMap),
    );
  }

  void setNewLogoBytes(Uint8List? bytes) {
    state = state.copyWith(newLogoBytes: bytes, clearLogoBytes: bytes == null);
  }

  void setNewBannerBytes(Uint8List? bytes) {
    state =
        state.copyWith(newBannerBytes: bytes, clearBannerBytes: bytes == null);
  }

  Future<String?> _uploadImageToSupabase(
      Uint8List imageBytes, String folder) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;

      const extension = 'jpg';
      final fileName =
          '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final storagePath = '$folder/$fileName';

      await Supabase.instance.client.storage.from('imagens').uploadBinary(
            storagePath,
            imageBytes,
            fileOptions:
                FileOptions(contentType: 'image/$extension', upsert: true),
          );

      final String publicUrl = Supabase.instance.client.storage
          .from('imagens')
          .getPublicUrl(storagePath);
      return publicUrl;
    } catch (e) {
      // A5: Log interno apenas em modo debug
      if (kDebugMode) debugPrint('Erro no upload da imagem: $e');
      return null;
    }
  }

  Future<bool> salvarAlteracoes() async {
    if (state.editedEstab == null || !state.hasChanges) return false;

    state = state.copyWith(isSaving: true, error: null);
    try {
      var modelToSave = state.editedEstab!;

      // Faz os uploads se existirem imagens novas
      if (state.newLogoBytes != null) {
        final logoUrl = await _uploadImageToSupabase(
            state.newLogoBytes!, 'logo_estabelecimentos');
        if (logoUrl != null) {
          modelToSave = modelToSave.copyWith(logoUrl: logoUrl);
        }
      }

      if (state.newBannerBytes != null) {
        final bannerUrl = await _uploadImageToSupabase(
            state.newBannerBytes!, 'capa_estabelecimentos');
        if (bannerUrl != null) {
          modelToSave = modelToSave.copyWith(bannerUrl: bannerUrl);
        }
      }

      // Lógica de validação de dados bancários (Regra de 2 dias)
      if (state.originalEstab?.dadosBancarios !=
          state.editedEstab?.dadosBancarios) {
        modelToSave = modelToSave.copyWith(
          dadosBancarios: modelToSave.dadosBancarios.copyWith(
            statusValidacao: 'pendente',
            ultimoUpdate: DateTime.now(),
          ),
        );
      }

      await _repository.saveEstabelecimento(modelToSave);
      state = state.copyWith(
        isSaving: false,
        originalEstab: modelToSave,
        editedEstab: modelToSave,
        clearLogoBytes: true,
        clearBannerBytes: true,
      );
      return true;
    } catch (e) {
      // A3: Mensagem amigável sem expor detalhes técnicos
      if (kDebugMode) debugPrint('Erro ao salvar configurações: $e');
      state = state.copyWith(
        isSaving: false,
        error: 'Não foi possível salvar as alterações. Tente novamente.',
      );
      return false;
    }
  }

  void descartarAlteracoes() {
    state = state.copyWith(
        editedEstab: state.originalEstab,
        clearLogoBytes: true,
        clearBannerBytes: true);
  }
}
