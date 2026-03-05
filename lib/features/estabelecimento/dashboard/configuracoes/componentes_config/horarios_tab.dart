import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/configuracoes_controller.dart';
import 'config_widgets.dart';

class HorariosTab extends ConsumerWidget {
  final bool isDark;

  const HorariosTab({super.key, required this.isDark});

  static const List<Map<String, String>> _diasDaSemana = [
    {'key': 'seg', 'label': 'Segunda'},
    {'key': 'ter', 'label': 'Terça'},
    {'key': 'qua', 'label': 'Quarta'},
    {'key': 'qui', 'label': 'Quinta'},
    {'key': 'sex', 'label': 'Sexta'},
    {'key': 'sab', 'label': 'Sábado'},
    {'key': 'dom', 'label': 'Domingo'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(configuracoesControllerProvider);
    final notifier = ref.read(configuracoesControllerProvider.notifier);
    final estab = state.editedEstab;

    if (estab == null) return const SizedBox.shrink();

    final horariosMap = Map<String, dynamic>.from(estab.horarioFuncionamento);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConfigSectionCard(
        title: 'Horário de Funcionamento',
        icon: Icons.schedule,
        subtitle: 'Defina os horários em que sua loja aceita pedidos.',
        isDark: isDark,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _diasDaSemana.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: isDark ? Colors.grey[800] : Colors.grey[100],
              ),
              itemBuilder: (context, index) {
                final item = _diasDaSemana[index];
                final key = item['key']!;
                final label = item['label']!;

                final diaData = horariosMap[key] as Map<String, dynamic>? ??
                    {'aberto': false, 'inicio': '08:00', 'fim': '18:00'};

                final isAberto = diaData['aberto'] as bool? ?? false;
                final inicio = diaData['inicio'] as String? ?? '08:00';
                final fim = diaData['fim'] as String? ?? '18:00';

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          label,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.grey[300] : Colors.grey[800],
                            decoration:
                                isAberto ? null : TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                      Switch(
                        value: isAberto,
                        activeColor: Colors.green,
                        onChanged: (v) {
                          final newDiaData = Map<String, dynamic>.from(diaData);
                          newDiaData['aberto'] = v;
                          notifier.updateHorarioDia(key, newDiaData);
                        },
                      ),
                      const SizedBox(width: 16),
                      if (isAberto) ...[
                        Expanded(
                          child: _TimeInput(
                            value: inicio,
                            isDark: isDark,
                            onChanged: (v) {
                              final newDiaData =
                                  Map<String, dynamic>.from(diaData);
                              newDiaData['inicio'] = v;
                              notifier.updateHorarioDia(key, newDiaData);
                            },
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('até'),
                        ),
                        Expanded(
                          child: _TimeInput(
                            value: fim,
                            isDark: isDark,
                            onChanged: (v) {
                              final newDiaData =
                                  Map<String, dynamic>.from(diaData);
                              newDiaData['fim'] = v;
                              notifier.updateHorarioDia(key, newDiaData);
                            },
                          ),
                        ),
                      ] else
                        const Expanded(
                          child: Text(
                            'Fechado',
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeInput extends StatelessWidget {
  final String value;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _TimeInput({
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        border:
            Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time,
              size: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: value,
              keyboardType: TextInputType.datetime,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
