import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:padoca_express/core/supabase/supabase_config.dart';
import 'package:padoca_express/core/router/app_router.dart';
import 'package:padoca_express/core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  // Carrega variáveis de ambiente do .env
  // Em produção (Web/Vercel), as variáveis --dart-define sobrescrevem os valores do .env
  // Em desenvolvimento web, o .env local é usado como fallback
  await dotenv.load(fileName: '.env');

  // Inicializa Supabase
  await SupabaseConfig.initialize();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Padoca Express',
      themeMode: themeMode,
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
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
