// lib/core/maps_loader.dart
//
// Carrega a Google Maps JavaScript API para Flutter Web buscando a chave
// de forma segura via Edge Function `maps-config` (JWT obrigatório).
// Em Android/iOS/Desktop este loader não faz nada — a chave fica no
// AndroidManifest.xml (Android) ou AppDelegate.swift (iOS).

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

// conditional import: dart:html no Web, no-op em mobile/desktop
import '_maps_loader_impl.dart';

// ignore: avoid_print
void _log(String msg) => print('[MapsLoader] $msg');

class MapsLoader {
  MapsLoader._();

  static bool _loaded = false;

  /// Chama a Edge Function `maps-config` para obter a Web Key e injeta
  /// o script da Google Maps JS API apenas no Flutter Web.
  /// Idempotente — segunda chamada retorna imediatamente.
  static Future<void> load() async {
    if (_loaded || !kIsWeb) return;

    try {
      final res = await Supabase.instance.client.functions
          .invoke('maps-config', method: HttpMethod.get);

      final key = (res.data as Map<String, dynamic>?)?['key'] as String? ?? '';
      if (key.isEmpty) {
        _log('GOOGLE_MAPS_WEB_KEY não configurado no Supabase Secrets.');
        return;
      }

      // loadMapsApi é resolvido por _maps_loader_impl.dart:
      // → _maps_web.dart  no browser (injeta <script> via dart:html)
      // → _maps_stub.dart no mobile (no-op)
      await loadMapsApi(key);
      _loaded = true;
    } catch (e) {
      _log('Erro ao carregar Maps API: $e');
    }
  }
}
