// ============================================================
// perfil_screen.dart — Perfil do Entregador
// Ôpadoca Express · App do Entregador
// Rota: /dashboard_entregador/perfil
// Tabelas: entregadores, usuarios, entregador_documentos,
//          entregador_kyc, entregador_saldos
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _bg0 = Color(0xFF0A0704);
const _bg2 = Color(0xFF1C1510);
const _card = Color(0xFF1A1510);
const _orange = Color(0xFFF97316);
const _green = Color(0xFF22C55E);
const _red = Color(0xFFEF4444);
const _yellow = Color(0xFFFBBF24);
const _text1 = Color(0xFFFAFAF9);
const _text2 = Color(0xA6FAFAF9);
const _text3 = Color(0x59FAFAF9);
const _border = Color(0x12FFFFFF);

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

Map<String, dynamic>? _embedOne(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value is List && value.isNotEmpty && value.last is Map) {
    return Map<String, dynamic>.from(value.last as Map);
  }
  return null;
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _loading = true;
  Map<String, dynamic> _perfil = {};
  Map<String, dynamic> _saldo = {};
  List<Map<String, dynamic>> _docs = [];
  String? _entregadorId;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    try {
      final ent = await Supabase.instance.client
          .from('entregadores')
          .select('''
            id, tipo_veiculo, veiculo_modelo, veiculo_placa, veiculo_cor,
            foto_perfil_url, status_cadastro, avaliacao_media, total_entregas, total_avaliacoes,
            cpf, data_nascimento, cnh_numero, cnh_validade, dados_bancarios, asaas_account_id,
            usuarios!entregadores_usuario_id_fkey ( nome_completo_fantasia ),
            entregador_kyc ( status )
          ''')
          .eq('usuario_id', uid)
          .maybeSingle();

      _entregadorId = ent?['id'] as String?;

      Map<String, dynamic> saldo = {};
      if (_entregadorId != null) {
        final splits = await Supabase.instance.client
            .from('splits_pagamento')
            .select(
              'entregador_valor_total, entregador_taxa_entrega_valor, repasse_entregador_processado',
            )
            .eq('entregador_id', _entregadorId!);
        var ganho = 0.0;
        var disponivel = 0.0;
        for (final raw in splits as List) {
          final r = Map<String, dynamic>.from(raw as Map);
          final v = (r['entregador_valor_total'] as num?)?.toDouble() ??
              (r['entregador_taxa_entrega_valor'] as num?)?.toDouble() ??
              0;
          ganho += v;
          if (r['repasse_entregador_processado'] == true) disponivel += v;
        }
        saldo = {'total_ganho': ganho, 'saldo_disponivel': disponivel};
      }

      final docs = _entregadorId != null
          ? await Supabase.instance.client
              .from('entregador_documentos')
              .select()
              .eq('entregador_id', _entregadorId!)
          : [];

      if (!mounted) return;
      setState(() {
        _perfil = Map<String, dynamic>.from(ent ?? {});
        _saldo = saldo;
        _docs = List<Map<String, dynamic>>.from(docs);
        _loading = false;
      });
    } catch (e) {
      debugPrint('[PerfilEntregador] erro ao carregar: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _atualizarFoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (img == null || _entregadorId == null) return;

    try {
      final bytes = await img.readAsBytes();
      final path = 'perfil/$_entregadorId.jpg';
      await Supabase.instance.client.storage
          .from('documentos-entregador')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          );
      final url = Supabase.instance.client.storage
          .from('documentos-entregador')
          .getPublicUrl(path);
      await Supabase.instance.client
          .from('entregadores')
          .update({'foto_perfil_url': url})
          .eq('id', _entregadorId!);
      _carregar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao atualizar foto'),
            backgroundColor: _red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _labelStatus(String s) =>
      const {
        'pendente': 'Pendente',
        'aprovado': 'Aprovado',
        'ativo': 'Ativo',
        'reprovado': 'Reprovado',
        'suspenso': 'Suspenso',
      }[s] ??
      s;

  Color _corStatus(String s) =>
      const {
        'pendente': _yellow,
        'aprovado': _green,
        'ativo': _green,
        'reprovado': _red,
        'suspenso': _red,
      }[s] ??
      _text3;

  String _labelVeiculo(String? t) =>
      const {
        'moto': 'Moto',
        'carro': 'Carro',
        'bicicleta': 'Bicicleta',
        'van': 'Van',
      }[t] ??
      'Veículo';

  IconData _iconVeiculo(String? t) => switch (t) {
        'carro' => Icons.directions_car_rounded,
        'bicicleta' => Icons.pedal_bike_rounded,
        'van' => Icons.airport_shuttle_rounded,
        _ => Icons.two_wheeler_rounded,
      };

  IconData _iconDoc(String t) => switch (t) {
        'cnh_frente' || 'cnh_verso' => Icons.badge_outlined,
        'veiculo' => Icons.two_wheeler_rounded,
        'residencia' => Icons.home_outlined,
        'selfie' => Icons.face_retouching_natural_rounded,
        _ => Icons.description_outlined,
      };

  String _labelDoc(String t) =>
      const {
        'cnh_frente': 'CNH (frente)',
        'cnh_verso': 'CNH (verso)',
        'veiculo': 'Foto do veículo',
        'residencia': 'Comp. residência',
        'selfie': 'Selfie',
      }[t] ??
      t;

  Color _corDocStatus(String s) =>
      (s == 'aprovado' || s == 'approved' || s == 'ativo')
          ? _green
          : s == 'reprovado'
              ? _red
              : _yellow;

  String _labelKyc(String s) => switch (s) {
        'aprovado' || 'approved' => 'Aprovado',
        'reprovado' => 'Reprovado',
        'pendente' => 'Pendente',
        _ => s,
      };

  String _fmtCpf(String? cpf) {
    final digits = (cpf ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) {
      return (cpf == null || cpf.trim().isEmpty) ? 'Não informado' : cpf;
    }
    return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
  }

  String get _nomeExibicao {
    final n = (_embedOne(_perfil['usuarios'])?['nome_completo_fantasia']
            as String?)
        ?.trim();
    if (n != null && n.isNotEmpty) return n;
    return 'Entregador';
  }

  String _statusKyc(dynamic raw, String statusCadastro) {
    final rows = <String>[];
    if (raw is Map) {
      final s = raw['status'] as String?;
      if (s != null && s.isNotEmpty) rows.add(s);
    } else if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          final s = item['status'] as String?;
          if (s != null && s.isNotEmpty) rows.add(s);
        }
      }
    }
    if (rows.any((s) => s == 'aprovado' || s == 'approved')) return 'aprovado';
    if (rows.isNotEmpty) return rows.last;
    // Quem já entrou no dashboard passou no gate de KYC.
    if (statusCadastro == 'aprovado' || statusCadastro == 'ativo') {
      return 'aprovado';
    }
    return 'pendente';
  }

  @override
  Widget build(BuildContext context) {
    final statusCadastro = (_perfil['status_cadastro'] as String?) ?? 'pendente';
    final dadosBancarios = _embedOne(_perfil['dados_bancarios']);
    final pixChave = (dadosBancarios?['pix_chave'] as String?)?.trim();
    final kycStatus = _statusKyc(_perfil['entregador_kyc'], statusCadastro);
    final inicial =
        _nomeExibicao.isNotEmpty ? _nomeExibicao[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: _bg0,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _orange, strokeWidth: 2.5))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Row(
                        children: [
                          if (context.canPop()) ...[
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: _bg2,
                                  border: Border.all(color: _border),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: _text1,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                          ],
                          Text(
                            'Meu Perfil',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: _text1,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () =>
                                context.push('/dashboard_entregador/configuracoes'),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: _bg2,
                                border: Border.all(color: _border),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.settings_outlined,
                                  color: _text1,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Avatar + nome + status
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _atualizarFoto,
                            child: Stack(
                              children: [
                                Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [_orange, Color(0xFFEA580C)],
                                    ),
                                    borderRadius: BorderRadius.circular(26),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _orange.withValues(alpha: .3),
                                        blurRadius: 16,
                                      ),
                                    ],
                                  ),
                                  child: _perfil['foto_perfil_url'] != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(26),
                                          child: Image.network(
                                            _perfil['foto_perfil_url'],
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            inicial,
                                            style: GoogleFonts.outfit(
                                              fontSize: 36,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: _orange,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: _bg0, width: 2),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.camera_alt_rounded,
                                        size: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _nomeExibicao,
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: _text1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: _corStatus(statusCadastro).withValues(alpha: .1),
                              border: Border.all(
                                color: _corStatus(statusCadastro).withValues(alpha: .3),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _labelStatus(statusCadastro),
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _corStatus(statusCadastro),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Stats
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _StatItem(
                            icon: Icons.two_wheeler_rounded,
                            valor: '${_perfil['total_entregas'] ?? 0}',
                            label: 'Entregas',
                          ),
                          _StatItem(
                            icon: Icons.star_rounded,
                            valor:
                                (_perfil['avaliacao_media'] as num?)?.toStringAsFixed(1) ?? '5.0',
                            label: 'Avaliação',
                          ),
                          _StatItem(
                            icon: Icons.payments_rounded,
                            valor:
                                'R\$${((_saldo['total_ganho'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}',
                            label: 'Ganhos',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Dados pessoais
                    _Secao(
                      titulo: 'DADOS PESSOAIS',
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _InfoRow(
                          icon: Icons.badge_outlined,
                          label: 'CPF',
                          valor: _fmtCpf(_perfil['cpf']),
                        ),
                        _InfoRow(
                          icon: Icons.credit_card_rounded,
                          label: 'CNH',
                          valor: _perfil['cnh_numero'] ?? 'Não informado',
                        ),
                        _InfoRow(
                          icon: _iconVeiculo(_perfil['tipo_veiculo'] as String?),
                          label: 'Veículo',
                          valor: _labelVeiculo(_perfil['tipo_veiculo'] as String?),
                        ),
                        _InfoRow(
                          icon: Icons.two_wheeler_outlined,
                          label: 'Modelo',
                          valor: _perfil['veiculo_modelo'] ?? 'Não informado',
                        ),
                        _InfoRow(
                          icon: Icons.pin_outlined,
                          label: 'Placa',
                          valor: _perfil['veiculo_placa'] ?? 'Não informado',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // PIX / Financeiro
                    _Secao(
                      titulo: 'DADOS FINANCEIROS',
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _InfoRow(
                          icon: Icons.pix,
                          label: 'Chave PIX',
                          valor: (pixChave == null || pixChave.isEmpty)
                              ? 'Não cadastrada'
                              : pixChave,
                        ),
                        _InfoRow(
                          icon: Icons.account_balance_rounded,
                          label: 'Conta Asaas',
                          valor: _perfil['asaas_account_id'] != null
                              ? 'Ativa'
                              : 'Não criada',
                          valorColor: _perfil['asaas_account_id'] != null
                              ? _green
                              : _text2,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Documentos
                    if (_docs.isNotEmpty) ...[
                      _Secao(
                        titulo: 'DOCUMENTOS',
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: _docs
                            .map(
                              (d) {
                                final status =
                                    (d['status_validacao'] as String?) ??
                                        'pendente';
                                return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    _IconBox(
                                      icon: _iconDoc(d['tipo'] ?? ''),
                                      size: 32,
                                      iconSize: 16,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _labelDoc(d['tipo'] ?? ''),
                                        style: GoogleFonts.dmSans(
                                          fontSize: 13,
                                          color: _text2,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    _StatusBadge(
                                      label: _labelKyc(status),
                                      color: _corDocStatus(status),
                                    ),
                                  ],
                                ),
                              );
                              },
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // KYC
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _card,
                          border: Border.all(color: _border),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            _IconBox(
                              icon: Icons.verified_user_rounded,
                              color: _corDocStatus(kycStatus),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Verificação Facial (KYC)',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: _text1,
                                    ),
                                  ),
                                  Text(
                                    'Status: ${_labelKyc(kycStatus)}',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      color: _text3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _StatusBadge(
                              label: _labelKyc(kycStatus),
                              color: _corDocStatus(kycStatus),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Ações
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _AcaoItem(
                            icon: Icons.settings_outlined,
                            label: 'Configurações',
                            onTap: () =>
                                context.push('/dashboard_entregador/configuracoes'),
                          ),
                          _AcaoItem(
                            icon: Icons.support_agent_rounded,
                            label: 'Suporte',
                            onTap: () => context.push('/dashboard_entregador/suporte'),
                          ),
                          _AcaoItem(
                            icon: Icons.logout_rounded,
                            label: 'Sair da conta',
                            cor: _red,
                            onTap: () async {
                              await Supabase.instance.client.auth.signOut();
                              if (!context.mounted) return;
                              context.go('/login');
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ─── Widgets auxiliares ──────────────────────────────────────────────────────

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  const _IconBox({
    required this.icon,
    this.color = _orange,
    this.size = 38,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        border: Border.all(color: color.withValues(alpha: .3)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String valor, label;
  const _StatItem({required this.icon, required this.valor, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _card,
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              Icon(icon, size: 18, color: _orange),
              const SizedBox(height: 4),
              Text(
                valor,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _text1,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  color: _text3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
}

class _Secao extends StatelessWidget {
  final String titulo;
  final List<Widget> children;
  final EdgeInsets padding;

  const _Secao({required this.titulo, required this.children, required this.padding});

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: _text3,
                letterSpacing: .8,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _card,
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(children: children),
            ),
          ],
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, valor;
  final Color? valorColor;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.valor,
    this.valorColor,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: _text3),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: _text3)),
            const Spacer(),
            Flexible(
              child: Text(
                valor,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: valorColor ?? _text2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}

class _AcaoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? cor;

  const _AcaoItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.cor,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _card,
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _IconBox(icon: icon, color: cor ?? _orange),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cor ?? _text1,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cor ?? _text3, size: 18),
            ],
          ),
        ),
      );
}
