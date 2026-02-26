import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'dart:async';

Future<Position?> getWebSafePosition() async {
  try {
    final geolocation = web.window.navigator.geolocation;

    final completer = Completer<Position>();

    geolocation.getCurrentPosition(
      (web.GeolocationPosition pos) {
        if (!completer.isCompleted) {
          completer.complete(Position(
            longitude: pos.coords.longitude,
            latitude: pos.coords.latitude,
            timestamp: DateTime.now(),
            accuracy: pos.coords.accuracy,
            altitude: pos.coords.altitude ?? 0.0,
            altitudeAccuracy: pos.coords.altitudeAccuracy ?? 0.0,
            heading: pos.coords.heading ?? 0.0,
            headingAccuracy: 0.0,
            speed: pos.coords.speed ?? 0.0,
            speedAccuracy: 0.0,
            isMocked: false,
          ));
        }
      }.toJS,
      (web.GeolocationPositionError error) {
        if (!completer.isCompleted) {
          completer.completeError(
              Exception('Geolocalização Web falhou: ${error.message}'));
        }
      }.toJS,
      web.PositionOptions(
        enableHighAccuracy: false,
        timeout:
            30000, // 30 segundos dá tempo do usuário ler e clicar em Permitir
        maximumAge: 5 *
            60 *
            1000, // 5 minutos de cache pra não precisar recalcular na mesma sessão
      ),
    );

    // O timeout do Dart precisa cobrir o timeout nativo + uma margem
    return await completer.future.timeout(
      const Duration(seconds: 35),
      onTimeout: () => throw Exception('Timeout nativo excedido'),
    );
  } catch (e) {
    debugPrint(
        '[Localizacao] Exception capturada em getWebSafePosition nativo: $e');
    return null;
  }
}
