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
            id, nome_completo, tipo_veiculo, veiculo_modelo, veiculo_placa, veiculo_cor,
            foto_perfil_url, status_cadastro, avaliacao_media, total_entregas, total_avaliacoes,
            cpf, data_nascimento, cnh_numero, cnh_validade, dados_bancarios, asaas_account_id,
            entregador_saldos ( saldo_disponivel, total_ganho, total_sacado ),
            entregador_kyc ( status )
          ''')
          .eq('usuario_id', uid)
          .maybeSingle();

      _entregadorId = ent?['id'];

      final docs = _entregadorId != null
          ? await Supabase.instance.client
              .from('entregador_documentos')
              .select()
              .eq('entregador_id', _entregadorId!)
          : [];

      if (!mounted) return;
      setState(() {
        _perfil = Map<String, dynamic>.from(ent ?? {});
        _saldo = Map<String, dynamic>.from((ent?['entregador_saldos'] as Map?) ?? {});
        _docs = List<Map<String, dynamic>>.from(docs);
        _loading = false;
      });
    } catch (_) {
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
        'ativo': 'Ativo',
        'reprovado': 'Reprovado',
        'suspenso': 'Suspenso',
      }[s] ??
      s;

  Color _corStatus(String s) =>
      const {
        'pendente': _yellow,
        'ativo': _green,
        'reprovado': _red,
        'suspenso': _red,
      }[s] ??
      _text3;

  String _labelVeiculo(String? t) =>
      const {
        'moto': '🛵 Moto',
        'carro': '🚗 Carro',
        'bicicleta': '🚲 Bicicleta',
        'van': '🚐 Van',
      }[t] ??
      '🚗 Veículo';

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
      s == 'aprovado' ? _green : s == 'reprovado' ? _red : _yellow;

  String _fmtCpf(String? cpf) {
    if (cpf == null || cpf.length < 11) return cpf ?? '';
    return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9)}';
  }

  @override
  Widget build(BuildContext context) {
    final statusCadastro = _perfil['status_cadastro'] ?? 'pendente';
    final pixChave = (_perfil['dados_bancarios'] as Map?)?['pix_chave'];
    final kycStatus =
        (_perfil['entregador_kyc'] as List?)?.isNotEmpty == true
            ? (_perfil['entregador_kyc'] as List).last['status']
            : 'pendente';

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
                                            (_perfil['nome_completo'] ?? '?')[0].toUpperCase(),
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
                            _perfil['nome_completo'] ?? 'Entregador',
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
                            icon: '🛵',
                            valor: '${_perfil['total_entregas'] ?? 0}',
                            label: 'Entregas',
                          ),
                          _StatItem(
                            icon: '⭐',
                            valor:
                                '${(_perfil['avaliacao_media'] as num?)?.toStringAsFixed(1) ?? '5.0'}',
                            label: 'Avaliação',
                          ),
                          _StatItem(
                            icon: '💰',
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
                        _InfoRow(label: 'CPF', valor: _fmtCpf(_perfil['cpf'])),
                        _InfoRow(
                          label: 'CNH',
                          valor: _perfil['cnh_numero'] ?? 'Não informado',
                        ),
                        _InfoRow(
                          label: 'Veículo',
                          valor: _labelVeiculo(_perfil['tipo_veiculo']),
                        ),
                        _InfoRow(
                          label: 'Modelo',
                          valor: _perfil['veiculo_modelo'] ?? 'Não informado',
                        ),
                        _InfoRow(
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
                        _InfoRow(label: 'Chave PIX', valor: pixChave ?? 'Não cadastrada'),
                        _InfoRow(
                          label: 'Conta Asaas',
                          valor: _perfil['asaas_account_id'] != null ? 'Ativa ✅' : 'Não criada',
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
                              (d) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _labelDoc(d['tipo'] ?? ''),
                                        style: GoogleFonts.dmSans(fontSize: 13, color: _text2),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _corDocStatus(
                                          d['status_validacao'] ?? 'pendente',
                                        ).withValues(alpha: .1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        d['status_validacao'] ?? 'pendente',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: _corDocStatus(
                                            d['status_validacao'] ?? 'pendente',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                            const Text('🔐', style: TextStyle(fontSize: 22)),
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
                                    'Status: $kycStatus',
                                    style: GoogleFonts.dmSans(fontSize: 11, color: _text3),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _corDocStatus(kycStatus).withValues(alpha: .1),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                kycStatus,
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _corDocStatus(kycStatus),
                                ),
                              ),
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
                            icon: '⚙️',
                            label: 'Configurações',
                            onTap: () =>
                                context.push('/dashboard_entregador/configuracoes'),
                          ),
                          _AcaoItem(
                            icon: '💬',
                            label: 'Suporte',
                            onTap: () => context.push('/dashboard_entregador/suporte'),
                          ),
                          _AcaoItem(
                            icon: '🚪',
                            label: 'Sair da conta',
                            cor: _red,
                            onTap: () async {
                              await Supabase.instance.client.auth.signOut();
                              if (mounted) context.go('/login');
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

class _StatItem extends StatelessWidget {
  final String icon, valor, label;
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
              Text(icon, style: const TextStyle(fontSize: 18)),
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
  final String label, valor;
  const _InfoRow({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: _text3)),
            const Spacer(),
            Text(
              valor,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: _text2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}

class _AcaoItem extends StatelessWidget {
  final String icon, label;
  final VoidCallback onTap;
  final Color? cor;

  const _AcaoItem({required this.icon, required this.label, required this.onTap, this.cor});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _card,
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
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
