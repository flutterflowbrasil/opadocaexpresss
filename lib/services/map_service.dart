// ============================================================
// map_service.dart — Serviço de Mapas
// Ôpadoca Express · App do Entregador
// Usa: supabase (geocode-proxy Edge Function)
// NOTE: Quando google_maps_flutter for adicionado ao pubspec,
//       substituir LatLng/LatLngBounds locais pelos da lib.
// ============================================================

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

// ═══════════════════════════════════════════════════════════════════════════
class MapService {
  MapService._();
  static final MapService instance = MapService._();

  // ── Busca rota entre dois pontos via Edge Function geocode-proxy ─────────
  Future<List<LatLng>> buscarRota({
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

      if (resp.status != 200) return _rotaReta(origem, destino);

      final data = resp.data as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return _rotaReta(origem, destino);

      final pontos = routes[0]['overview_polyline']?['points'] as String?;
      if (pontos == null) return _rotaReta(origem, destino);

      return _decodificarPolyline(pontos);
    } catch (_) {
      return _rotaReta(origem, destino);
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
  List<LatLng> _decodificarPolyline(String encoded) {
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

  // ── Fallback: linha reta entre dois pontos ────────────────────────────────
  List<LatLng> _rotaReta(LatLng a, LatLng b) => [a, b];

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
