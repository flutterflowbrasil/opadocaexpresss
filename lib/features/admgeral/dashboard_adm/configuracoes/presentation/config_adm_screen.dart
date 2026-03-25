import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/config_adm_controller.dart';
import '../controllers/config_adm_state.dart';
import 'widgets/config_adm_tab_bar.dart';
import 'widgets/config_adm_shared.dart';
import 'widgets/config_tab_financeiro.dart';
import 'widgets/config_tab_entrega.dart';
import 'widgets/config_tab_despacho.dart';
import 'widgets/config_tab_notificacoes.dart';
import 'widgets/config_tab_cupons.dart';
import 'widgets/config_tab_cancelamento.dart';
import 'widgets/config_tab_saques.dart';
import 'widgets/config_tab_sistema.dart';

class ConfigAdmScreen extends ConsumerWidget {
  const ConfigAdmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuta erros e sucessos para exibir SnackBar
    ref.listen<ConfigAdmState>(configAdmControllerProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.errorMessage!,
              style: GoogleFonts.dmSans(fontSize: 13),
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ref.read(configAdmControllerProvider.notifier).clearError();
              },
            ),
          ),
        );
      }
      // Sucesso: modificações foram limpas e não há erro
      if (prev?.isSaving == true &&
          !next.isSaving &&
          next.errorMessage == null &&
          prev?.modificacoes.isNotEmpty == true &&
          next.modificacoes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Configurações salvas com sucesso.',
              style: GoogleFonts.dmSans(fontSize: 13),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ConfigHeader(),
        const ConfigAdmTabBar(),
        const _SensiveisBanner(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: const _TabContent(),
          ),
        ),
      ],
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _ConfigHeader extends ConsumerWidget {
  const _ConfigHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(configAdmControllerProvider.select(
      (s) => (
        isSaving: s.isSaving,
        temMods: s.temModificacoes,
        totalMods: s.totalModificacoes,
        lastSync: s.lastSync,
        isLoading: s.isLoading,
      ),
    ));

    final notifier = ref.read(configAdmControllerProvider.notifier);

    String syncLabel() {
      if (state.lastSync == null) return '';
      final t = state.lastSync!;
      return 'Sync ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEAE8E4))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configurações do Sistema',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A0910),
                  ),
                ),
                if (state.lastSync != null)
                  Text(
                    syncLabel(),
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
              ],
            ),
          ),
          // Refresh
          if (!state.isLoading)
            _HeaderIconBtn(
              icon: Icons.refresh_rounded,
              tooltip: 'Recarregar',
              onPressed: () => notifier.fetch(),
            ),
          const SizedBox(width: 8),
          // Descartar
          if (state.temMods) ...[
            _HeaderOutlineBtn(
              label: 'Descartar',
              onPressed: () => notifier.descartarModificacoes(),
            ),
            const SizedBox(width: 8),
          ],
          // Salvar
          _SaveButton(
            modCount: state.totalMods,
            isSaving: state.isSaving,
            onPressed: state.temMods && !state.isSaving
                ? () => _handleSalvar(context, ref)
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _handleSalvar(BuildContext context, WidgetRef ref) async {
    final state = ref.read(configAdmControllerProvider);
    if (state.modificacoesSensiveis) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => const _ConfirmacaoSensivelDialog(),
      );
      if (confirm != true) return;
    }
    if (context.mounted) {
      ref.read(configAdmControllerProvider.notifier).salvar();
    }
  }
}

// ── Banner de campos sensíveis ────────────────────────────────────────────────

class _SensiveisBanner extends ConsumerWidget {
  const _SensiveisBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensivel = ref.watch(
      configAdmControllerProvider.select((s) => s.modificacoesSensiveis),
    );
    if (!sensivel) return const SizedBox.shrink();

    return Container(
      color: const Color(0xFFFFFBEB),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 14, color: Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Você tem alterações em campos sensíveis. Uma confirmação será solicitada ao salvar.',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Conteúdo da aba ───────────────────────────────────────────────────────────

class _TabContent extends ConsumerWidget {
  const _TabContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(configAdmControllerProvider.select(
      (s) => (isLoading: s.isLoading, aba: s.abaSelecionada),
    ));

    if (state.isLoading) return const ConfigShimmer();

    return switch (state.aba) {
      'financeiro' => const ConfigTabFinanceiro(),
      'entrega' => const ConfigTabEntrega(),
      'despacho' => const ConfigTabDespacho(),
      'notificacoes' => const ConfigTabNotificacoes(),
      'cupons' => const ConfigTabCupons(),
      'cancelamento' => const ConfigTabCancelamento(),
      'saques' => const ConfigTabSaques(),
      'sistema' => const ConfigTabSistema(),
      _ => const ConfigTabFinanceiro(),
    };
  }
}

// ── Botão Salvar ──────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final int modCount;
  final bool isSaving;
  final VoidCallback? onPressed;

  const _SaveButton({
    required this.modCount,
    required this.isSaving,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final active = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFFF97316)
              : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSaving)
              const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Icon(
                Icons.save_outlined,
                size: 14,
                color: active ? Colors.white : const Color(0xFF9CA3AF),
              ),
            const SizedBox(width: 6),
            Text(
              modCount > 0 ? 'Salvar ($modCount)' : 'Salvar',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Botão Descartar ───────────────────────────────────────────────────────────

class _HeaderOutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _HeaderOutlineBtn({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFFEAE8E4)),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _HeaderIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFEAE8E4)),
          ),
          child: Icon(icon, size: 15, color: const Color(0xFF6B7280)),
        ),
      ),
    );
  }
}

// ── Modal de confirmação para campos sensíveis ────────────────────────────────

class _ConfirmacaoSensivelDialog extends StatelessWidget {
  const _ConfirmacaoSensivelDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFDC2626), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Confirmar alterações sensíveis',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A0910),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Você está prestes a salvar alterações em campos sensíveis (splits financeiros, taxas, controles da plataforma). '
              'Essas mudanças entram em vigor imediatamente e afetam todos os usuários.',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFEAE8E4)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Confirmar e salvar',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
