// Conditional import: usa web em browser, stub no resto.
// O compilador do Dart inclui apenas o arquivo correto para cada plataforma.
export '_download_stub.dart'
    if (dart.library.html) '_download_web.dart';
