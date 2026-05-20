import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/configuracoes_controller.dart';
import '../../../../cliente/categorias/repositories/categoria_estabelecimento_repository.dart';
import '../../../../cliente/categorias/models/categoria_estabelecimento_model.dart';
import '../../componentes_dash/dashboard_colors.dart';
import 'config_widgets.dart';

class InfoTab extends ConsumerWidget {
  final bool isDark;

  const InfoTab({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(configuracoesControllerProvider);
    final editedEstab = state.editedEstab;

    if (editedEstab == null) {
      return const Center(child: CircularProgressIndicator());
    }

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
                placeholder: 'Ex: Ôpadoca Express LTDA',
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
                  onPressed: () => _showEditEmailDialog(
                    context,
                    ref,
                    editedEstab.emailComercial,
                  ),
                  child: const Text('Editar'),
                ),
                keyboardType: TextInputType.emailAddress,
                controller:
                    TextEditingController(text: editedEstab.emailComercial)
                      ..selection = TextSelection.collapsed(
                          offset: (editedEstab.emailComercial ?? '').length),
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
                      placeholder: 'Ôpadoca Express',
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

  Future<void> _showEditEmailDialog(
    BuildContext parentContext,
    WidgetRef ref,
    String? currentEmail,
  ) async {
    final emailController = TextEditingController(text: currentEmail ?? '');
    final formKey = GlobalKey<FormState>();
    bool isUpdating = false;

    try {
      await showDialog<void>(
        context: parentContext,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                backgroundColor:
                    isDark ? const Color(0xFF18181B) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  'Alterar e-mail',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informe o novo e-mail da conta. Enviaremos um link de confirmação para validar a alteração.',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        enabled: !isUpdating,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Novo e-mail',
                          hintText: 'contato@email.com',
                          filled: true,
                          fillColor:
                              isDark ? Colors.grey[800] : Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: DashboardColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          final current = currentEmail?.trim().toLowerCase();

                          if (email.isEmpty) {
                            return 'O e-mail é obrigatório';
                          }

                          final emailRegex =
                              RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                          if (!emailRegex.hasMatch(email)) {
                            return 'Digite um e-mail válido';
                          }

                          if (email.toLowerCase() == current) {
                            return 'Digite um e-mail diferente do atual';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed:
                        isUpdating ? null : () => Navigator.pop(dialogContext),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: isUpdating
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;

                            setStateDialog(() => isUpdating = true);

                            try {
                              await ref
                                  .read(configuracoesControllerProvider.notifier)
                                  .atualizarEmailConta(emailController.text);

                              if (!parentContext.mounted) return;
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'E-mail de confirmação enviado. Verifique sua caixa de entrada.',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (error) {
                              if (!parentContext.mounted) return;
                              setStateDialog(() => isUpdating = false);

                              final message =
                                  error is ConfiguracoesEmailException
                                      ? error.message
                                      : 'Não foi possível atualizar o e-mail. Tente novamente.';

                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                SnackBar(
                                  content: Text(message),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DashboardColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: isUpdating
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Atualizar'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      emailController.dispose();
    }
  }
}
