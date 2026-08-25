import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/admin_notificacoes_controller.dart';
import '../models/admin_notificacao_model.dart';

class AdminNotificacoesPanel extends ConsumerWidget {
  final VoidCallback onClose;
  final void Function(String rota, {String? entidadeId}) onNavigate;

  const AdminNotificacoesPanel({
    super.key,
    required this.onClose,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminNotificacoesControllerProvider);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Backdrop semi-transparente
          GestureDetector(
            onTap: onClose,
            child: Container(color: Colors.black.withValues(alpha: 0.35)),
          ),

          // Painel lateral direito
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: 380,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFAF9F7),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 32,
                    offset: Offset(-4, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildHeader(context, ref, state),
                  Expanded(child: _buildBody(state, ref)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(
      BuildContext context, WidgetRef ref, AdminNotificacoesState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEAE8E4))),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('🔔', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Central de Notificações',
                  style: GoogleFonts.publicSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A0910),
                  ),
                ),
                Text(
                  state.totalCriticos > 0
                      ? '${state.totalCriticos} pendência(s) ativas'
                      : 'Tudo em ordem',
                  style: GoogleFonts.publicSans(
                    fontSize: 11,
                    color: state.totalCriticos > 0
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
          // Botão atualizar
          if (state.isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            GestureDetector(
              onTap: () => ref
                  .read(adminNotificacoesControllerProvider.notifier)
                  .fetchAlertas(),
              child: const Icon(Icons.refresh,
                  size: 18, color: Color(0xFF6B7280)),
            ),
          const SizedBox(width: 10),
          // Botão fechar
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F2EF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close, size: 14, color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────

  Widget _buildBody(AdminNotificacoesState state, WidgetRef ref) {
    if (state.isLoading && state.alertas.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF97316)),
      );
    }

    if (state.error != null && state.alertas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text(
                'Erro ao carregar notificações',
                style: GoogleFonts.publicSans(
                    fontWeight: FontWeight.w700, color: const Color(0xFF1A0910)),
              ),
              const SizedBox(height: 4),
              Text(
                state.error!,
                style: GoogleFonts.publicSans(
                    fontSize: 11, color: const Color(0xFF6B7280)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (state.alertasVisiveis.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.urgentes.isNotEmpty) ...[
            _buildSectionHeader('🔴  Urgente', const Color(0xFFEF4444)),
            ...state.urgentes.map((a) => _buildCard(a, ref)),
            const SizedBox(height: 8),
          ],
          if (state.atencao.isNotEmpty) ...[
            _buildSectionHeader('🟡  Atenção', const Color(0xFFF59E0B)),
            ...state.atencao.map((a) => _buildCard(a, ref)),
            const SizedBox(height: 8),
          ],
          if (state.info.isNotEmpty) ...[
            _buildSectionHeader('🟢  Informativo', const Color(0xFF10B981)),
            ...state.info.map((a) => _buildCard(a, ref)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.publicSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCard(AdminNotificacaoModel alerta, WidgetRef ref) {
    final borderColor = switch (alerta.prioridade) {
      AdminNotificacaoPrioridade.urgente => const Color(0xFFFCA5A5),
      AdminNotificacaoPrioridade.atencao => const Color(0xFFFDE68A),
      AdminNotificacaoPrioridade.info => const Color(0xFFA7F3D0),
    };
    final bgColor = switch (alerta.prioridade) {
      AdminNotificacaoPrioridade.urgente => const Color(0xFFFFF5F5),
      AdminNotificacaoPrioridade.atencao => const Color(0xFFFFFBEB),
      AdminNotificacaoPrioridade.info => const Color(0xFFF0FDF4),
    };

    final canNavigate = alerta.rota != null;

    return GestureDetector(
      onTap: () {
        ref
            .read(adminNotificacoesControllerProvider.notifier)
            .dismissAlerta(alerta.id);
        if (canNavigate) {
          onClose();
          onNavigate(alerta.rota!, entidadeId: alerta.entidadeId);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícone
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: borderColor),
              ),
              child: Center(
                child: Text(alerta.iconLabel,
                    style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 10),
            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alerta.titulo,
                    style: GoogleFonts.publicSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A0910),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alerta.descricao,
                    style: GoogleFonts.publicSans(
                      fontSize: 11,
                      color: const Color(0xFF6B7280),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alerta.tempoRelativo,
                    style: GoogleFonts.publicSans(
                      fontSize: 10,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            if (canNavigate)
              const Icon(Icons.chevron_right,
                  size: 16, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text('✅', style: TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tudo em ordem!',
              style: GoogleFonts.publicSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A0910),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Não há pendências urgentes\nno momento.',
              style: GoogleFonts.publicSans(
                fontSize: 12,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
