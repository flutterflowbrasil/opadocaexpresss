import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:padoca_express/core/utils/brazilian_document_validator.dart';
import 'package:padoca_express/core/utils/supabase_error_handler.dart';
import 'package:padoca_express/features/auth/data/auth_repository.dart';
import 'package:padoca_express/shared/camera/camera_capture_screen.dart';
import 'package:padoca_express/shared/widgets/responsive_layout.dart';

class CadastroEntregadorScreen extends ConsumerStatefulWidget {
  const CadastroEntregadorScreen({super.key});

  @override
  ConsumerState<CadastroEntregadorScreen> createState() =>
      _CadastroEntregadorScreenState();
}

class _CadastroEntregadorScreenState
    extends ConsumerState<CadastroEntregadorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _cpfController = TextEditingController();
  final _dataNascimentoController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  final _placaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _cepController = TextEditingController();
  final _logradouroController = TextEditingController();
  final _numeroController = TextEditingController();
  final _complementoController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController(text: 'PI');

  final _phoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _dateFormatter = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _cepFormatter = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {'#': RegExp(r'[0-9]')},
  );

  int _step = 0;
  bool _isLoading = false;
  bool _acceptedTerms = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _showValidationErrors = false;
  bool _buscandoCep = false;
  String? _erroCep;
  String _tipoVeiculo = 'moto';
  _DocumentoArquivo? _documentoFrenteFile;
  _DocumentoArquivo? _documentoVersoFile;
  _DocumentoArquivo? _cnhFrenteFile;
  _DocumentoArquivo? _cnhVersoFile;
  _DocumentoArquivo? _fotoPerfilFile;

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _cpfController.dispose();
    _dataNascimentoController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _placaController.dispose();
    _modeloController.dispose();
    _cepController.dispose();
    _logradouroController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  bool get _cpfValido {
    return BrazilianDocumentValidator.isValidCpf(_cpfController.text);
  }

  bool get _placaObrigatoria => _tipoVeiculo != 'bicicleta';
  bool get _usaCnh => _tipoVeiculo == 'moto' || _tipoVeiculo == 'carro';

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1940),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFFF7034)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _dataNascimentoController.text = DateFormat('dd/MM/yyyy').format(picked);
      setState(() {});
    }
  }

  Future<void> _pickFile(_DocumentoSlot slot) async {
    final path = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => CameraCaptureScreen(
          mode: slot == _DocumentoSlot.perfil
              ? CaptureMode.selfie
              : CaptureMode.document,
        ),
      ),
    );
    if (path == null || path.isEmpty) return;
    final captured = XFile(path);
    late final _DocumentoArquivo file;
    try {
      file = _DocumentoArquivo(
        name: captured.name,
        bytes: await captured.readAsBytes(),
      );
    } catch (_) {
      _showMessage(
          'NÃ£o foi possÃ­vel carregar a foto capturada. Tente novamente.');
      return;
    }
    setState(() {
      switch (slot) {
        case _DocumentoSlot.frente:
          _documentoFrenteFile = file;
          break;
        case _DocumentoSlot.verso:
          _documentoVersoFile = file;
          break;
        case _DocumentoSlot.cnhFrente:
          _cnhFrenteFile = file;
          break;
        case _DocumentoSlot.cnhVerso:
          _cnhVersoFile = file;
          break;
        case _DocumentoSlot.perfil:
          _fotoPerfilFile = file;
          break;
      }
    });
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (_step == 0 && !_validateIdentificacao()) return;
    if (_step == 1 && !_validateVeiculo()) return;
    setState(() => _step += 1);
  }

  bool _validateIdentificacao() {
    if (!_showValidationErrors) {
      setState(() => _showValidationErrors = true);
    }
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return false;
    if (!_acceptedTerms) {
      _showMessage('Você deve aceitar os termos de serviço.');
      return false;
    }
    return true;
  }

  bool _validateVeiculo() {
    if (_modeloController.text.trim().length < 2) {
      _showMessage('Informe o modelo do veículo.');
      return false;
    }
    if (_placaObrigatoria && _placaController.text.trim().length < 7) {
      _showMessage('Informe a placa do veículo.');
      return false;
    }
    if (_cepController.text.replaceAll(RegExp(r'\D'), '').length != 8) {
      _showMessage('Informe o CEP do seu endereco.');
      return false;
    }
    if (_logradouroController.text.trim().length < 3) {
      _showMessage('Informe o logradouro do seu endereco.');
      return false;
    }
    if (_numeroController.text.trim().isEmpty) {
      _showMessage('Informe o numero do seu endereco.');
      return false;
    }
    if (_bairroController.text.trim().length < 2) {
      _showMessage('Informe o bairro do seu endereco.');
      return false;
    }
    if (_cidadeController.text.trim().length < 2) {
      _showMessage('Informe a cidade do seu endereco.');
      return false;
    }
    if (_estadoController.text.trim().length != 2) {
      _showMessage('Informe a UF do seu endereco.');
      return false;
    }
    return true;
  }

  bool _validateDocs() {
    if (!_usaCnh && _documentoFrenteFile == null) {
      _showMessage('Envie a frente da identidade.');
      return false;
    }
    if (!_usaCnh && _documentoVersoFile == null) {
      _showMessage('Envie o verso da identidade.');
      return false;
    }
    if (_usaCnh && _cnhFrenteFile == null) {
      _showMessage('Envie a frente da CNH.');
      return false;
    }
    if (_usaCnh && _cnhVersoFile == null) {
      _showMessage('Envie o verso da CNH.');
      return false;
    }
    if (_fotoPerfilFile == null) {
      _showMessage('Envie a foto de perfil.');
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_validateDocs()) return;
    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signUpEntregador(
        nome: _nomeController.text.trim(),
        telefone: _telefoneController.text.trim(),
        cpf: _cpfController.text.trim(),
        dataNascimento: _dataNascimentoIso(),
        tipoVeiculo: _tipoVeiculo,
        placaVeiculo: _tipoVeiculo == 'bicicleta'
            ? ''
            : _placaController.text.trim().toUpperCase(),
        modeloVeiculo: _modeloController.text.trim(),
        email: _emailController.text.trim(),
        senha: _senhaController.text,
        endereco: _enderecoEntregador(),
        identidadeFrenteBytes: !_usaCnh ? _documentoFrenteFile!.bytes : null,
        identidadeFrenteFileName: !_usaCnh ? _documentoFrenteFile!.name : null,
        identidadeVersoBytes: !_usaCnh ? _documentoVersoFile!.bytes : null,
        identidadeVersoFileName: !_usaCnh ? _documentoVersoFile!.name : null,
        cnhFrenteBytes: _usaCnh ? _cnhFrenteFile!.bytes : null,
        cnhFrenteFileName: _usaCnh ? _cnhFrenteFile!.name : null,
        cnhVersoBytes: _usaCnh ? _cnhVersoFile!.bytes : null,
        cnhVersoFileName: _usaCnh ? _cnhVersoFile!.name : null,
        fotoPerfilBytes: _fotoPerfilFile!.bytes,
        fotoPerfilFileName: _fotoPerfilFile!.name,
      );

      if (!mounted) return;
      context.go('/entregador/cadastro-pendente');
    } catch (e) {
      if (mounted) {
        debugPrint('Erro no cadastro de entregador: $e');
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _dataNascimentoIso() {
    final parts = _dataNascimentoController.text.split('/');
    if (parts.length != 3) return '';
    return '${parts[2]}-${parts[1]}-${parts[0]}';
  }

  Map<String, dynamic> _enderecoEntregador() {
    return {
      'cep': _cepController.text.replaceAll(RegExp(r'\D'), ''),
      'logradouro': _logradouroController.text.trim(),
      'numero': _numeroController.text.trim(),
      if (_complementoController.text.trim().isNotEmpty)
        'complemento': _complementoController.text.trim(),
      'bairro': _bairroController.text.trim(),
      'cidade': _cidadeController.text.trim(),
      'estado': _estadoController.text.trim().toUpperCase(),
    };
  }

  Future<void> _buscarCep() async {
    final cep = _cepController.text.replaceAll(RegExp(r'\D'), '');
    if (cep.length != 8) {
      setState(() => _erroCep = 'CEP deve ter 8 digitos.');
      return;
    }

    setState(() {
      _buscandoCep = true;
      _erroCep = null;
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
        setState(() => _erroCep = 'CEP nao encontrado.');
        return;
      }

      setState(() {
        _logradouroController.text = data!['logradouro'] as String;
        _bairroController.text = data['bairro'] as String;
        _cidadeController.text = data['cidade'] as String;
        _estadoController.text = data['estado'] as String;
      });
    } catch (_) {
      setState(() => _erroCep = 'Erro ao buscar CEP. Tente novamente.');
    } finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF7034);
    const burgundyColor = Color(0xFF8E2A2B);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1614) : const Color(0xFFF9F5F0);
    final textColor = isDark ? const Color(0xFFFFE0B2) : burgundyColor;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: (context) => _buildContent(
            primaryColor: primaryColor,
            burgundyColor: burgundyColor,
            textColor: textColor,
            isDark: isDark,
          ),
          desktop: (context) => _buildContent(
            primaryColor: primaryColor,
            burgundyColor: burgundyColor,
            textColor: textColor,
            isDark: isDark,
          ),
        ),
      ),
    );
  }

  Widget _buildContent({
    required Color primaryColor,
    required Color burgundyColor,
    required Color textColor,
    required bool isDark,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _formKey,
            autovalidateMode: _showValidationErrors
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  title: 'Cadastro de entregador',
                  subtitle:
                      'Envie seus dados para análise. O acesso ao app será liberado após aprovação do admin.',
                  isDark: isDark,
                  textColor: textColor,
                  primaryColor: primaryColor,
                  burgundyColor: burgundyColor,
                ),
                const SizedBox(height: 24),
                _StepIndicator(currentStep: _step, primaryColor: primaryColor),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: switch (_step) {
                    0 => _buildIdentificacao(primaryColor, textColor, isDark),
                    1 => _buildVeiculo(primaryColor, textColor, isDark),
                    _ => _buildDocumentacao(primaryColor, textColor, isDark),
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (_step > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => setState(() => _step -= 1),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            foregroundColor: burgundyColor,
                            side: BorderSide(
                                color: burgundyColor.withValues(alpha: .25)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Voltar'),
                        ),
                      ),
                    if (_step > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed:
                            _isLoading ? null : (_step == 2 ? _submit : _next),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(_step == 2
                                ? 'Enviar para análise'
                                : 'Continuar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdentificacao(Color primaryColor, Color textColor, bool isDark) {
    return Column(
      key: const ValueKey('identificacao'),
      children: [
        _buildInput(
          controller: _nomeController,
          label: 'Nome completo',
          icon: Icons.person_outline,
          hint: 'Seu nome completo',
          isDark: isDark,
          primaryColor: primaryColor,
          validator: (v) => (v == null || v.trim().length < 3)
              ? 'Informe seu nome completo'
              : null,
        ),
        _buildInput(
          controller: _cpfController,
          label: 'CPF',
          icon: Icons.badge_outlined,
          hint: '000.000.000-00',
          isDark: isDark,
          primaryColor: primaryColor,
          keyboardType: TextInputType.number,
          inputFormatters: [_cpfFormatter],
          onChanged: (_) => setState(() {}),
          suffixIcon: _cpfController.text.isEmpty
              ? null
              : Icon(
                  _cpfValido ? Icons.check_circle : Icons.error_outline,
                  color: _cpfValido
                      ? const Color(0xFF10B981)
                      : (_showValidationErrors ? Colors.red[600] : Colors.grey),
                ),
          validator: BrazilianDocumentValidator.cpfFormValidator,
        ),
        _buildInput(
          controller: _dataNascimentoController,
          label: 'Data de nascimento',
          icon: Icons.calendar_today_outlined,
          hint: 'DD/MM/AAAA',
          isDark: isDark,
          primaryColor: primaryColor,
          keyboardType: TextInputType.number,
          inputFormatters: [_dateFormatter],
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: _selectDate,
          ),
          validator: BrazilianDocumentValidator.adultBrazilianDateFormValidator,
        ),
        _buildInput(
          controller: _emailController,
          label: 'E-mail',
          icon: Icons.mail_outline,
          hint: 'seu@email.com',
          isDark: isDark,
          primaryColor: primaryColor,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            final email = v?.trim() ?? '';
            return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)
                ? null
                : 'Informe um e-mail válido';
          },
        ),
        _buildInput(
          controller: _telefoneController,
          label: 'Telefone',
          icon: Icons.call_outlined,
          hint: '(11) 99999-9999',
          isDark: isDark,
          primaryColor: primaryColor,
          keyboardType: TextInputType.phone,
          inputFormatters: [_phoneFormatter],
          validator: (v) =>
              ((v ?? '').replaceAll(RegExp(r'\D'), '').length >= 10)
                  ? null
                  : 'Informe um telefone válido',
        ),
        _buildInput(
          controller: _senhaController,
          label: 'Senha',
          icon: Icons.lock_outline,
          hint: 'Mínimo 6 caracteres',
          isDark: isDark,
          primaryColor: primaryColor,
          obscureText: !_isPasswordVisible,
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: () =>
                setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
          validator: (v) => (v == null || v.length < 6)
              ? 'A senha deve ter pelo menos 6 caracteres'
              : null,
        ),
        _buildInput(
          controller: _confirmarSenhaController,
          label: 'Confirmar senha',
          icon: Icons.lock_outline,
          hint: 'Digite a senha novamente',
          isDark: isDark,
          primaryColor: primaryColor,
          obscureText: !_isConfirmPasswordVisible,
          suffixIcon: IconButton(
            icon: Icon(
              _isConfirmPasswordVisible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: () => setState(
              () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
            ),
          ),
          validator: (v) =>
              v == _senhaController.text ? null : 'As senhas não coincidem',
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Checkbox(
              value: _acceptedTerms,
              activeColor: primaryColor,
              onChanged: (value) =>
                  setState(() => _acceptedTerms = value ?? false),
            ),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  children: [
                    const TextSpan(text: 'Eu aceito os '),
                    TextSpan(
                      text: 'termos de serviço e política de privacidade',
                      style: GoogleFonts.outfit(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => context.push('/privacy'),
                    ),
                    const TextSpan(text: ' da Padoca Express.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVeiculo(Color primaryColor, Color textColor, bool isDark) {
    return Column(
      key: const ValueKey('veiculo'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Selecione seu veículo',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _vehicleCard(
                'moto', 'Moto', Icons.two_wheeler, primaryColor, isDark),
            const SizedBox(width: 10),
            _vehicleCard(
                'carro', 'Carro', Icons.directions_car, primaryColor, isDark),
            const SizedBox(width: 10),
            _vehicleCard('bicicleta', 'Bicicleta', Icons.directions_bike,
                primaryColor, isDark),
          ],
        ),
        _buildInput(
          controller: _modeloController,
          label: 'Modelo',
          icon: Icons.build_circle_outlined,
          hint: 'Ex: Honda Biz 125',
          isDark: isDark,
          primaryColor: primaryColor,
        ),
        _buildInput(
          controller: _placaController,
          label: _placaObrigatoria ? 'Placa' : 'Placa (opcional)',
          icon: Icons.pin_outlined,
          hint: _placaObrigatoria
              ? 'ABC1D23 ou ABC-1234'
              : 'Opcional para bicicleta',
          isDark: isDark,
          primaryColor: primaryColor,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9-]')),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Endereco',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Usado para cadastro e validacao da subconta Asaas.',
          style: GoogleFonts.outfit(
            fontSize: 13,
            height: 1.4,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        _buildInput(
          controller: _cepController,
          label: 'CEP',
          icon: Icons.location_on_outlined,
          hint: '00000-000',
          isDark: isDark,
          primaryColor: primaryColor,
          keyboardType: TextInputType.number,
          inputFormatters: [_cepFormatter],
          onChanged: (_) {
            setState(() => _erroCep = null);
            if (_cepController.text.replaceAll(RegExp(r'\D'), '').length == 8 &&
                !_buscandoCep) {
              _buscarCep();
            }
          },
          suffixIcon: _buscandoCep
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  tooltip: 'Buscar CEP',
                  icon: const Icon(Icons.search),
                  onPressed: _buscarCep,
                ),
        ),
        if (_erroCep != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _erroCep!,
              style: GoogleFonts.outfit(
                color: Colors.red[600],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        _buildInput(
          controller: _logradouroController,
          label: 'Logradouro',
          icon: Icons.route_outlined,
          hint: 'Rua, avenida ou travessa',
          isDark: isDark,
          primaryColor: primaryColor,
          textCapitalization: TextCapitalization.words,
        ),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildInput(
                controller: _numeroController,
                label: 'Numero',
                icon: Icons.tag_outlined,
                hint: '123',
                isDark: isDark,
                primaryColor: primaryColor,
                keyboardType: TextInputType.text,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: _buildInput(
                controller: _complementoController,
                label: 'Complemento',
                icon: Icons.apartment_outlined,
                hint: 'Opcional',
                isDark: isDark,
                primaryColor: primaryColor,
                textCapitalization: TextCapitalization.words,
              ),
            ),
          ],
        ),
        _buildInput(
          controller: _bairroController,
          label: 'Bairro',
          icon: Icons.location_city_outlined,
          hint: 'Bairro',
          isDark: isDark,
          primaryColor: primaryColor,
          textCapitalization: TextCapitalization.words,
        ),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildInput(
                controller: _cidadeController,
                label: 'Cidade',
                icon: Icons.location_city_outlined,
                hint: 'Cidade',
                isDark: isDark,
                primaryColor: primaryColor,
                textCapitalization: TextCapitalization.words,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInput(
                controller: _estadoController,
                label: 'UF',
                icon: Icons.map_outlined,
                hint: 'PI',
                isDark: isDark,
                primaryColor: primaryColor,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(2),
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentacao(Color primaryColor, Color textColor, bool isDark) {
    return Column(
      key: const ValueKey('documentacao'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Documentação',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _usaCnh
              ? 'Envie sua selfie e CNH.'
              : 'Envie sua selfie e identidade.',
          style: GoogleFonts.outfit(
            fontSize: 13,
            height: 1.4,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        if (!_usaCnh) ...[
          _uploadCard(
            title: 'Identidade - frente',
            subtitle: 'Envie uma foto legível da frente da identidade.',
            icon: Icons.badge_outlined,
            file: _documentoFrenteFile,
            primaryColor: primaryColor,
            isDark: isDark,
            onTap: () => _pickFile(_DocumentoSlot.frente),
          ),
          const SizedBox(height: 12),
          _uploadCard(
            title: 'Identidade - verso',
            subtitle: 'Envie uma foto legível do verso da identidade.',
            icon: Icons.badge_outlined,
            file: _documentoVersoFile,
            primaryColor: primaryColor,
            isDark: isDark,
            onTap: () => _pickFile(_DocumentoSlot.verso),
          ),
        ] else ...[
          _uploadCard(
            title: 'CNH - frente',
            subtitle: 'Envie uma foto legível da frente da CNH.',
            icon: Icons.badge_outlined,
            file: _cnhFrenteFile,
            primaryColor: primaryColor,
            isDark: isDark,
            onTap: () => _pickFile(_DocumentoSlot.cnhFrente),
          ),
          const SizedBox(height: 12),
          _uploadCard(
            title: 'CNH - verso',
            subtitle: 'Envie uma foto legível do verso da CNH.',
            icon: Icons.badge_outlined,
            file: _cnhVersoFile,
            primaryColor: primaryColor,
            isDark: isDark,
            onTap: () => _pickFile(_DocumentoSlot.cnhVerso),
          ),
        ],
        const SizedBox(height: 12),
        _uploadCard(
          title: 'Selfie',
          subtitle: 'Use uma foto clara do seu rosto.',
          icon: Icons.account_circle_outlined,
          file: _fotoPerfilFile,
          primaryColor: primaryColor,
          isDark: isDark,
          onTap: () => _pickFile(_DocumentoSlot.perfil),
        ),
      ],
    );
  }

  Widget _vehicleCard(
    String value,
    String label,
    IconData icon,
    Color primaryColor,
    bool isDark,
  ) {
    final selected = _tipoVeiculo == value;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() {
          _tipoVeiculo = value;
          if (_usaCnh) {
            _documentoFrenteFile = null;
            _documentoVersoFile = null;
          } else {
            _cnhFrenteFile = null;
            _cnhVersoFile = null;
          }
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 112,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? primaryColor.withValues(alpha: .12)
                : (isDark ? const Color(0xFF171717) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? primaryColor
                  : (isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB)),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: selected ? primaryColor : Colors.grey[500], size: 30),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? primaryColor
                      : (isDark ? Colors.grey[200] : const Color(0xFF374151)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _uploadCard({
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
          color: isDark ? const Color(0xFF171717) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFile ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
            width: hasFile ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: hasFile
                    ? const Color(0xFFECFDF5)
                    : primaryColor.withValues(alpha: .1),
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
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color:
                          isDark ? Colors.grey[100] : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasFile ? file.name : subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
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

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    required bool isDark,
    required Color primaryColor,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    Widget? suffixIcon,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
        validator: validator,
        onChanged: onChanged,
        style: GoogleFonts.outfit(
          color: isDark ? Colors.grey[100] : Colors.grey[800],
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 20),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: isDark ? const Color(0xFF171717) : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
        ),
      ),
    );
  }
}

enum _DocumentoSlot { frente, verso, cnhFrente, cnhVerso, perfil }

class _DocumentoArquivo {
  final String name;
  final Uint8List bytes;

  const _DocumentoArquivo({
    required this.name,
    required this.bytes,
  });
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDark;
  final Color textColor;
  final Color primaryColor;
  final Color burgundyColor;

  const _Header({
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.textColor,
    required this.primaryColor,
    required this.burgundyColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: textColor),
              onPressed: () => context.pop(),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bakery_dining,
                      color: isDark ? primaryColor : burgundyColor),
                  const SizedBox(width: 8),
                  Text(
                    'PAD0CA EXPRESS'.replaceAll('0', 'O'),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 22),
        Container(
          width: 82,
          height: 82,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF262626) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Image.asset(
            'assets/imagens/6ecd0f44-dfa4-4738-9674-3876102610c9.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 14,
            height: 1.45,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final Color primaryColor;

  const _StepIndicator({required this.currentStep, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (Icons.person_outline, 'Identificação'),
      (Icons.two_wheeler, 'Veículo'),
      (Icons.verified_user_outlined, 'Documentação'),
    ];

    return Row(
      children: List.generate(steps.length, (index) {
        final active = index <= currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: active ? primaryColor : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        steps[index].$1,
                        color: active ? Colors.white : const Color(0xFF6B7280),
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      steps[index].$2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: active ? primaryColor : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              if (index < steps.length - 1)
                Container(
                  width: 22,
                  height: 2,
                  color: index < currentStep
                      ? primaryColor
                      : const Color(0xFFE5E7EB),
                ),
            ],
          ),
        );
      }),
    );
  }
}
