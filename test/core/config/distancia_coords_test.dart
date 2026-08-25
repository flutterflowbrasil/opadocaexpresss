import 'package:flutter_test/flutter_test.dart';
import 'package:padoca_express/core/config/plataforma_runtime_config.dart';
import 'package:padoca_express/services/map_service.dart';

void main() {
  group('distanciaKmCoords', () {
    test('São Paulo curto trecho fica abaixo do cap', () {
      final km = distanciaKmCoords(
        lat1: -23.5505,
        lng1: -46.6333,
        lat2: -23.5605,
        lng2: -46.6433,
      );
      expect(km, greaterThan(0));
      expect(km, lessThan(5));
    });

    test('distância absurda acima de 200 km vira 0', () {
      final km = distanciaKmCoords(
        lat1: -23.5505,
        lng1: -46.6333,
        lat2: 40.7128,
        lng2: -74.0060,
      );
      expect(km, 0);
    });

    test('coordenadas inválidas viram 0', () {
      expect(
        distanciaKmCoords(lat1: 200, lng1: 0, lat2: 0, lng2: 0),
        0,
      );
      expect(
        distanciaKmCoords(lat1: 0, lng1: 200, lat2: 0, lng2: 0),
        0,
      );
    });
  });

  group('distanciaEntregaKm', () {
    test('usa haversine quando rota é nula', () {
      expect(distanciaEntregaKm(haversineKm: 8, rotaKm: null), 8);
    });

    test('aceita rota dentro da sanidade', () {
      expect(
        distanciaEntregaKm(haversineKm: 8, rotaKm: 10.4),
        10.4,
      );
    });

    test('rejeita rota maior que haversine * 1.5 + 2', () {
      expect(
        distanciaEntregaKm(haversineKm: 8, rotaKm: 20),
        8,
      );
    });

    test('rejeita rota acima de 200 km', () {
      expect(
        distanciaEntregaKm(haversineKm: 10, rotaKm: 250),
        10,
      );
    });

    test('rejeita rota zero ou negativa', () {
      expect(distanciaEntregaKm(haversineKm: 5, rotaKm: 0), 5);
      expect(distanciaEntregaKm(haversineKm: 5, rotaKm: -1), 5);
    });
  });

  group('RouteInfo.fromDirectionsJson', () {
    test('lê distance.value em metros e textos da leg', () {
      final info = RouteInfo.fromDirectionsJson({
        'routes': [
          {
            'legs': [
              {
                'distance': {'text': '12,4 km', 'value': 12400},
                'duration': {'text': '28 min', 'value': 1680},
              }
            ],
          }
        ],
      });

      expect(info, isNotNull);
      expect(info!.distanciaMetros, 12400);
      expect(info.distanciaKm, closeTo(12.4, 0.001));
      expect(info.distanciaTexto, '12,4 km');
      expect(info.duracaoTexto, '28 min');
      expect(info.isRota, isTrue);
    });

    test('retorna null sem routes', () {
      expect(RouteInfo.fromDirectionsJson({'routes': []}), isNull);
      expect(RouteInfo.fromDirectionsJson({}), isNull);
    });

    test('fallback Haversine preenche km capado', () {
      final info = RouteInfo.fallbackHaversine(
        const LatLng(-23.5505, -46.6333),
        const LatLng(-23.5605, -46.6433),
      );
      expect(info.isRota, isFalse);
      expect(info.distanciaKm, greaterThan(0));
      expect(info.distanciaKm, lessThan(5));
    });
  });
}
