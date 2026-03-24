import '../models/usuario_adm_model.dart';

class UsuariosAdmState {
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final List<UsuarioAdmModel> usuarios;
  final String filtroTipo;   // todos | cliente | entregador | estabelecimento | admin
  final String filtroStatus; // todos | ativo | inativo | suspenso | banido
  final String termoBusca;
  final DateTime? lastSync;

  const UsuariosAdmState({
    this.isLoading = true,
    this.isSubmitting = false,
    this.errorMessage,
    this.usuarios = const [],
    this.filtroTipo = 'todos',
    this.filtroStatus = 'todos',
    this.termoBusca = '',
    this.lastSync,
  });

  // ── KPIs computados ──────────────────────────────────────────────────────────
  int get total => usuarios.length;
  int get clientes => usuarios.where((u) => u.tipoUsuario == 'cliente').length;
  int get entregadores => usuarios.where((u) => u.tipoUsuario == 'entregador').length;
  int get estabelecimentos => usuarios.where((u) => u.tipoUsuario == 'estabelecimento').length;
  int get admins => usuarios.where((u) => u.tipoUsuario == 'admin').length;
  int get ativos => usuarios.where((u) => u.status == 'ativo').length;
  int get naoVerificados => usuarios.where((u) => !u.emailVerificado).length;

  // ── Lista filtrada ────────────────────────────────────────────────────────────
  List<UsuarioAdmModel> get filtered {
    return usuarios.where((u) {
      final matchTipo = filtroTipo == 'todos' || u.tipoUsuario == filtroTipo;
      final matchStatus = filtroStatus == 'todos' || u.status == filtroStatus;
      final matchBusca = termoBusca.isEmpty ||
          u.nome.toLowerCase().contains(termoBusca.toLowerCase()) ||
          u.email.toLowerCase().contains(termoBusca.toLowerCase()) ||
          (u.telefone?.contains(termoBusca) ?? false);
      return matchTipo && matchStatus && matchBusca;
    }).toList();
  }

  bool get isEmpty => !isLoading && usuarios.isEmpty && errorMessage == null;

  UsuariosAdmState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    List<UsuarioAdmModel>? usuarios,
    String? filtroTipo,
    String? filtroStatus,
    String? termoBusca,
    DateTime? lastSync,
    bool clearError = false,
  }) {
    return UsuariosAdmState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      usuarios: usuarios ?? this.usuarios,
      filtroTipo: filtroTipo ?? this.filtroTipo,
      filtroStatus: filtroStatus ?? this.filtroStatus,
      termoBusca: termoBusca ?? this.termoBusca,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}
