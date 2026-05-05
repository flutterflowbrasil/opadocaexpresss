import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:padoca_express/features/auth/data/auth_repository.dart';
import 'package:padoca_express/shared/camera/camera_capture_screen.dart';

class CadastroPendenteScreen extends ConsumerStatefulWidget {
  const CadastroPendenteScreen({super.key});

  @override
  ConsumerState<CadastroPendenteScreen> createState() =>
      _CadastroPendenteScreenState();
}

class _CadastroPendenteScreenState
    extends ConsumerState<CadastroPendenteScreen> {
  late Future<Map<String, dynamic>?> _future;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _future = ref.read(authRepositoryProvider).getMeuCadastroEntregador();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFFF7034);
    const burgundy = Color(0xFF8E2A2B);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1614) : const Color(0xFFF9F5F0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: FutureBuilder<Map<String, dynamic>?>(
                future: _future,
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  final docs = _docsByTipo(data);
                  final status = data?['status_cadastro'] as String? ?? 'pendente';
                  final rejected = status == 'rejeitado';
                  final title =
                      rejected ? 'Documentacao nao aprovada' : 'Cadastro em analise';
                  final message = rejected
                      ? 'Revise os motivos abaixo e reenvie somente os documentos solicitados.'
                      : 'Sua solicitacao foi enviada para o administrador. O acesso ao app de entregador sera liberado apos a aprovacao.';

                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF292524) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .08),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: (rejected ? Colors.red : primary)
                                .withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(
                            rejected
                                ? Icons.report_problem_outlined
                                : Icons.hourglass_top_rounded,
                            color: rejected ? Colors.red[700] : primary,
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: isDark ? const Color(0xFFFFE0B2) : burgundy,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            height: 1.5,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: CircularProgressIndicator(),
                          )
                        else ...[
                          if (data?['motivo_rejeicao'] != null) ...[
                            const SizedBox(height: 18),
                            _ReasonBox(text: data!['motivo_rejeicao'] as String),
                          ],
                          const SizedBox(height: 18),
                          _buildDocsSection(data, docs, rejected),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await ref.read(authRepositoryProvider).signOut();
                              if (context.mounted) context.go('/login');
                            },
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Sair'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: burgundy,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              side: BorderSide(
                                  color: burgundy.withValues(alpha: .25)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocsSection(
    Map<String, dynamic>? data,
    Map<String, Map<String, dynamic>> docs,
    bool rejected,
  ) {
    if (data == null) {
      return const SizedBox.shrink();
    }
    final tipoVeiculo = data['tipo_veiculo'] as String?;
    final tipos = tipoVeiculo == 'moto' || tipoVeiculo == 'carro'
        ? const ['cnh_frente', 'cnh_verso', 'selfie']
        : const ['identidade_frente', 'identidade_verso', 'selfie'];

    return Column(
      children: [
        ...tipos.map((tipo) {
          final doc = docs[tipo];
          final status = doc?['status_validacao'] as String?;
          final motivo = doc?['motivo_rejeicao'] as String?;
          final needsUpload =
              rejected && (doc == null || status == 'reprovado');
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F8F7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEAE8E4)),
            ),
            child: Row(
              children: [
                Icon(_docIcon(tipo), color: _statusColor(status), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_docLabel(tipo),
                          style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1A0910))),
                      Text(
                        motivo ?? _statusLabel(status),
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: motivo != null
                                ? const Color(0xFF991B1B)
                                : const Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                if (needsUpload)
                  TextButton.icon(
                    onPressed: _isUploading ? null : () => _reenviar(tipo),
                    icon: const Icon(Icons.upload_file_rounded, size: 16),
                    label: const Text('Reenviar'),
                  ),
              ],
            ),
          );
        }),
        if (_isUploading) const LinearProgressIndicator(),
      ],
    );
  }

  Future<void> _reenviar(String tipo) async {
    final path = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => CameraCaptureScreen(
          mode: tipo == 'selfie' ? CaptureMode.selfie : CaptureMode.document,
        ),
      ),
    );
    if (path == null || path.isEmpty) return;

    setState(() => _isUploading = true);
    try {
      final file = XFile(path);
      await ref.read(authRepositoryProvider).reenviarDocumentoEntregador(
            tipo: tipo,
            bytes: await file.readAsBytes(),
            fileName: file.name,
          );
      if (!mounted) return;
      setState(() {
        _future = ref.read(authRepositoryProvider).getMeuCadastroEntregador();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documento reenviado para analise.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nao foi possivel reenviar: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Map<String, Map<String, dynamic>> _docsByTipo(Map<String, dynamic>? data) {
    final docs = (data?['entregador_documentos'] as List?) ?? const [];
    return {
      for (final doc in docs.cast<Map>())
        doc['tipo'] as String: Map<String, dynamic>.from(doc)
    };
  }

  String _docLabel(String tipo) => switch (tipo) {
        'cnh_frente' => 'CNH - frente',
        'cnh_verso' => 'CNH - verso',
        'identidade_frente' => 'Identidade - frente',
        'identidade_verso' => 'Identidade - verso',
        'selfie' => 'Selfie',
        _ => tipo,
      };

  IconData _docIcon(String tipo) =>
      tipo == 'selfie' ? Icons.face_retouching_natural : Icons.badge_outlined;

  Color _statusColor(String? status) => switch (status) {
        'aprovado' => const Color(0xFF10B981),
        'reprovado' => const Color(0xFFEF4444),
        _ => const Color(0xFFF59E0B),
      };

  String _statusLabel(String? status) => switch (status) {
        'aprovado' => 'Aprovado',
        'reprovado' => 'Reprovado',
        'pendente' => 'Aguardando revisao',
        _ => 'Nao enviado',
      };
}

class _ReasonBox extends StatelessWidget {
  final String text;

  const _ReasonBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 12.5,
          color: const Color(0xFF991B1B),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
