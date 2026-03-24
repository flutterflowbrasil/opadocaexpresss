import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/usuario_adm_model.dart';
import '../controllers/usuarios_adm_controller.dart';
import '../controllers/usuarios_adm_state.dart';
import 'widgets/usuarios_adm_widgets.dart';
import 'dialogs/usuarios_adm_dialogs.dart';


// ── Tela principal ────────────────────────────────────────────────────────────

class UsuariosAdmScreen extends ConsumerStatefulWidget {
  const UsuariosAdmScreen({super.key});

  @override
  ConsumerState<UsuariosAdmScreen> createState() => _UsuariosAdmScreenState();
}

class _UsuariosAdmScreenState extends ConsumerState<UsuariosAdmScreen> {
  UsuarioAdmModel? _selectedUsuario;
  String? _acaoSelecionada; // 'suspender' | 'banir' | 'reativar'

  void _abrirModal(UsuarioAdmModel usuario) {
    setState(() => _selectedUsuario = usuario);
  }

  void _fecharModal() {
    setState(() {
      _selectedUsuario = null;
      _acaoSelecionada = null;
    });
  }

  void _iniciarAcao(String acao, UsuarioAdmModel usuario) {
    setState(() {
      _selectedUsuario = usuario;
      _acaoSelecionada = acao;
    });
  }

  Future<void> _confirmarAcao(String acao, String userId, String motivo) async {
    _fecharModal();
    await ref.read(usuariosAdmControllerProvider.notifier).executarAcao(acao, userId);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _UsuariosContent(
          onVerDetalhes: _abrirModal,
          onIniciarAcao: _iniciarAcao,
        ),

        // Modal: detalhes do usuário
        if (_selectedUsuario != null && _acaoSelecionada == null)
          Positioned.fill(
            child: ModalDetalhesUsuario(
              usuario: _selectedUsuario!,
              onClose: _fecharModal,
              onAcao: _iniciarAcao,
            ),
          ),

        // Modal: confirmação de ação
        if (_selectedUsuario != null && _acaoSelecionada != null)
          Positioned.fill(
            child: ModalConfirmarAcao(
              acao: _acaoSelecionada!,
              usuario: _selectedUsuario!,
              onClose: _fecharModal,
              onConfirm: _confirmarAcao,
            ),
          ),
      ],
    );
  }
}

// ── Conteúdo da tela ──────────────────────────────────────────────────────────

class _UsuariosContent extends ConsumerStatefulWidget {
  final void Function(UsuarioAdmModel) onVerDetalhes;
  final void Function(String acao, UsuarioAdmModel usuario) onIniciarAcao;

  const _UsuariosContent({
    required this.onVerDetalhes,
    required this.onIniciarAcao,
  });

  @override
  ConsumerState<_UsuariosContent> createState() => _UsuariosContentState();
}

