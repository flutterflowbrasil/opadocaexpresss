import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/configuracoes_controller.dart';
import 'config_widgets.dart';

class ResponsavelTab extends ConsumerWidget {
  final bool isDark;

  const ResponsavelTab({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(configuracoesControllerProvider);
    final notifier = ref.read(configuracoesControllerProvider.notifier);
    final estab = state.editedEstab;

    if (estab == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConfigSectionCard(
            title: 'Dados do Responsável Legal',
            icon: Icons.person,
            subtitle:
                'Informações do responsável pela conta. Esses dados são confidenciais.',
            isDark: isDark,
            headerBadge: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.amber[900]?.withValues(alpha: 0.3)
                    : Colors.amber[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock,
                      size: 14,
                      color: isDark ? Colors.amber[400] : Colors.amber[700]),
                  const SizedBox(width: 4),
                  Text(
                    'Dados sensíveis',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.amber[400] : Colors.amber[700],
                    ),
                  ),
                ],
              ),
            ),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ConfigTextField(
                      label: 'Nome Completo',
                      initialValue: estab.responsavelNome,
                      placeholder: 'Nome completo do responsável',
                      onChanged: (v) => notifier.updateResponsavelNome(v),
                      isDark: isDark,
                      isRequired: true,
                      helperText: 'Campo: responsavel_nome',
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ConfigTextField(
                      label: 'CPF',
                      initialValue: estab.responsavelCpf,
                      placeholder: '000.000.000-00',
                      onChanged: (v) => notifier.updateResponsavelCpf(v),
                      isDark: isDark,
                      isRequired: true,
                      helperText: 'Campo: responsavel_cpf',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.blue[900]?.withValues(alpha: 0.1)
                      : Colors.blue[50],
                  border: Border.all(
                      color: isDark
                          ? Colors.blue[900]!.withValues(alpha: 0.3)
                          : Colors.blue[100]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info,
                        color: isDark ? Colors.blue[400] : Colors.blue[500],
                        size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Alterações nos dados do responsável podem requerer revalidação dos documentos. Em caso de dúvida, entre em contato com o suporte.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.blue[400] : Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
