import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/usuario_adm_model.dart';
import '../../controllers/usuarios_adm_controller.dart';

// ── Configurações de cores por tipo ──────────────────────────────────────────

const _tipoCores = {
  'cliente':        {'color': Color(0xFF3B82F6), 'bg': Color(0xFFEFF6FF), 'border': Color(0xFFBFDBFE), 'icon': '👤', 'label': 'Cliente'},
  'entregador':     {'color': Color(0xFFF97316), 'bg': Color(0xFFFFF7ED), 'border': Color(0xFFFED7AA), 'icon': '🏍️', 'label': 'Entregador'},
  'estabelecimento':{'color': Color(0xFF8B5CF6), 'bg': Color(0xFFF5F3FF), 'border': Color(0xFFDDD6FE), 'icon': '🏪', 'label': 'Estabelecimento'},
  'admin':          {'color': Color(0xFFEF4444), 'bg': Color(0xFFFEF2F2), 'border': Color(0xFFFCA5A5), 'icon': '🛡️', 'label': 'Admin'},
};

const _statusCores = {
  'ativo':    {'color': Color(0xFF10B981), 'bg': Color(0xFFECFDF5), 'border': Color(0xFFA7F3D0), 'label': 'Ativo'},
  'inativo':  {'color': Color(0xFF9CA3AF), 'bg': Color(0xFFF9FAFB), 'border': Color(0xFFE5E7EB), 'label': 'Inativo'},
  'suspenso': {'color': Color(0xFFEF4444), 'bg': Color(0xFFFEF2F2), 'border': Color(0xFFFCA5A5), 'label': 'Suspenso'},
  'banido':   {'color': Color(0xFF7F1D1D), 'bg': Color(0xFFFEF2F2), 'border': Color(0xFFFCA5A5), 'label': 'Banido'},
};

Map<String, dynamic> getTipoCfg(String tipo) =>
    _tipoCores[tipo] ?? _tipoCores['cliente']!;

Map<String, dynamic> getStatusCfg(String status) =>
    _statusCores[status] ?? _statusCores['ativo']!;

// ── UserAvatar ────────────────────────────────────────────────────────────────

class UserAvatar extends StatelessWidget {
  final String nome;
  final String tipo;
  final double size;

  const UserAvatar({
    super.key,
    required this.nome,
    required this.tipo,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = getTipoCfg(tipo);
    final initials = nome
        .split(' ')
        .take(2)
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
        .join();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [(cfg['bg'] as Color), (cfg['border'] as Color)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: cfg['border'] as Color, width: 2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials.isEmpty ? '?' : initials,
          style: GoogleFonts.dmSans(
            fontSize: size * 0.33,
            fontWeight: FontWeight.w700,
            color: cfg['color'] as Color,
          ),
        ),
      ),
    );
  }
}

// ── TipoBadge ─────────────────────────────────────────────────────────────────

class TipoBadge extends StatelessWidget {
  final String tipo;
  const TipoBadge({super.key, required this.tipo});

  @override
  Widget build(BuildContext context) {
    final cfg = getTipoCfg(tipo);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: cfg['bg'] as Color,
        border: Border.all(color: cfg['border'] as Color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${cfg['icon']} ${cfg['label']}',
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: cfg['color'] as Color,
        ),
      ),
    );
  }
}

// ── StatusBadge ───────────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final cfg = getStatusCfg(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: cfg['bg'] as Color,
        border: Border.all(color: cfg['border'] as Color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        cfg['label'] as String,
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: cfg['color'] as Color,
        ),
      ),
    );
  }
}

// ── KPI Strip ─────────────────────────────────────────────────────────────────

