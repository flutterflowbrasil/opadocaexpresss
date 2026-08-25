import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/categoria_model.dart';
import '../../controllers/categorias_controller.dart';

class CategoriaFormModal extends ConsumerStatefulWidget {
  final CategoriaModel? categoria;

  const CategoriaFormModal({super.key, this.categoria});

  @override
  ConsumerState<CategoriaFormModal> createState() => _CategoriaFormModalState();
}

class _CategoriaFormModalState extends ConsumerState<CategoriaFormModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeCtrl;
  late TextEditingController _slugCtrl;
  late TextEditingController _ordemCtrl;
  
  bool _ativa = true;
  File? _imagemFile;
  bool _autoSlug = true;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController(text: widget.categoria?.nome ?? '');
    _slugCtrl = TextEditingController(text: widget.categoria?.slug ?? '');
    _ordemCtrl = TextEditingController(text: widget.categoria?.ordemExibicao.toString() ?? '0');
    _ativa = widget.categoria?.ativa ?? true;

    if (widget.categoria != null) {
      _autoSlug = false;
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _slugCtrl.dispose();
    _ordemCtrl.dispose();
    super.dispose();
  }

  void _onNomeChanged(String value) {
    if (_autoSlug) {
      final controller = ref.read(categoriasControllerProvider.notifier);
      _slugCtrl.text = controller.gerarSlug(value);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imagemFile = File(picked.path);
      });
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    
    final controller = ref.read(categoriasControllerProvider.notifier);
    
    final success = await controller.salvarCategoria(
      id: widget.categoria?.id,
      nome: _nomeCtrl.text.trim(),
      slug: _slugCtrl.text.trim(),
      ordemExibicao: int.tryParse(_ordemCtrl.text.trim()) ?? 0,
      ativa: _ativa,
      imagemFile: _imagemFile,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoriasControllerProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Center(
        child: Container(
          width: 520,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 48,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.categoria == null ? 'Nova Categoria' : 'Editar Categoria',
                      style: GoogleFonts.publicSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A0910),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 20),
                      color: const Color(0xFF6B7280),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEAE8E4)),
              
              // Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (state.error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: Text(
                              state.error!,
                              style: GoogleFonts.publicSans(
                                fontSize: 12,
                                color: const Color(0xFF991B1B),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Imagem Preview
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9F8F7),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFEAE8E4)),
                                ),
                                child: _imagemFile != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(11),
                                        child: Image.file(_imagemFile!, fit: BoxFit.cover),
                                      )
                                    : widget.categoria?.imagemUrl != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(11),
                                            child: Image.network(widget.categoria!.imagemUrl!, fit: BoxFit.cover),
                                          )
                                        : Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF9CA3AF), size: 32),
                                              const SizedBox(height: 8),
                                              Text('Adicionar\\nImagem', textAlign: TextAlign.center, style: GoogleFonts.publicSans(fontSize: 11, color: const Color(0xFF6B7280))),
                                            ],
                                          ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Campos principais
                            Expanded(
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _nomeCtrl,
                                    decoration: _inputDecoration('Nome da Categoria'),
                                    onChanged: _onNomeChanged,
                                    validator: (val) => val == null || val.isEmpty ? 'Obrigatório' : null,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _slugCtrl,
                                    decoration: _inputDecoration('Slug (URL)'),
                                    onChanged: (_) => _autoSlug = false,
                                    validator: (val) => val == null || val.isEmpty ? 'Obrigatório' : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _ordemCtrl,
                                decoration: _inputDecoration('Ordem de Exibição'),
                                keyboardType: TextInputType.number,
                                validator: (val) => int.tryParse(val ?? '') == null ? 'Deve ser um número' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: SwitchListTile(
                                title: Text('Ativa', style: GoogleFonts.publicSans(fontSize: 14)),
                                value: _ativa,
                                onChanged: (val) => setState(() => _ativa = val),
                                contentPadding: EdgeInsets.zero,
                                activeThumbColor: const Color(0xFFF97316),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFEAE8E4))),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: state.isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: state.isSubmitting ? null : _salvar,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316),
                      ),
                      child: state.isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Salvar'),
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.publicSans(fontSize: 13, color: const Color(0xFF6B7280)),
      filled: true,
      fillColor: const Color(0xFFF9F8F7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEAE8E4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEAE8E4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFF97316)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
