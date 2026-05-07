import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/estab_adm_model.dart';
import 'estab_confirm_modal.dart';

class EstabDetalhesModal extends StatefulWidget {
  final EstabAdmModel estab;
  final void Function(String acao, String estabId, String motivo) onAcao;
  final Future<void> Function(
    EstabAdmModel estab,
    String tipo,
    String status,
    String? motivo,
  ) onRevisarDocumento;
  final VoidCallback onClose;
  final bool isSubmitting;

  const EstabDetalhesModal({
    super.key,
    required this.estab,
    required this.onAcao,
    required this.onRevisarDocumento,
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

  @override
  Widget build(BuildContext context) {
    final cfg =
        _statusCfg[widget.estab.statusCadastro] ?? _statusCfg['pendente']!;

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
          width: 680,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Avatar(nome: widget.estab.nomeFantasia),
                        const SizedBox(width: 14),
                        Expanded(child: _HeaderInfo(estab: widget.estab, cfg: cfg)),
                        Tooltip(
                          message: 'Fechar',
                          child: InkWell(
                            onTap: widget.onClose,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFEAE8E4),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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
                              ? widget.estab.avaliacaoMedia.toStringAsFixed(1)
                              : '-',
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
                          label:
                              'Documentos (${widget.estab.docApprovedCount}/${widget.estab.docTotal})',
                          activeTab: _tab,
                          onTap: (t) => setState(() => _tab = t),
                        ),
                        _Tab(
                          id: 'asaas',
                          label: 'Conta Asaas',
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
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: switch (_tab) {
                    'dados' => _tabDados(),
                    'docs' => _tabDocs(),
                    'asaas' => _tabAsaas(),
                    'acoes' => _tabAcoes(),
                    _ => const SizedBox.shrink(),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabDados() {
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
          _AlertBox(text: widget.estab.motivoSuspensao!),
        ],
      ],
    );
  }

  Widget _tabDocs() {
    final allOk = widget.estab.docsObrigatoriosAprovados;
    final pct = widget.estab.docTotal > 0
        ? widget.estab.docApprovedCount / widget.estab.docTotal
        : 0.0;

    return Column(
      children: [
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
                    color: allOk
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${widget.estab.docApprovedCount}/${widget.estab.docTotal} aprovados',
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
        ...widget.estab.docTiposObrigatorios.map(_docCard),
      ],
    );
  }

  Widget _docCard(String tipo) {
    final doc = widget.estab.documentosRevisao[tipo];
    final status = widget.estab.docs[tipo];
    final enviado = doc != null;
    final aprovado = status == 'aprovado';
    final reprovado = status == 'reprovado';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: aprovado
              ? const Color(0xFFA7F3D0)
              : reprovado
                  ? const Color(0xFFFCA5A5)
                  : enviado
                      ? const Color(0xFFFDE68A)
                      : const Color(0xFFFCA5A5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          _docPreview(doc, _docShortLabel(tipo)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _docLabel(tipo),
                  style: GoogleFonts.publicSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A0910),
                  ),
                ),
                Text(
                  enviado ? 'Enviado - ${_validacaoLabel(status)}' : 'Não enviado',
                  style: GoogleFonts.publicSans(
                    fontSize: 11,
                    color: aprovado
                        ? const Color(0xFF10B981)
                        : reprovado || !enviado
                            ? const Color(0xFFEF4444)
                            : const Color(0xFFF59E0B),
                  ),
                ),
                if (doc?.motivoRejeicao != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    doc!.motivoRejeicao!,
                    style: GoogleFonts.publicSans(
                      fontSize: 10.5,
                      color: const Color(0xFF991B1B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (enviado && !aprovado)
            Wrap(
              spacing: 6,
              children: [
                _MiniButton(
                  label: 'Aprovar',
                  color: const Color(0xFF065F46),
                  bg: const Color(0xFFECFDF5),
                  border: const Color(0xFFA7F3D0),
                  disabled: widget.isSubmitting,
                  onTap: () => widget.onRevisarDocumento(
                    widget.estab,
                    tipo,
                    'aprovado',
                    null,
                  ),
                ),
                _MiniButton(
                  label: 'Reprovar',
                  color: const Color(0xFF991B1B),
                  bg: const Color(0xFFFEF2F2),
                  border: const Color(0xFFFCA5A5),
                  disabled: widget.isSubmitting,
                  onTap: () => _pedirMotivoDocumento(tipo),
                ),
              ],
            )
          else if (enviado && aprovado)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Text(
                '✔ Aprovado',
                style: GoogleFonts.publicSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF065F46),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _docPreview(EstabDocumentoInfo? doc, String fallback) {
    final url = doc?.signedUrl;
    final isPdf = (doc?.storagePath ?? '').toLowerCase().endsWith('.pdf');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: url != null && !isPdf ? () => _abrirImagemDocumento(url) : null,
      child: Container(
        width: 56,
        height: 56,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: const Color(0xFFF9F8F7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEAE8E4)),
        ),
        child: url != null && !isPdf
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(fallback, style: GoogleFonts.publicSans(fontSize: 10)),
                ),
              )
            : Center(
                child: Icon(
                  isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
                  size: 22,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
      ),
    );
  }

  Future<void> _abrirImagemDocumento(String url) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final size = MediaQuery.of(context).size;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: size.width * 0.92,
              maxHeight: size.height * 0.88,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Material(
                color: const Color(0xFF111827),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: InteractiveViewer(
                          minScale: 0.8,
                          maxScale: 5,
                          child: Center(
                            child: Image.network(
                              url,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.broken_image_outlined,
                                size: 44,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF374151),
                        ),
                        tooltip: 'Fechar imagem',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pedirMotivoDocumento(String tipo) async {
    final motivoCtrl = TextEditingController();
    final motivo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Motivo da reprova',
          style: GoogleFonts.publicSans(fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: motivoCtrl,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Ex: documento ilegível, errado ou dados divergentes.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final text = motivoCtrl.text.trim();
              if (text.isNotEmpty) Navigator.pop(context, text);
            },
            child: const Text('Reprovar'),
          ),
        ],
      ),
    );
    motivoCtrl.dispose();
    if (motivo == null || motivo.isEmpty) return;
    await widget.onRevisarDocumento(widget.estab, tipo, 'reprovado', motivo);
  }