class _UsuariosContentState extends ConsumerState<_UsuariosContent> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          _UsuariosHeader(
            onRefresh: () => ref.read(usuariosAdmControllerProvider.notifier).fetch(),
            searchController: _searchController,
            onSearch: (v) => ref.read(usuariosAdmControllerProvider.notifier).setBusca(v),
          ),
          const SizedBox(height: 16),

          // ── KPI Strip ───────────────────────────────────────────────────────
          const UsuariosKpiStrip(),
          const SizedBox(height: 16),

          // ── Banner de e-mails não verificados ────────────────────────────────
          const _EmailPendenteBanner(),
          const SizedBox(height: 12),

          // ── Filter Bar ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFEAE8E4)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const UsuariosFilterBar(),
          ),
          const SizedBox(height: 12),

          // ── Tabela ──────────────────────────────────────────────────────────
          _UsuariosTabela(
            onVerDetalhes: widget.onVerDetalhes,
            onIniciarAcao: widget.onIniciarAcao,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _UsuariosHeader extends ConsumerWidget {
  final VoidCallback onRefresh;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;

  const _UsuariosHeader({
    required this.onRefresh,
    required this.searchController,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      usuariosAdmControllerProvider.select((s) => s.isLoading),
    );

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Usuários',
                    style: GoogleFonts.publicSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A0910),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('·', style: GoogleFonts.publicSans(fontSize: 14, color: const Color(0xFF9CA3AF))),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Gestão de contas',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.publicSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF97316),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'Visualize, filtre e gerencie todos os usuários da plataforma.',
                style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),

        // Campo de busca
        Container(
          width: 220,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: const Color(0xFFEAE8E4), width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_outlined, size: 15, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 7),
              Expanded(
                child: TextField(
                  controller: searchController,
                  onChanged: onSearch,
                  decoration: InputDecoration(
                    hintText: 'Buscar usuário…',
                    hintStyle: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF9CA3AF)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF1A0910)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Botão refresh
        GestureDetector(
          onTap: isLoading ? null : onRefresh,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: const Color(0xFFEAE8E4), width: 1.5),
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF9CA3AF)))
                  : const Icon(Icons.refresh, size: 16, color: Color(0xFF6B7280)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Banner e-mails pendentes ──────────────────────────────────────────────────

class _EmailPendenteBanner extends ConsumerWidget {
  const _EmailPendenteBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final naoVerificados = ref.watch(
      usuariosAdmControllerProvider.select((s) => s.naoVerificados),
    );
    if (naoVerificados == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: const Color(0xFFFDE68A)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$naoVerificados usuário${naoVerificados != 1 ? 's' : ''} com e-mail não verificado. '
              'Considere reenviar o e-mail de confirmação.',
              style: GoogleFonts.dmSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tabela de usuários ────────────────────────────────────────────────────────

class _UsuariosTabela extends ConsumerWidget {
  final void Function(UsuarioAdmModel) onVerDetalhes;
  final void Function(String acao, UsuarioAdmModel usuario) onIniciarAcao;

  const _UsuariosTabela({
    required this.onVerDetalhes,
    required this.onIniciarAcao,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(usuariosAdmControllerProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEAE8E4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Cabeçalho da tabela
          _TableHeader(),

          // Error inline
          if (state.errorMessage != null)
            _ErrorInline(
              message: state.errorMessage!,
              onRetry: () => ref.read(usuariosAdmControllerProvider.notifier).fetch(),
            ),

          // Shimmer loading
          if (state.isLoading)
            ...List.generate(6, (_) => const UsuariosShimmerRow()),

          // Empty state
          if (state.isEmpty)
            const _EmptyState(),

          // Lista de usuários
          if (!state.isLoading && state.errorMessage == null)
            ..._buildRows(state, ref),

          // Footer
          if (!state.isLoading && state.filtered.isNotEmpty)
            _TableFooter(
              filtrados: state.filtered.length,
              total: state.total,
            ),
        ],
      ),
    );
  }

  List<Widget> _buildRows(UsuariosAdmState state, WidgetRef ref) {
    if (state.filtered.isEmpty) {
      return [const _EmptySearch()];
    }
    return state.filtered
        .map((u) => Column(
              children: [
                const Divider(height: 1, color: Color(0xFFF3F1EE)),
                UsuarioListItem(
                  usuario: u,
                  onVerDetalhes: () => onVerDetalhes(u),
                  onSuspender: () => onIniciarAcao('suspender', u),
                  onReativar: () => onIniciarAcao('reativar', u),
                ),
              ],
            ))
        .toList();
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cols = [
      {'label': 'USUÁRIO',     'flex': 22},
      {'label': 'TIPO',        'flex': 11},
      {'label': 'STATUS',      'flex': 10},
      {'label': 'VERIFICADO',  'flex': 8},
      {'label': 'CADASTRO',    'flex': 7},
      {'label': 'AÇÕES',       'flex': 13},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF9F8F7),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(bottom: BorderSide(color: Color(0xFFEAE8E4))),
      ),
      child: Row(
        children: cols.map((c) {
          return Expanded(
            flex: c['flex'] as int,
            child: Text(
              c['label'] as String,
              style: GoogleFonts.dmSans(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: .5,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TableFooter extends StatelessWidget {
  final int filtrados;
  final int total;

  const _TableFooter({required this.filtrados, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF3F1EE))),
      ),
      child: Row(
        children: [
          Text(
            'Exibindo $filtrados de $total usuários',
            style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}

class _ErrorInline extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorInline({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFFCA5A5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF991B1B)))),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFFCA5A5)),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text('Tentar novamente', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFEF4444))),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👤', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 10),
          Text('Nenhum usuário encontrado', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF6B7280))),
          Text('Os usuários cadastrados aparecerão aqui.', style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF9CA3AF))),
        ],
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Text('🔍', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text('Nenhum usuário corresponde aos filtros selecionados.', style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF9CA3AF))),
        ],
      ),
    );
  }
}
