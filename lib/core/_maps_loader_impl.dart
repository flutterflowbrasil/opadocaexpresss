// Entrypoint de conditional import para MapsLoader.
// O compilador Dart seleciona automaticamente:
//   - _maps_web.dart  → quando dart:html está disponível (Flutter Web)
//   - _maps_stub.dart → nas demais plataformas (Android, iOS, Desktop)
export '_maps_stub.dart' if (dart.library.html) '_maps_web.dart';