class UsuariosKpiStrip extends ConsumerWidget {
  const UsuariosKpiStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      usuariosAdmControllerProvider.select(
        (s) => (
          isLoading: s.isLoading,
          total: s.total,
          clientes: s.clientes,
          entregadores: s.entregadores,
          estabelecimentos: s.estabelecimentos,
          admins: s.admins,
          ativos: s.ativos,
          naoVerificados: s.naoVerificados,
        ),
      ),
    );

    final cards = [
      {'label': 'Total',            'value': state.total,             'color': const Color(0xFF1A0910), 'bg': Colors.white,           'icon': '👥'},
      {'label': 'Clientes',         'value': state.clientes,          'color': const Color(0xFF3B82F6), 'bg': const Color(0xFFEFF6FF), 'icon': '👤'},
      {'label': 'Entregadores',     'value': state.entregadores,      'color': const Color(0xFFF97316), 'bg': const Color(0xFFFFF7ED), 'icon': '🏍️'},
      {'label': 'Estabelecimentos', 'value': state.estabelecimentos,  'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF5F3FF), 'icon': '🏪'},
      {'label': 'Admins',           'value': state.admins,            'color': const Color(0xFFEF4444), 'bg': const Color(0xFFFEF2F2), 'icon': '🛡️'},
      {'label': 'Ativos',           'value': state.ativos,            'color': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5), 'icon': '✓'},
      {'label': 'E-mail pendente',  'value': state.naoVerificados,    'color': const Color(0xFFF59E0B), 'bg': const Color(0xFFFFFBEB), 'icon': '⚠️'},
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 900
          ? 7
          : constraints.maxWidth > 600
              ? 4
              : 2;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          childAspectRatio: 1.6,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: cards.length,
        itemBuilder: (_, i) {
          final card = cards[i];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: card['bg'] as Color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEAE8E4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  card['label'] as String,
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF9CA3AF),
                    letterSpacing: .3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (state.isLoading)
                  Shimmer.fromColors(
                    baseColor: const Color(0xFFE5E7EB),
                    highlightColor: const Color(0xFFF3F4F6),
                    child: Container(
                      height: 22,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${card['value']}',
                        style: GoogleFonts.dmSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: card['color'] as Color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(card['icon'] as String, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
              ],
            ),
          );
        },
      );
    });
  }
}

// ── Filter Bar ────────────────────────────────────────────────────────────────

class UsuariosFilterBar extends ConsumerWidget {
  const UsuariosFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(usuariosAdmControllerProvider.select(
      (s) => (
        filtroTipo: s.filtroTipo,
        filtroStatus: s.filtroStatus,
        total: s.total,
        clientes: s.clientes,
        entregadores: s.entregadores,
        estabelecimentos: s.estabelecimentos,
        admins: s.admins,
        filtrados: s.filtered.length,
      ),
    ));
    final notifier = ref.read(usuariosAdmControllerProvider.notifier);

    final tipoOpts = [
      {'k': 'todos',          'l': 'Todos os tipos',     'n': state.total},
      {'k': 'cliente',        'l': '👤 Clientes',        'n': state.clientes},
      {'k': 'entregador',     'l': '🏍️ Entregadores',    'n': state.entregadores},
      {'k': 'estabelecimento','l': '🏪 Estabelecimentos', 'n': state.estabelecimentos},
      {'k': 'admin',          'l': '🛡️ Admins',           'n': state.admins},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Ícone filtro
        const Icon(Icons.filter_list, size: 14, color: Color(0xFF9CA3AF)),
        Text(
          'Tipo:',
          style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF9CA3AF)),
        ),
        // Botões de tipo
        ...tipoOpts.map((o) {
          final isActive = state.filtroTipo == o['k'];
          return _FilterButton(
            label: o['l'] as String,
            count: o['n'] as int,
            isActive: isActive,
            onTap: () => notifier.setFiltroTipo(o['k'] as String),
          );
        }),
        // Status
        const SizedBox(width: 4),
        Text(
          'Status:',
          style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF9CA3AF)),
        ),
        _StatusDropdown(
          value: state.filtroStatus,
          onChanged: notifier.setFiltroStatus,
        ),
        // Resultado count
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${state.filtrados} resultado${state.filtrados != 1 ? 's' : ''}',
            style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF9CA3AF)),
          ),
        ),
      ],
    );
  }
}

class _FilterButton extends StatefulWidget {
  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_FilterButton> createState() => _FilterButtonState();
}

class _FilterButtonState extends State<_FilterButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isActive
                ? const Color(0xFFEFF6FF)
                : _hover
                    ? const Color(0xFFF9F8F7)
                    : Colors.white,
            border: Border.all(
              color: widget.isActive
                  ? const Color(0xFF3B82F6)
                  : _hover
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFFEAE8E4),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: GoogleFonts.dmSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: widget.isActive || _hover
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                      : const Color(0xFFF4F2EF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.count}',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: widget.isActive
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _StatusDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEAE8E4), width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: value,
        isDense: true,
        underline: const SizedBox.shrink(),
        style: GoogleFonts.dmSans(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6B7280),
        ),
        onChanged: (v) => onChanged(v!),
        items: const [
          DropdownMenuItem(value: 'todos',   child: Text('Todos os status')),
          DropdownMenuItem(value: 'ativo',    child: Text('Ativo')),
          DropdownMenuItem(value: 'suspenso', child: Text('Suspenso')),
          DropdownMenuItem(value: 'banido',   child: Text('Banido')),
          DropdownMenuItem(value: 'inativo',  child: Text('Inativo')),
        ],
      ),
    );
  }
}

