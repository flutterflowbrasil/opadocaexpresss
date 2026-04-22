// Implementação real para Flutter Web usando dart:html.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> loadMapsApi(String key) async {
  // Evitar carregar o script múltiplas vezes durante hot restart
  final isLoaded = html.document.querySelectorAll('script').any((element) {
    final src = (element as html.ScriptElement).src;
    return src.contains('maps.googleapis.com/maps/api/js');
  });

  if (isLoaded) {
    return;
  }

  final scriptId = 'google-maps-js-api';
  if (html.document.getElementById(scriptId) != null) {
    return;
  }

  final script = html.ScriptElement()
    ..id = scriptId
    ..src = 'https://maps.googleapis.com/maps/api/js'
        '?key=$key&libraries=places'
    ..async = true
    ..defer = true;

  html.document.head!.append(script);
  await script.onLoad.first;
}