  Widget _tabAsaas() {
    final asaas = widget.estab.asaasInfo;
    final accountId = asaas?.accountId ?? widget.estab.asaasAccountId;
    final walletId = asaas?.walletId ?? widget.estab.asaasWalletId;

    if (accountId == null && walletId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Column(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 34,
                color: Color(0xFFD1D5DB),
              ),
              const SizedBox(height: 8),
              Text(
                'Subconta Asaas ainda não criada',
                style: GoogleFonts.publicSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ela será criada automaticamente ao aprovar o cadastro.',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Grid2(
          fields: [
            ('Status', asaas?.statusConta ?? 'pending'),
            ('Account ID', accountId),
            ('Wallet ID', walletId),
            ('Onboarding', asaas?.onboardingUrl),
            ('Última sincronização', _fmtDateTime(asaas?.ultimaSincronizacao)),
          ].where((f) => f.$2 != null && f.$2!.isNotEmpty).toList(),
        ),
        if (asaas?.motivoRejeicao != null) ...[
          const SizedBox(height: 12),
          _AlertBox(text: asaas!.motivoRejeicao!),
        ],
      ],
    );
  }

  Widget _tabAcoes() {
    final status = widget.estab.statusCadastro;
    final docsOk = widget.estab.docsObrigatoriosAprovados;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: docsOk ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: docsOk ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
              width: 1.5,
            ),
          ),
          child: Text(
            docsOk
                ? 'Pronto para aprovação: documentos obrigatórios aprovados.'
                : 'Aprove os documentos obrigatórios antes da aprovação final.',
            style: GoogleFonts.publicSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: docsOk ? const Color(0xFF065F46) : const Color(0xFF92400E),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (status == 'pendente') ...[
          _AcaoBtn(
            icon: Icons.check_circle_outline,
            titulo: 'Aprovar cadastro',
            subtitulo: 'Libera o painel e cria a subconta Asaas.',
            borderColor: const Color(0xFFA7F3D0),
            bgColor: const Color(0xFFECFDF5),
            textColor: const Color(0xFF065F46),
            onTap: () => setState(() => _acaoConfirm = 'aprovar'),
          ),
          const SizedBox(height: 8),
          _AcaoBtn(
            icon: Icons.cancel_outlined,
            titulo: 'Reprovar cadastro',
            subtitulo: 'Notifica o responsável com o motivo.',
            borderColor: const Color(0xFFFCA5A5),
            bgColor: const Color(0xFFFEF2F2),
            textColor: const Color(0xFF991B1B),
            onTap: () => setState(() => _acaoConfirm = 'rejeitar'),
          ),
        ],
        if (status == 'aprovado')
          _AcaoBtn(
            icon: Icons.warning_amber_rounded,
            titulo: 'Suspender estabelecimento',
            subtitulo: 'Bloqueia novos pedidos. Não afeta pedidos em andamento.',
            borderColor: const Color(0xFFFDE68A),
            bgColor: const Color(0xFFFFFBEB),
            textColor: const Color(0xFF92400E),
            onTap: () => setState(() => _acaoConfirm = 'suspender'),
          ),
        if (status == 'suspenso' || status == 'rejeitado')
          _AcaoBtn(
            icon: Icons.lock_open_outlined,
            titulo: 'Reativar estabelecimento',
            subtitulo: 'Retorna ao status aprovado e libera novos pedidos.',
            borderColor: const Color(0xFFA7F3D0),
            bgColor: const Color(0xFFECFDF5),
            textColor: const Color(0xFF065F46),
            onTap: () => setState(() => _acaoConfirm = 'reativar'),
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

  String _docLabel(String tipo) => switch (tipo) {
        'cnh_responsavel_frente' => 'CNH - frente',
        'cnh_responsavel_verso' => 'CNH - verso',
        'identidade_responsavel_frente' => 'Identidade - frente',
        'identidade_responsavel_verso' => 'Identidade - verso',
        'comprovante_endereco' => 'Comprovante de Endereço',
        _ => tipo,
      };

  String _docShortLabel(String tipo) {
    if (tipo.contains('cnh')) return 'CNH';
    if (tipo.contains('comprovante')) return 'END';
    return 'ID';
  }

  String _validacaoLabel(String? status) => switch (status) {
        'aprovado' => 'Aprovado',
        'reprovado' => 'Reprovado',
        'pendente' => 'Aguardando revisão',
        _ => 'Não enviado',
      };

  String _fmtCurrency(double v) {
    if (v >= 1000000) return 'R\$ ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'R\$ ${(v / 1000).toStringAsFixed(1)}K';
    return 'R\$ ${v.toStringAsFixed(2)}';
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String? _fmtDateTime(DateTime? dt) {
    if (dt == null) return null;
    final date = _fmtDate(dt);
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$date $hour:$minute';
  }

  String _elapsed(DateTime? dt) {
    if (dt == null) return '-';
    final d = DateTime.now().difference(dt).inDays;
    if (d == 0) return 'hoje';
    if (d == 1) return 'ontem';
    return 'há $d dias';
  }
}

class _Avatar extends StatelessWidget {
  final String nome;

  const _Avatar({required this.nome});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          nome.isNotEmpty ? nome[0].toUpperCase() : 'E',
          style: GoogleFonts.publicSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFF97316),
          ),
        ),
      ),
    );
  }
}

