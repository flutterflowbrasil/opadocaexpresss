import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:padoca_express/core/services/web_geolocation_helper.dart'
    if (dart.library.io) 'package:padoca_express/core/services/mobile_geolocation_helper.dart';

/// Tenta obter a localização atual do dispositivo.
///
/// Retorna [Position] se a permissão foi concedida e o GPS respondeu,
/// ou [null] se:
///   - o serviço de localização está desativado
///   - o usuário negou a permissão (agora ou permanentemente)
///   - o GPS não respondeu dentro do timeout
Future<Position?> obterLocalizacao() async {
  try {
    // 1. Verifica se o serviço está ligado
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint(
          '[Localizacao] Erro: Serviço de localização (GPS) do aparelho está desativado.');
      return null;
    }

    // 2. Verifica permissão atual
    var permission = await Geolocator.checkPermission();
    debugPrint('[Localizacao] Status da permissão atual: $permission');

    // 3. Pede permissão apenas se ainda não foi solicitada
    if (permission == LocationPermission.denied) {
      debugPrint('[Localizacao] Solicitando permissão ao usuário...');
      permission = await Geolocator.requestPermission();
      debugPrint('[Localizacao] Resposta da solicitação: $permission');
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    // 4. Bloqueado permanentemente — não pode pedir novamente
    if (permission == LocationPermission.deniedForever) {
      debugPrint('[Localizacao] Erro: Permissão negada permanentemente.');
      return null;
    }

    // 5. Obtém a posição usando o utilitário seguro para a plataforma
    debugPrint(
        '[Localizacao] Obtendo posição com utilitário específico da plataforma...');
    Position? position;
    try {
      position = await getWebSafePosition();
    } catch (e) {
      debugPrint('[Localizacao] Erro em getWebSafePosition: $e');
      if (!kIsWeb) {
        debugPrint('[Localizacao] Tentando getLastKnownPosition...');
        try {
          position = await Geolocator.getLastKnownPosition();
        } catch (e2) {
          debugPrint('[Localizacao] Erro em getLastKnownPosition: $e2');
        }
      }
    }
    debugPrint(
        '[Localizacao] Posição obtida: ${position?.latitude}, ${position?.longitude}');
    return position;
  } catch (e, stack) {
    debugPrint(
        '[Localizacao] Exception capturada em obterLocalizacao: $e\n$stack');
    return null;
  }
}

/// Verifica se já existe permissão concedida (sem pedir novamente).
Future<bool> temPermissaoLocalizacao() async {
  try {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  } catch (e) {
    debugPrint('[Localizacao] Erro ao checar permissão previa: $e');
    return false;
  }
}
