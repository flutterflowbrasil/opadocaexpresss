import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:padoca_express/features/auth/data/auth_repository.dart';
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
import 'package:padoca_express/features/cliente/carrinho/finalizar_pedido_screen.dart';

import 'package:padoca_express/features/estabelecimento/dashboard/dashboard_screen.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/pedidos/pedidos_screen.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/configuracoes/configuracoes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      // Rotas protegidas que precisam do tipo_usuario
      final isDashboardArea =
          state.matchedLocation.startsWith('/dashboard_estabelecimento');

      if (isDashboardArea) {
        if (authRepository.currentUser == null) {
          return '/login';
        }

        final type =
            await authRepository.getUserType(authRepository.currentUser!.id);

        if (type != 'estabelecimento') {
          // Se não for estabelecimento tenta voltar ou home
          return '/home';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/dashboard_estabelecimento',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: DashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/dashboard_estabelecimento/pedidos',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: PedidosScreen(),
        ),
      ),
      GoRoute(
        path: '/dashboard_estabelecimento/configuracoes',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: ConfiguracoesScreen(),
        ),
      ),
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
        path: '/finalizar_pedido',
        builder: (context, state) => const FinalizarPedidoScreen(),
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
});
