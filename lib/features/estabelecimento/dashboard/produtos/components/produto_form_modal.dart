import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../controllers/produtos_controller.dart';
import '../models/produto_model.dart';

/// Abre o modal de criação ou edição de produto.
/// Passe [produto] para edição, ou null para novo produto.
void showProdutoFormModal(
  BuildContext context, {
  ProdutoModel? produto,
}) {
  showGeneralDialog(
    context: context,
    barrierLabel: 'Produto Modal',
    barrierDismissible: true,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, anim1, anim2) => _ProdutoFormModal(produto: produto),
    transitionBuilder: (context, anim1, anim2, child) {
      final offset = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic));
      return SlideTransition(position: offset, child: child);
    },
  );
}

class _ProdutoFormModal extends ConsumerStatefulWidget {
  final ProdutoModel? produto;

  const _ProdutoFormModal({this.produto});

  @override
  ConsumerState<_ProdutoFormModal> createState() => _ProdutoFormModalState();
}

class _ProdutoFormModalState extends ConsumerState<_ProdutoFormModal>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // --- Controladores dos campos ---
  // Tab Básico
  final _nomeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _ordemCtrl = TextEditingController(text: '0');
  String _tipoProduto = 'simples';
  String? _categoriaId;
  bool _ativo = true;
  bool _disponivel = true;
  bool _destaque = false;
  bool _permiteObservacao = true;

  // Tab Preço
  final _precoCtrl = TextEditingController();
  final _precoPromoCtrl = TextEditingController();
  final _custoCtrl = TextEditingController();
  final _tempoPreparoCtrl = TextEditingController(text: '0');
  bool _temPromo = false;

  // Tab Estoque
  bool _controleEstoque = false;
  final _estoqueCtrl = TextEditingController();

  // Foto
  Uint8List? _fotoBytes;
  String _fotoExtensao = 'jpg';
  String? _fotoUrl; // URL existente (edição)

  bool get _isEdicao => widget.produto != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    if (_isEdicao) {
      final p = widget.produto!;
      _nomeCtrl.text = p.nome;
      _descCtrl.text = p.descricao ?? '';
      _ordemCtrl.text = p.ordemExibicao.toString();
      _tipoProduto = p.tipoProduto;
      _categoriaId = p.categoriaCardapioId;
      _ativo = p.ativo;
      _disponivel = p.disponivel;
      _destaque = p.destaque;
      _permiteObservacao = p.permiteObservacao;
      _precoCtrl.text = p.preco.toStringAsFixed(2);
      _precoPromoCtrl.text = p.precoPromocional?.toStringAsFixed(2) ?? '';
      _custoCtrl.text = p.custoEstimado?.toStringAsFixed(2) ?? '';
      _tempoPreparoCtrl.text = p.tempoPreparoAdicionalMin.toString();
      _temPromo = p.precoPromocional != null && p.precoPromocional! > 0;
      _controleEstoque = p.controleEstoque;
      _estoqueCtrl.text = p.quantidadeEstoque?.toString() ?? '';
      _fotoUrl = p.fotoPrincipalUrl;
    }
  }

  // ── Seletor de imagem ─────────────────────────────────────────────────────
  Future<void> _pickImagem() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final ext = picked.name.split('.').last.toLowerCase();
    setState(() {
      _fotoBytes = bytes;
      _fotoExtensao = ext.isEmpty ? 'jpg' : ext;
      _fotoUrl = null; // descarta URL antiga; nova imagem tem precedência
    });
  }

  // ── Upload da foto para o Supabase Storage ────────────────────────────────
  Future<String?> _uploadFoto() async {
    if (_fotoBytes == null) return _fotoUrl;
    final path = 'produtos/${const Uuid().v4()}.$_fotoExtensao';
    await Supabase.instance.client.storage.from('imagens').uploadBinary(
          path,
          _fotoBytes!,
          fileOptions: FileOptions(contentType: 'image/$_fotoExtensao'),
        );
    return Supabase.instance.client.storage.from('imagens').getPublicUrl(path);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomeCtrl.dispose();
    _descCtrl.dispose();
    _ordemCtrl.dispose();
    _precoCtrl.dispose();
    _precoPromoCtrl.dispose();
    _custoCtrl.dispose();
    _tempoPreparoCtrl.dispose();
    _estoqueCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar({bool fecharAoFim = true}) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      // Se o campo nome está vazio, muda para a aba básico
      _tabController.animateTo(0);
      return;
    }

    setState(() => _isSaving = true);

    final estabId = ref
            .read(produtosControllerProvider)
            .produtos
            .firstOrNull
            ?.estabelecimentoId ??
        '';

    // Faz upload da foto (se selecionada) antes de salvar o produto
    String? fotoUrl;
    try {
      fotoUrl = await _uploadFoto();
    } catch (_) {
      // Upload falhou — salva o produto sem a nova foto
      fotoUrl = _fotoUrl;
    }

    final preco = double.tryParse(_precoCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final precoPromo = _temPromo
        ? double.tryParse(_precoPromoCtrl.text.replaceAll(',', '.'))
        : null;
    final custo = double.tryParse(_custoCtrl.text.replaceAll(',', '.'));
    final estoque = _controleEstoque ? int.tryParse(_estoqueCtrl.text) : null;

    final novoProduto = ProdutoModel(
      id: widget.produto?.id ?? '',
      estabelecimentoId: estabId,
      nome: _nomeCtrl.text.trim(),
      descricao: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      preco: preco,
      precoPromocional: precoPromo,
      custoEstimado: custo,
      categoriaCardapioId: _categoriaId,
      tipoProduto: _tipoProduto,
      ativo: _ativo,
      disponivel: _disponivel,
      destaque: _destaque,
      permiteObservacao: _permiteObservacao,
      controleEstoque: _controleEstoque,
      quantidadeEstoque: estoque,
      tempoPreparoAdicionalMin: int.tryParse(_tempoPreparoCtrl.text) ?? 0,
      ordemExibicao: int.tryParse(_ordemCtrl.text) ?? 0,
      fotoPrincipalUrl: fotoUrl,
      totalVendidos: widget.produto?.totalVendidos ?? 0,
      opcoes: widget.produto?.opcoes ?? [],
    );

    await ref
        .read(produtosControllerProvider.notifier)
        .salvarProduto(novoProduto);

    setState(() => _isSaving = false);

    if (mounted) {
      final err = ref.read(produtosControllerProvider).error;
      if (err == null) {
        _mostrarToast(fecharAoFim
            ? (_isEdicao ? 'Produto atualizado! ✓' : 'Produto criado! ✓')
            : 'Salvo! Editando próximo produto...');
        if (fecharAoFim) Navigator.of(context).pop();
      } else {
        _mostrarToast('Erro: $err', isError: true);
      }
    }
  }

  void _mostrarToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(msg, style: GoogleFonts.publicSans(fontWeight: FontWeight.w600)),
      backgroundColor: isError ? Colors.red.shade700 : const Color(0xFFec5b13),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final categorias =
        ref.watch(produtosControllerProvider.select((s) => s.categorias));
    final screenW = MediaQuery.of(context).size.width;
    final modalWidth = screenW < 700 ? screenW : 640.0;

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: modalWidth,
          height: double.infinity,
          color: Colors.white,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // ── Header ──
                _ModalHeader(
                  isEdicao: _isEdicao,
                  isSaving: _isSaving,
                  onClose: () => Navigator.of(context).pop(),
                ),

                // ── Tabs ──
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFFec5b13),
                    unselectedLabelColor: Colors.grey.shade500,
                    indicatorColor: const Color(0xFFec5b13),
                    indicatorWeight: 2.5,
                    labelStyle: GoogleFonts.publicSans(
                        fontSize: 13, fontWeight: FontWeight.bold),
                    unselectedLabelStyle: GoogleFonts.publicSans(fontSize: 13),
                    tabs: const [
                      Tab(
                          icon: Icon(Icons.info_outline, size: 18),
                          text: 'Básico'),
                      Tab(
                          icon: Icon(Icons.payments_outlined, size: 18),
                          text: 'Preço'),
                      Tab(
                          icon: Icon(Icons.inventory_2_outlined, size: 18),
                          text: 'Estoque'),
                      Tab(icon: Icon(Icons.tune, size: 18), text: 'Opções'),
                      Tab(
                          icon: Text('🍰',
                              style: TextStyle(fontSize: 16)),
                          text: 'Ult. Mordida'),
                    ],
                  ),
                ),

                // ── Conteúdo das Abas ──
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // 1. Básico
                      _TabBasico(
                        nomeCtrl: _nomeCtrl,
                        descCtrl: _descCtrl,
                        ordemCtrl: _ordemCtrl,
                        tipoProduto: _tipoProduto,
                        categorias: categorias,
                        categoriaId: _categoriaId,
                        ativo: _ativo,
                        disponivel: _disponivel,
                        destaque: _destaque,
                        permiteObservacao: _permiteObservacao,
                        fotoBytes: _fotoBytes,
                        fotoUrl: _fotoUrl,
                        onPickFoto: _pickImagem,
                        onTipoChanged: (v) =>
                            setState(() => _tipoProduto = v ?? 'simples'),
                        onCategoriaChanged: (v) =>
                            setState(() => _categoriaId = v),
                        onAtivoChanged: (v) => setState(() => _ativo = v),
                        onDisponivelChanged: (v) =>
                            setState(() => _disponivel = v),
                        onDestaqueChanged: (v) => setState(() => _destaque = v),
                        onObsChanged: (v) =>
                            setState(() => _permiteObservacao = v),
                      ),
                      // 2. Preço
                      _TabPreco(
                        precoCtrl: _precoCtrl,
                        precoPromoCtrl: _precoPromoCtrl,
                        custoCtrl: _custoCtrl,
                        tempoPreparoCtrl: _tempoPreparoCtrl,
                        temPromo: _temPromo,
                        onTemPromoChanged: (v) => setState(() => _temPromo = v),
                      ),
                      // 3. Estoque
                      _TabEstoque(
                        controleEstoque: _controleEstoque,
                        estoqueCtrl: _estoqueCtrl,
                        onControleChanged: (v) =>
                            setState(() => _controleEstoque = v),
                      ),
                      // 4. Opções (informativo por enquanto)
                      const _TabOpcoes(),
                      // 5. Última Mordida
                      _TabUltimaMordida(produto: widget.produto),
                    ],
                  ),
                ),

                // ── Footer com botões ──
                _ModalFooter(
                  isSaving: _isSaving,
                  isEdicao: _isEdicao,
                  onCancel: () => Navigator.of(context).pop(),
                  onSaveAndContinue: () => _salvar(fecharAoFim: false),
                  onSave: () => _salvar(fecharAoFim: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// HEADER
// ═══════════════════════════════════════════
class _ModalHeader extends StatelessWidget {
  final bool isEdicao;
  final bool isSaving;
  final VoidCallback onClose;

  const _ModalHeader({
    required this.isEdicao,
    required this.isSaving,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdicao ? 'Editar Produto' : 'Novo Produto',
                  style: GoogleFonts.publicSans(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  isEdicao
                      ? 'Atualize as informações do produto'
                      : 'Preencha os dados do novo produto',
                  style: GoogleFonts.publicSans(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          if (isSaving)
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFFec5b13))),
          const SizedBox(width: 12),
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Icon(Icons.close, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// FOOTER
// ═══════════════════════════════════════════
class _ModalFooter extends StatelessWidget {
  final bool isSaving;
  final bool isEdicao;
  final VoidCallback onCancel;
  final VoidCallback onSaveAndContinue;
  final VoidCallback onSave;

  const _ModalFooter({
    required this.isSaving,
    required this.isEdicao,
    required this.onCancel,
    required this.onSaveAndContinue,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: isSaving ? null : onCancel,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            child: Text('Cancelar',
                style: GoogleFonts.publicSans(fontWeight: FontWeight.w600)),
          ),
          const Spacer(),
          if (!isEdicao) ...[
            OutlinedButton(
              onPressed: isSaving ? null : onSaveAndContinue,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFec5b13),
                side: const BorderSide(color: Color(0xFFec5b13)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              child: Text('Salvar e criar outro',
                  style: GoogleFonts.publicSans(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 12),
          ],
          ElevatedButton(
            onPressed: isSaving ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFec5b13),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            child: Text(
              isEdicao ? 'Atualizar Produto' : 'Salvar Produto',
              style: GoogleFonts.publicSans(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// TAB 1 — BÁSICO
// ═══════════════════════════════════════════
class _TabBasico extends StatelessWidget {
  final TextEditingController nomeCtrl;
  final TextEditingController descCtrl;
  final TextEditingController ordemCtrl;
  final String tipoProduto;
  final List categorias;
  final String? categoriaId;
  final bool ativo;
  final bool disponivel;
  final bool destaque;
  final bool permiteObservacao;
  // Foto
  final Uint8List? fotoBytes;
  final String? fotoUrl;
  final VoidCallback onPickFoto;
  final ValueChanged<String?> onTipoChanged;
  final ValueChanged<String?> onCategoriaChanged;
  final ValueChanged<bool> onAtivoChanged;
  final ValueChanged<bool> onDisponivelChanged;
  final ValueChanged<bool> onDestaqueChanged;
  final ValueChanged<bool> onObsChanged;

  const _TabBasico({
    required this.nomeCtrl,
    required this.descCtrl,
    required this.ordemCtrl,
    required this.tipoProduto,
    required this.categorias,
    required this.categoriaId,
    required this.ativo,
    required this.disponivel,
    required this.destaque,
    required this.permiteObservacao,
    required this.fotoBytes,
    required this.fotoUrl,
    required this.onPickFoto,
    required this.onTipoChanged,
    required this.onCategoriaChanged,
    required this.onAtivoChanged,
    required this.onDisponivelChanged,
    required this.onDestaqueChanged,
    required this.onObsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final temFoto = fotoBytes != null || fotoUrl != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Foto Principal ──
          _SectionLabel('Foto Principal',
              subtitle: 'Recomendado: 1200×900px, JPG ou PNG.'),
          const SizedBox(height: 10),
          Row(
            children: [
              // Preview / Placeholder
              GestureDetector(
                onTap: onPickFoto,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: temFoto
                          ? const Color(0xFFec5b13).withValues(alpha: .5)
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    image: fotoBytes != null
                        ? DecorationImage(
                            image: MemoryImage(fotoBytes!),
                            fit: BoxFit.cover,
                          )
                        : fotoUrl != null
                            ? DecorationImage(
                                image: NetworkImage(fotoUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                  ),
                  child: temFoto
                      ? null
                      : Icon(Icons.add_photo_alternate_outlined,
                          color: Colors.grey.shade400, size: 36),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onPickFoto,
                      icon: const Icon(Icons.upload_rounded, size: 16),
                      label: Text(
                        temFoto ? 'Trocar imagem' : 'Selecionar imagem',
                        style: GoogleFonts.publicSans(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFec5b13),
                        side: const BorderSide(color: Color(0xFFec5b13)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      temFoto
                          ? '✓ Imagem selecionada'
                          : 'Nenhuma imagem selecionada',
                      style: GoogleFonts.publicSans(
                        fontSize: 11,
                        color: temFoto
                            ? Colors.green.shade600
                            : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Nome (obrigatório)
          _SectionLabel('Nome do Produto *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: nomeCtrl,
            style: GoogleFonts.publicSans(fontSize: 14),
            decoration: _inputDecoration('Ex: Pão de Queijo Artesanal'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Nome obrigatório' : null,
          ),
          const SizedBox(height: 16),

          // Descrição
          _SectionLabel('Descrição'),
          const SizedBox(height: 8),
          TextFormField(
            controller: descCtrl,
            style: GoogleFonts.publicSans(fontSize: 14),
            decoration:
                _inputDecoration('Ingredientes, modo de preparo, porção...'),
            maxLines: 3,
            minLines: 2,
          ),
          const SizedBox(height: 16),

          // Categoria + Tipo Produto
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel('Categoria'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: categoriaId,
                      style: GoogleFonts.publicSans(
                          fontSize: 14, color: Colors.black87),
                      decoration: _inputDecoration('Selecione'),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Sem categoria',
                              style: GoogleFonts.publicSans(fontSize: 14)),
                        ),
                        ...categorias.map((c) => DropdownMenuItem(
                              value: c.id as String,
                              child: Text(c.nome as String,
                                  style: GoogleFonts.publicSans(fontSize: 14),
                                  overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: onCategoriaChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel('Tipo de Produto'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: tipoProduto,
                      style: GoogleFonts.publicSans(
                          fontSize: 14, color: Colors.black87),
                      decoration: _inputDecoration(null),
                      items: [
                        DropdownMenuItem(
                            value: 'simples',
                            child: Text('Simples',
                                style: GoogleFonts.publicSans(fontSize: 14))),
                        DropdownMenuItem(
                            value: 'variavel',
                            child: Text('Variável',
                                style: GoogleFonts.publicSans(fontSize: 14))),
                      ],
                      onChanged: onTipoChanged,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Ordem de Exibição
          _SectionLabel('Ordem de Exibição'),
          const SizedBox(height: 8),
          SizedBox(
            width: 140,
            child: TextFormField(
              controller: ordemCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.publicSans(fontSize: 14),
              decoration: _inputDecoration('0'),
            ),
          ),
          const SizedBox(height: 24),

          // Toggles
          _SectionLabel('Configurações'),
          const SizedBox(height: 12),
          _ToggleRow(
              title: 'Produto Ativo',
              subtitle: 'Visível no cardápio',
              value: ativo,
              onChanged: onAtivoChanged),
          _ToggleRow(
              title: 'Disponível Agora',
              subtitle: 'Aceita pedidos no momento',
              value: disponivel,
              onChanged: onDisponivelChanged),
          _ToggleRow(
              title: 'Produto em Destaque',
              subtitle: 'Aparece na seção de destaques',
              value: destaque,
              onChanged: onDestaqueChanged),
          _ToggleRow(
              title: 'Aceita Observação',
              subtitle: 'Cliente pode adicionar notas ao pedido',
              value: permiteObservacao,
              onChanged: onObsChanged),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// TAB 2 — PREÇO
// ═══════════════════════════════════════════
class _TabPreco extends StatelessWidget {
  final TextEditingController precoCtrl;
  final TextEditingController precoPromoCtrl;
  final TextEditingController custoCtrl;
  final TextEditingController tempoPreparoCtrl;
  final bool temPromo;
  final ValueChanged<bool> onTemPromoChanged;

  const _TabPreco({
    required this.precoCtrl,
    required this.precoPromoCtrl,
    required this.custoCtrl,
    required this.tempoPreparoCtrl,
    required this.temPromo,
    required this.onTemPromoChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preço Normal
          _SectionLabel('Preço Normal (R\$) *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: precoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.publicSans(fontSize: 14),
            decoration: _inputDecoration('0,00').copyWith(
                prefixText: 'R\$ ',
                prefixStyle: GoogleFonts.publicSans(
                    color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
            validator: (v) {
              final val = double.tryParse(v?.replaceAll(',', '.') ?? '');
              if (val == null || val <= 0) return 'Informe um preço válido';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Preço Promocional
          Row(
            children: [
              _SectionLabel('Preço Promocional (R\$)'),
              const Spacer(),
              Transform.scale(
                scale: 0.85,
                child: Switch.adaptive(
                  value: temPromo,
                  activeTrackColor: const Color(0xFFec5b13),
                  onChanged: onTemPromoChanged,
                ),
              ),
              Text('Ativar promoção',
                  style: GoogleFonts.publicSans(
                      fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: temPromo ? 1.0 : 0.4,
            child: IgnorePointer(
              ignoring: !temPromo,
              child: TextFormField(
                controller: precoPromoCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.publicSans(fontSize: 14),
                decoration: _inputDecoration('0,00').copyWith(
                  prefixText: 'R\$ ',
                  prefixStyle: GoogleFonts.publicSans(
                      color: Colors.pink.shade400, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Custo Estimado
          _SectionLabel('Custo Estimado (R\$)',
              subtitle: 'Uso interno — não exibido ao cliente'),
          const SizedBox(height: 8),
          TextFormField(
            controller: custoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.publicSans(fontSize: 14),
            decoration: _inputDecoration('0,00').copyWith(
                prefixText: 'R\$ ',
                prefixStyle: GoogleFonts.publicSans(
                    color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),

          // Tempo Preparo
          _SectionLabel('Tempo de Preparo Adicional (min)',
              subtitle: 'Adicionado ao tempo base do estabelecimento'),
          const SizedBox(height: 8),
          SizedBox(
            width: 160,
            child: TextFormField(
              controller: tempoPreparoCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.publicSans(fontSize: 14),
              decoration: _inputDecoration('0').copyWith(suffixText: ' min'),
            ),
          ),
          const SizedBox(height: 24),

          // Info margem
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFec5b13).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFec5b13).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.trending_up,
                    color: Color(0xFFec5b13), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'A margem de lucro estimada é calculada automaticamente ao informar o preço e o custo estimado do produto.',
                    style: GoogleFonts.publicSans(
                        fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// TAB 3 — ESTOQUE
// ═══════════════════════════════════════════
class _TabEstoque extends StatelessWidget {
  final bool controleEstoque;
  final TextEditingController estoqueCtrl;
  final ValueChanged<bool> onControleChanged;

  const _TabEstoque({
    required this.controleEstoque,
    required this.estoqueCtrl,
    required this.onControleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ToggleRow(
            title: 'Controlar Estoque',
            subtitle: 'Habilita o controle de quantidade disponível',
            value: controleEstoque,
            onChanged: onControleChanged,
            elevated: true,
          ),
          const SizedBox(height: 20),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: controleEstoque ? 1.0 : 0.4,
            child: IgnorePointer(
              ignoring: !controleEstoque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('Quantidade em Estoque'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: estoqueCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: GoogleFonts.publicSans(fontSize: 14),
                    decoration:
                        _inputDecoration('0').copyWith(suffixText: ' unidades'),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.amber.shade700, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Alerta de Estoque Baixo: Você será notificado quando o estoque atingir 5 unidades ou menos. O produto será automaticamente marcado como indisponível ao chegar a zero.',
                            style: GoogleFonts.publicSans(
                                fontSize: 12, color: Colors.amber.shade800),
                          ),
                        ),
                      ],
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
}

// ═══════════════════════════════════════════
// TAB 4 — OPÇÕES (informativo)
// ═══════════════════════════════════════════
class _TabOpcoes extends StatelessWidget {
  const _TabOpcoes();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Grupos de Opções / Adicionais'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'As opções são armazenadas como um array JSON no campo opcoes. Cada grupo pode ter tipo radio (escolha única) ou checkbox (múltipla escolha), com limites mín/máx.\n\nEsta funcionalidade estará disponível em breve.',
                    style: GoogleFonts.publicSans(
                        fontSize: 12, color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Icon(Icons.tune, size: 52, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'Opções em breve',
                  style: GoogleFonts.publicSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure tamanhos, adicionais e complementos',
                  style: GoogleFonts.publicSans(
                      fontSize: 12, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final String text;
  final String? subtitle;

  const _SectionLabel(this.text, {this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text,
            style: GoogleFonts.publicSans(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800)),
        if (subtitle != null)
          Text(subtitle!,
              style: GoogleFonts.publicSans(
                  fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool elevated;

  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: elevated ? Colors.grey.shade50 : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.publicSans(
                        fontSize: 13, fontWeight: FontWeight.bold)),
                Text(subtitle,
                    style: GoogleFonts.publicSans(
                        fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: const Color(0xFFec5b13),
            inactiveTrackColor: Colors.grey.shade200,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration(String? hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFec5b13), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// TAB: ÚLTIMA MORDIDA
// ═══════════════════════════════════════════════════════════════════════════
class _TabUltimaMordida extends ConsumerStatefulWidget {
  final ProdutoModel? produto;
  const _TabUltimaMordida({this.produto});

  @override
  ConsumerState<_TabUltimaMordida> createState() => _TabUltimaMordidaState();
}

class _TabUltimaMordidaState extends ConsumerState<_TabUltimaMordida> {
  final _chamadaCtrl = TextEditingController();
  int? _desconto;
  int? _duracaoHoras;
  bool _loading = false;

  @override
  void dispose() {
    _chamadaCtrl.dispose();
    super.dispose();
  }

  bool get _podeAtivar => widget.produto != null && widget.produto!.id.isNotEmpty;
  bool get _estaAtivo => widget.produto?.ultimaMordida ?? false;

  @override
  Widget build(BuildContext context) {
    if (!_podeAtivar) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🍰', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                'Salve o produto primeiro',
                style: GoogleFonts.publicSans(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'A Última Mordida pode ser ativada após o produto ser cadastrado.',
                textAlign: TextAlign.center,
                style: GoogleFonts.publicSans(
                    fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final produto = widget.produto!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status atual ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _estaAtivo
                  ? const Color(0xFFFFF3E0)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _estaAtivo
                    ? const Color(0xFFE65100)
                    : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Text(_estaAtivo ? '🍰' : '😴',
                    style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _estaAtivo
                            ? 'Última Mordida ATIVA'
                            : 'Última Mordida inativa',
                        style: GoogleFonts.publicSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: _estaAtivo
                              ? const Color(0xFFE65100)
                              : Colors.grey.shade600,
                        ),
                      ),
                      if (_estaAtivo && produto.ultimaMordidaChamada != null)
                        Text(
                          '"${produto.ultimaMordidaChamada}"',
                          style: GoogleFonts.publicSans(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey.shade600),
                        ),
                      if (_estaAtivo && produto.ultimaMordidaPreco != null)
                        Text(
                          '${fmt.format(produto.preco)} → ${fmt.format(produto.ultimaMordidaPreco)}',
                          style: GoogleFonts.publicSans(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (!_estaAtivo) ...[
            // ── Formulário de ativação ──
            Text('Configurar',
                style: GoogleFonts.publicSans(
                    fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _chamadaCtrl,
              decoration: InputDecoration(
                labelText: 'Chamada (opcional)',
                hintText: 'Ex: Última fatia de bolo!',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _desconto,
              decoration: InputDecoration(
                labelText: 'Desconto (%)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('Sem desconto')),
                ...([5, 10, 15, 20, 25, 30, 40, 50]).map(
                  (v) => DropdownMenuItem(value: v, child: Text('$v%')),
                ),
              ],
              onChanged: (v) => setState(() => _desconto = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _duracaoHoras,
              decoration: InputDecoration(
                labelText: 'Duração',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(
                    value: null, child: Text('Sem prazo de expiração')),
                DropdownMenuItem(value: 1, child: Text('1 hora')),
                DropdownMenuItem(value: 2, child: Text('2 horas')),
                DropdownMenuItem(value: 3, child: Text('3 horas')),
                DropdownMenuItem(value: 6, child: Text('6 horas')),
                DropdownMenuItem(value: 12, child: Text('12 horas')),
                DropdownMenuItem(
                    value: 24, child: Text('Até o fim do dia')),
              ],
              onChanged: (v) => setState(() => _duracaoHoras = v),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _loading
                    ? null
                    : () async {
                        setState(() => _loading = true);
                        await ref
                            .read(produtosControllerProvider.notifier)
                            .ativarUltimaMordida(
                              produto.id,
                              descontoPct: _desconto,
                              chamada: _chamadaCtrl.text.trim().isEmpty
                                  ? null
                                  : _chamadaCtrl.text.trim(),
                              duracaoHoras: _duracaoHoras,
                            );
                        setState(() => _loading = false);
                      },
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('🍰 Ativar Última Mordida',
                        style: GoogleFonts.publicSans(
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
          ] else ...[
            // ── Desativar ──
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE65100)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _loading
                    ? null
                    : () async {
                        setState(() => _loading = true);
                        await ref
                            .read(produtosControllerProvider.notifier)
                            .desativarUltimaMordida(produto.id);
                        setState(() => _loading = false);
                      },
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('Desativar Última Mordida',
                        style: GoogleFonts.publicSans(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFE65100))),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
