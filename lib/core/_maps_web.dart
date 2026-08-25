import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<void> loadMapsApi(String key) async {
  // Evitar carregar o script múltiplas vezes durante hot restart
  if (web.document.querySelector(
        'script[src*="maps.googleapis.com/maps/api/js"]',
      ) !=
      null) {
    return;
  }

  const scriptId = 'google-maps-js-api';
  if (web.document.getElementById(scriptId) != null) {
    return;
  }

  final loaded = Completer<void>();
  final script = web.HTMLScriptElement()
    ..id = scriptId
    ..src = 'https://maps.googleapis.com/maps/api/js'
        '?key=$key&libraries=places&loading=async'
    ..async = true
    ..defer = true;
  script.addEventListener(
    'load',
    (web.Event _) {
      if (!loaded.isCompleted) loaded.complete();
    }.toJS,
  );

  web.document.head?.append(script);
  await loaded.future;
}
