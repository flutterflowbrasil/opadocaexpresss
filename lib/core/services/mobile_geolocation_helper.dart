import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

Future<Position?> getWebSafePosition() async {
  try {
    // 1. Tenta pegar o último local conhecido pelo Android/iOS (Cache Instantâneo do O.S)
    final lastPosition = await Geolocator.getLastKnownPosition();
    if (lastPosition != null) {
      final difference = DateTime.now().difference(lastPosition.timestamp);
      // Se a posição tem menos de 10 minutos de vida, usamos ela para não gastar bateria/tempo do GPS novo
      if (difference.inMinutes <= 10) {
        debugPrint(
            '[Localizacao] Usando lastKnownPosition (Cache Nativo): ${difference.inMinutes}min de idade');
        return lastPosition;
      }
    }

    // 2. O mobile usa o pacote normal puxando ativamente do satélite (demora 2-5s em média na 1ª vez)
    debugPrint('[Localizacao] Buscando posição atual do satélite...');
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy
            .medium, // Medium é mais que suficiente e MUITO mais rápido
      ),
    ).timeout(const Duration(seconds: 15));
  } catch (e) {
    debugPrint('[Localizacao] Erro no utilitário Mobile nativo: $e');
    return null;
  }
}
