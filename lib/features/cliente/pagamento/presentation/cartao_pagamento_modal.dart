import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:padoca_express/features/cliente/pagamento/controllers/pagamento_controller.dart';
import 'package:padoca_express/features/cliente/pagamento/models/dados_cartao_model.dart';
import 'package:padoca_express/features/cliente/pagamento/presentation/cartao_pagamento_widgets.dart';

/// Modal de coleta de dados do cartão.
/// Retorna [DadosCartaoModel] ao caller via Navigator.pop.
/// Não toca no Supabase — apenas valida localmente e retorna os dados.
class CartaoPagamentoModal extends StatefulWidget {
  const CartaoPagamentoModal({super.key});

  static Future<DadosCartaoModel?> show(BuildContext context) {
    return showModalBottomSheet<DadosCartaoModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => const CartaoPagamentoModal(),
    );
  }

  @override
  State<CartaoPagamentoModal> createState() => _CartaoPagamentoModalState();
}

class _CartaoPagamentoModalState extends State<CartaoPagamentoModal> {
  final _formKey = GlobalKey<FormState>();

  final _numeroCtrl = TextEditingController();
  final _nomeCtrl = TextEditingController();
  final _vencimentoCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _apelidoCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();

  bool _isCredito = true;

  static const _primaryColor = Color(0xFFFF7034);
  static const _secondaryColor = Color(0xFF7D2D35);

