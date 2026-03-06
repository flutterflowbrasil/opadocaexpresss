import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../cupons_controller.dart';
import '../models/cupom_model.dart';

class FormCupomModal extends ConsumerStatefulWidget {
  final CupomModel? cupomExistente;

  const FormCupomModal({super.key, this.cupomExistente});

  @override
  ConsumerState<FormCupomModal> createState() => _FormCupomModalState();
}

class _FormCupomModalState extends ConsumerState<FormCupomModal> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _codigoController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _valorMinimoController = TextEditingController();
  final _limiteUsosController = TextEditingController();
  final _limitePorClienteController = TextEditingController(text: '1');

  // Estado local do form
  String _tipoCupom = 'percentual'; // percentual, valor_fixo, entrega_gratis
  DateTime? _dataInicio = DateTime.now();
  DateTime? _dataFim;
  bool _isAtivo = true;

  @override
  void initState() {
    super.initState();
    if (widget.cupomExistente != null) {
      final c = widget.cupomExistente!;
      _codigoController.text = c.codigo;
      _descricaoController.text = c.descricao ?? '';
      _tipoCupom = c.tipo;
      _valorController.text = c.valor.toString();
      _valorMinimoController.text = c.valorMinimoPedido.toString();
      _limiteUsosController.text = c.limiteUsos?.toString() ?? '';
      _limitePorClienteController.text = c.limiteUsosPorCliente.toString();
      _dataInicio = c.dataInicio;
      _dataFim = c.dataFim;
      _isAtivo = c.ativo;
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _descricaoController.dispose();
    _valorController.dispose();
    _valorMinimoController.dispose();
    _limiteUsosController.dispose();
    _limitePorClienteController.dispose();
    super.dispose();
  }

  Future<void> _salvarCupom() async {
    if (!_formKey.currentState!.validate()) return;

    final valor =
        double.tryParse(_valorController.text.replaceAll(',', '.')) ?? 0.0;

    if (_tipoCupom != 'entrega_gratis' && valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Valor do cupom deve ser maior que zero.')),
      );
      return;
    }

    if (_tipoCupom == 'percentual' && valor > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Porcentagem máxima é 100%.')),
      );
      return;
    }

    final valorMin =
        double.tryParse(_valorMinimoController.text.replaceAll(',', '.')) ??
            0.0;
    final limiteUsos = int.tryParse(_limiteUsosController.text);
    final limitePorCliente =
        int.tryParse(_limitePorClienteController.text) ?? 1;

    final novoCupom = CupomModel(
      id: widget.cupomExistente?.id ?? const Uuid().v4(),
      estabelecimentoId: widget.cupomExistente?.estabelecimentoId ??
          '', // Handle via controller
      codigo: _codigoController.text.toUpperCase().trim(),
      descricao: _descricaoController.text.trim(),
      tipo: _tipoCupom,
      valor: valor,
      valorMinimoPedido: valorMin,
      limiteUsos: limiteUsos,
      limiteUsosPorCliente: limitePorCliente,
      dataInicio: _dataInicio,
      dataFim: _dataFim,
      ativo: _isAtivo,
      usosAtuais: widget.cupomExistente?.usosAtuais ?? 0,
    );

    final controller = ref.read(cuponsControllerProvider.notifier);
    final sucesso = widget.cupomExistente == null
        ? await controller.criarCupom(novoCupom)
        : await controller.atualizarCupom(novoCupom);

    if (sucesso && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              widget.cupomExistente == null ? 'Cupom criado!' : 'Cupom salvo!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _selecionarData(BuildContext context, bool isFim) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isFim ? _dataFim : _dataInicio) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && context.mounted) {
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Theme.of(context).colorScheme.primary,
              ),
            ),
            child: child!,
          );
        },
      );

      if (timePicked != null && mounted) {
        final finalDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          timePicked.hour,
          timePicked.minute,
        );

        setState(() {
          if (isFim) {
            _dataFim = finalDateTime;
            // Se colocou data fim menor que inicio, corrige.
            if (_dataInicio != null && _dataFim!.isBefore(_dataInicio!)) {
              _dataInicio = _dataFim;
            }
          } else {
            _dataInicio = finalDateTime;
          }
        });
      }
    }
  }

  InputDecoration _customInputDecoration(
      {String? hintText, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle:
          GoogleFonts.publicSans(color: const Color(0xFF9CA3AF), fontSize: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      isDense: true,
    );
  }

  Widget _buildLabel(String text, {bool opcional = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: GoogleFonts.publicSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6B7280),
              letterSpacing: 0.5,
            ),
          ),
          if (opcional)
            Text(
              ' (opcional)',
              style: GoogleFonts.publicSans(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF9CA3AF),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTipoButton(String tipoValue, String label, IconData icon,
      Color activeColor, Color activeBg) {
    final isActive = _tipoCupom == tipoValue;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tipoCupom = tipoValue),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? activeBg : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? activeColor : const Color(0xFFE5E7EB),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isActive ? activeColor : const Color(0xFF6B7280),
                  size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.publicSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isActive ? activeColor : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cuponsControllerProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: isMobile ? double.infinity : 520,
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.92),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.cupomExistente == null
                            ? 'Novo cupom'
                            : 'Editar cupom',
                        style: GoogleFonts.publicSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.cupomExistente == null
                            ? 'Preencha os dados abaixo'
                            : 'Editando ${widget.cupomExistente!.codigo}',
                        style: GoogleFonts.publicSans(
                          fontSize: 11,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFFE5E7EB), width: 1.5),
                      ),
                      child: const Icon(Icons.close,
                          size: 16, color: Color(0xFF6B7280)),
                    ),
                  )
                ],
              ),
            ),

            // Error Feedback
            if (state.error != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.error!,
                        style: GoogleFonts.publicSans(
                            color: Colors.red.shade700, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => ref
                          .read(cuponsControllerProvider.notifier)
                          .limparErro(),
                    )
                  ],
                ),
              ),

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tipo de Desconto
                      _buildLabel('TIPO DE DESCONTO'),
                      Row(
                        children: [
                          _buildTipoButton(
                              'percentual',
                              '% Percentual',
                              Icons.percent,
                              const Color(0xFF8B5CF6),
                              const Color(0xFFF5F3FF)),
                          const SizedBox(width: 8),
                          _buildTipoButton(
                              'valor_fixo',
                              'R\$ Valor fixo',
                              Icons.attach_money,
                              const Color(0xFF10B981),
                              const Color(0xFFECFDF5)),
                          const SizedBox(width: 8),
                          _buildTipoButton(
                              'entrega_gratis',
                              'Frete grátis',
                              Icons.local_shipping_outlined,
                              const Color(0xFFF97316),
                              const Color(0xFFFFF7ED)),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Código
                      _buildLabel('CÓDIGO DO CUPOM'),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _codigoController,
                              textCapitalization: TextCapitalization.characters,
                              style: GoogleFonts.publicSans(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF111827),
                                letterSpacing: 1,
                                fontSize: 13,
                              ),
                              decoration: _customInputDecoration(
                                  hintText: 'EX: BEMVINDO10'),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Código obrigatório';
                                }
                                if (v.trim().length < 3) {
                                  return 'Mín. 3 caracteres';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              final chars =
                                  "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
                              final randomStr = List.generate(
                                  8,
                                  (index) => chars[(chars.length *
                                              (DateTime.now()
                                                      .microsecondsSinceEpoch %
                                                  100) /
                                              100)
                                          .floor() %
                                      chars.length]).join();
                              _codigoController.text = randomStr;
                            },
                            borderRadius: BorderRadius.circular(9),
                            child: Container(
                              height: 48,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAFAFA),
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                    color: const Color(0xFFE5E7EB), width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.shuffle,
                                      size: 16, color: Color(0xFF6B7280)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Gerar',
                                    style: GoogleFonts.publicSans(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Descrição
                      _buildLabel('DESCRIÇÃO', opcional: true),
                      TextFormField(
                        controller: _descricaoController,
                        style: GoogleFonts.publicSans(
                            fontSize: 13, color: const Color(0xFF111827)),
                        decoration: _customInputDecoration(
                            hintText:
                                'Ex: Desconto de boas-vindas para novos clientes'),
                      ),

                      const SizedBox(height: 20),

                      // Regras Valor e Pedido Mínimo
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_tipoCupom != 'entrega_gratis') ...[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel(_tipoCupom == 'percentual'
                                      ? 'DESCONTO (%)'
                                      : 'VALOR (R\$)'),
                                  TextFormField(
                                    controller: _valorController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    style: GoogleFonts.publicSans(
                                        fontSize: 13,
                                        color: const Color(0xFF111827)),
                                    decoration: _customInputDecoration(
                                        hintText: _tipoCupom == 'percentual'
                                            ? '10'
                                            : '5,00'),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d+\.?\d{0,2}'))
                                    ],
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty)
                                        return 'Obrigatório';
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(_tipoCupom == 'entrega_gratis'
                                    ? 'PEDIDO MÍNIMO P/ FRETE GRÁTIS (R\$)'
                                    : 'PEDIDO MÍNIMO (R\$)'),
                                TextFormField(
                                  controller: _valorMinimoController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  style: GoogleFonts.publicSans(
                                      fontSize: 13,
                                      color: const Color(0xFF111827)),
                                  decoration:
                                      _customInputDecoration(hintText: '0,00'),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d{0,2}'))
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Limites
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('LIMITE TOTAL DE USOS'),
                                TextFormField(
                                  controller: _limiteUsosController,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.publicSans(
                                      fontSize: 13,
                                      color: const Color(0xFF111827)),
                                  decoration: _customInputDecoration(
                                      hintText: 'Ilimitado'),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('USOS POR CLIENTE'),
                                TextFormField(
                                  controller: _limitePorClienteController,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.publicSans(
                                      fontSize: 13,
                                      color: const Color(0xFF111827)),
                                  decoration:
                                      _customInputDecoration(hintText: '1'),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty)
                                      return 'Requerido';
                                    if (int.tryParse(v) == 0) return '> 0';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Datas
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('DATA DE INÍCIO'),
                                InkWell(
                                  onTap: () => _selecionarData(context, false),
                                  child: InputDecorator(
                                    decoration: _customInputDecoration(
                                        suffixIcon: const Icon(
                                            Icons.calendar_today_outlined,
                                            size: 16,
                                            color: Color(0xFF6B7280))),
                                    child: Text(
                                      _dataInicio != null
                                          ? DateFormat('dd/MM/yyyy')
                                              .format(_dataInicio!)
                                          : 'dd/mm/aaaa',
                                      style: GoogleFonts.publicSans(
                                          fontSize: 13,
                                          color: const Color(0xFF111827)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('DATA DE FIM', opcional: true),
                                InkWell(
                                  onTap: () => _selecionarData(context, true),
                                  child: InputDecorator(
                                    decoration: _customInputDecoration(
                                      suffixIcon: _dataFim != null
                                          ? InkWell(
                                              onTap: () => setState(
                                                  () => _dataFim = null),
                                              child: const Icon(Icons.close,
                                                  size: 16,
                                                  color: Color(0xFF6B7280)),
                                            )
                                          : const Icon(
                                              Icons.calendar_today_outlined,
                                              size: 16,
                                              color: Color(0xFF6B7280)),
                                    ),
                                    child: Text(
                                      _dataFim != null
                                          ? DateFormat('dd/MM/yyyy')
                                              .format(_dataFim!)
                                          : 'dd/mm/aaaa',
                                      style: GoogleFonts.publicSans(
                                          fontSize: 13,
                                          color: _dataFim != null
                                              ? const Color(0xFF111827)
                                              : const Color(0xFF9CA3AF)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Status
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color(0xFFE5E7EB), width: 1.5),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Cupom ativo',
                                      style: GoogleFonts.publicSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF111827))),
                                  const SizedBox(height: 2),
                                  Text('Clientes poderão usar este cupom',
                                      style: GoogleFonts.publicSans(
                                          fontSize: 11,
                                          color: const Color(0xFF6B7280))),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isAtivo,
                              thumbColor: WidgetStateProperty.all(Colors.white),
                              trackColor:
                                  WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return const Color(0xFF10B981);
                                }
                                return const Color(0xFFE5E7EB);
                              }),
                              trackOutlineColor:
                                  WidgetStateProperty.all(Colors.transparent),
                              onChanged: (v) => setState(() => _isAtivo = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer (Actions)
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        side: const BorderSide(
                            color: Color(0xFFE5E7EB), width: 1.5),
                        foregroundColor: const Color(0xFF6B7280),
                      ),
                      onPressed:
                          state.isSaving ? null : () => Navigator.pop(context),
                      child: Text('Cancelar',
                          style: GoogleFonts.publicSans(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: state.isSaving ? null : _salvarCupom,
                      child: state.isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  widget.cupomExistente == null
                                      ? 'Criar cupom'
                                      : 'Salvar',
                                  style: GoogleFonts.publicSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
