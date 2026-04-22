import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../controllers/produtos_controller.dart';
import '../models/produto_model.dart';
import 'produto_form_modal.dart';

class ProdutosListView extends ConsumerWidget {
  final List<ProdutoModel> produtos;

  const ProdutosListView({super.key, required this.produtos});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    // Agrupando por categoria
    final Map<String, List<ProdutoModel>> mapCategorias = {};
    for (var p in produtos) {
      final key = p.categoriaCardapioNome ?? 'Sem Categoria';
      mapCategorias.putIfAbsent(key, () => []).add(p);
    }

    return CustomScrollView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        for (final entry in mapCategorias.entries) ...[
          // Cabeçalho da Categoria
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 16),
              child: Row(
                children: [
                  Text(
                    entry.key,
                    style: GoogleFonts.publicSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${entry.value.length} produto${entry.value.length != 1 ? 's' : ''}',
                    style: GoogleFonts.publicSans(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
            ),
          ),

          // Lista de Produtos da Categoria
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final prod = entry.value[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ProductListTile(
                      produto: prod, currencyFmt: currencyFmt, ref: ref),
                );
              },
              childCount: entry.value.length,
            ),
          ),
        ],
      ],
    );
  }
}

class _ProductListTile extends StatelessWidget {
  final ProdutoModel produto;
  final NumberFormat currencyFmt;
  final WidgetRef ref;

