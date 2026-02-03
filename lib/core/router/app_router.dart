import 'package:go_router/go_router.dart';
import 'package:padoca_express/features/auth/presentation/splash_screen.dart';
import 'package:padoca_express/features/auth/presentation/login_screen.dart';
import 'package:padoca_express/features/auth/presentation/politica_privacidade.dart';
import 'package:padoca_express/features/auth/presentation/pre_cadastro_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const PoliticaPrivacidadeScreen(),
    ),
    GoRoute(
      path: '/pre_cadastro',
      builder: (context, state) => const PreCadastroScreen(),
    ),
  ],
);
