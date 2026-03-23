import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/estab_adm_model.dart';
import 'estab_confirm_modal.dart';

class EstabDetalhesModal extends StatefulWidget {
  final EstabAdmModel estab;
  final void Function(String acao, String estabId, String motivo) onAcao;
  final VoidCallback onClose;
  final bool isSubmitting;

  const EstabDetalhesModal({
    super.key,
    required this.estab,
    required this.onAcao,
    required this.onClose,
    required this.isSubmitting,
  });

  @override
  State<EstabDetalhesModal> createState() => _EstabDetalhesModalState();
}

class _EstabDetalhesModalState extends State<EstabDetalhesModal> {
  String _tab = 'dados';
  String? _acaoConfirm;

  static const _statusCfg = {
    'aprovado': (
      label: 'Aprovado',
      color: Color(0xFF10B981),
      bg: Color(0xFFECFDF5),
      border: Color(0xFFA7F3D0),
    ),
    'pendente': (
      label: 'Pendente',
      color: Color(0xFFF59E0B),
      bg: Color(0xFFFFFBEB),
      border: Color(0xFFFDE68A),
    ),
    'suspenso': (
      label: 'Suspenso',
      color: Color(0xFFEF4444),
      bg: Color(0xFFFEF2F2),
      border: Color(0xFFFCA5A5),
    ),
    'rejeitado': (
      label: 'Rejeitado',
      color: Color(0xFF6B7280),
      bg: Color(0xFFF9FAFB),
      border: Color(0xFFE5E7EB),
    ),
  };

  static const _docLista = [
    ('contrato_social', 'Contrato Social'),
    ('alvara_funcionamento', 'Alvará de Funcionamento'),
    ('comprovante_endereco', 'Comprovante de Endereço'),
  ];

