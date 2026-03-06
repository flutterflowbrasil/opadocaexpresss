import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// Definindo o Enum de período localmente ou importando. Por simplicidade localmente:
enum DashboardPeriodo { hoje, semana, mes, custom }

class PeriodFilterBar extends ConsumerWidget {
  final DashboardPeriodo periodoSelecionado;
  final DateTime? customDate;
  final Function(DashboardPeriodo, DateTime?) onPeriodoChanged;

  const PeriodFilterBar({
    super.key,
    required this.periodoSelecionado,
    required this.onPeriodoChanged,
    this.customDate,
  });

  String _getPeriodoLabel() {
    if (periodoSelecionado == DashboardPeriodo.custom && customDate != null) {
      return "${customDate!.day.toString().padLeft(2, '0')}/${customDate!.month.toString().padLeft(2, '0')}/${customDate!.year}";
    }
    switch (periodoSelecionado) {
      case DashboardPeriodo.hoje:
        return "Hoje";
      case DashboardPeriodo.semana:
        return "Esta semana";
      case DashboardPeriodo.mes:
        return "Este mês";
      default:
        return "Hoje";
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCustom = periodoSelecionado == DashboardPeriodo.custom;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        // Title & Selected Label
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Painel Inicial',
              style: GoogleFonts.publicSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A0910),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('·', style: TextStyle(color: Color(0xFF9CA3AF))),
            ),
            Text(
              _getPeriodoLabel(),
              style: GoogleFonts.publicSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF97316),
              ),
            ),
          ],
        ),

        // Filter Buttons
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildButton('Hoje', DashboardPeriodo.hoje,
                !isCustom && periodoSelecionado == DashboardPeriodo.hoje),
            const SizedBox(width: 8),
            _buildButton('Semana', DashboardPeriodo.semana,
                !isCustom && periodoSelecionado == DashboardPeriodo.semana),
            const SizedBox(width: 8),
            _buildButton('Mês', DashboardPeriodo.mes,
                !isCustom && periodoSelecionado == DashboardPeriodo.mes),
            const SizedBox(width: 8),

            // Calendário Custom
            GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  locale: const Locale('pt', 'BR'),
                  initialDate: customDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Color(0xFFF97316), // accent color
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (date != null) {
                  onPeriodoChanged(DashboardPeriodo.custom, date);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 130),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isCustom ? const Color(0xFFFFF7ED) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCustom
                        ? const Color(0xFFF97316)
                        : const Color(0xFFEAE8E4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: isCustom
                          ? const Color(0xFFF97316)
                          : const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isCustom && customDate != null
                          ? "${customDate!.day.toString().padLeft(2, '0')}/${customDate!.month.toString().padLeft(2, '0')}"
                          : "Data",
                      style: GoogleFonts.publicSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isCustom
                            ? const Color(0xFFF97316)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                    if (isCustom) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () =>
                            onPeriodoChanged(DashboardPeriodo.hoje, null),
                        child: const Icon(Icons.close,
                            size: 14, color: Color(0xFFF97316)),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildButton(String label, DashboardPeriodo value, bool isSelected) {
    return GestureDetector(
      onTap: () => onPeriodoChanged(value, null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF7ED) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected ? const Color(0xFFF97316) : const Color(0xFFEAE8E4),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.publicSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color:
                isSelected ? const Color(0xFFF97316) : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}
