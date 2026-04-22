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

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descCtrl.dispose();
    _ordemCtrl.dispose();
    super.dispose();
  }

  void _iniciarEdicao(CategoriaCardapioModel cat) {
    setState(() {
      _editando = cat;
      _nomeCtrl.text = cat.nome;
      _descCtrl.text = cat.descricao ?? '';
      _ordemCtrl.text = cat.ordemExibicao.toString();
      _ativa = cat.ativa;
    });
  }

  void _cancelarEdicao() {
    setState(() {
      _editando = null;
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
    );

    try {
      await ref
          .read(produtosControllerProvider.notifier)
          .salvarCategoria(nova);
      if (mounted) {
        _cancelarEdicao();
        _mostrarSnack(_editando == null
            ? 'Categoria criada! ✓'
            : 'Categoria atualizada! ✓');
      }
    } catch (_) {
      if (mounted) _mostrarSnack('Erro ao salvar categoria.', isError: true);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _deletar(CategoriaCardapioModel cat) async {
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
    } catch (_) {
      if (mounted) _mostrarSnack('Erro ao remover categoria.', isError: true);
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
              _buildHeader(context),

              // ── Lista de categorias ──
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Lista
                      if (categorias.isEmpty)
                        _buildEmptyState()
                      else
                        _buildCategoriasList(categorias),

                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Formulário
                      _buildFormulario(),
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

  Widget _buildHeader(BuildContext context) {
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

  Widget _buildCategoriasList(List<CategoriaCardapioModel> categorias) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Categorias existentes (${categorias.length})',
            style: GoogleFonts.publicSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
                letterSpacing: .5)),
        const SizedBox(height: 10),
        ...categorias.map((cat) => _CategoriaItem(
              cat: cat,
              editando: _editando?.id == cat.id,
              onEditar: () => _iniciarEdicao(cat),
              onDeletar: () => _deletar(cat),
            )),
      ],
    );
  }

  Widget _buildFormulario() {
    final isEdit = _editando != null;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isEdit ? Icons.edit_rounded : Icons.add_circle_outline_rounded,
                color: const Color(0xFFec5b13),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                isEdit
                    ? 'Editando: ${_editando!.nome}'
                    : 'Nova Categoria',
                style: GoogleFonts.publicSans(
                    fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Nome
          TextFormField(
            controller: _nomeCtrl,
            style: GoogleFonts.publicSans(fontSize: 14),
            decoration: _dec('Nome da categoria *',
                hint: 'Ex: Lanches, Bebidas, Sobremesas...'),
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
                hint: 'Breve descrição da categoria'),
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
                      activeTrackColor: const Color(0xFFec5b13).withValues(alpha: .35),
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

          // Botões
          Row(
            children: [
              if (isEdit) ...[
                OutlinedButton(
                  onPressed: _salvando ? null : _cancelarEdicao,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  child: Text('Cancelar',
                      style: GoogleFonts.publicSans(
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _salvando ? null : _salvar,
                  icon: _salvando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Icon(
                          isEdit ? Icons.save_rounded : Icons.add_rounded,
                          size: 18),
                  label: Text(
                    isEdit ? 'Salvar alterações' : 'Criar categoria',
                    style: GoogleFonts.publicSans(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFec5b13),
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
  final VoidCallback onEditar;
  final VoidCallback onDeletar;

  const _CategoriaItem({
    required this.cat,
    required this.editando,
    required this.onEditar,
    required this.onDeletar,
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
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: editando
              ? const Color(0xFFec5b13).withValues(alpha: .35)
              : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
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
          const SizedBox(width: 8),
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
            icon:
                Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
            visualDensity: VisualDensity.compact,
            tooltip: 'Remover',
          ),
        ],
      ),
    );
  }
}
