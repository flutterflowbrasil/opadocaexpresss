import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../models/entregador_adm_model.dart';

class EntregadorDetalhesModal extends StatefulWidget {
  final EntregadorAdmModel entregador;
  final bool isSubmitting;
  final VoidCallback onClose;
  final void Function(String acao, EntregadorAdmModel e) onAcao;
  final void Function(EntregadorAdmModel e) onAbrirSelfie;
  final Future<void> Function(
    EntregadorAdmModel e,
    String tipo,
    String status,
    String? motivo,
  ) onRevisarDocumento;
  final Future<void> Function(
    EntregadorAdmModel e,
    EntregadorEnderecoInfo endereco,
  ) onSalvarEndereco;
  final Future<EntregadorEnderecoInfo?> Function(EntregadorAdmModel e)?
      onRecuperarEnderecoAsaas;

  const EntregadorDetalhesModal({
    super.key,
    required this.entregador,
    required this.isSubmitting,
    required this.onClose,
    required this.onAcao,
    required this.onAbrirSelfie,
    required this.onRevisarDocumento,
    required this.onSalvarEndereco,
    this.onRecuperarEnderecoAsaas,
  });

  @override
  State<EntregadorDetalhesModal> createState() =>
      _EntregadorDetalhesModalState();
}

class _EntregadorDetalhesModalState extends State<EntregadorDetalhesModal> {
  String _tab = 'dados';
  final _cepCtrl = TextEditingController();
  final _logradouroCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _complementoCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _estadoCtrl = TextEditingController();
  bool _buscandoCep = false;
  bool _salvandoEndereco = false;
  bool _buscandoAsaas = false;
  String? _erroEndereco;

  static const _tabs = [
    ('dados', 'Dados Pessoais'),
    ('veiculo', 'Veículo'),
    ('endereco', 'Endereço'),
    ('docs', 'Documentos'),
    ('acoes', 'Ações'),
  ];

  static const _docLabels = {
    'selfie': ('🤳', 'Selfie (verificação facial)'),
    'cnh_frente': ('🪪', 'CNH — Frente'),
    'cnh_verso': ('🪪', 'CNH — Verso'),
    'identidade_frente': ('🪪', 'Identidade — Frente'),
    'identidade_verso': ('🪪', 'Identidade — Verso'),
    'veiculo': ('🏍️', 'Foto do Veículo'),
  };

  EntregadorAdmModel get e => widget.entregador;

  @override
  void initState() {
    super.initState();
    _preencherEndereco(e.endereco);
  }

