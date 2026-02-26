import 'package:go_router/go_router.dart';
import 'package:padoca_express/features/auth/presentation/splash_screen.dart';
import 'package:padoca_express/features/auth/presentation/login_screen.dart';
import 'package:padoca_express/features/auth/presentation/politica_privacidade.dart';
import 'package:padoca_express/features/auth/presentation/pre_cadastro_screen.dart';
import 'package:padoca_express/features/cliente/cadastro_cliente/cadastro_cliente_screen.dart';
import 'package:padoca_express/features/entregador/cadastro_entregador/cadastro_entregador_screen.dart';
import 'package:padoca_express/features/cliente/home/home_screen.dart';
import 'package:padoca_express/features/cliente/categorias/models/categoria_estabelecimento_model.dart';
import 'package:padoca_express/features/cliente/categorias/categoria_estabelecimentos_screen.dart';
import 'package:padoca_express/features/estabelecimento/auth/steps/cadastro_estabelecimento_step1_screen.dart';
import 'package:padoca_express/features/estabelecimento/auth/steps/cadastro_estabelecimento_step2_screen.dart';
import 'package:padoca_express/features/estabelecimento/auth/steps/cadastro_estabelecimento_step3_screen.dart';
import 'package:padoca_express/features/cliente/busca/busca_resultados_screen.dart';
import 'package:padoca_express/features/cliente/carrinho/carrinho_screen.dart';
import 'package:padoca_express/features/estabelecimento/estabelecimento_screen.dart';
import 'package:padoca_express/features/cliente/home/models/estabelecimento_model.dart';

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
    GoRoute(
      path: '/categoria/:slug',
      builder: (context, state) {
        final slug = state.pathParameters['slug']!;
        final cat = state.extra as CategoriaEstabelecimentoModel?;

        return CategoriaEstabelecimentosScreen(
          categoriaId: cat?.id,
          categoriaSlug: slug,
          categoriaNome: cat?.nome ?? 'Categoria',
          categoriaImagemUrl: cat?.imagemUrl ?? '',
        );
      },
    ),
    GoRoute(
      path: '/busca',
      builder: (context, state) {
        final termo = state.uri.queryParameters['q'] ?? '';
        return BuscaResultadosScreen(termoInicial: termo);
      },
    ),
    GoRoute(
      path: '/carrinho',
      builder: (context, state) => const CarrinhoScreen(),
    ),
    GoRoute(
      path: '/estabelecimento/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final extra = state.extra as EstabelecimentoModel?;

        // Se o usuário acessar a URL direto ou dar refresh, o go_router não tem o object "extra".
        // Nesse caso, o controller EstabelecimentoController cuidará de fazer o fetch
        // usando este skeleton que passamos abaixo.
        final estabelecimento = extra ??
            EstabelecimentoModel(
              id: id,
              nome: 'Detalhes...',
              avaliacaoMedia: 0.0,
              totalAvaliacoes: 0,
              statusAberto: false,
            );

        return EstabelecimentoScreen(estabelecimento: estabelecimento);
      },
    ),
  ],
);
