import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/usuario_adm_model.dart';
import '../widgets/usuarios_adm_widgets.dart';

// ─── Modal Detalhes do Usuário (3 abas: Perfil / Atividade / Ações) ───────────

class ModalDetalhesUsuario extends StatefulWidget {
  final UsuarioAdmModel usuario;
  final VoidCallback onClose;
  final void Function(String acao, UsuarioAdmModel usuario) onAcao;

  const ModalDetalhesUsuario({
    super.key,
    required this.usuario,
    required this.onClose,
    required this.onAcao,
  });

  @override
  State<ModalDetalhesUsuario> createState() => _ModalDetalhesUsuarioState();
}

class _ModalDetalhesUsuarioState extends State<ModalDetalhesUsuario>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.usuario;
    final tipoCfg = getTipoCfg(u.tipoUsuario);

    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.48),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 580,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 64)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [tipoCfg['bg'] as Color, Colors.white],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              UserAvatar(nome: u.nome, tipo: u.tipoUsuario, size: 52),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(spacing: 8, children: [
                                      Text(
                                        u.nome.isEmpty ? 'Sem nome' : u.nome,
                                        style: GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF1A0910)),
                                      ),
                                      TipoBadge(tipo: u.tipoUsuario),
                                      StatusBadge(status: u.status),
                                    ]),
                                    const SizedBox(height: 4),
                                    Wrap(spacing: 12, children: [
                                      Row(mainAxisSize: MainAxisSize.min, children: [
                                        const Icon(Icons.mail_outline, size: 12, color: Color(0xFF6B7280)),
                                        const SizedBox(width: 3),
                                        Text(u.email, style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF6B7280))),
                                      ]),
                                      if (u.telefone != null)
                                        Row(mainAxisSize: MainAxisSize.min, children: [
                                          const Icon(Icons.phone_outlined, size: 12, color: Color(0xFF6B7280)),
                                          const SizedBox(width: 3),
                                          Text(u.telefone!, style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF6B7280))),
                                        ]),
                                    ]),
                                    const SizedBox(height: 6),
                                    Wrap(spacing: 8, children: [
                                      _VerifChip(verificado: u.emailVerificado, label: u.emailVerificado ? '✓ E-mail verificado' : '✗ E-mail não verificado'),
                                      _VerifChip(verificado: u.telefoneVerificado, label: u.telefoneVerificado ? '✓ Tel. verificado' : '✗ Tel. não verificado'),
                                    ]),
                                  ],
                                ),
                              ),
                              _CloseButton(onTap: widget.onClose),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _MetricasDoTipo(usuario: u),
                          const SizedBox(height: 14),
                          TabBar(
                            controller: _tabController,
                            labelColor: const Color(0xFFF97316),
                            unselectedLabelColor: const Color(0xFF9CA3AF),
                            indicatorColor: const Color(0xFFF97316),
                            labelStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600),
                            unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600),
                            tabs: const [Tab(text: 'Perfil'), Tab(text: 'Atividade'), Tab(text: 'Ações')],
                          ),
                        ],
                      ),
                    ),
                    // Tabs body
                    Flexible(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _TabPerfil(usuario: u),
                          _TabAtividade(usuario: u),
                          _TabAcoes(usuario: u, onAcao: widget.onAcao),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Auxiliares ────────────────────────────────────────────────────────────────

class _VerifChip extends StatelessWidget {
  final bool verificado;
  final String label;
  const _VerifChip({required this.verificado, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: verificado ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: verificado ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
    );
  }
}

class _CloseButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
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
          duration: const Duration(milliseconds: 120),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _hover ? const Color(0xFFF4F2EF) : Colors.white,
            border: Border.all(color: const Color(0xFFEAE8E4), width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.close, size: 14, color: Color(0xFF6B7280)),
        ),
      ),
    );
  }
}

class _MetricasDoTipo extends StatelessWidget {
  final UsuarioAdmModel usuario;
  const _MetricasDoTipo({required this.usuario});

