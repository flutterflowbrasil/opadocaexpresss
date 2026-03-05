import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/configuracoes_controller.dart';
import '../../componentes_dash/dashboard_colors.dart';
import 'config_widgets.dart';

class BancariosTab extends ConsumerWidget {
  final bool isDark;

  const BancariosTab({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(configuracoesControllerProvider);
    final editedEstab = state.editedEstab;

    if (editedEstab == null)
      return const Center(child: CircularProgressIndicator());

    final dados = editedEstab.dadosBancarios;
    final notifier = ref.read(configuracoesControllerProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConfigSectionCard(
            title: 'Dados Bancários',
            icon: Icons.account_balance,
            subtitle: 'Conta para recebimento dos pagamentos.',
            isDark: isDark,
            trailing: dados.statusValidacao == 'pendente'
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.hourglass_empty,
                            size: 14, color: Colors.orange),
                        SizedBox(width: 4),
                        Text('Em Validação',
                            style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold))
                      ],
                    ),
                  )
                : Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.green.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 14, color: Colors.green),
                        SizedBox(width: 4),
                        Text('Validado',
                            style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold))
                      ],
                    ),
                  ),
            children: [
              const Text('Tipo de Conta',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _TipoContaCard(
                      label: 'Conta Corrente',
                      description: 'Pessoa Jurídica ou Física',
                      isSelected: dados.tipoConta == 'corrente',
                      isDark: isDark,
                      onTap: () => notifier.updateDadosBancarios(
                          (d) => d.copyWith(tipoConta: 'corrente')),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _TipoContaCard(
                      label: 'Conta Poupança',
                      description: 'Pessoa Física',
                      isSelected: dados.tipoConta == 'poupanca',
                      isDark: isDark,
                      onTap: () => notifier.updateDadosBancarios(
                          (d) => d.copyWith(tipoConta: 'poupanca')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ConfigDropdownField(
                label: 'Banco *',
                items: const [
                  '001 - Banco do Brasil',
                  '104 - Caixa Econômica',
                  '341 - Itaú',
                  '260 - Nubank',
                  '033 - Santander',
                  '077 - Inter',
                ],
                value: dados.banco,
                isDark: isDark,
                onChanged: (val) => notifier
                    .updateDadosBancarios((d) => d.copyWith(banco: val)),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: ConfigTextField(
                      label: 'Agência *',
                      placeholder: '0000',
                      isDark: isDark,
                      controller: TextEditingController(text: dados.agencia)
                        ..selection = TextSelection.collapsed(
                            offset: (dados.agencia ?? '').length),
                      onChanged: (val) => notifier.updateDadosBancarios(
                          (d) => d.copyWith(agencia: val)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Expanded(
                          child: ConfigTextField(
                            label: 'Conta *',
                            placeholder: '00000000',
                            isDark: isDark,
                            controller: TextEditingController(text: dados.conta)
                              ..selection = TextSelection.collapsed(
                                  offset: (dados.conta ?? '').length),
                            onChanged: (val) => notifier.updateDadosBancarios(
                                (d) => d.copyWith(conta: val)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: ConfigTextField(
                            label: 'Dígito',
                            placeholder: '0',
                            isDark: isDark,
                            controller:
                                TextEditingController(text: dados.contaDigito)
                                  ..selection = TextSelection.collapsed(
                                      offset: (dados.contaDigito ?? '').length),
                            onChanged: (val) => notifier.updateDadosBancarios(
                                (d) => d.copyWith(contaDigito: val)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ConfigTextField(
                      label: 'Nome do Titular *',
                      placeholder: 'Como no banco',
                      isDark: isDark,
                      controller: TextEditingController(text: dados.titular)
                        ..selection = TextSelection.collapsed(
                            offset: (dados.titular ?? '').length),
                      onChanged: (val) => notifier.updateDadosBancarios(
                          (d) => d.copyWith(titular: val)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ConfigTextField(
                      label: 'CPF/CNPJ do Titular *',
                      placeholder: '00.000.000/0001-00',
                      isDark: isDark,
                      controller:
                          TextEditingController(text: dados.cpfCnpjTitular)
                            ..selection = TextSelection.collapsed(
                                offset: (dados.cpfCnpjTitular ?? '').length),
                      onChanged: (val) => notifier.updateDadosBancarios(
                          (d) => d.copyWith(cpfCnpjTitular: val)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.2))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                      'Os dados bancários são usados para repasse dos valores via Asaas. '
                      '${dados.statusValidacao == 'pendente' && dados.ultimoUpdate != null ? 'Alterado em ${dados.ultimoUpdate!.day.toString().padLeft(2, '0')}/${dados.ultimoUpdate!.month.toString().padLeft(2, '0')}. ' : ''}'
                      'Alterações podem levar até 2 dias úteis para ser validadas.',
                      style: TextStyle(color: Colors.orange[700], fontSize: 13),
                    ))
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}

class _TipoContaCard extends StatelessWidget {
  final String label;
  final String description;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _TipoContaCard({
    required this.label,
    required this.description,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: isSelected
                ? DashboardColors.primary.withValues(alpha: 0.05)
                : (isDark ? Colors.grey[800] : Colors.grey[50]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isSelected
                    ? DashboardColors.primary
                    : (isDark ? Colors.grey[700]! : Colors.grey[300]!))),
        child: Row(
          children: [
            Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? DashboardColors.primary : Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
