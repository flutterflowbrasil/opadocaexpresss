import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/configuracoes_controller.dart';
import '../../../../cliente/categorias/repositories/categoria_estabelecimento_repository.dart';
import '../../../../cliente/categorias/models/categoria_estabelecimento_model.dart';
import 'config_widgets.dart';

class InfoTab extends ConsumerWidget {
  final bool isDark;

  const InfoTab({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(configuracoesControllerProvider);
    final editedEstab = state.editedEstab;

    if (editedEstab == null)
      return const Center(child: CircularProgressIndicator());

    final notifier = ref.read(configuracoesControllerProvider.notifier);
    final categoriasAsync = ref.watch(categoriasEstabelecimentoProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConfigSectionCard(
            title: 'Dados Públicos',
            icon: Icons.storefront,
            isDark: isDark,
            children: [
              ConfigTextField(
                label: 'Razão Social *',
                placeholder: 'Ex: Padoca Express LTDA',
                isDark: isDark,
                controller: TextEditingController(text: editedEstab.razaoSocial)
                  ..selection = TextSelection.collapsed(
                      offset: (editedEstab.razaoSocial ?? '').length),
                onChanged: (val) => notifier
                    .updateEstabelecimento((e) => e.copyWith(razaoSocial: val)),
              ),
              const SizedBox(height: 16),
              categoriasAsync.when(
                data: (categoriasList) {
                  final catAtuais = categoriasList.where(
                      (c) => c.id == editedEstab.categoriaEstabelecimentoId);
                  String formatCat(CategoriaEstabelecimentoModel c) {
                    return c.nome;
                  }

                  final selectedVal =
                      catAtuais.isNotEmpty ? formatCat(catAtuais.first) : null;

                  return ConfigDropdownField(
                    label: 'Categoria do Estabelecimento',
                    items: categoriasList.map<String>(formatCat).toList(),
                    value: selectedVal ??
                        (categoriasList.isNotEmpty
                            ? formatCat(categoriasList.first)
                            : null),
                    isDark: isDark,
                    onChanged: (val) {
                      final cat = categoriasList
                          .where((c) => formatCat(c) == val)
                          .firstOrNull;
                      if (cat != null) {
                        notifier.updateEstabelecimento((e) =>
                            e.copyWith(categoriaEstabelecimentoId: cat.id));
                      }
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => const Text('Erro ao carregar categorias',
                    style: TextStyle(color: Colors.red)),
              ),
              const SizedBox(height: 16),
              ConfigTextField(
                label: 'Descrição',
                placeholder: 'Breve descrição...',
                isDark: isDark,
                maxLines: 3,
                controller: TextEditingController(text: editedEstab.descricao)
                  ..selection = TextSelection.collapsed(
                      offset: (editedEstab.descricao ?? '').length),
                onChanged: (val) => notifier
                    .updateEstabelecimento((e) => e.copyWith(descricao: val)),
              ),
            ],
          ),
          ConfigSectionCard(
            title: 'Contato Comercial',
            icon: Icons.contacts,
            isDark: isDark,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ConfigTextField(
                      label: 'Telefone Comercial',
                      placeholder: '(86) 3232-0000',
                      isDark: isDark,
                      controller: TextEditingController(
                          text: editedEstab.telefoneComercial)
                        ..selection = TextSelection.collapsed(
                            offset:
                                (editedEstab.telefoneComercial ?? '').length),
                      onChanged: (val) => notifier.updateEstabelecimento(
                          (e) => e.copyWith(telefoneComercial: val)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ConfigTextField(
                      label: 'WhatsApp',
                      placeholder: '(86) 99999-0000',
                      isDark: isDark,
                      controller:
                          TextEditingController(text: editedEstab.whatsapp)
                            ..selection = TextSelection.collapsed(
                                offset: (editedEstab.whatsapp ?? '').length),
                      onChanged: (val) => notifier.updateEstabelecimento(
                          (e) => e.copyWith(whatsapp: val)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ConfigTextField(
                label: 'E-mail Comercial',
                placeholder: 'contato@email.com',
                isDark: isDark,
                readOnly: true,
                suffix: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Edição de email configurada futuramente')),
                    );
                  },
                  child: const Text('Editar'),
                ),
                controller:
                    TextEditingController(text: editedEstab.emailComercial)
                      ..selection = TextSelection.collapsed(
                          offset: (editedEstab.emailComercial ?? '').length),
                onChanged: (val) => notifier.updateEstabelecimento(
                    (e) => e.copyWith(emailComercial: val)),
              ),
            ],
          ),
          ConfigSectionCard(
            title: 'Dados Jurídicos',
            icon: Icons.business,
            isDark: isDark,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ConfigTextField(
                      label: 'Nome Fantasia',
                      placeholder: 'Padoca Express',
                      isDark: isDark,
                      controller: TextEditingController(
                          text: editedEstab.nomeFantasia)
                        ..selection = TextSelection.collapsed(
                            offset: (editedEstab.nomeFantasia ?? '').length),
                      onChanged: (val) => notifier.updateEstabelecimento(
                          (e) => e.copyWith(nomeFantasia: val)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ConfigTextField(
                      label: 'CNPJ',
                      placeholder: '00.000.000/0001-00',
                      isDark: isDark,
                      controller: TextEditingController(text: editedEstab.cnpj)
                        ..selection = TextSelection.collapsed(
                            offset: (editedEstab.cnpj ?? '').length),
                      onChanged: (val) => notifier
                          .updateEstabelecimento((e) => e.copyWith(cnpj: val)),
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
