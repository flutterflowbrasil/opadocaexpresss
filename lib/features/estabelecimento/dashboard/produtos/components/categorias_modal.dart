// ============================================================
// categorias_modal.dart — Gerenciar Categorias do Cardápio
// Ôpadoca Express · Dashboard do Estabelecimento
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/produtos_controller.dart';
import '../../../models/categoria_cardapio_model.dart';
import 'package:padoca_express/core/utils/supabase_error_handler.dart';

/// Abre o modal de gerenciamento de categorias.
void showCategoriasModal(
  BuildContext context, {
  required String estabelecimentoId,
}) {
  showGeneralDialog(
    context: context,
    barrierLabel: 'Categorias Modal',
    barrierDismissible: true,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (ctx, a1, a2) => _CategoriasModal(
      estabelecimentoId: estabelecimentoId,
    ),
    transitionBuilder: (ctx, a1, a2, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: a1, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(
            CurvedAnimation(parent: a1, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
class _CategoriasModal extends ConsumerStatefulWidget {
  final String estabelecimentoId;

  const _CategoriasModal({required this.estabelecimentoId});

  @override
  ConsumerState<_CategoriasModal> createState() => _CategoriasModalState();
}

class _CategoriasModalState extends ConsumerState<_CategoriasModal> {
  // Formulário de criação/edição
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _ordemCtrl = TextEditingController(text: '0');
  bool _ativa = true;
  bool _salvando = false;

  // null = modo criação; não-null = modo edição
  CategoriaCardapioModel? _editando;

  // Se não-null, o formulário criará uma SUBcategoria desta categoria pai
  CategoriaCardapioModel? _criandoSubcategoriaDe;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descCtrl.dispose();
    _ordemCtrl.dispose();
    super.dispose();
  }

  void _iniciarEdicao(CategoriaCardapioModel cat) {
    if (cat.isCategoriaPadrao) {
      _mostrarSnack(
        'Categorias padrão da plataforma não podem ser editadas.',
        isError: true,
      );
      return;
    }
    setState(() {
      _editando = cat;
      _criandoSubcategoriaDe = null;
      _nomeCtrl.text = cat.nome;
      _descCtrl.text = cat.descricao ?? '';
      _ordemCtrl.text = cat.ordemExibicao.toString();
      _ativa = cat.ativa;
    });
  }

  /// Prepara o formulário para criar uma subcategoria de [pai].
  void _iniciarSubcategoria(CategoriaCardapioModel pai) {
    if (pai.isCategoriaPadrao) {
      _mostrarSnack(
        'Não é possível criar subcategorias em categorias padrão da plataforma.',
        isError: true,
      );
      return;
    }
    setState(() {
      _editando = null;
      _criandoSubcategoriaDe = pai;
      _nomeCtrl.clear();
      _descCtrl.clear();
      _ordemCtrl.text = '0';
      _ativa = true;
    });
    _formKey.currentState?.reset();
  }

  void _cancelarEdicao() {
    setState(() {
      _editando = null;
      _criandoSubcategoriaDe = null;
      _nomeCtrl.clear();
      _descCtrl.clear();
      _ordemCtrl.text = '0';
      _ativa = true;
    });
    _formKey.currentState?.reset();
  }

  Future<void> _salvar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _salvando = true);

    final nova = CategoriaCardapioModel(
      id: _editando?.id ?? '',
      estabelecimentoId: widget.estabelecimentoId,
      nome: _nomeCtrl.text.trim(),
      descricao:
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      ordemExibicao: int.tryParse(_ordemCtrl.text) ?? 0,
      ativa: _ativa,
      // Preserva categoria pai na edição, ou define ao criar subcategoria
      categoriaPaiId: _editando?.categoriaPaiId ?? _criandoSubcategoriaDe?.id,
    );

    try {
      await ref
          .read(produtosControllerProvider.notifier)
          .salvarCategoria(nova);
      if (mounted) {
        _cancelarEdicao();
        _mostrarSnack(_editando == null
            ? (_criandoSubcategoriaDe != null
                ? 'Subcategoria criada! ✓'
                : 'Categoria criada! ✓')
            : 'Categoria atualizada! ✓');
      }
    } catch (e) {
      if (mounted) {
        _mostrarSnack(
          SupabaseErrorHandler.parseError(e),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _deletar(CategoriaCardapioModel cat) async {
    if (cat.isCategoriaPadrao) {
      _mostrarSnack(
        'Categorias padrão da plataforma não podem ser removidas.',
        isError: true,
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remover categoria?',
            style: GoogleFonts.publicSans(fontWeight: FontWeight.bold)),
        content: Text(
          'A categoria "${cat.nome}" será removida. Os produtos vinculados a ela '
          'ficarão sem categoria, mas não serão deletados.',
          style: GoogleFonts.publicSans(fontSize: 14, color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref
          .read(produtosControllerProvider.notifier)
          .deletarCategoria(cat.id);
      if (mounted) _mostrarSnack('Categoria removida.');
      if (_editando?.id == cat.id) _cancelarEdicao();
    } catch (e) {
      if (mounted) {
        _mostrarSnack(
          SupabaseErrorHandler.parseError(e),
          isError: true,
        );
      }
    }
  }

  void _mostrarSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(msg, style: GoogleFonts.publicSans(fontWeight: FontWeight.w600)),
      backgroundColor:
          isError ? Colors.red.shade700 : const Color(0xFFec5b13),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final categorias =
        ref.watch(produtosControllerProvider.select((s) => s.categorias));
    final podeGerenciar = ref.watch(
      produtosControllerProvider.select((s) => s.podeGerenciarCategoriasCardapio),
    );

    // Organiza: categorias raiz (sem pai) + lista plana de sub para lookup
    final raizes = categorias.where((c) => c.categoriaPaiId == null).toList();
    final subMap = <String, List<CategoriaCardapioModel>>{};
    for (final cat in categorias) {
      if (cat.categoriaPaiId != null) {
        subMap.putIfAbsent(cat.categoriaPaiId!, () => []).add(cat);
      }
    }

    final screenW = MediaQuery.of(context).size.width;
    final modalW = screenW < 600 ? screenW * 0.95 : 520.0;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: modalW,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Cabeçalho ──
              _buildHeader(context, podeGerenciar: podeGerenciar),

              // ── Lista de categorias ──
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!podeGerenciar) ...[
                        _buildBannerSomenteLeitura(),
                        const SizedBox(height: 16),
                      ],

                      // Lista
                      if (raizes.isEmpty)
                        _buildEmptyState()
                      else
                        _buildCategoriasList(raizes, subMap, podeGerenciar),

                      if (podeGerenciar) ...[
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),
                        _buildFormulario(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required bool podeGerenciar}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFec5b13).withValues(alpha: .1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.category_rounded,
                color: Color(0xFFec5b13), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Categorias do Cardápio',
                    style: GoogleFonts.publicSans(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Organize seus produtos por categorias',
                    style: GoogleFonts.publicSans(
                        fontSize: 12, color: Colors.grey.shade500)),
                if (!podeGerenciar)
                  Text('Modo visualização',
                      style: GoogleFonts.publicSans(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                          fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Icon(Icons.close, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerSomenteLeitura() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFec5b13).withValues(alpha: .07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFec5b13).withValues(alpha: .25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18, color: const Color(0xFFec5b13)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Categorias padrão do cardápio. Organize seus produtos escolhendo '
              'uma categoria ao cadastrar. Categorias personalizadas exigem '
              'permissão de administrador da loja.',
              style: GoogleFonts.publicSans(
                fontSize: 12,
                color: const Color(0xFF9a3412),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.category_outlined, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Nenhuma categoria ainda',
                style: GoogleFonts.publicSans(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Crie a primeira categoria abaixo.',
                style: GoogleFonts.publicSans(
                    fontSize: 13, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriasList(
    List<CategoriaCardapioModel> raizes,
    Map<String, List<CategoriaCardapioModel>> subMap,
    bool podeGerenciar,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Categorias existentes (${raizes.length})',
            style: GoogleFonts.publicSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
                letterSpacing: .5)),
        const SizedBox(height: 10),
        ...raizes.map((cat) {
          final subs = subMap[cat.id] ?? [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CategoriaItem(
                cat: cat,
                editando: _editando?.id == cat.id,
                somenteLeitura: !podeGerenciar || cat.isCategoriaPadrao,
                onEditar: () => _iniciarEdicao(cat),
                onDeletar: () => _deletar(cat),
                onAdicionarSubcategoria: (!podeGerenciar || cat.isCategoriaPadrao)
                    ? null
                    : () => _iniciarSubcategoria(cat),
              ),
              // Subcategorias com indentação visual
              if (subs.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: subs
                        .map((sub) => _CategoriaItem(
                              cat: sub,
                              editando: _editando?.id == sub.id,
                              somenteLeitura:
                                  !podeGerenciar || sub.isCategoriaPadrao,
                              onEditar: () => _iniciarEdicao(sub),
                              onDeletar: () => _deletar(sub),
                              onAdicionarSubcategoria: null,
                              isSubcategoria: true,
                            ))
                        .toList(),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildFormulario() {
    final isEdit = _editando != null;
    final isSub = _criandoSubcategoriaDe != null;

    // Título dinâmico do formulário
    final String tituloForm = isEdit
        ? 'Editando: ${_editando!.nome}'
        : isSub
            ? 'Nova Subcategoria de "${_criandoSubcategoriaDe!.nome}"'
            : 'Nova Categoria';

    final IconData iconForm = isEdit
        ? Icons.edit_rounded
        : isSub
            ? Icons.subdirectory_arrow_right_rounded
            : Icons.add_circle_outline_rounded;

    final Color corForm = isSub
        ? const Color(0xFF6366F1) // roxo para subcategoria
        : const Color(0xFFec5b13);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconForm, color: corForm, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tituloForm,
                  style: GoogleFonts.publicSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSub ? const Color(0xFF6366F1) : Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSub || isEdit)
                TextButton(
                  onPressed: _salvando ? null : _cancelarEdicao,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: Colors.grey.shade600,
                  ),
                  child: Text('Cancelar',
                      style: GoogleFonts.publicSans(fontSize: 13)),
                ),
            ],
          ),
          // Banner explicativo para subcategoria
          if (isSub) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: .07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: .25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 15, color: const Color(0xFF6366F1)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta subcategoria ficará aninhada dentro de "${_criandoSubcategoriaDe!.nome}".',
                      style: GoogleFonts.publicSans(
                          fontSize: 12, color: const Color(0xFF6366F1)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Nome
          TextFormField(
            controller: _nomeCtrl,
            style: GoogleFonts.publicSans(fontSize: 14),
            decoration: _dec(
              isSub ? 'Nome da subcategoria *' : 'Nome da categoria *',
              hint: isSub
                  ? 'Ex: Bolos no pote, Cupcakes...'
                  : 'Ex: Lanches, Bebidas, Sobremesas...',
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Nome obrigatório' : null,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),

          // Descrição
          TextFormField(
            controller: _descCtrl,
            style: GoogleFonts.publicSans(fontSize: 14),
            decoration: _dec('Descrição (opcional)',
                hint: 'Breve descrição'),
            maxLines: 2,
            minLines: 1,
          ),
          const SizedBox(height: 12),

          // Ordem + Ativa
          Row(
            children: [
              SizedBox(
                width: 110,
                child: TextFormField(
                  controller: _ordemCtrl,
                  style: GoogleFonts.publicSans(fontSize: 14),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _dec('Ordem', hint: '0'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Switch(
                      value: _ativa,
                      activeThumbColor: const Color(0xFFec5b13),
                      activeTrackColor:
                          const Color(0xFFec5b13).withValues(alpha: .35),
                      onChanged: (v) => setState(() => _ativa = v),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _ativa ? 'Ativa' : 'Inativa',
                      style: GoogleFonts.publicSans(
                          fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Botão salvar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _salvando ? null : _salvar,
              icon: _salvando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(
                      isEdit
                          ? Icons.save_rounded
                          : isSub
                              ? Icons.subdirectory_arrow_right_rounded
                              : Icons.add_rounded,
                      size: 18),
              label: Text(
                isEdit
                    ? 'Salvar alterações'
                    : isSub
                        ? 'Criar subcategoria'
                        : 'Criar categoria',
                style: GoogleFonts.publicSans(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSub
                    ? const Color(0xFF6366F1)
                    : const Color(0xFFec5b13),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle:
            GoogleFonts.publicSans(fontSize: 13, color: Colors.grey.shade600),
        hintStyle:
            GoogleFonts.publicSans(fontSize: 13, color: Colors.grey.shade400),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFec5b13), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Item individual da lista
// ─────────────────────────────────────────────────────────────────────────────
class _CategoriaItem extends StatelessWidget {
  final CategoriaCardapioModel cat;
  final bool editando;
  final bool somenteLeitura;
  final VoidCallback onEditar;
  final VoidCallback onDeletar;

  /// Se não-null, exibe o botão "+ Subcategoria". Null desabilita (para subcategorias).
  final VoidCallback? onAdicionarSubcategoria;

  final bool isSubcategoria;

  const _CategoriaItem({
    required this.cat,
    required this.editando,
    this.somenteLeitura = false,
    required this.onEditar,
    required this.onDeletar,
    required this.onAdicionarSubcategoria,
    this.isSubcategoria = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: editando
            ? const Color(0xFFec5b13).withValues(alpha: .06)
            : isSubcategoria
                ? const Color(0xFF6366F1).withValues(alpha: .04)
                : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: editando
              ? const Color(0xFFec5b13).withValues(alpha: .35)
              : isSubcategoria
                  ? const Color(0xFF6366F1).withValues(alpha: .2)
                  : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Indicador visual de subcategoria
          if (isSubcategoria)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(Icons.subdirectory_arrow_right_rounded,
                  size: 14, color: const Color(0xFF6366F1).withValues(alpha: .6)),
            ),
          // Ativa/Inativa dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: cat.ativa ? Colors.green.shade400 : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat.nome,
                    style: GoogleFonts.publicSans(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                if (cat.descricao != null && cat.descricao!.isNotEmpty)
                  Text(cat.descricao!,
                      style: GoogleFonts.publicSans(
                          fontSize: 12, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          // Ordem badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('#${cat.ordemExibicao}',
                style: GoogleFonts.publicSans(
                    fontSize: 11, color: Colors.grey.shade500)),
          ),
          if (cat.isCategoriaPadrao) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFec5b13).withValues(alpha: .1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('Padrão',
                  style: GoogleFonts.publicSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFec5b13))),
            ),
          ],
          const SizedBox(width: 4),

          if (!somenteLeitura) ...[
            // Botão "+ Subcategoria" — só exibido para categorias raiz
            if (onAdicionarSubcategoria != null)
              Tooltip(
                message: 'Adicionar subcategoria',
                child: InkWell(
                  onTap: onAdicionarSubcategoria,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.subdirectory_arrow_right_rounded,
                            size: 14,
                            color:
                                const Color(0xFF6366F1).withValues(alpha: .8)),
                        const SizedBox(width: 2),
                        Text('Sub',
                            style: GoogleFonts.publicSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6366F1)
                                    .withValues(alpha: .8))),
                      ],
                    ),
                  ),
                ),
              ),

            // Editar
            IconButton(
              onPressed: onEditar,
              icon: Icon(
                Icons.edit_outlined,
                size: 18,
                color: editando
                    ? const Color(0xFFec5b13)
                    : Colors.grey.shade500,
              ),
              visualDensity: VisualDensity.compact,
              tooltip: 'Editar',
            ),
            // Deletar
            IconButton(
              onPressed: onDeletar,
              icon: Icon(Icons.delete_outline,
                  size: 18, color: Colors.red.shade400),
              visualDensity: VisualDensity.compact,
              tooltip: 'Remover',
            ),
          ],
        ],
      ),
    );
  }
}
