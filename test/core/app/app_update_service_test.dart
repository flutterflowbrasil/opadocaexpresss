import 'package:flutter_test/flutter_test.dart';
import 'package:padoca_express/core/app/app_update_service.dart';
import 'package:padoca_express/core/config/plataforma_runtime_config.dart';

void main() {
  group('AppUpdateService', () {
    test('mensagemResultado descreve cada estado', () {
      expect(
        AppUpdateService.mensagemResultado(AppUpdateCheckResult.upToDate),
        contains('versão mais recente'),
      );
      expect(
        AppUpdateService.mensagemResultado(AppUpdateCheckResult.updateRequired),
        contains('versão mais recente disponível'),
      );
      expect(
        AppUpdateService.mensagemResultado(
          AppUpdateCheckResult.cacheClearedReloading,
        ),
        contains('Recarregando'),
      );
      expect(
        AppUpdateService.mensagemResultado(AppUpdateCheckResult.openedStore),
        contains('Play Store'),
      );
    });

    test('appAbaixoDaMinima integra com verificação', () {
      const cfg = PlataformaRuntimeConfig(versaoMinimaApp: '2.0.0');
      expect(cfg.appAbaixoDaMinima(), isTrue);
      const ok = PlataformaRuntimeConfig(versaoMinimaApp: '1.0.0');
      expect(ok.appAbaixoDaMinima(), isFalse);
    });
  });
}