  List<Map<String, dynamic>> _metricas() {
    final u = usuario;
    if (u.tipoUsuario == 'cliente') {
      return [
        {'l': 'Pedidos',     'v': '${u.totalPedidos ?? 0}',                'c': const Color(0xFFF97316)},
        {'l': 'Gasto total', 'v': _fmt(u.valorTotalGasto),                 'c': const Color(0xFF10B981)},
        {'l': 'Pontos',      'v': '${u.pontosFidelidade ?? 0}',            'c': const Color(0xFF8B5CF6)},
      ];
    }
    if (u.tipoUsuario == 'entregador') {
      return [
        {'l': 'Entregas',   'v': '${u.totalEntregas ?? 0}',                           'c': const Color(0xFFF97316)},
        {'l': 'Avaliação',  'v': (u.totalEntregas ?? 0) > 0 ? '${u.entregadorAvaliacaoMedia?.toStringAsFixed(1)}★' : '—', 'c': const Color(0xFFF59E0B)},
        {'l': 'Status KYC', 'v': u.entregadorStatusCadastro ?? '—',                    'c': u.entregadorStatusCadastro == 'aprovado' ? const Color(0xFF10B981) : const Color(0xFFF59E0B)},
      ];
    }
    if (u.tipoUsuario == 'estabelecimento') {
      return [
        {'l': 'Pedidos', 'v': '${u.estabTotalPedidos ?? 0}', 'c': const Color(0xFFF97316)},
        {'l': 'Status',  'v': u.estabStatusCadastro ?? '—',  'c': u.estabStatusCadastro == 'aprovado' ? const Color(0xFF10B981) : const Color(0xFFF59E0B)},
        {'l': 'Loja',    'v': u.nomeFantasia ?? '—',         'c': const Color(0xFF8B5CF6)},
      ];
    }
    return [
      {'l': 'Nível',  'v': 'Admin Geral', 'c': const Color(0xFFEF4444)},
      {'l': 'Acesso', 'v': 'Total',       'c': const Color(0xFFEF4444)},
      {'l': 'Tipo',   'v': 'Sistema',     'c': const Color(0xFFEF4444)},
    ];
  }

  String _fmt(double? v) {
    if (v == null) return 'R\$ 0,00';
    return 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _metricas().map((m) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              border: Border.all(color: const Color(0xFFEAE8E4)),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((m['l'] as String).toUpperCase(), style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF9CA3AF))),
                const SizedBox(height: 2),
                Text(m['v'] as String, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w800, color: m['c'] as Color), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Tab Perfil ────────────────────────────────────────────────────────────────

class _TabPerfil extends StatelessWidget {
  final UsuarioAdmModel usuario;
  const _TabPerfil({required this.usuario});

  @override
  Widget build(BuildContext context) {
    final u = usuario;
    final tipoCfg = getTipoCfg(u.tipoUsuario);

    final campos = [
      {'l': 'Tipo',          'v': '${tipoCfg['icon']} ${tipoCfg['label']}'},
      {'l': 'E-mail',        'v': u.email},
      {'l': 'Telefone',      'v': u.telefone ?? 'Não informado'},
      {'l': 'Cadastrado em', 'v': _fmtDate(u.createdAt)},
      {'l': 'Último acesso', 'v': _fmtDateTime(u.ultimoLogin)},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.8,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: campos.length,
            itemBuilder: (_, i) {
              final c = campos[i];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F8F7),
                  border: Border.all(color: const Color(0xFFEAE8E4)),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((c['l'] as String).toUpperCase(), style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF9CA3AF))),
                    const SizedBox(height: 3),
                    Expanded(
                      child: Text(c['v'] as String, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1A0910)), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _DadosExtrasTipo(usuario: u),
        ],
      ),
    );
  }
}

// ── Dados extras por tipo ─────────────────────────────────────────────────────

