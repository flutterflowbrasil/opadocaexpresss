import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:padoca_express/core/app/web_reload.dart';
import 'package:padoca_express/core/config/plataforma_runtime_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const kPlayStorePackageId = 'com.opadocaexpress.app';

enum AppUpdateCheckResult {
  upToDate,
  updateRequired,
  cacheClearedReloading,
  openedStore,
}

class AppUpdateService {
  AppUpdateService._();

  static const _prefsPreservadas = {'theme_mode'};

  /// Web: limpa cache local e recarrega a página.
  /// Android: abre a Play Store se a versão estiver abaixo da mínima.
  static Future<AppUpdateCheckResult> verificarAtualizacao({
    required PlataformaRuntimeConfig cfg,
    WidgetRef? ref,
  }) async {
    final precisaAtualizar = cfg.appAbaixoDaMinima();

    if (kIsWeb) {
      await limparCacheLocal(ref: ref);
      recarregarPaginaWeb();
      return precisaAtualizar
          ? AppUpdateCheckResult.updateRequired
          : AppUpdateCheckResult.cacheClearedReloading;
    }

    if (defaultTargetPlatform == TargetPlatform.android && precisaAtualizar) {
      final uri = Uri.parse(
        'https://play.google.com/store/apps/details?id=$kPlayStorePackageId',
      );
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      return AppUpdateCheckResult.openedStore;
    }

    if (precisaAtualizar) {
      return AppUpdateCheckResult.updateRequired;
    }
    return AppUpdateCheckResult.upToDate;
  }

  static Future<void> limparCacheLocal({WidgetRef? ref}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().toList();
      for (final key in keys) {
        if (_prefsPreservadas.contains(key)) continue;
        await prefs.remove(key);
      }
    } catch (_) {}

    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (_) {}

    ref?.invalidate(plataformaRuntimeConfigProvider);
  }

  static String mensagemResultado(AppUpdateCheckResult result) {
    return switch (result) {
      AppUpdateCheckResult.upToDate =>
        'Você já está com a versão mais recente ($kAppVersion).',
      AppUpdateCheckResult.updateRequired =>
        'Há uma versão mais recente disponível. Atualize para continuar com todos os recursos.',
      AppUpdateCheckResult.cacheClearedReloading =>
        'Cache limpo. Recarregando o app…',
      AppUpdateCheckResult.openedStore =>
        'Abrindo a Play Store para atualizar o app.',
    };
  }
}