import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:typed_data';

class EditarInformacoesModal extends ConsumerStatefulWidget {
  const EditarInformacoesModal({super.key});

  @override
  ConsumerState<EditarInformacoesModal> createState() =>
      _EditarInformacoesModalState();
}

class _EditarInformacoesModalState
    extends ConsumerState<EditarInformacoesModal> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _dataNascimentoController =
      TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Initial values for comparison
  String _initialNome = '';
  String _initialCpf = '';
  String _initialDataNascimento = '';
  String _initialTelefone = '';

  String _fotoPerfilUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuB3TYB3nqJUiQDEvsnYTSQOCp1namm9a65lATM2cc8ubuael3Nr1Ul4AderRK6Edi-lO38d_HYIgstd9X06jK5zhkX3UaY-NDqa0g2uvEDwJ_0Zt_d1Y1kQztqZB0i82DV8IqZza4C4CCQGKdNx5WnPxOd00pyXSeucasIFrszm7nGWWJqh3O35jXiY6ApwsJ8eBWVhuZeYp61CkRJp_-KF1GWrx3Rp3vD0wXCCoZybsaWzoX1paLPYt9eIyHP8x8Cvy5TPEkKq';

  // New image state
  Uint8List? _newImageBytes;

  // Has changes getter
  bool get _hasChanges {
    if (_newImageBytes != null) return true;
    if (_nomeController.text.trim() != _initialNome) return true;
    if (_cpfController.text.trim() != _initialCpf) return true;
    if (_dataNascimentoController.text.trim() != _initialDataNascimento)
      return true;
    if (_telefoneController.text.trim() != _initialTelefone) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    _nomeController.addListener(() => setState(() {}));
    _cpfController.addListener(() => setState(() {}));
    _dataNascimentoController.addListener(() => setState(() {}));
    _telefoneController.addListener(() => setState(() {}));
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Fetch user data
      final usuarioData = await _supabase
          .from('usuarios')
          .select('nome_completo_fantasia, telefone, email')
          .eq('id', userId)
          .maybeSingle();

      // Fetch client data
      final clienteData = await _supabase
          .from('clientes')
          .select('data_nascimento, cpf, foto_perfil_url')
          .eq('usuario_id', userId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _nomeController.text = usuarioData?['nome_completo_fantasia'] ?? '';
          _telefoneController.text = usuarioData?['telefone'] ?? '';
          _emailController.text =
              usuarioData?['email'] ?? _supabase.auth.currentUser?.email ?? '';

          _cpfController.text = clienteData?['cpf'] ?? '';
          _dataNascimentoController.text =
              clienteData?['data_nascimento'] ?? '';

          _initialNome = _nomeController.text;
          _initialTelefone = _telefoneController.text;
          _initialCpf = _cpfController.text;
          _initialDataNascimento = _dataNascimentoController.text;

          if (clienteData?['foto_perfil_url'] != null) {
            _fotoPerfilUrl = clienteData!['foto_perfil_url'];
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    }
  }

  Future<void> _pickAndCropImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 80,
      );

      if (image != null) {
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          compressQuality: 80,
          maxWidth: 400,
          maxHeight: 400,
          uiSettings: [
            AndroidUiSettings(
                toolbarTitle: 'Cortar',
                toolbarColor: const Color(0xFFFF7034),
                toolbarWidgetColor: Colors.white,
                initAspectRatio: CropAspectRatioPreset.square,
                lockAspectRatio: true),
            IOSUiSettings(
              title: 'Cortar',
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
            ),
            WebUiSettings(
              context: context,
              presentStyle: WebPresentStyle.page,
            ),
          ],
        );

        if (croppedFile != null) {
          final bytes = await croppedFile.readAsBytes();
          setState(() {
            _newImageBytes = bytes;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar imagem: $e')),
        );
      }
    }
  }

  Future<void> _saveData() async {
    if (!_hasChanges) return;

    if (_nomeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O nome não pode estar vazio')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não logado');

      // Handle Image Upload First
      String? uploadedImageUrl;
      if (_newImageBytes != null) {
        final ext = 'jpg';
        final fileName =
            '${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final imagePath = 'imagens_perfil/$fileName';

        await _supabase.storage.from('imagens').uploadBinary(
              imagePath,
              _newImageBytes!,
              fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
            );

        uploadedImageUrl =
            _supabase.storage.from('imagens').getPublicUrl(imagePath);
      }

      // Update usuarios table
      await _supabase.from('usuarios').update({
        'nome_completo_fantasia': _nomeController.text.trim(),
        'telefone': _telefoneController.text.trim(),
        // Cannot easily update auth email through just the table if we want the actual login to change.
        // We will just update the public table for now as a fallback, but auth email requires auth API change.
      }).eq('id', userId);

      // Check if client exists, if so update, else insert (upsert logic)
      final clienteData = await _supabase
          .from('clientes')
          .select('id')
          .eq('usuario_id', userId)
          .maybeSingle();

      if (clienteData != null) {
        final updates = {
          'cpf': _cpfController.text.trim().isEmpty
              ? null
              : _cpfController.text.trim(),
          'data_nascimento': _dataNascimentoController.text.trim().isEmpty
              ? null
              : _dataNascimentoController.text.trim(),
        };
        if (uploadedImageUrl != null)
          updates['foto_perfil_url'] = uploadedImageUrl;

        await _supabase
            .from('clientes')
            .update(updates)
            .eq('usuario_id', userId);
      } else {
        await _supabase.from('clientes').insert({
          'usuario_id': userId,
          'cpf': _cpfController.text.trim().isEmpty
              ? null
              : _cpfController.text.trim(),
          'data_nascimento': _dataNascimentoController.text.trim().isEmpty
              ? null
              : _dataNascimentoController.text.trim(),
          'foto_perfil_url': uploadedImageUrl,
        });
      }

      if (mounted) {
        Navigator.pop(context, true); // true indicates success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informações atualizadas com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar dados: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _dataNascimentoController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFFFF7034);
    const burgundyColor = Color(0xFF7D2D35);
    final bgColor = isDark ? const Color(0xFF23150F) : const Color(0xFFF9F5F0);
    final textColor = isDark ? Colors.white : burgundyColor;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // Use constrained height for bottom sheet
      height: MediaQuery.of(context).size.height * 0.9,
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  color: textColor,
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  'Editar Informações',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 48), // Balance for centering
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: primaryColor))
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    child: Column(
                      children: [
                        // Avatar Edit
                        Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[200],
                                border: Border.all(
                                  color:
                                      isDark ? Colors.grey[800]! : Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                  )
                                ],
                                image: DecorationImage(
                                  image: _newImageBytes != null
                                      ? MemoryImage(_newImageBytes!)
                                          as ImageProvider
                                      : NetworkImage(_fotoPerfilUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              child: GestureDetector(
                                onTap: _isSaving ? null : _pickAndCropImage,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.edit,
                                          color: Colors.white, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        'ALTERAR',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Informações Pessoais
                        _buildSectionTitle('Informações Pessoais', isDark),
                        const SizedBox(height: 16),
                        _buildInputField('Nome', _nomeController, isDark,
                            primaryColor, burgundyColor),
                        const SizedBox(height: 16),
                        _buildInputField(
                            'Data de Nascimento',
                            _dataNascimentoController,
                            isDark,
                            primaryColor,
                            burgundyColor,
                            placeholder: 'DD/MM/AAAA'),
                        const SizedBox(height: 16),
                        _buildInputField('CPF', _cpfController, isDark,
                            primaryColor, burgundyColor,
                            placeholder: '000.000.000-00'),
                        const SizedBox(height: 16),
                        _buildInputField('Telefone', _telefoneController,
                            isDark, primaryColor, burgundyColor,
                            placeholder: '(00) 00000-0000'),

                        const SizedBox(height: 32),

                        // Segurança
                        _buildSectionTitle('Segurança', isDark),
                        const SizedBox(height: 16),
                        _buildInputField('Alterar E-mail', _emailController,
                            isDark, primaryColor, burgundyColor,
                            icon: Icons.edit, enabled: false),

                        const SizedBox(height: 40),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                (_isSaving || !_hasChanges) ? null : _saveData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  isDark ? Colors.grey[800] : Colors.grey[300],
                              disabledForegroundColor:
                                  isDark ? Colors.grey[600] : Colors.grey[500],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: _hasChanges ? 4 : 0,
                              shadowColor: primaryColor.withOpacity(0.4),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Text(
                                    'Salvar Alterações',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: isDark ? Colors.white : const Color(0xFF7D2D35),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller,
      bool isDark, Color primaryColor, Color burgundyColor,
      {String? placeholder, IconData? icon, bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: isDark
                  ? Colors.white60
                  : burgundyColor.withValues(alpha: 0.6),
            ),
          ),
        ),
        TextField(
          controller: controller,
          enabled: enabled,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: isDark ? Colors.white : burgundyColor,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle:
                TextStyle(color: isDark ? Colors.white30 : Colors.black38),
            filled: true,
            fillColor: isDark ? const Color(0xFF18181B) : Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[800]! : Colors.orange[100]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[800]! : Colors.orange[100]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            suffixIcon: icon != null
                ? Icon(icon,
                    color: burgundyColor.withValues(alpha: 0.4), size: 20)
                : null,
          ),
        ),
      ],
    );
  }
}
