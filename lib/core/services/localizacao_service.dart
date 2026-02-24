import 'package:geolocator/geolocator.dart';

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
      print(
          '[Localizacao] Erro: Serviço de localização (GPS) do aparelho está desativado.');
      return null;
    }

    // 2. Verifica permissão atual
    var permission = await Geolocator.checkPermission();
    print('[Localizacao] Status da permissão atual: $permission');

    // 3. Pede permissão apenas se ainda não foi solicitada
    if (permission == LocationPermission.denied) {
      print('[Localizacao] Solicitando permissão ao usuário...');
      permission = await Geolocator.requestPermission();
      print('[Localizacao] Resposta da solicitação: $permission');
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    // 4. Bloqueado permanentemente — não pode pedir novamente
    if (permission == LocationPermission.deniedForever) {
      print('[Localizacao] Erro: Permissão negada permanentemente.');
      return null;
    }

    // 5. Obtém a posição com timeout garantido pelo Dart
    print('[Localizacao] Obtendo posição atual...');
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      ),
    ).timeout(const Duration(seconds: 10));
    print(
        '[Localizacao] Posição obtida: ${position.latitude}, ${position.longitude}');
    return position;
  } catch (e, stack) {
    print('[Localizacao] Exception capturada em obterLocalizacao: $e\n$stack');
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
    print('[Localizacao] Erro ao checar permissão previa: $e');
    return false;
  }
}
