// Implementação real para Flutter Web usando dart:html.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> loadMapsApi(String key) async {
  final script = html.ScriptElement()
    ..src = 'https://maps.googleapis.com/maps/api/js'
        '?key=$key&libraries=places'
    ..async = true
    ..defer = true;

  html.document.head!.append(script);
  await script.onLoad.first;
}
