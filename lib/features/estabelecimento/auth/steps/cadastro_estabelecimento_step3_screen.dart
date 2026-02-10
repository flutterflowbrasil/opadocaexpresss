import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:padoca_express/features/auth/data/auth_repository.dart';
import 'package:padoca_express/features/estabelecimento/componentes/app_bar_estabelecimento.dart';
import 'package:padoca_express/features/estabelecimento/auth/cadastro_estabelecimento_controller.dart';
import 'package:padoca_express/features/estabelecimento/data/storage_service.dart';

class CadastroEstabelecimentoStep3Screen extends ConsumerStatefulWidget {
  const CadastroEstabelecimentoStep3Screen({super.key});

  @override
  ConsumerState<CadastroEstabelecimentoStep3Screen> createState() =>
      _CadastroEstabelecimentoStep3ScreenState();
}

class _CadastroEstabelecimentoStep3ScreenState
    extends ConsumerState<CadastroEstabelecimentoStep3Screen> {
  final _formKey = GlobalKey<FormState>();
  final _bancoController = TextEditingController(); // Idealmente um Dropdown
  final _agenciaController = TextEditingController();
  final _contaController = TextEditingController();
  final _contaDigitoController = TextEditingController();
  final _titularNomeController = TextEditingController();
  final _titularCpfCnpjController = TextEditingController();

  String _tipoConta = 'corrente';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(cadastroEstabelecimentoProvider);
    // Preencher campos se existirem
    if (state.titularCpfCnpj != null) {
      _titularCpfCnpjController.text = state.titularCpfCnpj!;
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final controller = ref.read(cadastroEstabelecimentoProvider.notifier);
        controller.updateStep3(
          banco: _bancoController.text,
          agencia: _agenciaController.text,
          conta: _contaController.text,
          contaDigito: _contaDigitoController.text,
          tipoConta: _tipoConta,
          titularNome: _titularNomeController.text,
          titularCpfCnpj: _titularCpfCnpjController.text,
        );

        final state = ref.read(cadastroEstabelecimentoProvider);
        final authRepo = ref.read(authRepositoryProvider);
        final storageService = ref.read(storageServiceProvider);

        // Chamada única para realizar todo o cadastro
        // Note: authRepo.signUpEstabelecimento precisa ser implementado para aceitar
        // o File da imagem e fazer o upload internamente ou receber a URL.
        // Aqui vou fazer o upload primeiro se houver imagem e passar a URL.

        // O upload precisa do ID do usuário, mas o usuário só é criado no signUp.
        // Estratégia: O AuthRepository deve lidar com isso ou retornar o AuthResponse
        // antes de inserir na tabela, mas como estamos fazendo tudo junto,
        // vamos passar o File para o AuthRepository lidar pós-criação do Auth User.

        await authRepo.signUpEstabelecimento(
          dadosCadastro: state,
          storageService: storageService,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cadastro realizado com sucesso!')),
          );
          // Redirecionar para dashboard ou aguardar aprovação
          context.go('/home'); // Ajustar rota de destino
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erro no cadastro: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFFff7033);
    final burgundyColor = const Color(0xFF7d2d35);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF23150f)
          : const Color(0xFFf9f5f0),
      appBar: const AppBarEstabelecimento(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PASSO 3 DE 3',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: burgundyColor.withOpacity(0.6),
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '100%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: burgundyColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 1.0,
                      backgroundColor: burgundyColor.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation(primaryColor),
                      minHeight: 6,
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'Dados para Recebimento',
                    style: GoogleFonts.plusJakartaSans(
                      color: isDark ? Colors.white : burgundyColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Informe a conta onde deseja receber suas vendas do Padoca Express.',
                    style: GoogleFonts.plusJakartaSans(
                      color: isDark
                          ? Colors.grey[400]
                          : burgundyColor.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 32),

                  _buildTextField(
                    controller: _bancoController,
                    label: 'Nome do Banco',
                    icon: Icons.account_balance,
                    isDark: isDark,
                    hintText: 'Banco do Brasil',
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Campo obrigatório' : null,
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _agenciaController,
                          label: 'Agência',
                          icon: Icons.apartment,
                          isDark: isDark,
                          hintText: '0000',
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Campo obrigatório'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _contaController,
                          label: 'Conta + Dígito',
                          icon: Icons.tag,
                          isDark: isDark,
                          hintText: '00000-0',
                          keyboardType: TextInputType.text, // Aceitar hífen
                          validator: (v) => v == null || v.isEmpty
                              ? 'Campo obrigatório'
                              : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'Tipo de Conta',
                    style: GoogleFonts.plusJakartaSans(
                      color: isDark ? Colors.white : burgundyColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRadioOption(
                          'Corrente',
                          'corrente',
                          isDark,
                          primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildRadioOption(
                          'Poupança',
                          'poupanca',
                          isDark,
                          primaryColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  _buildTextField(
                    controller: _titularNomeController,
                    label: 'Nome do Titular',
                    icon: Icons.person,
                    isDark: isDark,
                    hintText: 'Nome Completo',
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Campo obrigatório' : null,
                  ),

                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _titularCpfCnpjController,
                    label: 'CPF/CNPJ do Titular',
                    icon: Icons.badge,
                    isDark: isDark,
                    hintText: '000.000.000-00',
                    keyboardType: TextInputType.number,
                  ),
                  Text(
                    'Deve coincidir com os dados de cadastro da empresa.',
                    style: GoogleFonts.plusJakartaSans(
                      color: isDark
                          ? Colors.grey[400]
                          : burgundyColor.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),

                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: primaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pagamentos Seguros via ASAAS',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isDark ? Colors.white : burgundyColor,
                                ),
                              ),
                              Text(
                                'Seus repasses serão processados com segurança através da tecnologia ASAAS.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.grey[300]
                                      : burgundyColor.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF23150f) : const Color(0xFFf9f5f0),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              isDark ? const Color(0xFF23150f) : const Color(0xFFf9f5f0),
              isDark
                  ? const Color(0xFF23150f).withOpacity(0)
                  : const Color(0xFFf9f5f0).withOpacity(0),
            ],
          ),
        ),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.rocket_launch, color: Colors.white),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
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
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
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
                    : burgundyColor.withOpacity(0.4),
              ),
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

  Widget _buildRadioOption(
    String label,
    String value,
    bool isDark,
    Color primaryColor,
  ) {
    bool isSelected = _tipoConta == value;
    return GestureDetector(
      onTap: () => setState(() => _tipoConta = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.withOpacity(0.3),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: isSelected
                  ? primaryColor
                  : (isDark
                        ? Colors.white
                        : const Color(0xFF7d2d35).withOpacity(0.6)),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
