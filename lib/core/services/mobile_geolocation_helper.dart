import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

Future<Position?> getWebSafePosition() async {
  try {
    if (kDebugMode) {
      debugPrint('[Localizacao] Buscando posição atual com alta precisão...');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    ).timeout(const Duration(seconds: 20));
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Localizacao] Erro no utilitário Mobile nativo: $e');
    }
    return null;
  }
}
