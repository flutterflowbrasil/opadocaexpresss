import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/entregador_adm_model.dart';

class EntregadorDetalhesModal extends StatefulWidget {
  final EntregadorAdmModel entregador;
  final bool isSubmitting;
  final VoidCallback onClose;
  final void Function(String acao, EntregadorAdmModel e) onAcao;
  final void Function(EntregadorAdmModel e) onAbrirSelfie;

  const EntregadorDetalhesModal({
    super.key,
    required this.entregador,
    required this.isSubmitting,
    required this.onClose,
    required this.onAcao,
    required this.onAbrirSelfie,
  });

  @override
  State<EntregadorDetalhesModal> createState() =>
      _EntregadorDetalhesModalState();
}

class _EntregadorDetalhesModalState extends State<EntregadorDetalhesModal> {
  String _tab = 'dados';

  static const _tabs = [
    ('dados',   'Dados Pessoais'),
    ('veiculo', 'Veículo & CNH'),
    ('selfie',  'Selfie'),
    ('docs',    'Documentos'),
    ('acoes',   'Ações'),
  ];

  static const _docLabels = {
    'selfie':     ('🤳', 'Selfie (verificação facial)'),
    'cnh_frente': ('🪪', 'CNH — Frente'),
    'cnh_verso':  ('🪪', 'CNH — Verso'),
    'veiculo':    ('🏍️', 'Foto do Veículo'),
    'residencia': ('📄', 'Comprovante de Residência'),
  };

