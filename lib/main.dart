import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:padoca_express/core/supabase/supabase_config.dart';
import 'package:padoca_express/core/router/app_router.dart';
import 'package:padoca_express/core/theme/theme_provider.dart';
import 'package:padoca_express/services/notifications/onesignal_service.dart';
import 'package:padoca_express/services/notifications/push_notification_controller.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  // No Web, as variáveis já são compiladas no binário via --dart-define-from-file=.env.
  // Nunca tentamos carregar o .env via HTTP no web — isso geraria um GET público
  // em /assets/.env e um 404 desnecessário no console.
  // Em mobile/desktop, o .env é lido do filesystem local (nunca exposto via HTTP).
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // .env ausente — variáveis devem vir via --dart-define
    }
  }

  // Inicializa Supabase e Datas
  await initializeDateFormatting('pt_BR', null);
  _installAuthErrorGuards();
  await SupabaseConfig.initialize();
  // OneSignal no Chrome pode rejeitar (SW, localhost, SDK defer).
  // Nunca bloquear nem derrubar o app por falha de push.
  unawaited(_initOneSignal());

  // Maps na web: só depois de sessão válida (auth_repository).
  // Carregar aqui dispara refreshSession() com token morto no localStorage.

  runApp(const ProviderScope(child: MyApp()));
}

void _installAuthErrorGuards() {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    if (SupabaseConfig.isUnrecoverableAuthError(details.exception)) {
      debugPrint('[Auth] sessão expirada: ${details.exception}');
      return;
    }
    if (previous != null) {
      previous(details);
    } else {
      FlutterError.presentError(details);
    }
  };

  final previousPlatform = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    if (SupabaseConfig.isUnrecoverableAuthError(error)) {
      debugPrint('[Auth] sessão expirada: $error');
      return true;
    }
    return previousPlatform?.call(error, stack) ?? false;
  };
}

Future<void> _initOneSignal() async {
  try {
    await OneSignalService.initialize();
  } catch (e) {
    debugPrint('[OneSignal] falha na inicializacao: $e');
  }
}


class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final router = ref.watch(appRouterProvider);

    ref.listen<PushNotificationState>(pushNotificationControllerProvider,
        (previous, next) {
      final route = next.pendingRoute;
      if (route == null || route == previous?.pendingRoute) return;
      router.go(route);
      ref.read(pushNotificationControllerProvider.notifier).clearPendingRoute();
    });

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Ôpadoca Express',
      themeMode: themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('pt', 'BR'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF7034)),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF7034),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      routerConfig: router,
    );
  }
}
