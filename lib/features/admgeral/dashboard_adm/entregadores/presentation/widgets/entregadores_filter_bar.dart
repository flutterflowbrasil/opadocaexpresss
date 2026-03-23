import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/entregadores_adm_controller.dart';

class EntregadoresFilterBar extends ConsumerStatefulWidget {
  const EntregadoresFilterBar({super.key});

  @override
  ConsumerState<EntregadoresFilterBar> createState() =>
      _EntregadoresFilterBarState();
}

class _EntregadoresFilterBarState
    extends ConsumerState<EntregadoresFilterBar> {
  final _searchCtrl = TextEditingController();

  static const _statusFiltros = [
    ('todos', 'Todos'),
    ('pendente', 'Pendentes'),
    ('aprovado', 'Aprovados'),
    ('suspenso', 'Suspensos'),
    ('rejeitado', 'Rejeitados'),
  ];

  static const _veiculoFiltros = [
    ('todos', 'Todos veículos'),
    ('moto', '🏍️ Moto'),
    ('carro', '🚗 Carro'),
    ('bicicleta', '🚲 Bicicleta'),
    ('van', '🚐 Van'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context, ) {
    final state = ref.watch(entregadoresAdmControllerProvider);
    final ctrl = ref.read(entregadoresAdmControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Campo de busca ────────────────────────────────
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: const Color(0xFFEAE8E4), width: 1.5),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search, size: 16, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: ctrl.setBusca,
                    decoration: InputDecoration(
                      hintText: 'Buscar nome, e-mail, CPF ou placa…',
                      hintStyle: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: const Color(0xFF9CA3AF),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: const Color(0xFF1A0910),
                    ),
                  ),
                ),
                // Botão × inline, visível junto ao texto
                if (state.termoBusca.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      ctrl.setBusca('');
                    },
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD1D5DB),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 11, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                ] else
                  const SizedBox(width: 12),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Pills de status + dropdown de veículo ─────────
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusFiltros.map((f) {
                      final active = state.filtroStatus == f.$1;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => ctrl.setFiltroStatus(f.$1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFFEFF6FF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: active
                                    ? const Color(0xFF3B82F6)
                                    : const Color(0xFFEAE8E4),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              f.$2,
                              style: GoogleFonts.dmSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? const Color(0xFF3B82F6)
                                    : const Color(0xFF6B7280),
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

              // Dropdown de veículo
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: const Color(0xFFEAE8E4), width: 1.5),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: state.filtroVeiculo,
                    isDense: true,
                    style: GoogleFonts.dmSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                    items: _veiculoFiltros
                        .map((f) => DropdownMenuItem(
                              value: f.$1,
                              child: Text(f.$2),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) ctrl.setFiltroVeiculo(v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
