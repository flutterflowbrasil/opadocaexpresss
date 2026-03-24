import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../controllers/suporte_adm_controller.dart';
import '../../models/suporte_adm_models.dart';
import 'suporte_modal_atender.dart';

// ── Configurações visuais ─────────────────────────────────────────────────────

const _priorBorderCfg = {
  'urgente': Color(0xFFEF4444),
  'alta':    Color(0xFFF97316),
  'normal':  Color(0xFF3B82F6),
  'baixa':   Color(0xFFE5E7EB),
};

const _statusCfg = {
  'aberto':         (l: 'Aberto',         c: Color(0xFFEF4444), bg: Color(0xFFFEF2F2)),
  'em_atendimento': (l: 'Em Atendimento', c: Color(0xFFF59E0B), bg: Color(0xFFFFFBEB)),
  'resolvido':      (l: 'Resolvido',      c: Color(0xFF10B981), bg: Color(0xFFECFDF5)),
  'fechado':        (l: 'Fechado',        c: Color(0xFF9CA3AF), bg: Color(0xFFF9FAFB)),
};

const _priorCfg = {
  'urgente': (l: 'Urgente', c: Color(0xFFDC2626), bg: Color(0xFFFEF2F2)),
  'alta':    (l: 'Alta',    c: Color(0xFFEA580C), bg: Color(0xFFFFF7ED)),
  'normal':  (l: 'Normal',  c: Color(0xFF2563EB), bg: Color(0xFFEFF6FF)),
  'baixa':   (l: 'Baixa',   c: Color(0xFF6B7280), bg: Color(0xFFF9FAFB)),
};

const _tipoCfg = {
  'cliente':         (l: 'Cliente',         c: Color(0xFF3B82F6), bg: Color(0xFFEFF6FF), icon: Icons.person_outline),
  'entregador':      (l: 'Entregador',      c: Color(0xFFF97316), bg: Color(0xFFFFF7ED), icon: Icons.directions_bike_outlined),
  'estabelecimento': (l: 'Estabelecimento', c: Color(0xFF8B5CF6), bg: Color(0xFFF5F3FF), icon: Icons.store_outlined),
  'admin':           (l: 'Admin',           c: Color(0xFFEF4444), bg: Color(0xFFFEF2F2), icon: Icons.shield_outlined),
};

// ── Aba Chamados ──────────────────────────────────────────────────────────────