// ── Usuario List Item (linha da tabela) ───────────────────────────────────────

class UsuarioListItem extends StatefulWidget {
  final UsuarioAdmModel usuario;
  final VoidCallback onVerDetalhes;
  final VoidCallback onSuspender;
  final VoidCallback onReativar;

  const UsuarioListItem({
    super.key,
    required this.usuario,
    required this.onVerDetalhes,
    required this.onSuspender,
    required this.onReativar,
  });

  @override
  State<UsuarioListItem> createState() => _UsuarioListItemState();
}

class _UsuarioListItemState extends State<UsuarioListItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final u = widget.usuario;
    final isAdmin = u.isAdmin;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onVerDetalhes,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          color: _hover ? const Color(0xFFFAFAF8) : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              // Coluna Usuário (flex 2.2)
              Expanded(
                flex: 22,
                child: Row(
                  children: [
                    UserAvatar(nome: u.nome, tipo: u.tipoUsuario),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  u.nome.isEmpty ? 'Sem nome' : u.nome,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1A0910),
                                  ),
                                ),
                              ),
                              if (isAdmin) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    border: Border.all(color: const Color(0xFFFCA5A5)),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '🛡️ ADMIN',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFEF4444),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            u.email,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Tipo
              SizedBox(width: 110, child: TipoBadge(tipo: u.tipoUsuario)),
              const SizedBox(width: 8),

              // Status
              SizedBox(width: 100, child: StatusBadge(status: u.status)),
              const SizedBox(width: 8),

              // Verificado
              SizedBox(
                width: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _VerificadoChip(verificado: u.emailVerificado, label: 'E-mail'),
                    const SizedBox(height: 3),
                    _VerificadoChip(verificado: u.telefoneVerificado, label: 'Tel.'),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Cadastro
              SizedBox(
                width: 70,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u.createdAt != null
                          ? '${u.createdAt!.day.toString().padLeft(2,'0')}/'
                            '${u.createdAt!.month.toString().padLeft(2,'0')}/'
                            '${u.createdAt!.year}'
                          : '—',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    if (u.createdAt != null)
                      Text(
                        _elapsedLabel(u.createdAt!),
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Ações
              SizedBox(
                width: 130,
                child: GestureDetector(
                  onTap: () {}, // absorve o tap para não propagar para a linha
                  child: Row(
                    children: [
                      if (!isAdmin && u.status == 'ativo')
                        _ActionButton(
                          icon: Icons.block_outlined,
                          tooltip: 'Suspender',
                          color: const Color(0xFF92400E),
                          bg: const Color(0xFFFFFBEB),
                          border: const Color(0xFFFDE68A),
                          onTap: widget.onSuspender,
                        ),
                      if (!isAdmin && (u.status == 'suspenso' || u.status == 'banido'))
                        _ActionButton(
                          icon: Icons.lock_open_outlined,
                          tooltip: 'Reativar',
                          color: const Color(0xFF065F46),
                          bg: const Color(0xFFECFDF5),
                          border: const Color(0xFFA7F3D0),
                          onTap: widget.onReativar,
                        ),
                      const SizedBox(width: 4),
                      _ActionButton(
                        icon: Icons.remove_red_eye_outlined,
                        tooltip: 'Ver detalhes',
                        color: const Color(0xFF1E40AF),
                        bg: const Color(0xFFEFF6FF),
                        border: const Color(0xFFBFDBFE),
                        onTap: widget.onVerDetalhes,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerificadoChip extends StatelessWidget {
  final bool verificado;
  final String label;
  const _VerificadoChip({required this.verificado, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          verificado ? Icons.check_circle_outline : Icons.cancel_outlined,
          size: 11,
          color: verificado ? const Color(0xFF10B981) : const Color(0xFFD1D5DB),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: verificado ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color color, bg, border;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.bg,
    required this.border,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: _hover ? widget.bg : Colors.white,
              border: Border.all(
                color: _hover ? widget.border : const Color(0xFFEAE8E4),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(widget.icon, size: 13, color: _hover ? widget.color : const Color(0xFF6B7280)),
          ),
        ),
      ),
    );
  }
}

// ── Shimmer rows ──────────────────────────────────────────────────────────────

class UsuariosShimmerRow extends StatelessWidget {
  const UsuariosShimmerRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFF3F4F6),
      highlightColor: const Color(0xFFE5E7EB),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        color: Colors.white,
        child: Row(
          children: List.generate(
            6,
            (i) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _elapsedLabel(DateTime dt) {
  final diff = DateTime.now().difference(dt).inDays;
  if (diff == 0) return 'hoje';
  if (diff == 1) return 'ontem';
  return 'há ${diff}d';
}
