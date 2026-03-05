import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/configuracoes_controller.dart';
import '../../componentes_dash/dashboard_colors.dart';
import 'config_widgets.dart';

class EnderecoTab extends ConsumerWidget {
  final bool isDark;

  const EnderecoTab({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(configuracoesControllerProvider);
    final editedEstab = state.editedEstab;

    if (editedEstab == null)
      return const Center(child: CircularProgressIndicator());

    final endereco = editedEstab.endereco;
    final notifier = ref.read(configuracoesControllerProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConfigSectionCard(
            title: 'Endereço do Estabelecimento',
            icon: Icons.location_on,
            subtitle: 'Campos armazenados no objeto endereço (jsonb)',
            isDark: isDark,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: ConfigTextField(
                      label: 'CEP *',
                      placeholder: '64000-000',
                      isDark: isDark,
                      suffix: const Icon(Icons.search,
                          color: DashboardColors.primary),
                      controller: TextEditingController(text: endereco.cep)
                        ..selection = TextSelection.collapsed(
                            offset: (endereco.cep ?? '').length),
                      onChanged: (val) =>
                          notifier.updateEndereco((e) => e.copyWith(cep: val)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ConfigTextField(
                      label: 'Logradouro *',
                      placeholder: 'Rua, Avenida...',
                      isDark: isDark,
                      controller:
                          TextEditingController(text: endereco.logradouro)
                            ..selection = TextSelection.collapsed(
                                offset: (endereco.logradouro ?? '').length),
                      onChanged: (val) => notifier
                          .updateEndereco((e) => e.copyWith(logradouro: val)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: ConfigTextField(
                      label: 'Número *',
                      placeholder: '123',
                      isDark: isDark,
                      controller: TextEditingController(text: endereco.numero)
                        ..selection = TextSelection.collapsed(
                            offset: (endereco.numero ?? '').length),
                      onChanged: (val) => notifier
                          .updateEndereco((e) => e.copyWith(numero: val)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: ConfigTextField(
                      label: 'Complemento',
                      placeholder: 'Sala, Loja...',
                      isDark: isDark,
                      controller:
                          TextEditingController(text: endereco.complemento)
                            ..selection = TextSelection.collapsed(
                                offset: (endereco.complemento ?? '').length),
                      onChanged: (val) => notifier
                          .updateEndereco((e) => e.copyWith(complemento: val)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ConfigTextField(
                      label: 'Bairro *',
                      placeholder: 'Centro',
                      isDark: isDark,
                      controller: TextEditingController(text: endereco.bairro)
                        ..selection = TextSelection.collapsed(
                            offset: (endereco.bairro ?? '').length),
                      onChanged: (val) => notifier
                          .updateEndereco((e) => e.copyWith(bairro: val)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: ConfigTextField(
                      label: 'Cidade *',
                      placeholder: 'Teresina',
                      isDark: isDark,
                      controller: TextEditingController(text: endereco.cidade)
                        ..selection = TextSelection.collapsed(
                            offset: (endereco.cidade ?? '').length),
                      onChanged: (val) => notifier
                          .updateEndereco((e) => e.copyWith(cidade: val)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: ConfigDropdownField(
                      label: 'Estado *',
                      items: const ['PI', 'SP', 'RJ', 'CE', 'MA'],
                      value: endereco.estado ?? 'PI',
                      isDark: isDark,
                      onChanged: (val) => notifier
                          .updateEndereco((e) => e.copyWith(estado: val)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          ConfigSectionCard(
            title: 'Coordenadas Geográficas',
            icon: Icons.my_location,
            subtitle: 'Usadas para calcular distância e exibir no mapa.',
            isDark: isDark,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ConfigTextField(
                      label: 'Latitude',
                      placeholder: '-5.0892',
                      isDark: isDark,
                      controller: TextEditingController(
                          text: editedEstab.latitude?.toString())
                        ..selection = TextSelection.collapsed(
                            offset: (editedEstab.latitude?.toString() ?? '')
                                .length),
                      onChanged: (val) => notifier.updateEstabelecimento(
                          (e) => e.copyWith(latitude: double.tryParse(val))),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ConfigTextField(
                      label: 'Longitude',
                      placeholder: '-42.8019',
                      isDark: isDark,
                      controller: TextEditingController(
                          text: editedEstab.longitude?.toString())
                        ..selection = TextSelection.collapsed(
                            offset: (editedEstab.longitude?.toString() ?? '')
                                .length),
                      onChanged: (val) => notifier.updateEstabelecimento(
                          (e) => e.copyWith(longitude: double.tryParse(val))),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
