import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../cliente/localizacao/adicionar_endereco_formulario.dart';
import '../../../../cliente/localizacao/localizacao_repository.dart';
import '../controllers/configuracoes_controller.dart';
import '../../componentes_dash/dashboard_colors.dart';
import 'config_widgets.dart';

class EnderecoTab extends ConsumerStatefulWidget {
  final bool isDark;

  const EnderecoTab({super.key, required this.isDark});

  @override
  ConsumerState<EnderecoTab> createState() => _EnderecoTabState();
}

class _EnderecoTabState extends ConsumerState<EnderecoTab> {
  bool _buscandoCep = false;
  String? _erroCep;
  String? _ultimoCepBuscado;
  late final LocalizacaoRepository _localizacaoRepository;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _localizacaoRepository = LocalizacaoRepository(Supabase.instance.client);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(configuracoesControllerProvider);
    final editedEstab = state.editedEstab;

    if (editedEstab == null) {
      return const Center(child: CircularProgressIndicator());
    }

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
            subtitle:
                'Informe o CEP ou marque o ponto exato no mapa para preencher os campos.',
            isDark: widget.isDark,
            children: [
              _MapActionCard(
                isDark: widget.isDark,
                latitude: editedEstab.latitude,
                longitude: editedEstab.longitude,
                onTap: () => _abrirMapa(
                  latitude: editedEstab.latitude,
                  longitude: editedEstab.longitude,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: ConfigTextField(
                      label: 'CEP *',
                      placeholder: '64000-000',
                      isDark: widget.isDark,
                      helperText: _erroCep,
                      suffix: _buscandoCep
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: DashboardColors.primary,
                                ),
                              ),
                            )
                          : IconButton(
                              tooltip: 'Buscar CEP',
                              icon: const Icon(
                                Icons.search,
                                color: DashboardColors.primary,
                              ),
                              onPressed: () => _buscarCep(endereco.cep ?? ''),
                            ),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(text: endereco.cep)
                        ..selection = TextSelection.collapsed(
                            offset: (endereco.cep ?? '').length),
                      onChanged: (val) {
                        notifier.updateEndereco((e) => e.copyWith(cep: val));
                        final cep = val.replaceAll(RegExp(r'\D'), '');
                        if (cep.length == 8 && cep != _ultimoCepBuscado) {
                          _buscarCep(cep);
                        } else if (_erroCep != null) {
                          setState(() => _erroCep = null);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ConfigTextField(
                      label: 'Logradouro *',
                      placeholder: 'Rua, Avenida...',
                      isDark: widget.isDark,
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
                      isDark: widget.isDark,
                      keyboardType: TextInputType.number,
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
                      isDark: widget.isDark,
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
                      isDark: widget.isDark,
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
                      isDark: widget.isDark,
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
                    child: ConfigTextField(
                      label: 'Estado *',
                      placeholder: 'UF',
                      isDark: widget.isDark,
                      controller: TextEditingController(text: endereco.estado)
                        ..selection = TextSelection.collapsed(
                            offset: (endereco.estado ?? '').length),
                      onChanged: (val) => notifier.updateEndereco(
                        (e) => e.copyWith(estado: val.toUpperCase()),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          ConfigSectionCard(
            title: 'Coordenadas Geográficas',
            icon: Icons.my_location,
            subtitle:
                'Preenchidas automaticamente pela busca do CEP ou pelo ponto marcado no mapa.',
            isDark: widget.isDark,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ConfigTextField(
                      label: 'Latitude',
                      placeholder: '-5.0892',
                      isDark: widget.isDark,
                      readOnly: true,
                      enabled: false,
                      controller: TextEditingController(
                          text: editedEstab.latitude?.toString() ?? '')
                        ..selection = TextSelection.collapsed(
                            offset: (editedEstab.latitude?.toString() ?? '')
                                .length),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ConfigTextField(
                      label: 'Longitude',
                      placeholder: '-42.8019',
                      isDark: widget.isDark,
                      readOnly: true,
                      enabled: false,
                      controller: TextEditingController(
                          text: editedEstab.longitude?.toString() ?? '')
                        ..selection = TextSelection.collapsed(
                            offset: (editedEstab.longitude?.toString() ?? '')
                                .length),
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

  Future<void> _buscarCep(String rawCep) async {
    final cep = rawCep.replaceAll(RegExp(r'\D'), '');
    final notifier = ref.read(configuracoesControllerProvider.notifier);

    if (cep.length != 8) {
      setState(() => _erroCep = 'CEP deve ter 8 dígitos.');
      return;
    }

    setState(() {
      _buscandoCep = true;
      _erroCep = null;
      _ultimoCepBuscado = cep;
    });

    try {
      final data = await _buscarEnderecoPorCep(cep);
      if (data == null) {
        setState(() => _erroCep = 'CEP não encontrado.');
        return;
      }

      notifier.updateEndereco(
        (e) => e.copyWith(
          cep: cep,
          logradouro: data['logradouro'] ?? e.logradouro,
          bairro: data['bairro'] ?? e.bairro,
          cidade: data['cidade'] ?? e.cidade,
          estado: data['estado'] ?? e.estado,
        ),
      );

      final coords = await _localizacaoRepository.geocodeCep(cep);
      if (coords != null) {
        notifier.updateEstabelecimento(
          (e) => e.copyWith(
            latitude: coords['lat'],
            longitude: coords['lng'],
          ),
        );
      }
    } catch (_) {
      setState(() => _erroCep = 'Erro ao buscar CEP. Tente novamente.');
    } finally {
      if (mounted) {
        setState(() => _buscandoCep = false);
      }
    }
  }

  Future<Map<String, String>?> _buscarEnderecoPorCep(String cep) async {
    const headers = {
      'User-Agent': 'PadocaExpressApp/1.0',
      'Accept': 'application/json',
    };

    try {
      final res = await http
          .get(
            Uri.parse('https://brasilapi.com.br/api/cep/v1/$cep'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (!data.containsKey('errors')) {
          return {
            'logradouro': data['street'] as String? ?? '',
            'bairro': data['neighborhood'] as String? ?? '',
            'cidade': data['city'] as String? ?? '',
            'estado': data['state'] as String? ?? '',
          };
        }
      }
    } catch (_) {
      // Fallback abaixo.
    }

    final res = await http
        .get(
          Uri.parse('https://viacep.com.br/ws/$cep/json/'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 6));
    final data = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode != 200 || data['erro'] == true) return null;

    return {
      'logradouro': data['logradouro'] as String? ?? '',
      'bairro': data['bairro'] as String? ?? '',
      'cidade': data['localidade'] as String? ?? '',
      'estado': data['uf'] as String? ?? '',
    };
  }

  Future<void> _abrirMapa({
    double? latitude,
    double? longitude,
  }) async {
    final estab = ref.read(configuracoesControllerProvider).editedEstab;
    if (estab == null) return;

    var lat = latitude ?? -5.0892;
    var lng = longitude ?? -42.8019;
    final endereco = estab.endereco;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        insetPadding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: SizedBox.expand(
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              return AdicionarEnderecoMapa(
                lat: lat,
                lng: lng,
                logradouro: endereco.logradouro ?? '',
                bairro: endereco.bairro ?? '',
                mapController: _mapController,
                onPositionChanged: (newLat, newLng) {
                  setStateDialog(() {
                    lat = newLat;
                    lng = newLng;
                  });
                },
                onVoltar: () => Navigator.pop(dialogContext),
                onGps: () async {
                  try {
                    if (!await Geolocator.isLocationServiceEnabled()) {
                      throw Exception('location_disabled');
                    }
                    var permission = await Geolocator.checkPermission();
                    if (permission == LocationPermission.denied) {
                      permission = await Geolocator.requestPermission();
                    }
                    if (permission == LocationPermission.denied ||
                        permission == LocationPermission.deniedForever) {
                      throw Exception('permission_denied');
                    }

                    final position = await Geolocator.getCurrentPosition(
                      locationSettings: const LocationSettings(
                        accuracy: LocationAccuracy.high,
                      ),
                    );
                    setStateDialog(() {
                      lat = position.latitude;
                      lng = position.longitude;
                    });
                    _mapController.move(
                      LatLng(position.latitude, position.longitude),
                      17,
                    );
                  } catch (_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Não foi possível obter a localização.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                onConfirmar: () async {
                  final geo = await _localizacaoRepository.reverseGeocode(
                    lat,
                    lng,
                  );
                  if (!mounted) return;

                  final notifier =
                      ref.read(configuracoesControllerProvider.notifier);

                  notifier.updateEstabelecimento(
                    (e) => e.copyWith(latitude: lat, longitude: lng),
                  );

                  if (geo != null) {
                    notifier.updateEndereco(
                      (e) => e.copyWith(
                        cep: (geo['cep'] as String? ?? '').isNotEmpty
                            ? geo['cep'] as String
                            : e.cep,
                        logradouro:
                            (geo['logradouro'] as String? ?? '').isNotEmpty
                                ? geo['logradouro'] as String
                                : e.logradouro,
                        bairro: (geo['bairro'] as String? ?? '').isNotEmpty
                            ? geo['bairro'] as String
                            : e.bairro,
                        cidade: (geo['cidade'] as String? ?? '').isNotEmpty
                            ? geo['cidade'] as String
                            : e.cidade,
                        estado: (geo['estado'] as String? ?? '').isNotEmpty
                            ? geo['estado'] as String
                            : e.estado,
                      ),
                    );
                  }

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MapActionCard extends StatelessWidget {
  final bool isDark;
  final double? latitude;
  final double? longitude;
  final VoidCallback onTap;

  const _MapActionCard({
    required this.isDark,
    required this.latitude,
    required this.longitude,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasCoords = latitude != null && longitude != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? DashboardColors.primary.withValues(alpha: 0.10)
              : DashboardColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: DashboardColors.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: DashboardColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_location_alt, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Marcar ponto exato no mapa',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasCoords
                        ? '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}'
                        : 'Ajuste o pin para preencher endereço e coordenadas.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }
}