  @override
  void didUpdateWidget(covariant EntregadorDetalhesModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entregador.id != widget.entregador.id ||
        oldWidget.entregador.endereco != widget.entregador.endereco) {
      _preencherEndereco(e.endereco);
    }
  }

  @override
  void dispose() {
    _cepCtrl.dispose();
    _logradouroCtrl.dispose();
    _numeroCtrl.dispose();
    _complementoCtrl.dispose();
    _bairroCtrl.dispose();
    _cidadeCtrl.dispose();
    _estadoCtrl.dispose();
    super.dispose();
  }

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
      'pendente': (
        Color(0xFFF59E0B),
        Color(0xFFFFFBEB),
        Color(0xFFFDE68A),
        'Pendente'
      ),
      'aprovado': (
        Color(0xFF10B981),
        Color(0xFFECFDF5),
        Color(0xFFA7F3D0),
        'Aprovado'
      ),
      'suspenso': (
        Color(0xFFEF4444),
        Color(0xFFFEF2F2),
        Color(0xFFFCA5A5),
        'Suspenso'
      ),
      'rejeitado': (
        Color(0xFF6B7280),
        Color(0xFFF9FAFB),
        Color(0xFFE5E7EB),
        'Rejeitado'
      ),
    };
    const veiculoIcon = {
      'moto': '🏍️',
      'carro': '🚗',
      'bicicleta': '🚲',
      'van': '🚐'
    };
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
                  border:
                      Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
                ),
                child: Center(
                    child: Text(veiculoIcon[e.tipoVeiculo] ?? '🏍️',
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
                            const Icon(Icons.mail_outline,
                                size: 12, color: Color(0xFF9CA3AF)),
                            const SizedBox(width: 3),
                            Text(e.email!,
                                style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: const Color(0xFF6B7280))),
                          ]),
                        if (e.telefone != null)
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.phone_outlined,
                                size: 12, color: Color(0xFF9CA3AF)),
                            const SizedBox(width: 3),
                            Text(e.telefone!,
                                style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: const Color(0xFF6B7280))),
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
                  child: const Icon(Icons.close,
                      size: 14, color: Color(0xFF6B7280)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // KPIs rápidos
          Row(
            children: [
              _kpiCell(
                  'Veículo', e.veiculoModelo ?? '—', const Color(0xFF1A0910)),
              const SizedBox(width: 8),
              _kpiCell(
                  'Entregas', '${e.totalEntregas}', const Color(0xFFF97316)),
              const SizedBox(width: 8),
              _kpiCell(
                  'Avaliação',
                  e.totalAvaliacoes > 0
                      ? '${e.avaliacaoMedia.toStringAsFixed(1)}★ (${e.totalAvaliacoes})'
                      : '—',
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
            label = 'Docs (${e.docCount}/${e.docTotal})';
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
      'dados' => _tabDados(),
      'veiculo' => _tabVeiculo(),
      'endereco' => _tabEndereco(),
      'docs' => _tabDocsNew(),
      'acoes' => _tabAcoes(),
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
      (
        'Data nascimento',
        e.dataNascimento != null
            ? DateFormat('dd/MM/yyyy').format(e.dataNascimento!)
            : '—'
      ),
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
        ]),
      ],
    );
  }

  Widget _tabEndereco() {
    final disabled = widget.isSubmitting || _salvandoEndereco || _buscandoAsaas;
    final temWallet = e.temCarteiraAsaas;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Text(
            temWallet
                ? 'Carteira Asaas já vinculada. Se o endereço estiver vazio, busque no Asaas ou preencha e salve para completar o cadastro.'
                : 'Endereço usado na criação da subconta Asaas do entregador. Sem ele a aprovação cria a carteira.',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF92400E),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _addressInput(
                controller: _cepCtrl,
                label: 'CEP',
                hint: '00000000',
                enabled: !disabled && !_buscandoCep,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 42,
              child: FilledButton.icon(
                onPressed: disabled || _buscandoCep ? null : _buscarCep,
                icon: _buscandoCep
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search, size: 16),
                label: Text(
                  _buscandoCep ? 'Buscando' : 'Buscar',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _addressInput(
          controller: _logradouroCtrl,
          label: 'Logradouro',
          hint: 'Rua, avenida ou travessa',
          enabled: !disabled,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _addressInput(
                controller: _numeroCtrl,
                label: 'Numero',
                hint: '123',
                enabled: !disabled,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: _addressInput(
                controller: _complementoCtrl,
                label: 'Complemento',
                hint: 'Opcional',
                enabled: !disabled,
                textCapitalization: TextCapitalization.words,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _addressInput(
          controller: _bairroCtrl,
          label: 'Bairro',
          hint: 'Bairro',
          enabled: !disabled,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _addressInput(
                controller: _cidadeCtrl,
                label: 'Cidade',
                hint: 'Cidade',
                enabled: !disabled,
                textCapitalization: TextCapitalization.words,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _addressInput(
                controller: _estadoCtrl,
                label: 'UF',
                hint: 'SP',
                enabled: !disabled,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                  LengthLimitingTextInputFormatter(2),
                ],
              ),
            ),
          ],
        ),
        if (_erroEndereco != null) ...[
          const SizedBox(height: 10),
          _warningBanner(_erroEndereco!),
        ],
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            if (temWallet && widget.onRecuperarEnderecoAsaas != null)
              OutlinedButton.icon(
                onPressed: disabled ? null : _recuperarEnderecoAsaas,
                icon: _buscandoAsaas
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_download_outlined, size: 16),
                label: Text(
                  _buscandoAsaas ? 'Buscando' : 'Buscar no Asaas',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            FilledButton.icon(
              onPressed: disabled ? null : _salvarEndereco,
              icon: _salvandoEndereco
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined, size: 16),
              label: Text(
                _salvandoEndereco ? 'Salvando' : 'Salvar endereço',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _preencherEndereco(EntregadorEnderecoInfo? endereco) {
    _cepCtrl.text = endereco?.cep ?? '';
    _logradouroCtrl.text = endereco?.logradouro ?? '';
    _numeroCtrl.text = endereco?.numero ?? '';
    _complementoCtrl.text = endereco?.complemento ?? '';
    _bairroCtrl.text = endereco?.bairro ?? '';
    _cidadeCtrl.text = endereco?.cidade ?? '';
    _estadoCtrl.text = endereco?.estado ?? '';
    _erroEndereco = null;
  }

  Future<void> _recuperarEnderecoAsaas() async {
    final recuperar = widget.onRecuperarEnderecoAsaas;
    if (recuperar == null) return;
    setState(() {
      _buscandoAsaas = true;
      _erroEndereco = null;
    });
    try {
      final endereco = await recuperar(e);
      if (!mounted) return;
      if (endereco == null) {
        setState(() {
          _erroEndereco =
              'Asaas não devolveu endereço. Preencha CEP e use Buscar, depois Salvar.';
        });
        return;
      }
      _preencherEndereco(endereco);
      if (_cepCtrl.text.replaceAll(RegExp(r'\D'), '').length == 8 &&
          _cidadeCtrl.text.trim().isEmpty) {
        await _buscarCep();
      }
      setState(() {});
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _erroEndereco = err.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _buscandoAsaas = false);
    }
  }

  EntregadorEnderecoInfo _enderecoFromForm() {
    return EntregadorEnderecoInfo(
      cep: _cepCtrl.text.replaceAll(RegExp(r'\D'), ''),
      logradouro: _logradouroCtrl.text.trim(),
      numero: _numeroCtrl.text.trim(),
      complemento: _complementoCtrl.text.trim().isEmpty
          ? null
          : _complementoCtrl.text.trim(),
      bairro: _bairroCtrl.text.trim(),
      cidade: _cidadeCtrl.text.trim(),
      estado: _estadoCtrl.text.trim().toUpperCase(),
    );
  }

  Future<void> _buscarCep() async {
    final cep = _cepCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (cep.length != 8) {
      setState(() => _erroEndereco = 'CEP deve ter 8 digitos.');
      return;
    }

    setState(() {
      _buscandoCep = true;
      _erroEndereco = null;
    });

    try {
      final headers = {
        'User-Agent': 'PadocaExpressApp/1.0',
        'Accept': 'application/json',
      };
      Map<String, dynamic>? data;

      try {
        final res = await http
            .get(
              Uri.parse('https://brasilapi.com.br/api/cep/v1/$cep'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 6));
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body) as Map<String, dynamic>;
          if (!body.containsKey('errors')) {
            data = {
              'logradouro': body['street'] ?? '',
              'bairro': body['neighborhood'] ?? '',
              'cidade': body['city'] ?? '',
              'estado': body['state'] ?? '',
            };
          }
        }
      } catch (_) {
        data = null;
      }

      if (data == null) {
        final res = await http
            .get(
              Uri.parse('https://viacep.com.br/ws/$cep/json/'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 6));
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (res.statusCode == 200 && body['erro'] != true) {
          data = {
            'logradouro': body['logradouro'] ?? '',
            'bairro': body['bairro'] ?? '',
            'cidade': body['localidade'] ?? '',
            'estado': body['uf'] ?? '',
          };
        }
      }

      if (data == null) {
        setState(() => _erroEndereco = 'CEP nao encontrado.');
        return;
      }

      setState(() {
        _logradouroCtrl.text = data!['logradouro'] as String;
        _bairroCtrl.text = data['bairro'] as String;
        _cidadeCtrl.text = data['cidade'] as String;
        _estadoCtrl.text = data['estado'] as String;
      });
    } catch (_) {
      setState(() => _erroEndereco = 'Erro ao buscar CEP. Tente novamente.');
    } finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
  }

  Future<void> _salvarEndereco() async {
    final endereco = _enderecoFromForm();
    if (!endereco.isComplete) {
      setState(() {
        _erroEndereco =
            'Preencha CEP, logradouro, numero, bairro, cidade e UF.';
      });
      return;
    }

    setState(() {
      _salvandoEndereco = true;
      _erroEndereco = null;
    });
    try {
      await widget.onSalvarEndereco(e, endereco);
    } catch (error) {
      setState(() {
        _erroEndereco = error.toString().replaceFirst('Exception: ', '').trim();
      });
    } finally {
      if (mounted) setState(() => _salvandoEndereco = false);
    }
  }

  // ── Tab: Ações ────────────────────────────────────────────────────────────

  Widget _tabDocsNew() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: e.docTotal > 0 ? e.docApprovedCount / e.docTotal : 0.0,
                  minHeight: 6,
                  backgroundColor: e.docsObrigatoriosAprovados
                      ? const Color(0xFFD1FAE5)
                      : const Color(0xFFFEF3C7),
                  color: e.docsObrigatoriosAprovados
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text('${e.docApprovedCount}/${e.docTotal} aprovados',
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: e.docsObrigatoriosAprovados
                        ? const Color(0xFF065F46)
                        : const Color(0xFF92400E))),
          ],
        ),
        const SizedBox(height: 12),
        ...e.docTiposVisiveis.map(_docReviewCard),
      ],
    );
  }

  Widget _docReviewCard(String tipo) {
    final ok = e.docEnviado(tipo);
    final obrigatorio = e.docObrigatorio(tipo);
    final validacao = e.docs[tipo];
    final doc = e.documentos[tipo];
    final label = _docLabels[tipo];
    final isSelfie = tipo == 'selfie';
    final aprovado = validacao == 'aprovado' ||
        (isSelfie && e.selfieRevisao?.status == 'aprovado');
    final reprovado = validacao == 'reprovado' ||
        (isSelfie && e.selfieRevisao?.status == 'reprovado');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: aprovado
                ? const Color(0xFFA7F3D0)
                : reprovado
                    ? const Color(0xFFFCA5A5)
                    : ok
                        ? const Color(0xFFFDE68A)
                        : obrigatorio
                            ? const Color(0xFFFCA5A5)
                            : const Color(0xFFEAE8E4),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            _docPreview(doc, label?.$1 ?? 'DOC'),
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
                          color: obrigatorio
                              ? const Color(0xFFFEF2F2)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(obrigatorio ? 'Obrigatório' : 'Opcional',
                            style: GoogleFonts.dmSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: obrigatorio
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF6B7280))),
                      ),
                    ],
                  ),
                  Text(
                    _docSubtitle(tipo, ok, validacao),
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: aprovado
                          ? const Color(0xFF10B981)
                          : reprovado
                              ? const Color(0xFFEF4444)
                              : ok
                                  ? const Color(0xFFF59E0B)
                                  : obrigatorio
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFF6B7280),
                    ),
                  ),
                  if (doc?.motivoRejeicao != null) ...[
                    const SizedBox(height: 4),
                    Text(doc!.motivoRejeicao!,
                        style: GoogleFonts.dmSans(
                            fontSize: 10.5,
                            color: const Color(0xFF991B1B),
                            fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
            if (isSelfie && ok)
              _miniDocButton(
                label: 'Revisar',
                color: const Color(0xFF1E40AF),
                bg: const Color(0xFFEFF6FF),
                border: const Color(0xFF3B82F6),
                onTap: () => widget.onAbrirSelfie(e),
              )
            else if (ok && !aprovado)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _miniDocButton(
                    label: 'Aprovar',
                    color: const Color(0xFF065F46),
                    bg: const Color(0xFFECFDF5),
                    border: const Color(0xFFA7F3D0),
                    onTap: () =>
                        widget.onRevisarDocumento(e, tipo, 'aprovado', null),
                  ),
                  const SizedBox(width: 6),
                  _miniDocButton(
                    label: 'Reprovar',
                    color: const Color(0xFF991B1B),
                    bg: const Color(0xFFFEF2F2),
                    border: const Color(0xFFFCA5A5),
                    onTap: () => _pedirMotivoDocumento(tipo),
                  ),
                ],
              )
            else if (ok && aprovado)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Text('✔ Aprovado',
                    style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF065F46))),
              ),
          ],
        ),
      ),
    );
  }

  Widget _docPreview(EntregadorDocumentoInfo? doc, String fallback) {
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
                  child:
                      Text(fallback, style: GoogleFonts.dmSans(fontSize: 10)),
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

  Widget _miniDocButton({
    required String label,
    required Color color,
    required Color bg,
    required Color border,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: widget.isSubmitting ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ),
    );
  }

  Future<void> _pedirMotivoDocumento(String tipo) async {
    final motivoCtrl = TextEditingController();
    final motivo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Motivo da reprova',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: motivoCtrl,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText:
                'Ex: CNH ilegivel, documento errado ou dados divergentes.',
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
    await widget.onRevisarDocumento(e, tipo, 'reprovado', motivo);
  }

  String _docSubtitle(String tipo, bool enviado, String? status) {
    if (!enviado) return 'Nao enviado pelo entregador';
    if (tipo == 'selfie') {
      return 'Enviada - ${_selfieStatusLabel(e.selfieRevisao?.status)}';
    }
    return 'Enviado - ${_validacaoLabel(status)}';
  }

  Widget _tabAcoes() {
    final selfieOk = e.selfieRevisao?.status == 'aprovado';
    final docsOk = e.docsObrigatoriosAprovados;
    final veiculoOk = e.tipoVeiculo != null;
    final telefoneOk = e.telefone != null;
    final enderecoOk = e.endereco?.isComplete == true;
    final temWallet = e.temCarteiraAsaas;
    final enderecoOuWalletOk = enderecoOk || temWallet;

    final checklist = [
      (selfieOk, 'Selfie aprovada pelo admin', null),
      (
        docsOk,
        'Todos os documentos aprovados (${e.docApprovedCount}/${e.docTotal})',
        null,
      ),
      (veiculoOk, 'Tipo de veículo selecionado', null),
      (telefoneOk, 'Telefone cadastrado', null),
      (
        enderecoOuWalletOk,
        enderecoOk
            ? 'Endereço completo para Asaas'
            : (temWallet
                ? 'Carteira Asaas já vinculada'
                : 'Endereço completo para Asaas'),
        enderecoOk ? null : 'endereco',
      ),
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
                color:
                    allOk ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
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
                    child: InkWell(
                      onTap: item.$1 || item.$3 == null
                          ? null
                          : () => setState(() => _tab = item.$3!),
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
            subtitle: temWallet
                ? 'Libera o entregador para usar o app.'
                : 'Libera o entregador. Cria carteira Asaas automaticamente.',
            borderColor: const Color(0xFFA7F3D0),
            bgColor: const Color(0xFFECFDF5),
            textColor: const Color(0xFF065F46),
            opacity: allOk ? 1.0 : 0.5,
            onTap: allOk ? () => widget.onAcao('aprovar', e) : () {},
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

  Widget _addressInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool enabled,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      style: GoogleFonts.dmSans(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A0910),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xFFF9F8F7),
        labelStyle: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF6B7280),
        ),
        hintStyle: GoogleFonts.dmSans(
          fontSize: 12,
          color: const Color(0xFF9CA3AF),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFFEAE8E4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFFEAE8E4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.5),
        ),
      ),
    );
  }

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
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
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
                    fontSize: 13, fontWeight: FontWeight.w800, color: color)),
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
      children: fields.map((f) => _infoCell(f.$1, f.$2, alert: false)).toList(),
    );
  }

  Widget _infoCell(String label, String value, {required bool alert}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: alert ? const Color(0xFFFEF2F2) : const Color(0xFFF9F8F7),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
            color: alert ? const Color(0xFFFCA5A5) : const Color(0xFFEAE8E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label.toUpperCase(),
              style: GoogleFonts.dmSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color:
                      alert ? const Color(0xFFDC2626) : const Color(0xFF9CA3AF),
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
                            fontSize: 11,
                            color: textColor.withValues(alpha: 0.7))),
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
