import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/configuracoes_controller.dart';
import 'config_widgets.dart';

class AvancadoTab extends ConsumerWidget {
  final bool isDark;

  const AvancadoTab({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(configuracoesControllerProvider);
    final notifier = ref.read(configuracoesControllerProvider.notifier);
    final estab = state.editedEstab;

    if (estab == null) return const SizedBox.shrink();

    final advanced = estab.configAvancada;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConfigSectionCard(
            title: 'Configurações Avançadas',
            icon: Icons.tune,
            subtitle: 'Campo: config_avancada (jsonb)',
            isDark: isDark,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ConfigTextField(
                      label: 'Tempo Mínimo de Entrega (min)',
                      initialValue: advanced.tempoMinimoEntregaMin.toString(),
                      placeholder: 'Min',
                      onChanged: (v) {
                        final val = int.tryParse(v) ?? 15;
                        notifier.updateConfigAvancada(
                            advanced.copyWith(tempoMinimoEntregaMin: val));
                      },
                      isDark: isDark,
                      helperText: 'tempo_minimo_entrega_min',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ConfigTextField(
                      label: 'Tempo Máximo de Entrega (min)',
                      initialValue: advanced.tempoMaximoEntregaMin.toString(),
                      placeholder: 'Max',
                      onChanged: (v) {
                        final val = int.tryParse(v) ?? 60;
                        notifier.updateConfigAvancada(
                            advanced.copyWith(tempoMaximoEntregaMin: val));
                      },
                      isDark: isDark,
                      helperText: 'tempo_maximo_entrega_min',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ConfigTextField(
                label: 'Intervalo de Atualização de Estoque (min)',
                initialValue:
                    advanced.intervaloAtualizacaoEstoqueMin.toString(),
                placeholder: 'Intervalo',
                onChanged: (v) {
                  final val = int.tryParse(v) ?? 5;
                  notifier.updateConfigAvancada(
                      advanced.copyWith(intervaloAtualizacaoEstoqueMin: val));
                },
                isDark: isDark,
                helperText: 'intervalo_atualizacao_estoque_min',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),

              // Toggles Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Aceita Agendamento',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Permite que clientes façam pedidos agendados. Campo: aceita_agendamento',
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: advanced.aceitaAgendamento,
                      onChanged: (v) {
                        notifier.updateConfigAvancada(
                            advanced.copyWith(aceitaAgendamento: v));
                      },
                      activeColor: Colors.orange,
                    ),
                  ],
                ),
              ),
              if (advanced.aceitaAgendamento) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.orange.withOpacity(0.05)
                        : Colors.orange.withOpacity(0.1),
                    border: Border.all(
                      color: isDark
                          ? Colors.orange.withOpacity(0.2)
                          : Colors.orange.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ConfigTextField(
                    label: 'Antecedência Mínima para Agendamento (min)',
                    initialValue:
                        advanced.tempoAntecedenciaAgendamentoMin.toString(),
                    placeholder: 'Tempo',
                    onChanged: (v) {
                      final val = int.tryParse(v) ?? 60;
                      notifier.updateConfigAvancada(advanced.copyWith(
                          tempoAntecedenciaAgendamentoMin: val));
                    },
                    isDark: isDark,
                    helperText: 'tempo_antecedencia_agendamento_min',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // Danger Zone
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color:
                  isDark ? Colors.red[900]?.withOpacity(0.1) : Colors.red[50],
              border: Border.all(
                  color: isDark
                      ? Colors.red[900]!.withOpacity(0.3)
                      : Colors.red[100]!),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning,
                        color: isDark ? Colors.red[400] : Colors.red[700],
                        size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Zona de Atenção',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.red[400] : Colors.red[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            estab.statusAberto
                                ? 'Desativar Loja Temporariamente'
                                : 'Ativar Loja',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? Colors.red[400] : Colors.red[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            estab.statusAberto
                                ? 'Sua loja ficará invisível no marketplace enquanto desativada. Campo: status_aberto'
                                : 'Sua loja voltará a aparecer no marketplace.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.red[300]
                                  : Colors.red[600]?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            isDark ? Colors.red[400] : Colors.red[600],
                        side: BorderSide(
                            color:
                                isDark ? Colors.red[400]! : Colors.red[500]!),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      onPressed: () {
                        notifier.updateStatusAberto(!estab.statusAberto);
                      },
                      child: Text(
                        estab.statusAberto ? 'Desativar Loja' : 'Ativar Loja',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
