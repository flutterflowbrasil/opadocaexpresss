import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:padoca_express/core/utils/supabase_error_handler.dart';
import 'package:padoca_express/features/auth/data/auth_repository.dart';
import 'package:padoca_express/features/auth/presentation/cadastro_estabelecimento/cadastro_estabelecimento_controller.dart';
import 'package:padoca_express/features/estabelecimento/componentes/app_bar_estabelecimento.dart';
import 'package:padoca_express/features/estabelecimento/data/storage_service.dart';
import 'package:padoca_express/services/notifications/push_device_registrar.dart';

class CadastroEstabelecimentoStep3Screen extends ConsumerStatefulWidget {
  const CadastroEstabelecimentoStep3Screen({super.key});

  @override
  ConsumerState<CadastroEstabelecimentoStep3Screen> createState() =>
      _CadastroEstabelecimentoStep3ScreenState();
}

class _CadastroEstabelecimentoStep3ScreenState
    extends ConsumerState<CadastroEstabelecimentoStep3Screen> {
  String _documentoResponsavelTipo = 'identidade';
  _DocumentoArquivo? _identidadeFrenteFile;
  _DocumentoArquivo? _identidadeVersoFile;
  _DocumentoArquivo? _cnhFrenteFile;
  _DocumentoArquivo? _cnhVersoFile;
  _DocumentoArquivo? _comprovanteEnderecoFile;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(cadastroEstabelecimentoProvider);
    _documentoResponsavelTipo =
        state.documentoResponsavelTipo ?? 'identidade';

    if (state.identidadeResponsavelFrenteBytes != null &&
        state.identidadeResponsavelFrenteFileName != null) {
      _identidadeFrenteFile = _DocumentoArquivo(
        name: state.identidadeResponsavelFrenteFileName!,
        bytes: state.identidadeResponsavelFrenteBytes!,
      );
    }
    if (state.identidadeResponsavelVersoBytes != null &&
        state.identidadeResponsavelVersoFileName != null) {
      _identidadeVersoFile = _DocumentoArquivo(
        name: state.identidadeResponsavelVersoFileName!,
        bytes: state.identidadeResponsavelVersoBytes!,
      );
    }
    if (state.cnhResponsavelFrenteBytes != null &&
        state.cnhResponsavelFrenteFileName != null) {
      _cnhFrenteFile = _DocumentoArquivo(
        name: state.cnhResponsavelFrenteFileName!,
        bytes: state.cnhResponsavelFrenteBytes!,
      );
    }
    if (state.cnhResponsavelVersoBytes != null &&
        state.cnhResponsavelVersoFileName != null) {
      _cnhVersoFile = _DocumentoArquivo(
        name: state.cnhResponsavelVersoFileName!,
        bytes: state.cnhResponsavelVersoBytes!,
      );
    }
    if (state.comprovanteEnderecoBytes != null &&
        state.comprovanteEnderecoFileName != null) {
      _comprovanteEnderecoFile = _DocumentoArquivo(
        name: state.comprovanteEnderecoFileName!,
        bytes: state.comprovanteEnderecoBytes!,
      );
    }
  }

  Future<void> _pickDocumento(_DocumentoEstabelecimentoSlot slot) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final selected = result.files.single;
    final bytes = selected.bytes;
    if (bytes == null) {
      _showMessage(
        'Não foi possível carregar o arquivo selecionado. Tente novamente.',
      );
      return;
    }

    final file = _DocumentoArquivo(name: selected.name, bytes: bytes);

    setState(() {
      switch (slot) {
        case _DocumentoEstabelecimentoSlot.identidadeFrente:
          _identidadeFrenteFile = file;
          break;
        case _DocumentoEstabelecimentoSlot.identidadeVerso:
          _identidadeVersoFile = file;
          break;
        case _DocumentoEstabelecimentoSlot.cnhFrente:
          _cnhFrenteFile = file;
          break;
        case _DocumentoEstabelecimentoSlot.cnhVerso:
          _cnhVersoFile = file;
          break;
        case _DocumentoEstabelecimentoSlot.comprovanteEndereco:
          _comprovanteEnderecoFile = file;
          break;
      }
    });
  }

  bool _validateDocumentos() {
    if (_documentoResponsavelTipo == 'identidade') {
      if (_identidadeFrenteFile == null) {
        _showMessage('Envie a frente da identidade do responsável.');
        return false;
      }
      if (_identidadeVersoFile == null) {
        _showMessage('Envie o verso da identidade do responsável.');
        return false;
      }
    } else {
      if (_cnhFrenteFile == null) {
        _showMessage('Envie a frente da CNH do responsável.');
        return false;
      }
      if (_cnhVersoFile == null) {
        _showMessage('Envie o verso da CNH do responsável.');
        return false;
      }
    }

    if (_comprovanteEnderecoFile == null) {
      _showMessage('Envie o comprovante de endereço.');
      return false;
    }
    return true;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _submit() async {
    if (!_validateDocumentos()) return;
    setState(() => _isLoading = true);

    try {
      final controller = ref.read(cadastroEstabelecimentoProvider.notifier);
      controller.updateStep3(
        documentoResponsavelTipo: _documentoResponsavelTipo,
        identidadeResponsavelFrenteBytes:
            _documentoResponsavelTipo == 'identidade'
                ? _identidadeFrenteFile!.bytes
                : null,
        identidadeResponsavelFrenteFileName:
            _documentoResponsavelTipo == 'identidade'
                ? _identidadeFrenteFile!.name
                : null,
        identidadeResponsavelVersoBytes:
            _documentoResponsavelTipo == 'identidade'
                ? _identidadeVersoFile!.bytes
                : null,
        identidadeResponsavelVersoFileName:
            _documentoResponsavelTipo == 'identidade'
                ? _identidadeVersoFile!.name
                : null,
        cnhResponsavelFrenteBytes: _documentoResponsavelTipo == 'cnh'
            ? _cnhFrenteFile!.bytes
            : null,
        cnhResponsavelFrenteFileName: _documentoResponsavelTipo == 'cnh'
            ? _cnhFrenteFile!.name
            : null,
        cnhResponsavelVersoBytes: _documentoResponsavelTipo == 'cnh'
            ? _cnhVersoFile!.bytes
            : null,
        cnhResponsavelVersoFileName: _documentoResponsavelTipo == 'cnh'
            ? _cnhVersoFile!.name
            : null,
        comprovanteEnderecoBytes: _comprovanteEnderecoFile!.bytes,
        comprovanteEnderecoFileName: _comprovanteEnderecoFile!.name,
      );

      final state = ref.read(cadastroEstabelecimentoProvider);
      final authRepo = ref.read(authRepositoryProvider);
      final storageService = ref.read(storageServiceProvider);

      await authRepo.signUpEstabelecimento(
        dadosCadastro: state,
        storageService: storageService,
      );
      await PushDeviceRegistrar.sync();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastro realizado com sucesso!')),
      );
      final rota = await authRepo.validateSessionAndRoute();
      if (mounted) context.go(rota);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(SupabaseErrorHandler.parseError(e)),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFFff7033);
    final burgundyColor = const Color(0xFF7d2d35);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF23150f) : const Color(0xFFf9f5f0),
      appBar: const AppBarEstabelecimento(),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 112),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PASSO 3 DE 3',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: burgundyColor.withValues(alpha: 0.6),
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '100%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: burgundyColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 1.0,
                      backgroundColor: burgundyColor.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(primaryColor),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDocumentacao(primaryColor, burgundyColor, isDark),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Salvar e Iniciar',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.rocket_launch,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentacao(
    Color primaryColor,
    Color burgundyColor,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.verified_user_outlined, color: primaryColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Documentação do Responsável',
                style: GoogleFonts.plusJakartaSans(
                  color: isDark ? Colors.white : burgundyColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Envie o documento do responsável e o comprovante de endereço.',
          style: GoogleFonts.plusJakartaSans(
            color:
                isDark ? Colors.grey[400] : burgundyColor.withValues(alpha: .7),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _buildDocumentTypeOption(
                label: 'Identidade',
                value: 'identidade',
                isDark: isDark,
                primaryColor: primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDocumentTypeOption(
                label: 'CNH',
                value: 'cnh',
                isDark: isDark,
                primaryColor: primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_documentoResponsavelTipo == 'identidade') ...[
          _buildUploadCard(
            title: 'Identidade - frente',
            subtitle: 'Envie a frente da identidade.',
            icon: Icons.badge_outlined,
            file: _identidadeFrenteFile,
            primaryColor: primaryColor,
            isDark: isDark,
            onTap: () =>
                _pickDocumento(_DocumentoEstabelecimentoSlot.identidadeFrente),
          ),
          const SizedBox(height: 12),
          _buildUploadCard(
            title: 'Identidade - verso',
            subtitle: 'Envie o verso da identidade.',
            icon: Icons.badge_outlined,
            file: _identidadeVersoFile,
            primaryColor: primaryColor,
            isDark: isDark,
            onTap: () =>
                _pickDocumento(_DocumentoEstabelecimentoSlot.identidadeVerso),
          ),
        ] else ...[
          _buildUploadCard(
            title: 'CNH - frente',
            subtitle: 'Envie a frente da CNH.',
            icon: Icons.badge_outlined,
            file: _cnhFrenteFile,
            primaryColor: primaryColor,
            isDark: isDark,
            onTap: () =>
                _pickDocumento(_DocumentoEstabelecimentoSlot.cnhFrente),
          ),
          const SizedBox(height: 12),
          _buildUploadCard(
            title: 'CNH - verso',
            subtitle: 'Envie o verso da CNH.',
            icon: Icons.badge_outlined,
            file: _cnhVersoFile,
            primaryColor: primaryColor,
            isDark: isDark,
            onTap: () => _pickDocumento(_DocumentoEstabelecimentoSlot.cnhVerso),
          ),
        ],
        const SizedBox(height: 12),
        _buildUploadCard(
          title: 'Comprovante de endereço',
          subtitle: 'Envie um comprovante recente do endereço da loja.',
          icon: Icons.home_work_outlined,
          file: _comprovanteEnderecoFile,
          primaryColor: primaryColor,
          isDark: isDark,
          onTap: () => _pickDocumento(
            _DocumentoEstabelecimentoSlot.comprovanteEndereco,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentTypeOption({
    required String label,
    required String value,
    required bool isDark,
    required Color primaryColor,
  }) {
    final selected = _documentoResponsavelTipo == value;
    return GestureDetector(
      onTap: () => setState(() {
        _documentoResponsavelTipo = value;
        if (value == 'identidade') {
          _cnhFrenteFile = null;
          _cnhVersoFile = null;
        } else {
          _identidadeFrenteFile = null;
          _identidadeVersoFile = null;
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? primaryColor : Colors.grey.withValues(alpha: 0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: selected
                  ? primaryColor
                  : (isDark ? Colors.white70 : Colors.grey[600]),
              fontWeight: selected ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required _DocumentoArquivo? file,
    required Color primaryColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final hasFile = file != null;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF27272A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFile ? const Color(0xFF10B981) : Colors.grey[200]!,
            width: hasFile ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: hasFile
                    ? const Color(0xFFECFDF5)
                    : primaryColor.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                hasFile ? Icons.check_circle_outline : icon,
                color: hasFile ? const Color(0xFF10B981) : primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF7d2d35),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasFile ? file.name : subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: hasFile
                          ? const Color(0xFF059669)
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.upload_file_outlined, color: primaryColor),
          ],
        ),
      ),
    );
  }
}

enum _DocumentoEstabelecimentoSlot {
  identidadeFrente,
  identidadeVerso,
  cnhFrente,
  cnhVerso,
  comprovanteEndereco,
}

class _DocumentoArquivo {
  final String name;
  final Uint8List bytes;

  const _DocumentoArquivo({
    required this.name,
    required this.bytes,
  });
}
