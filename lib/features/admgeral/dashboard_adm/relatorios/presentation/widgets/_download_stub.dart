// Stub para plataformas não-web (Android, iOS, Desktop).
// A funcionalidade de download não está disponível nessas plataformas.

void downloadBytes(List<int> bytes, String mimeType, String filename) {
  // No-op em mobile/desktop.
  // No futuro: usar path_provider + open_file para salvar localmente.
}
