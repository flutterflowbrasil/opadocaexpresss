import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/categorias_controller.dart';
import 'dialogs/categoria_form_modal.dart';

class CategoriasScreen extends ConsumerStatefulWidget {
  const CategoriasScreen({super.key});

  @override
  ConsumerState<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends ConsumerState<CategoriasScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoriasControllerProvider);
    final controller = ref.read(categoriasControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Categorias',
                    style: GoogleFonts.publicSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A0910),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('·', style: GoogleFonts.publicSans(fontSize: 14, color: const Color(0xFF9CA3AF))),
                  const SizedBox(width: 10),
                  Text(
                    'Gestão de Tipos de Estabelecimento',
                    style: GoogleFonts.publicSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF97316),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: controller.carregarCategorias,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFEAE8E4)),
                      ),
                      child: const Icon(Icons.refresh, size: 16, color: Color(0xFF6B7280)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _abrirModal(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nova Categoria'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Erro
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: GoogleFonts.publicSans(fontSize: 12, color: const Color(0xFFDC2626)),
                    ),
                  ),
                  IconButton(
                    onPressed: controller.limparErro,
                    icon: const Icon(Icons.close, size: 16, color: Color(0xFFDC2626)),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),

        // Lista
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEAE8E4)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: state.isLoading
                  ? _buildShimmer()
                  : state.categorias.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          itemCount: state.categorias.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F1EE)),
                          itemBuilder: (context, i) {
                            final cat = state.categorias[i];
                            return ListTile(
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9F8F7),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFEAE8E4)),
                                ),
                                child: cat.imagemUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(7),
                                        child: Image.network(cat.imagemUrl!, fit: BoxFit.cover),
                                      )
                                    : const Icon(Icons.category_outlined, color: Color(0xFF9CA3AF), size: 20),
                              ),
                              title: Text(
                                cat.nome,
                                style: GoogleFonts.publicSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A0910),
                                ),
                              ),
                              subtitle: Text(
                                '/${cat.slug} • Ordem: ${cat.ordemExibicao}',
                                style: GoogleFonts.publicSans(
                                  fontSize: 11,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: cat.ativa,
                                    onChanged: (_) => controller.toggleAtiva(cat),
                                    activeColor: const Color(0xFFF97316),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () => _abrirModal(context, categoria: cat),
                                    icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF6B7280)),
                                    tooltip: 'Editar',
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ),
        ),
        const SizedBox(height: 22),
      ],
    );
  }

  void _abrirModal(BuildContext context, {categoria}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CategoriaFormModal(categoria: categoria),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE5E7EB),
      highlightColor: const Color(0xFFF3F4F6),
      child: ListView.separated(
        itemCount: 5,
        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F1EE)),
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 12, width: 140, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                    const SizedBox(height: 8),
                    Container(height: 10, width: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                  ],
                ),
              ),
              Container(width: 40, height: 20, color: Colors.white),
              const SizedBox(width: 16),
              Container(width: 20, height: 20, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.category_outlined, size: 48, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 12),
          Text(
            'Nenhuma categoria cadastrada',
            style: GoogleFonts.publicSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