  final _numeroMask = MaskTextInputFormatter(
    mask: '#### #### #### ####',
    filter: {'#': RegExp('[0-9]')},
  );
  final _vencimentoMask = MaskTextInputFormatter(
    mask: '##/##',
    filter: {'#': RegExp('[0-9]')},
  );
  final _cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp('[0-9]')},
  );
  final _cnpjMask = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {'#': RegExp('[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    // Rebuild o preview ao vivo
    for (final ctrl in [_numeroCtrl, _nomeCtrl, _vencimentoCtrl]) {
      ctrl.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _nomeCtrl.dispose();
    _vencimentoCtrl.dispose();
    _cvvCtrl.dispose();
    _apelidoCtrl.dispose();
    _cpfCtrl.dispose();
    super.dispose();
  }

  String? _validarVencimento(String? value) {
    if (value == null || value.isEmpty) return 'Informe a validade';
    final parts = value.split('/');
    if (parts.length != 2 || parts[0].length != 2 || parts[1].length != 2) {
      return 'Formato inválido (MM/AA)';
    }
    final mes = int.tryParse(parts[0]);
    if (mes == null || mes < 1 || mes > 12) return 'Mês inválido';
    final ano = int.tryParse(parts[1]);
    if (ano == null) return 'Ano inválido';
    final now = DateTime.now();
    final anoCompleto = 2000 + ano;
    if (anoCompleto < now.year ||
        (anoCompleto == now.year && mes < now.month)) {
      return 'Cartão vencido';
    }
    return null;
  }

  String? _validarCpfCnpj(String? value) {
    if (value == null || value.isEmpty) return 'Informe o CPF/CNPJ';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11 && digits.length != 14) {
      return 'CPF (11 dígitos) ou CNPJ (14 dígitos)';
    }
    if (!PagamentoController.validarCpfOuCnpj(value)) {
      return digits.length == 11 ? 'CPF inválido' : 'CNPJ inválido';
    }
    return null;
  }

  void _confirmar() {
    if (!_formKey.currentState!.validate()) return;

    final vencParts = _vencimentoCtrl.text.split('/');
    final dados = DadosCartaoModel(
      numero: _numeroCtrl.text.replaceAll(RegExp(r'\D'), ''),
      nomeTitular: _nomeCtrl.text.trim(),
      vencimentoMes: vencParts[0],
      vencimentoAno: vencParts[1],
      cvv: _cvvCtrl.text.trim(),
      apelido: _apelidoCtrl.text.trim(),
      cpfCnpj: _cpfCtrl.text.replaceAll(RegExp(r'\D'), ''),
      isCredito: _isCredito,
    );
    Navigator.of(context).pop(dados);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF1C1917) : const Color(0xFFF9F5F0);

    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Container(
            color: bgColor,
            child: Column(
              children: [
                // Handle
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'Dados do Cartão',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : _secondaryColor,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          color: isDark ? Colors.white70 : _secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                    height: 1,
                    color: _primaryColor.withValues(alpha: 0.1)),
                // Conteúdo scrollável
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      MediaQuery.of(context).padding.bottom + 24,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Toggle Crédito / Débito
                          Row(
                            children: [
                              _TipoCartaoChip(
                                label: 'Crédito',
                                selected: _isCredito,
                                onTap: () =>
                                    setState(() => _isCredito = true),
                                isDark: isDark,
                              ),
                              const SizedBox(width: 12),
                              _TipoCartaoChip(
                                label: 'Débito',
                                selected: !_isCredito,
                                onTap: () =>
                                    setState(() => _isCredito = false),
                                isDark: isDark,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Preview do cartão
                          CartaoPreviewWidget(
                            numero: _numeroCtrl.text,
                            nome: _nomeCtrl.text,
                            vencimento: _vencimentoCtrl.text,
                            isCredito: _isCredito,
                          ),
                          const SizedBox(height: 24),
                          // Campos
                          CampoCartao(
                            label: 'Número do cartão',
                            controller: _numeroCtrl,
                            formatter: _numeroMask,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                              if (d.length < 16) {
                                return 'Número incompleto';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          CampoCartao(
                            label: 'Nome impresso no cartão',
                            controller: _nomeCtrl,
                            textCapitalization: TextCapitalization.characters,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Informe o nome'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: CampoCartao(
                                  label: 'Validade',
                                  hint: 'MM/AA',
                                  controller: _vencimentoCtrl,
                                  formatter: _vencimentoMask,
                                  keyboardType: TextInputType.number,
                                  validator: _validarVencimento,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: CampoCartao(
                                  label: 'CVV',
                                  controller: _cvvCtrl,
                                  keyboardType: TextInputType.number,
                                  obscureText: true,
                                  maxLength: 4,
                                  validator: (v) {
                                    if (v == null ||
                                        v.length < 3) {
                                      return 'CVV inválido';
                                    }
                                    return null;
                                  },
                                  formatter: FilteringTextInputFormatter.digitsOnly,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          CampoCartao(
                            label: 'Apelido do cartão',
                            hint: 'Ex: Nubank pessoal',
                            controller: _apelidoCtrl,
                          ),
                          const SizedBox(height: 14),
                          // CPF/CNPJ — troca máscara automaticamente
                          _CampoCpfCnpj(
                            controller: _cpfCtrl,
                            cpfMask: _cpfMask,
                            cnpjMask: _cnpjMask,
                            validator: _validarCpfCnpj,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.lock_outline,
                                size: 14,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[400],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Faremos uma pequena cobrança com devolução automática.',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey[500]
                                      : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          // Botão confirmar
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _confirmar,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 4,
                                shadowColor:
                                    _primaryColor.withValues(alpha: 0.4),
                              ),
                              child: Text(
                                'Adicionar',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chip de seleção Crédito / Débito
// ─────────────────────────────────────────────────────────────────────────────
class _TipoCartaoChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  static const _primaryColor = Color(0xFFFF7034);

  const _TipoCartaoChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? _primaryColor
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? _primaryColor
                : (isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.grey.withValues(alpha: 0.3)),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
            color: selected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Campo CPF/CNPJ com troca automática de máscara
// ─────────────────────────────────────────────────────────────────────────────
class _CampoCpfCnpj extends StatefulWidget {
  final TextEditingController controller;
  final MaskTextInputFormatter cpfMask;
  final MaskTextInputFormatter cnpjMask;
  final String? Function(String?)? validator;
  final bool isDark;

  const _CampoCpfCnpj({
    required this.controller,
    required this.cpfMask,
    required this.cnpjMask,
    required this.validator,
    required this.isDark,
  });

  @override
  State<_CampoCpfCnpj> createState() => _CampoCpfCnpjState();
}

class _CampoCpfCnpjState extends State<_CampoCpfCnpj> {
  bool _isCnpj = false;

  static const _primaryColor = Color(0xFFFF7034);
  static const _secondaryColor = Color(0xFF7D2D35);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_detectarTipo);
  }

  void _detectarTipo() {
    final digits =
        widget.controller.text.replaceAll(RegExp(r'\D'), '');
    final isCnpj = digits.length > 11;
    if (isCnpj != _isCnpj) setState(() => _isCnpj = isCnpj);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_detectarTipo);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return TextFormField(
      controller: widget.controller,
      keyboardType: TextInputType.number,
      validator: widget.validator,
      inputFormatters: [
        _isCnpj ? widget.cnpjMask : widget.cpfMask,
      ],
      style: GoogleFonts.outfit(
        fontSize: 15,
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: 'CPF/CNPJ do titular',
        counterText: '',
        labelStyle: GoogleFonts.outfit(
          color: isDark
              ? Colors.grey[400]
              : _secondaryColor.withValues(alpha: 0.7),
          fontSize: 14,
        ),
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
          borderSide:
              const BorderSide(color: _primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[400]!),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.red[400]!, width: 1.5),
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.04),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
