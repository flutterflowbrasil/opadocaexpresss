import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:padoca_express/core/utils/account_uniqueness_validator.dart';
import 'package:padoca_express/core/utils/brazilian_document_validator.dart';
import 'package:padoca_express/core/utils/cliente_cpf_service.dart';
import 'package:padoca_express/core/utils/supabase_error_handler.dart';

/// Pede o CPF na primeira cobrança online e grava em `clientes.cpf`.
class InformarCpfCheckoutModal extends ConsumerStatefulWidget {
  const InformarCpfCheckoutModal({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => const InformarCpfCheckoutModal(),
    );
    return result == true;
  }

  @override
  ConsumerState<InformarCpfCheckoutModal> createState() =>
      _InformarCpfCheckoutModalState();
}

class _InformarCpfCheckoutModalState
    extends ConsumerState<InformarCpfCheckoutModal> {
  static const _primary = Color(0xFFFF7034);
  static const _secondary = Color(0xFF7D2D35);

  final _formKey = GlobalKey<FormState>();
  final _cpfCtrl = TextEditingController();
  final _cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );
  bool _saving = false;

  @override
  void dispose() {
    _cpfCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(clienteCpfServiceProvider).validateAndSave(
            _cpfCtrl.text,
            userId: userId,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final message = e is DuplicateAccountException
          ? e.message
          : e is Exception
              ? e.toString().replaceFirst('Exception: ', '')
              : SupabaseErrorHandler.parseError(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red[700]),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1C1917) : Colors.white;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Informe seu CPF',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : _secondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Precisamos do CPF para gerar o Pix ou a cobrança no cartão. '
                'Ele fica salvo no seu perfil.',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _cpfCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [_cpfMask],
                enabled: !_saving,
                validator: BrazilianDocumentValidator.cpfFormValidator,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: isDark ? Colors.white : _secondary,
                ),
                decoration: InputDecoration(
                  labelText: 'CPF',
                  hintText: '000.000.000-00',
                  labelStyle: GoogleFonts.outfit(
                    color: isDark
                        ? Colors.grey[400]
                        : _secondary.withValues(alpha: 0.7),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.withValues(alpha: 0.04),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _primary, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red[400]!),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red[400]!, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _saving ? null : _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    disabledBackgroundColor: _primary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Salvar e continuar',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _saving
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.outfit(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
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
