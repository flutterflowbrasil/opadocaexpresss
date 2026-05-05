import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:padoca_express/core/utils/brazilian_document_validator.dart';
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

class ConfiguracoesEmailException implements Exception {
  final String message;

  const ConfiguracoesEmailException(this.message);

  @override
  String toString() => message;
}

class ConfiguracoesController extends StateNotifier<ConfiguracoesState> {
  final ConfiguracoesRepository _repository;
  final SupabaseClient _supabaseClient;
  static const String _emailRedirectTo = String.fromEnvironment(
    'APP_URL',
    defaultValue: 'https://padoca-express.web.app/login',
  );

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
        horariosAlterados: false,
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

  Future<void> atualizarEmailConta(String email) async {
    final editedEstab = state.editedEstab;
    if (editedEstab == null) {
      throw const ConfiguracoesEmailException(
        'Estabelecimento não encontrado.',
      );
    }

    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const ConfiguracoesEmailException('Usuário não autenticado.');
    }

    final novoEmail = email.trim().toLowerCase();
    final emailAuthAtual = user.email?.trim().toLowerCase();
    final emailComercialAtual = editedEstab.emailComercial?.trim().toLowerCase();

    if (novoEmail == emailAuthAtual && novoEmail == emailComercialAtual) {
      throw const ConfiguracoesEmailException(
        'Digite um e-mail diferente do atual.',
      );
    }

    final existingUser = await _supabaseClient
        .from('usuarios')
        .select('id')
        .eq('email', novoEmail)
        .maybeSingle();

    if (existingUser != null && existingUser['id'] != user.id) {
      throw const ConfiguracoesEmailException(
        'Este e-mail já está em uso por outro usuário.',
      );
    }

    await _supabaseClient.auth.updateUser(
      UserAttributes(email: novoEmail),
      emailRedirectTo: _emailRedirectTo,
    );

    await _supabaseClient
        .from('usuarios')
        .update({'email': novoEmail}).eq('id', user.id);

    await _repository.updateEmailComercial(editedEstab.id, novoEmail);

    final updatedEdited = editedEstab.copyWith(emailComercial: novoEmail);
    final updatedOriginal =
        state.originalEstab?.copyWith(emailComercial: novoEmail);

    state = state.copyWith(
      originalEstab: updatedOriginal,
      editedEstab: updatedEdited,
    );
  }

  void updateResponsavelNome(String name) {
    if (state.editedEstab == null) return;
    state = state.copyWith(
      editedEstab: state.editedEstab!.copyWith(responsavelNome: name),
    );
  }

  void updateResponsavelCpf(String cpf) {
    if (state.editedEstab == null) return;
    if (BrazilianDocumentValidator.optionalCpfFormValidator(cpf) != null) {
      state = state.copyWith(
        error: BrazilianDocumentValidator.invalidCpfMessage,
      );
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
    currentMap[dia] = Map<String, dynamic>.from(diaData);
    state = state.copyWith(
      editedEstab:
          state.editedEstab!.copyWith(horarioFuncionamento: currentMap),
      horariosAlterados: true,
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
      final enderecoError = _validarEndereco(modelToSave);
      if (enderecoError != null) {
        state = state.copyWith(isSaving: false, error: enderecoError);
        return false;
      }

      modelToSave = modelToSave.copyWith(
        horarioFuncionamento: _normalizarHorarioFuncionamento(
          modelToSave.horarioFuncionamento,
        ),
      );

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
        horariosAlterados: false,
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
        clearBannerBytes: true,
        horariosAlterados: false);
  }

  Map<String, dynamic> _normalizarHorarioFuncionamento(
    Map<String, dynamic> horarios,
  ) {
    const dias = ['seg', 'ter', 'qua', 'qui', 'sex', 'sab', 'dom'];
    final normalized = <String, dynamic>{};

    for (final dia in dias) {
      final rawDia = horarios[dia];
      final diaData = rawDia is Map
          ? Map<String, dynamic>.from(rawDia)
          : <String, dynamic>{};

      normalized[dia] = {
        'aberto': diaData['aberto'] as bool? ?? false,
        'inicio': diaData['inicio'] as String? ?? '08:00',
        'fim': diaData['fim'] as String? ?? '18:00',
      };
    }

    return normalized;
  }

  String? _validarEndereco(EstabelecimentoModel estabelecimento) {
    final endereco = estabelecimento.endereco;
    final cep = (endereco.cep ?? '').replaceAll(RegExp(r'\D'), '');
    final estado = (endereco.estado ?? '').trim();

    if (cep.length != 8) {
      return 'Informe um CEP válido com 8 dígitos.';
    }
    if ((endereco.logradouro ?? '').trim().isEmpty) {
      return 'Informe o logradouro do estabelecimento.';
    }
    if ((endereco.numero ?? '').trim().isEmpty) {
      return 'Informe o número do estabelecimento.';
    }
    if ((endereco.bairro ?? '').trim().isEmpty) {
      return 'Informe o bairro do estabelecimento.';
    }
    if ((endereco.cidade ?? '').trim().isEmpty) {
      return 'Informe a cidade do estabelecimento.';
    }
    if (estado.length != 2) {
      return 'Informe a UF do estabelecimento com 2 letras.';
    }

    return null;
  }
}