  EntregadorAdmModel get e => widget.entregador;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 620,
          constraints: const BoxConstraints(maxHeight: 740),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2), blurRadius: 64)
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              _buildTabBar(),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
                  child: _buildTabContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    const stConfig = {
      'pendente':  (Color(0xFFF59E0B), Color(0xFFFFFBEB), Color(0xFFFDE68A), 'Pendente'),
      'aprovado':  (Color(0xFF10B981), Color(0xFFECFDF5), Color(0xFFA7F3D0), 'Aprovado'),
      'suspenso':  (Color(0xFFEF4444), Color(0xFFFEF2F2), Color(0xFFFCA5A5), 'Suspenso'),
      'rejeitado': (Color(0xFF6B7280), Color(0xFFF9FAFB), Color(0xFFE5E7EB), 'Rejeitado'),
    };
    const veiculoIcon = {'moto': '🏍️', 'carro': '🚗', 'bicicleta': '🚲', 'van': '🚐'};
    final st = stConfig[e.statusCadastro] ?? stConfig['pendente']!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEFF6FF), Color(0xFFBFDBFE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
                ),
                child: Center(
                    child: Text(
                        veiculoIcon[e.tipoVeiculo] ?? '🏍️',
                        style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(e.nome,
                            style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1A0910))),
                        _pill(st.$4, st.$1, st.$2, st.$3),
                        if (e.statusOnline)
                          _pill('● Online', const Color(0xFF10B981),
                              const Color(0xFFECFDF5), const Color(0xFFA7F3D0)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 12,
                      children: [
                        if (e.email != null)
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.mail_outline, size: 12, color: Color(0xFF9CA3AF)),
                            const SizedBox(width: 3),
                            Text(e.email!, style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF6B7280))),
                          ]),
                        if (e.telefone != null)
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.phone_outlined, size: 12, color: Color(0xFF9CA3AF)),
                            const SizedBox(width: 3),
                            Text(e.telefone!, style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF6B7280))),
                          ]),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFFEAE8E4), width: 1.5)),
                  child: const Icon(Icons.close, size: 14, color: Color(0xFF6B7280)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // KPIs rápidos
          Row(
            children: [
              _kpiCell('Veículo', e.veiculoModelo ?? '—', const Color(0xFF1A0910)),
              const SizedBox(width: 8),
              _kpiCell('Entregas', '${e.totalEntregas}', const Color(0xFFF97316)),
              const SizedBox(width: 8),
              _kpiCell('Avaliação',
                  e.totalAvaliacoes > 0 ? '${e.avaliacaoMedia.toStringAsFixed(1)}★ (${e.totalAvaliacoes})' : '—',
                  const Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              _kpiCell('Ganhos', _fmt(e.ganhoTotal), const Color(0xFF10B981)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab bar ───────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
          border: Border(
        top: BorderSide(color: Color(0xFFF3F1EE)),
        bottom: BorderSide(color: Color(0xFFEAE8E4)),
      )),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: _tabs.map((t) {
          final active = _tab == t.$1;
          String label = t.$2;
          if (t.$1 == 'docs') {
            label = 'Docs (${e.docCount}/${EntregadorAdmModel.docTotal})';
          }
          return GestureDetector(
            onTap: () => setState(() => _tab = t.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: active
                            ? const Color(0xFFF97316)
                            : Colors.transparent,
                        width: 2)),
              ),
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active
                      ? const Color(0xFFF97316)
                      : const Color(0xFF9CA3AF),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Tab content ───────────────────────────────────────────────────────────

  Widget _buildTabContent() {
    return switch (_tab) {
      'dados'   => _tabDados(),
      'veiculo' => _tabVeiculo(),
      'selfie'  => _tabSelfie(),
      'docs'    => _tabDocs(),
      'acoes'   => _tabAcoes(),
      _ => const SizedBox.shrink(),
    };
  }

  // ── Tab: Dados ────────────────────────────────────────────────────────────

  Widget _tabDados() {
    final fields = [
      ('Nome completo', e.nome),
      ('CPF', e.cpf ?? '—'),
      ('E-mail', e.email ?? '—'),
      ('Telefone', e.telefone ?? '—'),
      ('Data nascimento', e.dataNascimento != null ? DateFormat('dd/MM/yyyy').format(e.dataNascimento!) : '—'),
      ('Cadastrado', _elapsed(e.createdAt)),
      ('Ganhos disponíveis', _fmt(e.ganhoDisponivel)),
      ('Wallet Asaas', e.asaasWalletId ?? 'Não vinculada'),
    ];
    return Column(
      children: [
        _infoGrid(fields),
        if (e.motivoRejeicao != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Motivo da rejeição/suspensão',
                    style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF991B1B))),
                const SizedBox(height: 4),
                Text(e.motivoRejeicao!,
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: const Color(0xFFDC2626))),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Tab: Veículo & CNH ────────────────────────────────────────────────────

  Widget _tabVeiculo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoGrid([
          ('Tipo', (e.tipoVeiculo ?? '—').toUpperCase()),
          ('Modelo', e.veiculoModelo ?? '—'),
          ('Placa', e.veiculoPlaca ?? 'Sem placa'),
          ('Cor', e.veiculoCor ?? '—'),
        ]),
        const SizedBox(height: 10),
        _infoGridCustom([
          ('Número CNH', e.cnhNumero ?? 'Não informado', false),
          ('Categoria', e.cnhCategoria ?? '—', false),
          ('Validade CNH',
              e.cnhValidade != null
                  ? DateFormat('dd/MM/yyyy').format(e.cnhValidade!)
                  : '—',
              e.cnhVencida),
        ]),
        if (e.cnhVencida) ...[
          const SizedBox(height: 10),
          _warningBanner('⚠️ CNH vencida — aprove somente após regularização.'),
        ],
      ],
    );
  }

  // ── Tab: Selfie ───────────────────────────────────────────────────────────

  Widget _tabSelfie() {
    final selfie = e.selfieRevisao;
    const selfieStCfg = {
      'aprovado':       (Color(0xFF10B981), Color(0xFFECFDF5), Color(0xFFA7F3D0), '✅ Selfie Aprovada'),
      'revisao_manual': (Color(0xFFF59E0B), Color(0xFFFFFBEB), Color(0xFFFDE68A), '👁 Aguardando Revisão'),
      'reprovado':      (Color(0xFFEF4444), Color(0xFFFEF2F2), Color(0xFFFCA5A5), '❌ Selfie Reprovada'),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Text(
            '📋 O entregador envia a selfie pelo app Flutter. O admin visualiza no '
            'Supabase Storage (bucket: documentos-entregador) e aprova/rejeita aqui.',
            style: GoogleFonts.dmSans(
                fontSize: 11,
                color: const Color(0xFF3B82F6),
                height: 1.6),
          ),
        ),
        const SizedBox(height: 12),

        if (selfie == null)
          _emptyCard('🤳', 'Selfie não enviada',
              'O entregador ainda não enviou a foto no app.')
        else ...[
          Builder(builder: (_) {
            final cfg = selfieStCfg[selfie.status] ?? selfieStCfg['revisao_manual']!;
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cfg.$2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cfg.$3),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cfg.$4,
                            style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: cfg.$1)),
                        if (selfie.revisadoEm != null)
                          Text(
                            'Revisado em ${DateFormat('dd/MM/yyyy').format(selfie.revisadoEm!)}',
                            style: GoogleFonts.dmSans(
                                fontSize: 10, color: const Color(0xFF9CA3AF)),
                          ),
                      ],
                    ),
                  ),
                  if (selfie.status != 'aprovado')
                    GestureDetector(
                      onTap: () => widget.onAbrirSelfie(e),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFF3B82F6), width: 1.5),
                        ),
                        child: Text('Revisar agora',
                            style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E40AF))),
                      ),
                    ),
                ],
              ),
            );
          }),
          if (selfie.observacaoAdmin != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F8F7),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: const Color(0xFFEAE8E4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('OBSERVAÇÃO DO ADMIN',
                      style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF9CA3AF))),
                  const SizedBox(height: 4),
                  Text(selfie.observacaoAdmin!,
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: const Color(0xFF374151))),
                ],
              ),
            ),
          ],
        ],

        if (e.docEnviado('selfie')) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => widget.onAbrirSelfie(e),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF3B82F6), width: 2),
              ),
              child: Center(
                child: Text('🤳  Abrir revisão de selfie',
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E40AF))),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Tab: Documentos ───────────────────────────────────────────────────────

  Widget _tabDocs() {
    return Column(
      children: [
        // Progress bar geral
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: e.docCount / EntregadorAdmModel.docTotal,
                  minHeight: 6,
                  backgroundColor:
                      e.docCount == EntregadorAdmModel.docTotal
                          ? const Color(0xFFD1FAE5)
                          : const Color(0xFFFEF3C7),
                  color:
                      e.docCount == EntregadorAdmModel.docTotal
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text('${e.docCount}/${EntregadorAdmModel.docTotal} enviados',
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: e.docCount == EntregadorAdmModel.docTotal
                        ? const Color(0xFF065F46)
                        : const Color(0xFF92400E))),
          ],
        ),
        const SizedBox(height: 12),
        ...EntregadorAdmModel.docTipos.map((tipo) {
          final ok = e.docEnviado(tipo);
          final validacao = e.docs[tipo]; // 'pendente' | 'aprovado' | 'reprovado' | null
          final label = _docLabels[tipo];
          final isSelfie = tipo == 'selfie';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                    color: ok
                        ? const Color(0xFFA7F3D0)
                        : const Color(0xFFFCA5A5),
                    width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color:
                          ok ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                        child: Text(label?.$1 ?? '📄',
                            style: const TextStyle(fontSize: 18))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(label?.$2 ?? tipo,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1A0910))),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('Obrigatório',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFEF4444))),
                            ),
                          ],
                        ),
                        Text(
                          isSelfie
                              ? ok
                                  ? 'Enviada · ${_selfieStatusLabel(e.selfieRevisao?.status)}'
                                  : 'Não enviada pelo entregador'
                              : ok
                                  ? 'Enviado · ${_validacaoLabel(validacao)}'
                                  : 'Não enviado pelo entregador',
                          style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: ok
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444)),
                        ),
                      ],
                    ),
                  ),
                  if (isSelfie && ok)
                    GestureDetector(
                      onTap: () => widget.onAbrirSelfie(e),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                              color: const Color(0xFF3B82F6), width: 1.5),
                        ),
                        child: Text('Revisar',
                            style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E40AF))),
                      ),
                    )
                  else if (ok)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('✓ Enviado',
                          style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF10B981))),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Tab: Ações ────────────────────────────────────────────────────────────

  Widget _tabAcoes() {
    final selfieOk = e.selfieRevisao?.status == 'aprovado';
    final docsOk = e.docCount == EntregadorAdmModel.docTotal;
    final cnhOk = !e.cnhVencida && e.cnhNumero != null;
    final veiculoOk = e.tipoVeiculo != null;
    final telefoneOk = e.telefone != null;

    final checklist = [
      (selfieOk, 'Selfie aprovada pelo admin'),
      (docsOk, 'Todos os documentos enviados (${EntregadorAdmModel.docTotal}/${EntregadorAdmModel.docTotal})'),
      (cnhOk, 'CNH válida e não vencida'),
      (veiculoOk, 'Tipo de veículo selecionado'),
      (telefoneOk, 'Telefone cadastrado'),
    ];
    final allOk = checklist.every((c) => c.$1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Checklist
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: allOk ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
                color: allOk
                    ? const Color(0xFFA7F3D0)
                    : const Color(0xFFFDE68A),
                width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                allOk ? '✅ Pronto para aprovação' : '⚠️ Checklist de aprovação',
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: allOk
                        ? const Color(0xFF065F46)
                        : const Color(0xFF92400E)),
              ),
              const SizedBox(height: 10),
              ...checklist.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: item.$1
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFFEF2F2),
                            border: Border.all(
                                color: item.$1
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                width: 1.5),
                          ),
                          child: Icon(
                            item.$1 ? Icons.check : Icons.close,
                            size: 10,
                            color: item.$1
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(item.$2,
                              style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: item.$1
                                      ? FontWeight.w500
                                      : FontWeight.w600,
                                  color: item.$1
                                      ? const Color(0xFF065F46)
                                      : const Color(0xFFDC2626))),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Botões de ação contextuais
        if (e.statusCadastro == 'pendente') ...[
          _acaoBtn(
            icon: '✅',
            title: 'Aprovar cadastro',
            subtitle: 'Libera o entregador. Cria carteira Asaas automaticamente.',
            borderColor: const Color(0xFFA7F3D0),
            bgColor: const Color(0xFFECFDF5),
            textColor: const Color(0xFF065F46),
            opacity: allOk ? 1.0 : 0.5,
            onTap: () => widget.onAcao('aprovar', e),
          ),
          const SizedBox(height: 8),
          _acaoBtn(
            icon: '❌',
            title: 'Rejeitar cadastro',
            subtitle: 'Notifica com motivo. Cadastro arquivado.',
            borderColor: const Color(0xFFFCA5A5),
            bgColor: const Color(0xFFFEF2F2),
            textColor: const Color(0xFF991B1B),
            onTap: () => widget.onAcao('rejeitar', e),
          ),
        ],
        if (e.statusCadastro == 'aprovado')
          _acaoBtn(
            icon: '⚠️',
            title: 'Suspender entregador',
            subtitle: 'Bloqueia novas entregas imediatamente.',
            borderColor: const Color(0xFFFDE68A),
            bgColor: const Color(0xFFFFFBEB),
            textColor: const Color(0xFF92400E),
            onTap: () => widget.onAcao('suspender', e),
          ),
        if (e.statusCadastro == 'suspenso' || e.statusCadastro == 'rejeitado')
          _acaoBtn(
            icon: '🔓',
            title: 'Reativar entregador',
            subtitle: 'Retorna ao status aprovado.',
            borderColor: const Color(0xFFA7F3D0),
            bgColor: const Color(0xFFECFDF5),
            textColor: const Color(0xFF065F46),
            onTap: () => widget.onAcao('reativar', e),
          ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _pill(String label, Color color, Color bg, Color border) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(label,
          style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color)),
    );
  }

  Widget _kpiCell(String label, String value, Color color) {
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
            Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF9CA3AF),
                    letterSpacing: 0.3)),
            const SizedBox(height: 2),
            Text(value,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ],
        ),
      ),
    );
  }

  Widget _infoGrid(List<(String, String)> fields) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 3.5,
      children: fields
          .map((f) => _infoCell(f.$1, f.$2, alert: false))
          .toList(),
    );
  }

  Widget _infoGridCustom(List<(String, String, bool)> fields) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.8,
      children:
          fields.map((f) => _infoCell(f.$1, f.$2, alert: f.$3)).toList(),
    );
  }

  Widget _infoCell(String label, String value, {required bool alert}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: alert ? const Color(0xFFFEF2F2) : const Color(0xFFF9F8F7),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
            color: alert
                ? const Color(0xFFFCA5A5)
                : const Color(0xFFEAE8E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label.toUpperCase(),
              style: GoogleFonts.dmSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: alert
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF9CA3AF),
                  letterSpacing: 0.3)),
          const SizedBox(height: 2),
          Text(value,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: alert
                      ? const Color(0xFFDC2626)
                      : value == 'Não vinculada'
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF1A0910))),
        ],
      ),
    );
  }

  Widget _acaoBtn({
    required String icon,
    required String title,
    required String subtitle,
    required Color borderColor,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
    double opacity = 1.0,
  }) {
    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: widget.isSubmitting ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textColor)),
                    Text(subtitle,
                        style: GoogleFonts.dmSans(
                            fontSize: 11, color: textColor.withValues(alpha: 0.7))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _warningBanner(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Text(msg,
          style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFDC2626))),
    );
  }

  Widget _emptyCard(String icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F8F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAE8E4)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(title,
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151))),
          const SizedBox(height: 4),
          Text(subtitle,
              style: GoogleFonts.dmSans(
                  fontSize: 11, color: const Color(0xFF9CA3AF))),
        ],
      ),
    );
  }

  // ── Formatters ────────────────────────────────────────────────────────────

  String _fmt(double v) =>
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(v);

  String _elapsed(DateTime? dt) {
    if (dt == null) return '—';
    final d = DateTime.now().difference(dt).inDays;
    if (d == 0) return 'hoje';
    if (d == 1) return 'ontem';
    return 'há $d dias';
  }

  String _validacaoLabel(String? status) {
    return switch (status) {
      'aprovado' => 'Aprovado',
      'reprovado' => 'Reprovado',
      _ => 'Pendente',
    };
  }

  String _selfieStatusLabel(String? status) {
    return switch (status) {
      'aprovado' => 'Selfie aprovada',
      'revisao_manual' => 'Aguardando revisão',
      'reprovado' => 'Selfie reprovada',
      _ => 'Aguardando revisão',
    };
  }
}