class _DadosExtrasTipo extends StatelessWidget {
  final UsuarioAdmModel usuario;
  const _DadosExtrasTipo({required this.usuario});

  @override
  Widget build(BuildContext context) {
    final u = usuario;
    if (u.tipoUsuario == 'cliente') {
      return _ExtraCard(
        title: 'Dados do Cliente',
        color: const Color(0xFF1E40AF),
        bg: const Color(0xFFEFF6FF),
        border: const Color(0xFFBFDBFE),
        campos: [
          {'l': 'Pedidos',     'v': '${u.totalPedidos ?? 0}'},
          {'l': 'Total gasto', 'v': 'R\$ ${(u.valorTotalGasto ?? 0).toStringAsFixed(2).replaceAll('.', ',')}'},
          {'l': 'Pontos',      'v': '${u.pontosFidelidade ?? 0}'},
        ],
      );
    }
    if (u.tipoUsuario == 'entregador') {
      return _ExtraCard(
        title: 'Dados do Entregador',
        color: const Color(0xFF92400E),
        bg: const Color(0xFFFFF7ED),
        border: const Color(0xFFFED7AA),
        campos: [
          {'l': 'Cadastro', 'v': u.entregadorStatusCadastro ?? '—'},
          {'l': 'Entregas',  'v': '${u.totalEntregas ?? 0}'},
        ],
      );
    }
    if (u.tipoUsuario == 'estabelecimento') {
      return _ExtraCard(
        title: 'Dados do Estabelecimento',
        color: const Color(0xFF5B21B6),
        bg: const Color(0xFFF5F3FF),
        border: const Color(0xFFDDD6FE),
        campos: [
          {'l': 'Nome Fantasia', 'v': u.nomeFantasia ?? 'Não informado'},
          {'l': 'Status',        'v': u.estabStatusCadastro ?? '—'},
          {'l': 'Pedidos',       'v': '${u.estabTotalPedidos ?? 0}'},
        ],
      );
    }
    if (u.tipoUsuario == 'admin') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          border: Border.all(color: const Color(0xFFFCA5A5)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          const Text('🛡️', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Administrador Geral', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF991B1B))),
            Text('Acesso total à plataforma.', style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFFEF4444))),
          ])),
        ]),
      );
    }
    return const SizedBox.shrink();
  }
}

class _ExtraCard extends StatelessWidget {
  final String title;
  final Color color, bg, border;
  final List<Map<String, String>> campos;

  const _ExtraCard({
    required this.title,
    required this.color,
    required this.bg,
    required this.border,
    required this.campos,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, border: Border.all(color: border), borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 8),
        Wrap(spacing: 24, runSpacing: 8, children: campos.map((c) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text((c['l']!).toUpperCase(), style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w700, color: color.withValues(alpha: 0.6))),
            Text(c['v']!, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          ],
        )).toList()),
      ]),
    );
  }
}

// ── Tab Atividade ─────────────────────────────────────────────────────────────

class _TabAtividade extends StatelessWidget {
  final UsuarioAdmModel usuario;
  const _TabAtividade({required this.usuario});

