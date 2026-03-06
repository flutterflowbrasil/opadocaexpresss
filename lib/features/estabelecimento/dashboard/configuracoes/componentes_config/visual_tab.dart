import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../controllers/configuracoes_controller.dart';
import '../../componentes_dash/dashboard_colors.dart';

class VisualTab extends ConsumerStatefulWidget {
  final bool isDark;

  const VisualTab({super.key, required this.isDark});

  @override
  ConsumerState<VisualTab> createState() => _VisualTabState();
}

class _VisualTabState extends ConsumerState<VisualTab> {
  Future<void> _pickAndCropImage(bool isLogo) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image == null) return;

      final ratioX = isLogo ? 1.0 : 2.0;
      final ratioY = 1.0;
      final maxWidth = isLogo ? 400 : 800;
      final maxHeight = isLogo ? 400 : 400;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: CropAspectRatio(ratioX: ratioX, ratioY: ratioY),
        compressQuality: 85,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: isLogo ? 'Cortar Logo' : 'Cortar Capa',
            toolbarColor: DashboardColors.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: isLogo
                ? CropAspectRatioPreset.square
                : CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: isLogo ? 'Cortar Logo' : 'Cortar Capa',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
          WebUiSettings(
            // ignore: use_build_context_synchronously
            context: context,
            presentStyle: WebPresentStyle.page,
            translations: const WebTranslations(
              title: 'Editar Imagem',
              cropButton: 'Cortar',
              cancelButton: 'Cancelar',
              rotateLeftTooltip: 'Girar Esquerda',
              rotateRightTooltip: 'Girar Direita',
            ),
          ),
        ],
      );

      if (croppedFile != null) {
        final bytes = await croppedFile.readAsBytes();
        final notifier = ref.read(configuracoesControllerProvider.notifier);
        if (isLogo) {
          notifier.setNewLogoBytes(bytes);
        } else {
          notifier.setNewBannerBytes(bytes);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao processar imagem: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(configuracoesControllerProvider);
    final editedEstab = state.editedEstab;

    if (editedEstab == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isDark = widget.isDark;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    // Banner
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        image: state.newBannerBytes != null
                            ? DecorationImage(
                                image: MemoryImage(state.newBannerBytes!),
                                fit: BoxFit.cover,
                              )
                            : editedEstab.bannerUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(editedEstab.bannerUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                      ),
                      child: Stack(
                        children: [
                          if (state.newBannerBytes == null &&
                              editedEstab.bannerUrl == null)
                            const Center(
                                child: Icon(Icons.photo_camera,
                                    size: 48, color: Colors.grey)),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text('Recomendado: 800×400px',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: CircleAvatar(
                              backgroundColor: DashboardColors.primary,
                              child: IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.white),
                                onPressed: () => _pickAndCropImage(false),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    // Logo section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Transform.translate(
                            offset: const Offset(0, -20),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                    color: isDark
                                        ? Colors.grey[900]!
                                        : Colors.white,
                                    width: 4),
                                borderRadius: BorderRadius.circular(16),
                                image: state.newLogoBytes != null
                                    ? DecorationImage(
                                        image: MemoryImage(state.newLogoBytes!),
                                        fit: BoxFit.cover,
                                      )
                                    : editedEstab.logoUrl != null
                                        ? DecorationImage(
                                            image: NetworkImage(
                                                editedEstab.logoUrl!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                  )
                                ],
                              ),
                              child: (state.newLogoBytes == null &&
                                      editedEstab.logoUrl == null)
                                  ? const Center(
                                      child: Icon(Icons.store, size: 40))
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Logo e Banner',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Logo: 400×400px. Banner: 800×400px.',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Wrap(
                            spacing: 8,
                            children: [
                              ElevatedButton(
                                onPressed: () => _pickAndCropImage(true),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: DashboardColors.primary,
                                    foregroundColor: Colors.white),
                                child: const Text('Alterar'),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
