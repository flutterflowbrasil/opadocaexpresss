import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'localizacao_controller.dart';
import 'adicionar_endereco_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Etapa 2: Formulário detalhado de endereço
// ─────────────────────────────────────────────────────────────────────────────
class AdicionarEnderecoFormulario extends ConsumerWidget {
  final TextEditingController logradouroCtrl;
  final TextEditingController numeroCtrl;
  final TextEditingController complementoCtrl;
  final TextEditingController bairroCtrl;
  final TextEditingController cidadeCtrl;
  final TextEditingController estadoCtrl;
  final TextEditingController referenciaCtrl;
  final GlobalKey<FormState> formKey;
  final double lat;
  final double lng;
  final VoidCallback onAbrirMapa;
  final Future<void> Function() onSalvar;

  const AdicionarEnderecoFormulario({
    super.key,
    required this.logradouroCtrl,
    required this.numeroCtrl,
    required this.complementoCtrl,
    required this.bairroCtrl,
    required this.cidadeCtrl,
    required this.estadoCtrl,
    required this.referenciaCtrl,
    required this.formKey,
    required this.lat,
    required this.lng,
    required this.onAbrirMapa,
    required this.onSalvar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitting = ref.watch(
      localizacaoControllerProvider.select((s) => s.isSubmitting),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Placeholder do mapa (abre mapa fullscreen) ─────────────────
          // GoogleMap mini não funciona no Flutter Web (MapTypeId crash).
          // O mapa fullscreen (AdicionarEnderecoMapa) continua funcionando.
          GestureDetector(
            onTap: onAbrirMapa,
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF2A1A1A), const Color(0xFF3D1F1F)]
                      : [
                          kOrange.withValues(alpha: 0.06),
                          kVinho.withValues(alpha: 0.04),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kOrange.withValues(alpha: 0.25)),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _MapGridPainter(isDark)),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kOrange,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: kOrange.withValues(alpha: 0.35),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.location_on,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.10),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit_location_alt,
                                  color: kOrange, size: 14),
                              const SizedBox(width: 5),
                              Text(
                                'Ajustar pin no mapa',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: kVinho,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 12,
                    child: Text(
                      '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: isDark ? Colors.white38 : Colors.grey[500],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Logradouro — editável ──────────────────────────────────────
          const LblWidget('Endereço *'),
          CampoTextoEndereco(
            controller: logradouroCtrl,
            hint: 'Rua / Avenida',
            icon: Icons.signpost_outlined,
            required: true,
          ),

          const SizedBox(height: 10),

          // ── Número + Complemento ───────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LblWidget('Número *'),
                    CampoTextoEndereco(
                      controller: numeroCtrl,
                      hint: 'Ex: 123',
                      icon: Icons.tag,
                      required: true,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LblWidget('Complemento'),
                    CampoTextoEndereco(
                      controller: complementoCtrl,
                      hint: 'Apto, Casa...',
                      icon: Icons.apartment_outlined,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Bairro — editável ──────────────────────────────────────────
          const LblWidget('Bairro *'),
          CampoTextoEndereco(
            controller: bairroCtrl,
            hint: 'Bairro',
            icon: Icons.location_city_outlined,
            required: true,
          ),

          const SizedBox(height: 10),

          // ── Cidade + UF — editáveis ────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LblWidget('Cidade *'),
                    CampoTextoEndereco(
                      controller: cidadeCtrl,
                      hint: 'Cidade',
                      icon: Icons.place_outlined,
                      required: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LblWidget('UF *'),
                    CampoTextoEndereco(
                      controller: estadoCtrl,
                      hint: 'UF',
                      icon: Icons.map_outlined,
                      required: true,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Ponto de referência ────────────────────────────────────────
          const LblWidget('Ponto de referência'),
          CampoTextoEndereco(
            controller: referenciaCtrl,
            hint: 'Ex: Próximo ao mercado, portão verde...',
            icon: Icons.flag_outlined,
            maxLines: 2,
          ),

          const SizedBox(height: 28),

          // ── Botão Salvar ───────────────────────────────────────────────
          BotaoPrimarioModal(
            label: 'Salvar endereço',
            onPressed: isSubmitting ? null : onSalvar,
            isLoading: isSubmitting,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painter decorativo — grade de mapa no placeholder
// ─────────────────────────────────────────────────────────────────────────────
class _MapGridPainter extends CustomPainter {
  final bool isDark;
  _MapGridPainter(this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.04)
          : kOrange.withValues(alpha: 0.06)
      ..strokeWidth = 1;

    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_MapGridPainter old) => old.isDark != isDark;
}

// ─────────────────────────────────────────────────────────────────────────────
// Etapa 3: Mapa fullscreen para ajuste de pin (OpenStreetMap via flutter_map)
// ─────────────────────────────────────────────────────────────────────────────
class AdicionarEnderecoMapa extends StatelessWidget {
  final double lat;
  final double lng;
  final String logradouro;
  final String bairro;
  final MapController mapController;
  final void Function(double lat, double lng) onPositionChanged;
  final VoidCallback onVoltar;
  final Future<void> Function() onConfirmar;
  final Future<void> Function() onGps;

  const AdicionarEnderecoMapa({
    super.key,
    required this.lat,
    required this.lng,
    required this.logradouro,
    required this.bairro,
    required this.mapController,
    required this.onPositionChanged,
    required this.onVoltar,
    required this.onConfirmar,
    required this.onGps,
  });

  void _zoom(double delta) {
    try {
      final camera = mapController.camera;
      mapController.move(
        camera.center,
        (camera.zoom + delta).clamp(2.0, 19.0),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final botPad = MediaQuery.of(context).padding.bottom;

    final coordsLabel =
        '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';

    return Material(
      color: Colors.black,
      child: Column(
        children: [
          // ── Área do mapa ────────────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                // Mapa OpenStreetMap — scroll/pinch zoom habilitados
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: LatLng(lat, lng),
                    initialZoom: 17,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                    onPositionChanged: (camera, _) => onPositionChanged(
                      camera.center.latitude,
                      camera.center.longitude,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.opadocaexpress.app',
                    ),
                  ],
                ),

                // Pin fixo no centro da área do mapa
                const Center(child: PinMapaWidget()),

                // ── Overlays respeitam status bar / notch via SafeArea ────
                Positioned.fill(
                  child: SafeArea(
                    bottom: false, // bottom gerenciado pelo card abaixo
                    child: Stack(
                      children: [
                        // Botão voltar
                        Positioned(
                          top: 10,
                          left: 16,
                          child: BotaoMapaFlutuante(
                            icon: Icons.arrow_back_ios_new,
                            onTap: onVoltar,
                          ),
                        ),

                        // Card de instrução
                        Positioned(
                          top: 10,
                          left: 64,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Text(
                              'Arraste o mapa para ajustar o pin',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: kVinho,
                              ),
                            ),
                          ),
                        ),

                        // Botões direita: GPS + Zoom (empilhados, 42px + 8px gap)
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Zoom –
                              BotaoMapaFlutuante(
                                icon: Icons.remove,
                                onTap: () => _zoom(-1),
                              ),
                              const SizedBox(height: 8),
                              // Zoom +
                              BotaoMapaFlutuante(
                                icon: Icons.add,
                                onTap: () => _zoom(1),
                              ),
                              const SizedBox(height: 8),
                              // GPS
                              BotaoMapaFlutuante(
                                icon: Icons.my_location,
                                onTap: onGps,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Card confirmar (abaixo do mapa, sem sobreposição) ──────────
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(20, 18, 20, botPad + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: kOrange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        coordsLabel,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                BotaoPrimarioModal(
                  label: 'Confirmar localização',
                  onPressed: onConfirmar,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
