// Stub para plataformas não-web (Android, iOS, Desktop).
// MapsLoader.load() é no-op fora do browser.

Future<void> loadMapsApi(String key) async {
  // No-op em mobile/desktop — Maps é carregado via AndroidManifest/AppDelegate.
}