  @override
  Widget build(BuildContext context) {
    final cfg = _statusCfg[widget.estab.statusCadastro] ?? _statusCfg['pendente']!;
    final docs = widget.estab.documentos ?? {};
    final db = widget.estab.dadosBancarios ?? {};
    final docOk = _docLista.where((d) => docs[d.$1] != null).length;
    final docTotal = _docLista.length;

    if (_acaoConfirm != null) {
      return EstabConfirmModal(
        acao: _acaoConfirm!,
        estab: widget.estab,
        onClose: () => setState(() => _acaoConfirm = null),
        onConfirm: (acao, motivo) {
          setState(() => _acaoConfirm = null);
          widget.onAcao(acao, widget.estab.id, motivo);
        },
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Center(
        child: Container(
          width: 600,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 48,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFF7ED), Color(0xFFFED7AA)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: const Color(0xFFFED7AA), width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              widget.estab.nomeFantasia.isNotEmpty
                                  ? widget.estab.nomeFantasia[0].toUpperCase()
                                  : '🏪',
                              style: GoogleFonts.publicSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFF97316),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      widget.estab.nomeFantasia,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.publicSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF1A0910),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cfg.bg,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: cfg.border),
                                    ),
                                    child: Text(
                                      cfg.label,
                                      style: GoogleFonts.publicSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: cfg.color,
                                      ),
                                    ),
                                  ),
                                  if (widget.estab.destaque) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF7ED),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: const Color(0xFFFED7AA)),
                                      ),
                                      child: Text(
                                        '⭐ DESTAQUE',
                                        style: GoogleFonts.publicSans(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFF97316),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${widget.estab.razaoSocial}${widget.estab.cnpj != null ? ' · CNPJ ${widget.estab.cnpj}' : ''}',
                                style: GoogleFonts.publicSans(
                                  fontSize: 11,
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 10,
                                children: [
                                  if (widget.estab.telefoneComercial != null)
                                    _InfoChip(
                                      icon: Icons.phone_outlined,
                                      text: widget.estab.telefoneComercial!,
                                    ),
                                  if (widget.estab.emailComercial != null)
                                    _InfoChip(
                                      icon: Icons.mail_outline,
                                      text: widget.estab.emailComercial!,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onClose,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFEAE8E4)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 15,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // KPIs rápidos
                    Row(
                      children: [
                        _QuickKpi(
                          label: 'Faturamento',
                          value: _fmtCurrency(widget.estab.faturamentoTotal ?? 0),
                          color: const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 8),
                        _QuickKpi(
                          label: 'Pedidos',
                          value: '${widget.estab.totalPedidos ?? 0}',
                          color: const Color(0xFFF97316),
                        ),
                        const SizedBox(width: 8),
                        _QuickKpi(
                          label: 'Avaliação',
                          value: widget.estab.avaliacaoMedia > 0
                              ? '${widget.estab.avaliacaoMedia.toStringAsFixed(1)} ★'
                              : '—',
                          color: const Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 8),
                        _QuickKpi(
                          label: 'Cadastro',
                          value: _elapsed(widget.estab.createdAt),
                          color: const Color(0xFF6B7280),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Tabs
                    Row(
                      children: [
                        _Tab(
                          id: 'dados',
                          label: 'Dados Cadastrais',
                          activeTab: _tab,
                          onTap: (t) => setState(() => _tab = t),
                        ),
                        _Tab(
                          id: 'docs',
                          label: 'Documentos ($docOk/$docTotal)',
                          activeTab: _tab,
                          onTap: (t) => setState(() => _tab = t),
                        ),
                        _Tab(
                          id: 'bancario',
                          label: 'Dados Bancários',
                          activeTab: _tab,
                          onTap: (t) => setState(() => _tab = t),
                        ),
                        _Tab(
                          id: 'acoes',
                          label: 'Ações',
                          activeTab: _tab,
                          onTap: (t) => setState(() => _tab = t),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEAE8E4)),

              // ── Corpo scrollável ────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: _buildTabContent(docs, db, docOk, docTotal),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(
    Map<String, dynamic> docs,
    Map<String, dynamic> db,
    int docOk,
    int docTotal,
  ) {
    return switch (_tab) {
      'dados' => _buildTabDados(),
      'docs' => _buildTabDocs(docs, docOk, docTotal),
      'bancario' => _buildTabBancario(db),
      'acoes' => _buildTabAcoes(),
      _ => const SizedBox.shrink(),
    };
  }

  // ── Tab Dados ────────────────────────────────────────────
  Widget _buildTabDados() {
    final fields = [
      ('Responsável', widget.estab.responsavelNome),
      ('CPF Responsável', widget.estab.responsavelCpf),
      ('Tempo médio entrega', '${widget.estab.tempoMedioEntregaMin ?? 40} min'),
      ('Conta Asaas', widget.estab.asaasAccountId ?? 'Não vinculada'),
      ('Cadastrado em', _fmtDate(widget.estab.createdAt)),
      ('Aberto agora', widget.estab.statusAberto ? 'Sim' : 'Não'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Grid2(fields: fields),
        if (widget.estab.motivoSuspensao != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFEF4444),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Motivo da suspensão/rejeição',
                        style: GoogleFonts.publicSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF991B1B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.estab.motivoSuspensao!,
                        style: GoogleFonts.publicSans(
                          fontSize: 12,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Tab Documentos ───────────────────────────────────────
  Widget _buildTabDocs(Map<String, dynamic> docs, int docOk, int docTotal) {
    final pct = docTotal > 0 ? docOk / docTotal : 0.0;
    final allOk = docOk == docTotal;

    return Column(
      children: [
        // Progress bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: allOk ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: allOk ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: allOk
                        ? const Color(0xFFD1FAE5)
                        : const Color(0xFFFEF3C7),
                    valueColor: AlwaysStoppedAnimation(
                      allOk ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$docOk/$docTotal docs enviados',
                style: GoogleFonts.publicSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: allOk
                      ? const Color(0xFF065F46)
                      : const Color(0xFF92400E),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ..._docLista.map((d) {
          final ok = docs[d.$1] != null;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: ok ? const Color(0xFFA7F3D0) : const Color(0xFFFCA5A5),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ok ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    size: 18,
                    color: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.$2,
                        style: GoogleFonts.publicSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A0910),
                        ),
                      ),
                      Text(
                        ok ? 'Documento enviado' : 'Não enviado',
                        style: GoogleFonts.publicSans(
                          fontSize: 11,
                          color: ok
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: ok ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ok ? '✓ OK' : 'Pendente',
                    style: GoogleFonts.publicSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Tab Bancário ─────────────────────────────────────────
  Widget _buildTabBancario(Map<String, dynamic> db) {
    final hasData = db.values.any((v) => v != null && v != '');
    if (!hasData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Column(
            children: [
              const Text('🏦', style: TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                'Dados bancários não cadastrados',
                style: GoogleFonts.publicSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'O estabelecimento ainda não informou conta para repasse.',
                textAlign: TextAlign.center,
                style: GoogleFonts.publicSans(
                  fontSize: 11,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final fields = [
      ('Titular', db['titular']),
      ('Banco', db['banco']),
      ('Agência', db['agencia']),
      ('Conta', db['conta']),
      ('Tipo', db['tipo_conta']),
      ('Chave Pix', db['pix_chave']),
    ].where((f) => f.$2 != null).map((f) => (f.$1, f.$2 as String?)).toList();

    return _Grid2(fields: fields);
  }

  // ── Tab Ações ────────────────────────────────────────────
  Widget _buildTabAcoes() {
    final status = widget.estab.statusCadastro;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações disponíveis para este estabelecimento:',
          style: GoogleFonts.publicSans(
            fontSize: 11,
            color: const Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 10),

        if (status == 'pendente') ...[
          _AcaoBtn(
            emoji: '✅',
            titulo: 'Aprovar cadastro',
            subtitulo: 'Libera o estabelecimento na plataforma.',
            borderColor: const Color(0xFFA7F3D0),
            bgColor: const Color(0xFFECFDF5),
            textColor: const Color(0xFF065F46),
            onTap: () => setState(() => _acaoConfirm = 'aprovar'),
          ),
          const SizedBox(height: 8),
          _AcaoBtn(
            emoji: '❌',
            titulo: 'Rejeitar cadastro',
            subtitulo: 'Notifica o responsável com o motivo.',
            borderColor: const Color(0xFFFCA5A5),
            bgColor: const Color(0xFFFEF2F2),
            textColor: const Color(0xFF991B1B),
            onTap: () => setState(() => _acaoConfirm = 'rejeitar'),
          ),
        ],

        if (status == 'aprovado')
          _AcaoBtn(
            emoji: '⚠️',
            titulo: 'Suspender estabelecimento',
            subtitulo: 'Bloqueia novos pedidos. Não afeta pedidos em andamento.',
            borderColor: const Color(0xFFFDE68A),
            bgColor: const Color(0xFFFFFBEB),
            textColor: const Color(0xFF92400E),
            onTap: () => setState(() => _acaoConfirm = 'suspender'),
          ),

        if (status == 'suspenso' || status == 'rejeitado')
          _AcaoBtn(
            emoji: '🔓',
            titulo: 'Reativar estabelecimento',
            subtitulo: 'Retorna ao status aprovado e libera novos pedidos.',
            borderColor: const Color(0xFFA7F3D0),
            bgColor: const Color(0xFFECFDF5),
            textColor: const Color(0xFF065F46),
            onTap: () => setState(() => _acaoConfirm = 'reativar'),
          ),

        const SizedBox(height: 14),

        // Acesso rápido
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F8F7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFEAE8E4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Acesso rápido',
                style: GoogleFonts.publicSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _QuickBtn(label: 'Ver pedidos', color: const Color(0xFFF97316)),
                  _QuickBtn(label: 'Ver cardápio', color: const Color(0xFF8B5CF6)),
                  _QuickBtn(label: 'Ver financeiro', color: const Color(0xFF10B981)),
                ],
              ),
            ],
          ),
        ),

        if (widget.isSubmitting) ...[
          const SizedBox(height: 14),
          const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFF97316),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _fmtCurrency(double v) {
    if (v >= 1000000) return 'R\$ ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'R\$ ${(v / 1000).toStringAsFixed(1)}K';
    return 'R\$ ${v.toStringAsFixed(2)}';
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _elapsed(DateTime? dt) {
    if (dt == null) return '—';
    final d = DateTime.now().difference(dt).inDays;
    if (d == 0) return 'hoje';
    if (d == 1) return 'ontem';
    return 'há $d dias';
  }
}

// ── Widgets auxiliares do modal ───────────────────────────────────────────────

class _Tab extends StatelessWidget {
  final String id;
  final String label;
  final String activeTab;
  final void Function(String) onTap;

  const _Tab({
    required this.id,
    required this.label,
    required this.activeTab,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = activeTab == id;
    return GestureDetector(
      onTap: () => onTap(id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFFF97316) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.publicSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? const Color(0xFFF97316) : const Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }
}

class _QuickKpi extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _QuickKpi({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F8F7),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFFEAE8E4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.publicSans(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF9CA3AF),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.publicSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: const Color(0xFF6B7280)),
        const SizedBox(width: 3),
        Text(
          text,
          style: GoogleFonts.publicSans(
            fontSize: 11,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

class _Grid2 extends StatelessWidget {
  final List<(String, String?)> fields;

  const _Grid2({required this.fields});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: fields.map((f) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 100) / 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F8F7),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: const Color(0xFFEAE8E4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.$1,
                  style: GoogleFonts.publicSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF9CA3AF),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  f.$2 ?? '—',
                  style: GoogleFonts.publicSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: f.$2 == null || f.$2!.startsWith('Não')
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF1A0910),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AcaoBtn extends StatelessWidget {
  final String emoji;
  final String titulo;
  final String subtitulo;
  final Color borderColor;
  final Color bgColor;
  final Color textColor;
  final VoidCallback onTap;

  const _AcaoBtn({
    required this.emoji,
    required this.titulo,
    required this.subtitulo,
    required this.borderColor,
    required this.bgColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: GoogleFonts.publicSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  Text(
                    subtitulo,
                    style: GoogleFonts.publicSans(
                      fontSize: 11,
                      color: textColor.withValues(alpha: 0.7),
                    ),
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

class _QuickBtn extends StatelessWidget {
  final String label;
  final Color color;

  const _QuickBtn({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.publicSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
