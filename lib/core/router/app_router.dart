import 'package:go_router/go_router.dart';
import 'package:padoca_express/features/auth/presentation/splash_screen.dart';
import 'package:padoca_express/features/auth/presentation/login_screen.dart';
import 'package:padoca_express/features/auth/presentation/politica_privacidade.dart';
import 'package:padoca_express/features/auth/presentation/pre_cadastro_screen.dart';
import 'package:padoca_express/features/cliente/cadastro_cliente/cadastro_cliente_screen.dart';
import 'package:padoca_express/features/entregador/cadastro_entregador/cadastro_entregador_screen.dart';
import 'package:padoca_express/features/cliente/home/home_screen.dart';
import 'package:padoca_express/features/estabelecimento/auth/steps/cadastro_estabelecimento_step1_screen.dart';
import 'package:padoca_express/features/estabelecimento/auth/steps/cadastro_estabelecimento_step2_screen.dart';
import 'package:padoca_express/features/estabelecimento/auth/steps/cadastro_estabelecimento_step3_screen.dart';

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
    GoRoute(
      path: '/cadastro_cliente',
      builder: (context, state) => const CadastroClienteScreen(),
    ),
    GoRoute(
      path: '/cadastro_entregador',
      builder: (context, state) => const CadastroEntregadorScreen(),
    ),
    GoRoute(
      path: '/cadastro-estabelecimento/step1',
      builder: (context, state) => const CadastroEstabelecimentoStep1Screen(),
    ),
    GoRoute(
      path: '/cadastro-estabelecimento/step2',
      builder: (context, state) => const CadastroEstabelecimentoStep2Screen(),
    ),
    GoRoute(
      path: '/cadastro-estabelecimento/step3',
      builder: (context, state) => const CadastroEstabelecimentoStep3Screen(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
  ],
);
