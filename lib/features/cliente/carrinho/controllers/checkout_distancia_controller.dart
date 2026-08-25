import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:padoca_express/core/config/plataforma_runtime_config.dart';
import 'package:padoca_express/services/map_service.dart';

class CheckoutDistanciaState {
  final double distanciaKm;
  final String? distanciaTexto;
  final String? duracaoTexto;
  final bool carregando;
  final bool isRota;
  final String? erro;

  const CheckoutDistanciaState({
    this.distanciaKm = 0,
    this.distanciaTexto,
    this.duracaoTexto,
    this.carregando = false,
    this.isRota = false,
    this.erro,
  });

  CheckoutDistanciaState copyWith({
    double? distanciaKm,
    String? distanciaTexto,
    String? duracaoTexto,
    bool? carregando,
    bool? isRota,
    String? erro,
    bool clearErro = false,
    bool clearTextos = false,
  }) {
    return CheckoutDistanciaState(
      distanciaKm: distanciaKm ?? this.distanciaKm,
      distanciaTexto: clearTextos ? distanciaTexto : (distanciaTexto ?? this.distanciaTexto),
      duracaoTexto: clearTextos ? duracaoTexto : (duracaoTexto ?? this.duracaoTexto),
      carregando: carregando ?? this.carregando,
      isRota: isRota ?? this.isRota,
      erro: clearErro ? null : (erro ?? this.erro),
    );
  }
}

class CheckoutDistanciaController extends StateNotifier<CheckoutDistanciaState> {
  CheckoutDistanciaController({MapService? mapService})
      : _mapService = mapService ?? MapService.instance,
        super(const CheckoutDistanciaState());

  final MapService _mapService;
  final Map<String, CheckoutDistanciaState> _cache = {};
  Timer? _debounce;
  int _seq = 0;
  String? _chaveAtual;

  static String chave({
    required double origLat,
    required double origLng,
    required double destLat,
    required double destLng,
  }) {
    String r(double v) => v.toStringAsFixed(5);
    return '${r(origLat)},${r(origLng)}>${r(destLat)},${r(destLng)}';
  }

  void limpar() {
    _debounce?.cancel();
    _seq++;
    _chaveAtual = null;
    state = const CheckoutDistanciaState();
  }

  void solicitar({
    required double origLat,
    required double origLng,
    required double destLat,
    required double destLng,
  }) {
    final key = chave(
      origLat: origLat,
      origLng: origLng,
      destLat: destLat,
      destLng: destLng,
    );
    if (key == _chaveAtual && (state.isRota || state.carregando)) return;

    final cached = _cache[key];
    if (cached != null) {
      _chaveAtual = key;
      state = cached;
      return;
    }

    final haversine = distanciaKmCoords(
      lat1: origLat,
      lng1: origLng,
      lat2: destLat,
      lng2: destLng,
    );
    _chaveAtual = key;
    state = CheckoutDistanciaState(
      distanciaKm: haversine,
      distanciaTexto: haversine > 0
          ? '${haversine.toStringAsFixed(1).replaceAll('.', ',')} km'
          : null,
      carregando: true,
      isRota: false,
    );

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(_buscarRota(
        key: key,
        origLat: origLat,
        origLng: origLng,
        destLat: destLat,
        destLng: destLng,
        haversine: haversine,
      ));
    });
  }

  Future<void> _buscarRota({
    required String key,
    required double origLat,
    required double origLng,
    required double destLat,
    required double destLng,
    required double haversine,
  }) async {
    final seq = ++_seq;
    try {
      final info = await _mapService.buscarRotaDetalhada(
        origem: LatLng(origLat, origLng),
        destino: LatLng(destLat, destLng),
      );
      if (!mounted || seq != _seq || _chaveAtual != key) return;

      final rotaKm = info.distanciaKm;
      final km = distanciaEntregaKm(
        haversineKm: haversine,
        rotaKm: info.isRota && rotaKm > 0 ? rotaKm : null,
      );
      final rotaKmArred = (rotaKm * 100).round() / 100;
      final isRota = info.isRota && (km - rotaKmArred).abs() < 0.001;
      final next = CheckoutDistanciaState(
        distanciaKm: km,
        distanciaTexto: info.distanciaTexto ??
            (km > 0 ? '${km.toStringAsFixed(1).replaceAll('.', ',')} km' : null),
        duracaoTexto: info.duracaoTexto,
        carregando: false,
        isRota: isRota,
        erro: isRota ? null : 'distancia_estimada',
      );
      _cache[key] = next;
      state = next;
    } catch (_) {
      if (!mounted || seq != _seq || _chaveAtual != key) return;
      state = CheckoutDistanciaState(
        distanciaKm: haversine,
        distanciaTexto: haversine > 0
            ? '${haversine.toStringAsFixed(1).replaceAll('.', ',')} km'
            : null,
        carregando: false,
        isRota: false,
        erro: 'distancia_estimada',
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final checkoutDistanciaControllerProvider = StateNotifierProvider.autoDispose<
    CheckoutDistanciaController, CheckoutDistanciaState>((ref) {
  return CheckoutDistanciaController();
});