  @override
  Widget build(BuildContext context) {
    final u = usuario;
    final eventos = [
      {'label': 'Conta criada',      'date': u.createdAt,   'color': const Color(0xFF10B981)},
      if (u.emailVerificado) {'label': 'E-mail verificado', 'date': null,          'color': const Color(0xFF3B82F6)},
      if (u.ultimoLogin != null) {'label': 'Último acesso', 'date': u.ultimoLogin, 'color': const Color(0xFFF97316)},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            _ActCard(icon: '📅', label: 'Cadastrado em', value: _fmtDateTime(u.createdAt)),
            _ActCard(icon: '🕐', label: 'Último acesso', value: _fmtDateTime(u.ultimoLogin)),
            _ActCard(icon: '📧', label: 'E-mail', value: u.emailVerificado ? 'Verificado ✓' : 'Não verificado ✗', color: u.emailVerificado ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
            _ActCard(icon: '📱', label: 'Telefone', value: u.telefoneVerificado ? 'Verificado ✓' : 'Não verificado ✗', color: u.telefoneVerificado ? const Color(0xFF10B981) : const Color(0xFF9CA3AF)),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F8F7),
            border: Border.all(color: const Color(0xFFEAE8E4)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Linha do tempo', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF6B7280))),
            const SizedBox(height: 10),
            ...eventos.map((ev) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: ev['color'] as Color, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ev['label'] as String, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1A0910))),
                  Text(ev['date'] != null ? _fmtDateTime(ev['date'] as DateTime?) : '—', style: GoogleFonts.dmSans(fontSize: 10, color: const Color(0xFF9CA3AF))),
                ]),
              ]),
            )),
          ]),
        ),
      ]),
    );
  }
}

class _ActCard extends StatelessWidget {
  final String icon, label, value;
  final Color? color;
  const _ActCard({required this.icon, required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF9F8F7), border: Border.all(color: const Color(0xFFEAE8E4)), borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$icon $label'.toUpperCase(), style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF9CA3AF))),
        const SizedBox(height: 4),
        Expanded(child: Text(value, style: GoogleFonts.dmSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: color ?? const Color(0xFF1A0910)), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

// ── Tab Ações ─────────────────────────────────────────────────────────────────

class _TabAcoes extends StatelessWidget {
  final UsuarioAdmModel usuario;
  final void Function(String acao, UsuarioAdmModel usuario) onAcao;

  const _TabAcoes({required this.usuario, required this.onAcao});

  @override
  Widget build(BuildContext context) {
    final u = usuario;
    if (u.isAdmin) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(22),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFFFEF2F2), border: Border.all(color: const Color(0xFFFCA5A5)), borderRadius: BorderRadius.circular(10)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🛡️', style: TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text('Usuário Admin', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF991B1B))),
            const SizedBox(height: 4),
            Text('Ações de bloqueio não estão disponíveis para administradores.', textAlign: TextAlign.center, style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFFEF4444))),
          ]),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(children: [
        if (u.status == 'ativo') ...[
          _AcaoButton(icon: '⚠️', title: 'Suspender usuário', desc: 'Bloqueia temporariamente o acesso. Pode ser revertido.', bg: const Color(0xFFFFFBEB), border: const Color(0xFFFDE68A), textColor: const Color(0xFF92400E), onTap: () => onAcao('suspender', u)),
          const SizedBox(height: 10),
          _AcaoButton(icon: '🚫', title: 'Banir usuário', desc: 'Bloqueio permanente. Impede qualquer acesso à plataforma.', bg: const Color(0xFFFEF2F2), border: const Color(0xFFFCA5A5), textColor: const Color(0xFF991B1B), onTap: () => onAcao('banir', u)),
        ],
        if (u.status == 'suspenso' || u.status == 'banido')
          _AcaoButton(icon: '🔓', title: 'Reativar usuário', desc: 'Restaura o acesso do usuário à plataforma.', bg: const Color(0xFFECFDF5), border: const Color(0xFFA7F3D0), textColor: const Color(0xFF065F46), onTap: () => onAcao('reativar', u)),
        if (!u.emailVerificado) ...[
          const SizedBox(height: 10),
          _AcaoButton(icon: '📧', title: 'Reenviar e-mail de verificação', desc: 'Envia novo link de confirmação para o e-mail do usuário.', bg: const Color(0xFFEFF6FF), border: const Color(0xFFBFDBFE), textColor: const Color(0xFF1E40AF), onTap: () {}),
        ],
      ]),
    );
  }
}

class _AcaoButton extends StatefulWidget {
  final String icon, title, desc;
  final Color bg, border, textColor;
  final VoidCallback onTap;

  const _AcaoButton({required this.icon, required this.title, required this.desc, required this.bg, required this.border, required this.textColor, required this.onTap});

