import '../models/suporte_adm_models.dart';

// ── Estado ────────────────────────────────────────────────────────────────────

class SuporteAdmState {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final List<SupporteChamado> chamados;
  final List<NotificacaoFila> notificacoes;
  final List<Avaliacao> avaliacoes;
  final String abaAtiva;        // 'chamados' | 'notificacoes' | 'avaliacoes'
  final String search;
  final String filtroStatus;    // todos | aberto | em_atendimento | resolvido | fechado
  final String filtroPrioridade; // todos | urgente | alta | normal | baixa
  final String filtroTipo;      // todos | cliente | entregador | estabelecimento | admin
  final DateTime? lastSync;

  const SuporteAdmState({
    this.isLoading = true,
    this.isSaving = false,
    this.errorMessage,
    this.chamados = const [],
    this.notificacoes = const [],
    this.avaliacoes = const [],
    this.abaAtiva = 'chamados',
    this.search = '',
    this.filtroStatus = 'todos',
    this.filtroPrioridade = 'todos',
    this.filtroTipo = 'todos',
    this.lastSync,
  });

  // ── KPIs ──────────────────────────────────────────────────────────────────

  int get totalChamados => chamados.length;

  int get chamadosAbertos =>
      chamados.where((c) => c.status == 'aberto').length;

  int get chamadosEmAtendimento =>
      chamados.where((c) => c.status == 'em_atendimento').length;

  int get chamadosUrgentes => chamados
      .where((c) => c.prioridade == 'urgente' && c.status == 'aberto')
      .length;

  int get notifsErro =>
      notificacoes.where((n) => n.tentativas >= n.maxTentativas).length;

  int get avalNegativas => avaliacoes
      .where((a) =>
          (a.notaEstabelecimento ?? 5) <= 3 ||
          (a.notaEntregador ?? 5) <= 3)
      .length;

  // ── Lista filtrada ─────────────────────────────────────────────────────────

  List<SupporteChamado> get chamadosFiltrados {
    return chamados.where((c) {
      // Busca textual: nome, email, descrição
      final s = search.toLowerCase();
      final matchSearch = s.isEmpty ||
          (c.solicitanteNome?.toLowerCase().contains(s) ?? false) ||
          (c.solicitanteEmail?.toLowerCase().contains(s) ?? false) ||
          c.descricao.toLowerCase().contains(s);

      final matchStatus =
          filtroStatus == 'todos' || c.status == filtroStatus;

      final matchPrior =
          filtroPrioridade == 'todos' || c.prioridade == filtroPrioridade;

      final matchTipo =
          filtroTipo == 'todos' || c.tipoSolicitante == filtroTipo;

      return matchSearch && matchStatus && matchPrior && matchTipo;
    }).toList();
  }

  // ── copyWith ───────────────────────────────────────────────────────────────

  SuporteAdmState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    List<SupporteChamado>? chamados,
    List<NotificacaoFila>? notificacoes,
    List<Avaliacao>? avaliacoes,
    String? abaAtiva,
    String? search,
    String? filtroStatus,
    String? filtroPrioridade,
    String? filtroTipo,
    DateTime? lastSync,
    bool clearError = false,
    bool clearSaving = false,
  }) {
    return SuporteAdmState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: clearSaving ? false : (isSaving ?? this.isSaving),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      chamados: chamados ?? this.chamados,
      notificacoes: notificacoes ?? this.notificacoes,
      avaliacoes: avaliacoes ?? this.avaliacoes,
      abaAtiva: abaAtiva ?? this.abaAtiva,
      search: search ?? this.search,
      filtroStatus: filtroStatus ?? this.filtroStatus,
      filtroPrioridade: filtroPrioridade ?? this.filtroPrioridade,
      filtroTipo: filtroTipo ?? this.filtroTipo,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}
