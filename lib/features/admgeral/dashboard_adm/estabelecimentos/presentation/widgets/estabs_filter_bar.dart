import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/estabs_adm_controller.dart';

class EstabsFilterBar extends ConsumerWidget {
  const EstabsFilterBar({super.key});

  static const _filtros = [
    ('todos', 'Todos'),
    ('pendente', 'Pendentes'),
    ('aprovado', 'Aprovados'),
    ('suspenso', 'Suspensos'),
    ('rejeitado', 'Rejeitados'),
  ];

  static const _cores = {
    'todos': Color(0xFF6B7280),
    'pendente': Color(0xFFF59E0B),
    'aprovado': Color(0xFF10B981),
    'suspenso': Color(0xFFEF4444),
    'rejeitado': Color(0xFF9CA3AF),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtroAtual = ref.watch(
      estabsAdmControllerProvider.select((s) => s.filtroStatus),
    );
    final controller = ref.read(estabsAdmControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          // Chips de status
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filtros.map((f) {
                  final (id, label) = f;
                  final isActive = filtroAtual == id;
                  final cor = _cores[id] ?? const Color(0xFF6B7280);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => controller.setFiltro(id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isActive ? cor.withValues(alpha: 0.12) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive ? cor : const Color(0xFFEAE8E4),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          label,
                          style: GoogleFonts.publicSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isActive ? cor : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Campo de busca
          SizedBox(
            width: 200,
            height: 34,
            child: TextField(
              onChanged: controller.setBusca,
              style: GoogleFonts.publicSans(fontSize: 12, color: const Color(0xFF1A0910)),
              decoration: InputDecoration(
                hintText: 'Buscar nome, CNPJ...',
                hintStyle: GoogleFonts.publicSans(
                  fontSize: 12,
                  color: const Color(0xFF9CA3AF),
                ),
                prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF9CA3AF)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                filled: true,
                fillColor: Colors.white,
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
                  borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