  const _ProductListTile({
    required this.produto,
    required this.currencyFmt,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final bool pEstoqueBaixo = produto.controleEstoque &&
        (produto.quantidadeEstoque != null && produto.quantidadeEstoque! <= 5);
    final bool pDisponivel = produto.disponivel && produto.ativo;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Imagem / Placeholder
            Container(
              width: 72,
              height: 72,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: produto.fotoPrincipalUrl == null ||
                        produto.fotoPrincipalUrl!.isEmpty
                    ? const LinearGradient(
                        colors: [Color(0xFFFDE68A), Color(0xFFFCD34D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
              ),
              child: produto.fotoPrincipalUrl != null &&
                      produto.fotoPrincipalUrl!.isNotEmpty
                  // M5: CachedNetworkImage evita re-download a cada rebuild da lista
                  ? CachedNetworkImage(
                      imageUrl: produto.fotoPrincipalUrl!,
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (ctx, url, error) => const Icon(
                        Icons.restaurant,
                        color: Colors.white60,
                        size: 32,
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.restaurant,
                          color: Colors.white60, size: 32),
                    ),
            ),
            const SizedBox(width: 16),

            // Info Central
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          produto.nome,
                          style: GoogleFonts.publicSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Badge de Status
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: pDisponivel
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          pDisponivel ? 'Disponível' : 'Indisponível',
                          style: GoogleFonts.publicSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: pDisponivel
                                ? Colors.green.shade600
                                : Colors.red.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (produto.descricao?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      produto.descricao!,
                      style: GoogleFonts.publicSans(
                          fontSize: 12, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Preço
                      if (produto.precoPromocional != null &&
                          produto.precoPromocional! > 0) ...[
                        Text(
                          currencyFmt.format(produto.preco),
                          style: GoogleFonts.publicSans(
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          currencyFmt.format(produto.precoPromocional),
                          style: GoogleFonts.publicSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink.shade600,
                          ),
                        ),
                      ] else
                        Text(
                          currencyFmt.format(produto.preco),
                          style: GoogleFonts.publicSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFec5b13),
                          ),
                        ),

                      const SizedBox(width: 12),

                      // Badges adicionais
                      if (produto.ultimaMordida) ...[
                        _SmallBadge(
                            text: '🍰 Última Mordida',
                            bg: const Color(0xFFFFF3E0),
                            fg: const Color(0xFFE65100)),
                        const SizedBox(width: 4),
                      ],
                      if (produto.destaque) ...[
                        _SmallBadge(
                            text: '⭐ Destaque',
                            bg: Colors.yellow.shade100,
                            fg: Colors.yellow.shade800),
                        const SizedBox(width: 4),
                      ],
                      if (pEstoqueBaixo) ...[
                        _SmallBadge(
                            text: '⚠️ ${produto.quantidadeEstoque} un.',
                            bg: Colors.amber.shade100,
                            fg: Colors.amber.shade800),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Ações
            Column(
              children: [
                // Toggle Disponibilidade
                Switch.adaptive(
                  value: pDisponivel,
                  activeTrackColor: const Color(0xFFec5b13),
                  inactiveTrackColor: Colors.grey.shade200,
                  onChanged: (val) {
                    ref
                        .read(produtosControllerProvider.notifier)
                        .toggleDisponibilidade(produto.id, produto.disponivel);
                  },
                ),
                const SizedBox(height: 4),
                // Botão Última Mordida
                InkWell(
                  onTap: () => _showUltimaMordidaSheet(context, ref, produto),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: produto.ultimaMordida
                          ? const Color(0xFFFFF3E0)
                          : null,
                      border: Border.all(
                        color: produto.ultimaMordida
                            ? const Color(0xFFE65100)
                            : Colors.grey.shade200,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '🍰',
                      style: TextStyle(
                        fontSize: 16,
                        color: produto.ultimaMordida
                            ? const Color(0xFFE65100)
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Botão Editar
                InkWell(
                  onTap: () {
                    showProdutoFormModal(context, produto: produto);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        Icon(Icons.edit, size: 18, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void _showUltimaMordidaSheet(
    BuildContext context, WidgetRef ref, ProdutoModel produto) {
  if (produto.ultimaMordida) {
    // Já está ativo → oferecer desativar
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _UltimaMordidaDesativarSheet(produto: produto, ref: ref),
    );
  } else {
    // Não está ativo → configurar e ativar
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _UltimaMordidaAtivarSheet(produto: produto, ref: ref),
    );
  }
}

// ── Bottom Sheet: Ativar Última Mordida ──────────────────────────────────────
class _UltimaMordidaAtivarSheet extends StatefulWidget {
  final ProdutoModel produto;
  final WidgetRef ref;
  const _UltimaMordidaAtivarSheet(
      {required this.produto, required this.ref});

  @override
  State<_UltimaMordidaAtivarSheet> createState() =>
      _UltimaMordidaAtivarSheetState();
}

class _UltimaMordidaAtivarSheetState
    extends State<_UltimaMordidaAtivarSheet> {
  final _chamadaCtrl = TextEditingController();
  int? _desconto;
  int? _duracaoHoras;
  bool _loading = false;

  @override
  void dispose() {
    _chamadaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🍰', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Text(
                'Ativar Última Mordida',
                style: GoogleFonts.publicSans(
                    fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.produto.nome,
            style: GoogleFonts.publicSans(
                fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          // Chamada
          TextField(
            controller: _chamadaCtrl,
            decoration: InputDecoration(
              labelText: 'Chamada (opcional)',
              hintText: 'Ex: Última fatia de bolo!',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          // Desconto
          DropdownButtonFormField<int?>(
            initialValue: _desconto,
            decoration: InputDecoration(
              labelText: 'Desconto (%)',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Sem desconto')),
              ...([5, 10, 15, 20, 25, 30, 40, 50]).map(
                (v) => DropdownMenuItem(value: v, child: Text('$v%')),
              ),
            ],
            onChanged: (v) => setState(() => _desconto = v),
          ),
          const SizedBox(height: 12),
          // Duração
          DropdownButtonFormField<int?>(
            initialValue: _duracaoHoras,
            decoration: InputDecoration(
              labelText: 'Duração',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem(
                  value: null, child: Text('Sem prazo de expiração')),
              const DropdownMenuItem(value: 1, child: Text('1 hora')),
              const DropdownMenuItem(value: 2, child: Text('2 horas')),
              const DropdownMenuItem(value: 3, child: Text('3 horas')),
              const DropdownMenuItem(value: 6, child: Text('6 horas')),
              const DropdownMenuItem(value: 12, child: Text('12 horas')),
              const DropdownMenuItem(value: 24, child: Text('Até o fim do dia')),
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
                      await widget.ref
                          .read(produtosControllerProvider.notifier)
                          .ativarUltimaMordida(
                            widget.produto.id,
                            descontoPct: _desconto,
                            chamada: _chamadaCtrl.text.trim().isEmpty
                                ? null
                                : _chamadaCtrl.text.trim(),
                            duracaoHoras: _duracaoHoras,
                          );
                      if (context.mounted) Navigator.of(context).pop();
                    },
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      '🍰 Ativar Última Mordida',
                      style: GoogleFonts.publicSans(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom Sheet: Desativar Última Mordida ───────────────────────────────────
class _UltimaMordidaDesativarSheet extends StatefulWidget {
  final ProdutoModel produto;
  final WidgetRef ref;
  const _UltimaMordidaDesativarSheet(
      {required this.produto, required this.ref});

  @override
  State<_UltimaMordidaDesativarSheet> createState() =>
      _UltimaMordidaDesativarSheetState();
}

class _UltimaMordidaDesativarSheetState
    extends State<_UltimaMordidaDesativarSheet> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final expira = widget.produto.ultimaMordidaExpiraEm;
    String expiraText = 'Sem prazo';
    if (expira != null) {
      final diff = expira.difference(DateTime.now());
      if (diff.isNegative) {
        expiraText = 'Expirado';
      } else if (diff.inMinutes < 60) {
        expiraText = 'Expira em ${diff.inMinutes} min';
      } else {
        expiraText = 'Expira em ${diff.inHours}h';
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🍰', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Text(
                'Última Mordida ativa',
                style: GoogleFonts.publicSans(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE65100)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.produto.ultimaMordidaChamada != null)
            Text(
              '"${widget.produto.ultimaMordidaChamada}"',
              style: GoogleFonts.publicSans(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (widget.produto.ultimaMordidaDescontoPct != null) ...[
                _SmallBadge(
                  text:
                      '${widget.produto.ultimaMordidaDescontoPct!.toStringAsFixed(0)}% off',
                  bg: const Color(0xFFFFECB3),
                  fg: const Color(0xFFE65100),
                ),
                const SizedBox(width: 8),
              ],
              if (widget.produto.ultimaMordidaPreco != null) ...[
                Text(
                  fmt.format(widget.produto.preco),
                  style: GoogleFonts.publicSans(
                    fontSize: 13,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  fmt.format(widget.produto.ultimaMordidaPreco),
                  style: GoogleFonts.publicSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFE65100)),
                ),
                const SizedBox(width: 8),
              ],
              _SmallBadge(
                text: expiraText,
                bg: Colors.grey.shade100,
                fg: Colors.grey.shade600,
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                      await widget.ref
                          .read(produtosControllerProvider.notifier)
                          .desativarUltimaMordida(widget.produto.id);
                      if (context.mounted) Navigator.of(context).pop();
                    },
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(
                      'Desativar Última Mordida',
                      style: GoogleFonts.publicSans(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFE65100)),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;

  const _SmallBadge({required this.text, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.publicSans(
            fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