class SuporteChamadosTab extends ConsumerWidget {
  const SuporteChamadosTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      suporteAdmControllerProvider.select((s) => s.isLoading),
    );
    final state = ref.watch(suporteAdmControllerProvider);
    final notifier = ref.read(suporteAdmControllerProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAE8E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Filtros ──────────────────────────────────────────────────────
          _FiltrosChamados(
            search: state.search,
            filtroStatus: state.filtroStatus,
            filtroPrioridade: state.filtroPrioridade,
            filtroTipo: state.filtroTipo,
            onSearch: notifier.setSearch,
            onStatus: notifier.setFiltroStatus,
            onPrioridade: notifier.setFiltroPrioridade,
            onTipo: notifier.setFiltroTipo,
          ),
          const SizedBox(height: 14),

          // ── Lista ─────────────────────────────────────────────────────────
          if (isLoading)
            const _ChamadosShimmer()
          else if (state.chamadosFiltrados.isEmpty)
            _EmptyChamados(hasFilters: state.chamados.isNotEmpty)
          else
            ...state.chamadosFiltrados.map(
              (c) => _ChamadoCard(
                chamado: c,
                onTap: () => _abrirModal(context, ref, c),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _abrirModal(
    BuildContext context,
    WidgetRef ref,
    SupporteChamado chamado,
  ) async {
    final salvou = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => SuporteModalAtender(chamado: chamado),
    );
    if (salvou == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Chamado atualizado e usuário notificado ✓',
            style: GoogleFonts.dmSans(fontSize: 13),
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }
}

// ── Filtros ───────────────────────────────────────────────────────────────────

class _FiltrosChamados extends StatelessWidget {
  final String search;
  final String filtroStatus;
  final String filtroPrioridade;
  final String filtroTipo;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onStatus;
  final ValueChanged<String> onPrioridade;
  final ValueChanged<String> onTipo;

  const _FiltrosChamados({
    required this.search,
    required this.filtroStatus,
    required this.filtroPrioridade,
    required this.filtroTipo,
    required this.onSearch,
    required this.onStatus,
    required this.onPrioridade,
    required this.onTipo,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Campo de busca
        SizedBox(
          width: 200,
          height: 34,
          child: TextField(
            onChanged: onSearch,
            style: GoogleFonts.dmSans(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Buscar chamados…',
              hintStyle: GoogleFonts.dmSans(
                  fontSize: 12, color: const Color(0xFF9CA3AF)),
              prefixIcon: const Icon(Icons.search,
                  size: 15, color: Color(0xFF9CA3AF)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFEAE8E4)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFEAE8E4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                    color: Color(0xFFF97316), width: 1.5),
              ),
            ),
          ),
        ),
        _FilterDropdown(
          value: filtroStatus,
          items: const {
            'todos': 'Status: Todos',
            'aberto': 'Aberto',
            'em_atendimento': 'Em Atendimento',
            'resolvido': 'Resolvido',
            'fechado': 'Fechado',
          },
          onChanged: onStatus,
        ),
        _FilterDropdown(
          value: filtroPrioridade,
          items: const {
            'todos': 'Prioridade: Todas',
            'urgente': 'Urgente',
            'alta': 'Alta',
            'normal': 'Normal',
            'baixa': 'Baixa',
          },
          onChanged: onPrioridade,
        ),
        _FilterDropdown(
          value: filtroTipo,
          items: const {
            'todos': 'Tipo: Todos',
            'cliente': 'Cliente',
            'entregador': 'Entregador',
            'estabelecimento': 'Estabelecimento',
            'admin': 'Admin',
          },
          onChanged: onTipo,
        ),
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;

  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEAE8E4)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          style: GoogleFonts.dmSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
          icon: const Icon(Icons.expand_more,
              size: 16, color: Color(0xFF9CA3AF)),
          items: items.entries
              .map((e) =>
                  DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ── Card de chamado ───────────────────────────────────────────────────────────

class _ChamadoCard extends StatelessWidget {
  final SupporteChamado chamado;
  final VoidCallback onTap;

  const _ChamadoCard({required this.chamado, required this.onTap});

  String _elapsed(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}min atrás';
    if (diff.inHours < 24) return '${diff.inHours}h atrás';
    return '${diff.inDays}d atrás';
  }

  @override
  Widget build(BuildContext context) {
    final borderColor =
        _priorBorderCfg[chamado.prioridade] ?? const Color(0xFFE5E7EB);
    final stCfg =
        _statusCfg[chamado.status] ?? _statusCfg['aberto']!;
    final prCfg =
        _priorCfg[chamado.prioridade] ?? _priorCfg['normal']!;
    final tipoCfg =
        _tipoCfg[chamado.tipoSolicitante] ?? _tipoCfg['cliente']!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            top: BorderSide(color: const Color(0xFFEAE8E4)),
            right: BorderSide(color: const Color(0xFFEAE8E4)),
            bottom: BorderSide(color: const Color(0xFFEAE8E4)),
            left: BorderSide(color: borderColor, width: 3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar tipo
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tipoCfg.bg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(tipoCfg.icon, size: 18, color: tipoCfg.c),
            ),
            const SizedBox(width: 10),

            // Conteúdo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        chamado.solicitanteNome ?? 'Usuário',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A0910),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _Badge(
                          label: tipoCfg.l,
                          color: tipoCfg.c,
                          bg: tipoCfg.bg),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 11,
                              color: const Color(0xFF9CA3AF)),
                          const SizedBox(width: 3),
                          Text(
                            _elapsed(chamado.createdAt),
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    chamado.solicitanteEmail ?? '',
                    style: GoogleFonts.dmSans(
                      fontSize: 10.5,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    chamado.descricao,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: const Color(0xFF374151),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _Badge(
                          label: stCfg.l,
                          color: stCfg.c,
                          bg: stCfg.bg),
                      const SizedBox(width: 5),
                      _Badge(
                          label: prCfg.l,
                          color: prCfg.c,
                          bg: prCfg.bg),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded,
                          size: 16,
                          color: const Color(0xFF9CA3AF)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _Badge(
      {required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ── Estados vazios e shimmer ──────────────────────────────────────────────────

class _EmptyChamados extends StatelessWidget {
  final bool hasFilters;
  const _EmptyChamados({required this.hasFilters});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFilters
                ? Icons.filter_list_off_rounded
                : Icons.support_agent_outlined,
            size: 44,
            color: const Color(0xFFD1D5DB),
          ),
          const SizedBox(height: 12),
          Text(
            hasFilters
                ? 'Nenhum chamado encontrado com os filtros aplicados.'
                : 'Nenhum chamado de suporte aberto.\nTudo em ordem por aqui.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChamadosShimmer extends StatelessWidget {
  const _ChamadosShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFF3F4F6),
      highlightColor: const Color(0xFFE5E7EB),
      child: Column(
        children: List.generate(
          3,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
