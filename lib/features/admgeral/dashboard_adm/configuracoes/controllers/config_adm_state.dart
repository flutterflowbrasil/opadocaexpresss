import '../models/config_adm_models.dart';

const _kChavesSensiveis = {
  'split_estabelecimento_pct',
  'split_plataforma_pct',
  'taxa_servico_app_pct',
  'taxa_transacao_gateway',
  'retencao_temporaria',
  'compensacao_antes_coleta',
  'compensacao_apos_coleta_pct',
  'plataforma_ativa',
  'modo_manutencao',
  'logs_avancados',
  'modo_debug',
};

class ConfigAdmState {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final List<ConfigItem> configs;

  /// Mapa de chave → novo valor — apenas campos que foram modificados.
  final Map<String, String> modificacoes;

  /// Aba visível. Corresponde ao campo `secao` na tabela.
  final String abaSelecionada;

  final DateTime? lastSync;

  const ConfigAdmState({
    this.isLoading = true,
    this.isSaving = false,
    this.errorMessage,
    this.configs = const [],
    this.modificacoes = const {},
    this.abaSelecionada = 'financeiro',
    this.lastSync,
  });

  // ── Computed ────────────────────────────────────────────────────────────────

  bool get temModificacoes => modificacoes.isNotEmpty;
  int get totalModificacoes => modificacoes.length;

  /// Configs da aba selecionada.
  List<ConfigItem> get configsDaAba =>
      configs.where((c) => c.secao == abaSelecionada).toList();

  /// Conta modificações em uma aba específica (para badge).
  int modificacoesNaAba(String aba) => configs
      .where((c) => c.secao == aba && modificacoes.containsKey(c.chave))
      .length;

  /// True se qualquer campo modificado estiver na lista de sensíveis.
  bool get modificacoesSensiveis =>
      modificacoes.keys.any((k) => _kChavesSensiveis.contains(k));

  /// Retorna o valor efetivo: modificado ou original.
  String valorEfetivo(String chave) {
    if (modificacoes.containsKey(chave)) return modificacoes[chave]!;
    final matches = configs.where((c) => c.chave == chave);
    final cfg = matches.isEmpty ? null : matches.first;
    return cfg?.valor ?? '';
  }

  // ── CopyWith ─────────────────────────────────────────────────────────────────

  ConfigAdmState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    List<ConfigItem>? configs,
    Map<String, String>? modificacoes,
    String? abaSelecionada,
    DateTime? lastSync,
    bool clearError = false,
  }) {
    return ConfigAdmState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      configs: configs ?? this.configs,
      modificacoes: modificacoes ?? this.modificacoes,
      abaSelecionada: abaSelecionada ?? this.abaSelecionada,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}
