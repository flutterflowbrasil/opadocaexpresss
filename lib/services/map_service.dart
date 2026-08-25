// ============================================================
// map_service.dart — Serviço de Mapas
// Ôpadoca Express · App do Entregador
// Usa: supabase (geocode-proxy Edge Function)
// Mantem tipos simples para desacoplar o servico da implementacao visual do mapa.
// ============================================================

import 'package:padoca_express/core/config/plataforma_runtime_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Tipos simples compatíveis com google_maps_flutter ───────────────────────
class LatLng {
  final double latitude, longitude;
  const LatLng(this.latitude, this.longitude);
}

class LatLngBounds {
  final LatLng southwest, northeast;
  const LatLngBounds({required this.southwest, required this.northeast});
}

class RouteInfo {
  final List<LatLng> pontos;
  final String? distanciaTexto;
  final String? duracaoTexto;
  final int? distanciaMetros;
  final bool isRota;

  const RouteInfo({
    required this.pontos,
    this.distanciaTexto,
    this.duracaoTexto,
    this.distanciaMetros,
    this.isRota = false,
  });

  double get distanciaKm =>
      distanciaMetros == null ? 0 : distanciaMetros! / 1000.0;

  /// Parse da resposta Google Directions (via geocode-proxy).
  static RouteInfo? fromDirectionsJson(Map<String, dynamic> data) {
    final routes = data['routes'];
    if (routes is! List || routes.isEmpty) return null;
    final route = routes.first;
    if (route is! Map) return null;
    final routeMap = Map<String, dynamic>.from(route);

    final encoded = routeMap['overview_polyline'] is Map
        ? (routeMap['overview_polyline'] as Map)['points'] as String?
        : null;

    final legs = routeMap['legs'];
    Map<String, dynamic>? leg;
    if (legs is List && legs.isNotEmpty && legs.first is Map) {
      leg = Map<String, dynamic>.from(legs.first as Map);
    }

    final distance = leg?['distance'];
    final duration = leg?['duration'];
    final distanceValue =
        distance is Map ? distance['value'] : null;
    final distanciaMetros =
        distanceValue is num ? distanceValue.round() : null;

    if (encoded == null && distanciaMetros == null) return null;

    return RouteInfo(
      pontos: encoded != null ? MapService.decodePolyline(encoded) : const [],
      distanciaTexto: distance is Map ? distance['text'] as String? : null,
      duracaoTexto: duration is Map ? duration['text'] as String? : null,
      distanciaMetros: distanciaMetros,
      isRota: distanciaMetros != null && distanciaMetros > 0,
    );
  }

  static RouteInfo fallbackHaversine(LatLng a, LatLng b) {
    final km = distanciaKmCoords(
      lat1: a.latitude,
      lng1: a.longitude,
      lat2: b.latitude,
      lng2: b.longitude,
    );
    final metros = (km * 1000).round();
    return RouteInfo(
      pontos: [a, b],
      distanciaMetros: metros > 0 ? metros : null,
      distanciaTexto: km > 0
          ? '${km.toStringAsFixed(1).replaceAll('.', ',')} km'
          : null,
      isRota: false,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
class MapService {
  MapService._();
  static final MapService instance = MapService._();

  // ── Busca rota entre dois pontos via Edge Function geocode-proxy ─────────
  Future<List<LatLng>> buscarRota({
    required LatLng origem,
    required LatLng destino,
  }) async {
    final info = await buscarRotaDetalhada(origem: origem, destino: destino);
    return info.pontos;
  }

  Future<RouteInfo> buscarRotaDetalhada({
    required LatLng origem,
    required LatLng destino,
  }) async {
    try {
      final resp = await Supabase.instance.client.functions.invoke(
        'geocode-proxy',
        body: {
          'action': 'directions',
          'origin': '${origem.latitude},${origem.longitude}',
          'destination': '${destino.latitude},${destino.longitude}',
          'mode': 'driving',
        },
      );

      if (resp.status != 200) {
        return RouteInfo.fallbackHaversine(origem, destino);
      }

      final data = resp.data is Map
          ? Map<String, dynamic>.from(resp.data as Map)
          : <String, dynamic>{};
      final parsed = RouteInfo.fromDirectionsJson(data);
      if (parsed == null || parsed.distanciaMetros == null) {
        return RouteInfo.fallbackHaversine(origem, destino);
      }
      if (parsed.pontos.isEmpty) {
        return RouteInfo(
          pontos: [origem, destino],
          distanciaTexto: parsed.distanciaTexto,
          duracaoTexto: parsed.duracaoTexto,
          distanciaMetros: parsed.distanciaMetros,
          isRota: parsed.isRota,
        );
      }
      return parsed;
    } catch (_) {
      return RouteInfo.fallbackHaversine(origem, destino);
    }
  }

  // ── Geocodifica um endereço texto → LatLng ───────────────────────────────
  Future<LatLng?> geocodificar(String endereco) async {
    try {
      final resp = await Supabase.instance.client.functions.invoke(
        'geocode-proxy',
        body: {'action': 'geocode', 'address': endereco},
      );
      if (resp.status != 200) return null;
      final data = resp.data as Map<String, dynamic>;
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) return null;
      final loc = results[0]['geometry']?['location'];
      if (loc == null) return null;
      return LatLng(
        (loc['lat'] as num).toDouble(),
        (loc['lng'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  // ── Decodifica encoded polyline do Google ────────────────────────────────
  static List<LatLng> decodePolyline(String encoded) {
    final List<LatLng> pontos = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      pontos.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return pontos;
  }

  // ── Calcula bounds para encaixar todos os pontos na câmera ───────────────
  static LatLngBounds calcularBounds(List<LatLng> pontos) {
    double minLat = pontos.first.latitude;
    double maxLat = pontos.first.latitude;
    double minLng = pontos.first.longitude;
    double maxLng = pontos.first.longitude;

    for (final p in pontos) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat - 0.002, minLng - 0.002),
      northeast: LatLng(maxLat + 0.002, maxLng + 0.002),
    );
  }

  // ── Estilo escuro para o mapa (JSON) ─────────────────────────────────────
  static const String estiloEscuro = '''[
    {"elementType":"geometry","stylers":[{"color":"#0a0a0a"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#0a0704"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#746855"}]},
    {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},
    {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},
    {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#0d1a0d"}]},
    {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#6b9a76"}]},
    {"featureType":"road","elementType":"geometry","stylers":[{"color":"#251c14"}]},
    {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#1a1510"}]},
    {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#9ca5b3"}]},
    {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3a2d1f"}]},
    {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#1f1b16"}]},
    {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#f3d19c"}]},
    {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#1c1510"}]},
    {"featureType":"transit.station","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#070e14"}]},
    {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#515c6d"}]},
    {"featureType":"water","elementType":"labels.text.stroke","stylers":[{"color":"#17263c"}]}
  ]''';
}