  @override
  State<_AcaoButton> createState() => _AcaoButtonState();
}

class _AcaoButtonState extends State<_AcaoButton> {
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _hover ? widget.bg : Colors.white,
            border: Border.all(color: _hover ? widget.border : const Color(0xFFEAE8E4), width: 2),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(children: [
            Text(widget.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.title, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: widget.textColor)),
              Text(widget.desc, style: GoogleFonts.dmSans(fontSize: 11, color: widget.textColor.withValues(alpha: 0.7))),
            ])),
          ]),
        ),
      ),
    );
  }
}

// ─── Modal de Confirmação ─────────────────────────────────────────────────────

class ModalConfirmarAcao extends StatefulWidget {
  final String acao;
  final UsuarioAdmModel usuario;
  final void Function(String acao, String userId, String motivo) onConfirm;
  final VoidCallback onClose;

  const ModalConfirmarAcao({
    super.key,
    required this.acao,
    required this.usuario,
    required this.onConfirm,
    required this.onClose,
  });

  @override
  State<ModalConfirmarAcao> createState() => _ModalConfirmarAcaoState();
}

class _ModalConfirmarAcaoState extends State<ModalConfirmarAcao> {
  final _controller = TextEditingController();

  static const _cfg = {
    'suspender': {'title': 'Suspender usuário', 'color': Color(0xFFF59E0B), 'bg': Color(0xFFFFFBEB), 'btn': 'Confirmar suspensão',  'icon': '⚠️'},
    'banir':     {'title': 'Banir usuário',     'color': Color(0xFFEF4444), 'bg': Color(0xFFFEF2F2), 'btn': 'Confirmar banimento',  'icon': '🚫'},
    'reativar':  {'title': 'Reativar usuário',  'color': Color(0xFF10B981), 'bg': Color(0xFFECFDF5), 'btn': 'Confirmar reativação', 'icon': '🔓'},
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg[widget.acao] ?? _cfg['suspender']!;
    final precisaMotivo = widget.acao != 'reativar';
    final motivoValido = !precisaMotivo || _controller.text.trim().isNotEmpty;

    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 420,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 64)]),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF3F1EE)))),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: cfg['bg'] as Color, borderRadius: BorderRadius.circular(10)),
                      child: Center(child: Text(cfg['icon'] as String, style: const TextStyle(fontSize: 18))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(cfg['title'] as String, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF1A0910))),
                      Text(widget.usuario.nome, style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF9CA3AF))),
                    ])),
                    _CloseButton(onTap: widget.onClose),
                  ]),
                ),
                // Body
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(children: [
                    if (precisaMotivo) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('MOTIVO *', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF6B7280), letterSpacing: .5)),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _controller,
                        maxLines: 3,
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF1A0910)),
                        decoration: InputDecoration(
                          hintText: 'Descreva o motivo…',
                          hintStyle: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF9CA3AF)),
                          contentPadding: const EdgeInsets.all(12),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: Color(0xFFEAE8E4), width: 1.5)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide(color: cfg['color'] as Color, width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      GestureDetector(
                        onTap: widget.onClose,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFEAE8E4), width: 1.5), borderRadius: BorderRadius.circular(9)),
                          child: Text('Cancelar', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Opacity(
                        opacity: motivoValido ? 1.0 : 0.5,
                        child: GestureDetector(
                          onTap: motivoValido ? () => widget.onConfirm(widget.acao, widget.usuario.id, _controller.text) : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                            decoration: BoxDecoration(color: cfg['color'] as Color, borderRadius: BorderRadius.circular(9)),
                            child: Text(cfg['btn'] as String, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                      ),
                    ]),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmtDate(DateTime? dt) {
  if (dt == null) return '—';
  return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
}

String _fmtDateTime(DateTime? dt) {
  if (dt == null) return 'Nunca';
  return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year} '
      '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
}