class _HeaderInfo extends StatelessWidget {
  final EstabAdmModel estab;
  final ({
    String label,
    Color color,
    Color bg,
    Color border,
  }) cfg;

  const _HeaderInfo({required this.estab, required this.cfg});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                estab.nomeFantasia,
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
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
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
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${estab.razaoSocial}${estab.cnpj != null ? ' - CNPJ ${estab.cnpj}' : ''}',
          style: GoogleFonts.publicSans(
            fontSize: 11,
            color: const Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 10,
          children: [
            if (estab.telefoneComercial != null)
              _InfoChip(icon: Icons.phone_outlined, text: estab.telefoneComercial!),
            if (estab.emailComercial != null)
              _InfoChip(icon: Icons.mail_outline, text: estab.emailComercial!),
          ],
        ),
      ],
    );
  }
}

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
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              overflow: TextOverflow.ellipsis,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth > 520
            ? (constraints.maxWidth - 10) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: fields.map((f) {
            return SizedBox(
              width: itemWidth,
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
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      f.$2 ?? '-',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
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
      },
    );
  }
}

class _AcaoBtn extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final Color borderColor;
  final Color bgColor;
  final Color textColor;
  final VoidCallback onTap;

  const _AcaoBtn({
    required this.icon,
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
            Icon(icon, color: textColor, size: 22),
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
                      color: textColor.withValues(alpha: 0.72),
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

class _MiniButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final Color border;
  final bool disabled;
  final VoidCallback onTap;

  const _MiniButton({
    required this.label,
    required this.color,
    required this.bg,
    required this.border,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFFF3F4F6) : bg,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: disabled ? const Color(0xFFE5E7EB) : border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.publicSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: disabled ? const Color(0xFF9CA3AF) : color,
          ),
        ),
      ),
    );
  }
}

class _AlertBox extends StatelessWidget {
  final String text;

  const _AlertBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Text(
        text,
        style: GoogleFonts.publicSans(
          fontSize: 12,
          color: const Color(0xFF991B1B),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
