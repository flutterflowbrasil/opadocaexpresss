import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:padoca_express/features/estabelecimento/componentes/app_bar_estabelecimento.dart';
import 'package:padoca_express/features/estabelecimento/auth/cadastro_estabelecimento_controller.dart';

class CadastroEstabelecimentoStep1Screen extends ConsumerStatefulWidget {
  const CadastroEstabelecimentoStep1Screen({super.key});

  @override
  ConsumerState<CadastroEstabelecimentoStep1Screen> createState() =>
      _CadastroEstabelecimentoStep1ScreenState();
}

class _CadastroEstabelecimentoStep1ScreenState
    extends ConsumerState<CadastroEstabelecimentoStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmSenhaController = TextEditingController();

  String? _imagePath;
  String _tipoPessoa = 'juridica'; // 'fisica' ou 'juridica'

  final _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _cnpjFormatter = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _telefoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    // Preencher campos se já existirem no estado (para voltar da etapa 2)
    final state = ref.read(cadastroEstabelecimentoProvider);
    if (state.nomeFantasia != null) _nomeController.text = state.nomeFantasia!;
    if (state.cnpj != null) _cnpjController.text = state.cnpj!;
    if (state.telefone != null) _telefoneController.text = state.telefone!;
    if (state.email != null) _emailController.text = state.email!;

    _imagePath = state.imagemCapaPath;
    _tipoPessoa = state.tipoPessoa ?? 'juridica';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      _cropImage(pickedFile.path);
    }
  }

  Future<void> _cropImage(String sourcePath) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      aspectRatio: const CropAspectRatio(ratioX: 2, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recortar Capa',
          toolbarColor: const Color(0xFFff7033),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.ratio16x9,
          lockAspectRatio: true,
        ),
        IOSUiSettings(title: 'Recortar Capa'),
        WebUiSettings(
          context: context,
          size: const CropperSize(width: 400, height: 400),
          translations: const WebTranslations(
            title: 'Recortar Capa',
            rotateLeftTooltip: 'Girar para esquerda',
            rotateRightTooltip: 'Girar para direita',
            cancelButton: 'Cancelar',
            cropButton: 'Salvar',
          ),
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _imagePath = croppedFile.path;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_senhaController.text != _confirmSenhaController.text) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('As senhas não conferem')));
        return;
      }

      ref
          .read(cadastroEstabelecimentoProvider.notifier)
          .updateStep1(
            nomeFantasia: _nomeController.text,
            cnpj: _cnpjController.text,
            telefone: _telefoneController.text,
            email: _emailController.text,
            senha: _senhaController.text,

            imagemCapaPath: _imagePath,
            tipoPessoa: _tipoPessoa,
          );

      context.push('/cadastro-estabelecimento/step2');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Detectar tema (simples, via brilho do sistema ou provider se tiver acesso)
    // Assumindo ThemeProvider global ou similar
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFFff7033);
    final burgundyColor = const Color(0xFF7d2d35);

    // Determine image provider based on platform
    ImageProvider? imageProvider;
    if (_imagePath != null) {
      if (kIsWeb) {
        imageProvider = NetworkImage(_imagePath!);
      } else {
        imageProvider = FileImage(File(_imagePath!));
      }
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF23150f)
          : const Color(0xFFf9f5f0),
      appBar: const AppBarEstabelecimento(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Cadastro de Estabelecimento',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: isDark ? Colors.white : burgundyColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Etapa 1 de 3: Dados básicos da loja',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: isDark
                          ? Colors.grey[400]
                          : burgundyColor.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Image Picker
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.3),
                          style: BorderStyle.solid,
                          width: 2,
                        ),
                        image: imageProvider != null
                            ? DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _imagePath == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.add_a_photo,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Foto da Padaria',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: isDark
                                        ? Colors.white
                                        : burgundyColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Banner ou logo da loja (800x400)',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: isDark
                                        ? Colors.grey[400]
                                        : burgundyColor.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Informações da Loja
                  _buildSectionTitle(
                    Icons.storefront,
                    'Informações da Loja',
                    isDark,
                    burgundyColor,
                    primaryColor,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _nomeController,
                    label: 'Nome da Padaria/Loja',
                    icon: Icons.store,
                    isDark: isDark,
                    hintText: 'Digite o nome da padaria',
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 12),

                  // Toggle Pessoa Física / Jurídica
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _tipoPessoa = 'fisica';
                              _cnpjController.clear();
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _tipoPessoa == 'fisica'
                                ? primaryColor.withValues(alpha: 0.1)
                                : Colors.transparent,
                            side: BorderSide(
                              color: _tipoPessoa == 'fisica'
                                  ? primaryColor
                                  : (isDark
                                        ? Colors.grey[700]!
                                        : Colors.grey[300]!),
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Pessoa Física',
                              style: GoogleFonts.plusJakartaSans(
                                color: _tipoPessoa == 'fisica'
                                    ? primaryColor
                                    : (isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600]),
                                fontWeight: _tipoPessoa == 'fisica'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _tipoPessoa = 'juridica';
                              _cnpjController.clear();
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _tipoPessoa == 'juridica'
                                ? primaryColor.withValues(alpha: 0.1)
                                : Colors.transparent,
                            side: BorderSide(
                              color: _tipoPessoa == 'juridica'
                                  ? primaryColor
                                  : (isDark
                                        ? Colors.grey[700]!
                                        : Colors.grey[300]!),
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Pessoa Jurídica',
                              style: GoogleFonts.plusJakartaSans(
                                color: _tipoPessoa == 'juridica'
                                    ? primaryColor
                                    : (isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600]),
                                fontWeight: _tipoPessoa == 'juridica'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _cnpjController,
                          label: _tipoPessoa == 'fisica' ? 'CPF' : 'CNPJ',
                          icon: Icons.badge,
                          isDark: isDark,
                          hintText: _tipoPessoa == 'fisica'
                              ? '000.000.000-00'
                              : '00.000.000/0000-00',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            _tipoPessoa == 'fisica'
                                ? _cpfFormatter
                                : _cnpjFormatter,
                          ],
                          validator: (v) => v == null || v.isEmpty
                              ? 'Campo obrigatório'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _telefoneController,
                          label: 'Telefone',
                          icon: Icons.call,
                          isDark: isDark,
                          hintText: '(11) 99999-9999',
                          keyboardType: TextInputType.phone,
                          inputFormatters: [_telefoneFormatter],
                          validator: (v) => v == null || v.isEmpty
                              ? 'Campo obrigatório'
                              : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Credenciais
                  _buildSectionTitle(
                    Icons.lock,
                    'Credenciais de Acesso',
                    isDark,
                    burgundyColor,
                    primaryColor,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    label: 'E-mail',
                    icon: Icons.email,
                    isDark: isDark,
                    hintText: 'seu@email.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || !v.contains('@')
                        ? 'E-mail inválido'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _senhaController,
                    label: 'Senha',
                    icon: Icons.key,
                    isDark: isDark,
                    obscureText: _obscurePassword,
                    hintText: 'Mínimo 6 caracteres',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) => v == null || v.length < 6
                        ? 'Mínimo 6 caracteres'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _confirmSenhaController,
                    label: 'Confirmar Senha',
                    icon: Icons.verified_user,
                    isDark: isDark,
                    obscureText: _obscureConfirmPassword,
                    hintText: 'Digite a senha novamente',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                      ),
                      onPressed: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Confirme a senha' : null,
                  ),

                  // Checkbox Termos (Simplificado para o exemplo)
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: true,
                          onChanged: (v) {},
                          fillColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.selected)
                                ? primaryColor
                                : Colors.transparent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Li e concordo com os Termos de Serviço e as Políticas de Privacidade da Padoca Express.',
                          style: GoogleFonts.plusJakartaSans(
                            color: isDark
                                ? Colors.grey[400]
                                : burgundyColor.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Botão Continuar
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Continuar',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, color: Colors.white),
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

  Widget _buildSectionTitle(
    IconData icon,
    String title,
    bool isDark,
    Color color,
    Color primary,
  ) {
    return Row(
      children: [
        Icon(icon, color: primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            color: isDark ? Colors.white : color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    List<dynamic>? inputFormatters,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    final formatters = inputFormatters?.cast<TextInputFormatter>();
    final primaryColor = const Color(0xFFff7033);
    final burgundyColor = const Color(0xFF7d2d35);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFD4D4D8) : burgundyColor,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF27272A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            inputFormatters: formatters,
            validator: validator,
            style: GoogleFonts.plusJakartaSans(
              color: isDark ? Colors.white : burgundyColor,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.plusJakartaSans(
                color: isDark ? Colors.grey[600] : Colors.grey[400],
                fontSize: 14,
              ),
              prefixIcon: Icon(
                icon,
                color: isDark
                    ? Colors.grey[600]
                    : burgundyColor.withValues(alpha: 0.4),
              ),
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.red[400]!),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.red[400]!, width: 2),
              ),
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ),
      ],
    );
  }
}
