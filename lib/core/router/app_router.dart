import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:padoca_express/features/auth/data/auth_repository.dart';
import 'package:padoca_express/features/auth/presentation/splash_screen.dart';
import 'package:padoca_express/features/auth/presentation/login_screen.dart';
import 'package:padoca_express/features/auth/presentation/politica_privacidade.dart';
import 'package:padoca_express/features/auth/presentation/pre_cadastro_screen.dart';
import 'package:padoca_express/features/auth/presentation/cadastro_cliente/cadastro_cliente_screen.dart';
import 'package:padoca_express/features/entregador/cadastro_entregador/cadastro_entregador_screen.dart';
import 'package:padoca_express/features/auth/presentation/esqueceu_senha/esqueceu_senha_screen.dart';
import 'package:padoca_express/features/auth/presentation/nova_senha/nova_senha_screen.dart';
import 'package:padoca_express/features/cliente/home/home_screen.dart';
import 'package:padoca_express/features/cliente/categorias/models/categoria_estabelecimento_model.dart';
import 'package:padoca_express/features/cliente/categorias/categoria_estabelecimentos_screen.dart';
import 'package:padoca_express/features/auth/presentation/cadastro_estabelecimento/steps/cadastro_estabelecimento_step1_screen.dart';
import 'package:padoca_express/features/auth/presentation/cadastro_estabelecimento/steps/cadastro_estabelecimento_step2_screen.dart';
import 'package:padoca_express/features/auth/presentation/cadastro_estabelecimento/steps/cadastro_estabelecimento_step3_screen.dart';
import 'package:padoca_express/features/cliente/busca/busca_resultados_screen.dart';
import 'package:padoca_express/features/cliente/carrinho/carrinho_screen.dart';
import 'package:padoca_express/features/estabelecimento/estabelecimento_screen.dart';
import 'package:padoca_express/features/cliente/home/models/estabelecimento_model.dart';
import 'package:padoca_express/features/cliente/carrinho/finalizar_pedido_screen.dart';
import 'package:padoca_express/features/cliente/pagamento/presentation/pix_pagamento_screen.dart';
import 'package:padoca_express/features/cliente/pagamento/presentation/pagamento_sucesso_screen.dart';

import 'package:padoca_express/features/estabelecimento/dashboard/dashboard_screen.dart';
import 'package:padoca_express/features/entregador/dashboard/presentation/ui/dashboard_screen.dart';
import 'package:padoca_express/features/admgeral/dashboard_adm/presentation/admin_dashboard_screen.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/pedidos/pedidos_screen.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/configuracoes/configuracoes.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/produtos/produtos_screen.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/cupons/cupons_screen.dart';
import 'package:padoca_express/features/estabelecimento/financeiro/financeiro_screen.dart';
import 'package:padoca_express/features/cliente/pedidos/presentation/meus_pedidos_screen.dart';
import 'package:padoca_express/features/entregador/carteira/presentation/ui/carteira_screen.dart';
import 'package:padoca_express/features/entregador/historico/presentation/ui/historico_screen.dart';
import 'package:padoca_express/features/entregador/entregas/presentation/ui/entrega_andamento_screen.dart';
import 'package:padoca_express/features/entregador/avaliacoes/presentation/ui/avaliacoes_screen.dart';
import 'package:padoca_express/features/entregador/perfil/presentation/ui/perfil_screen.dart';
import 'package:padoca_express/features/entregador/configuracoes/presentation/ui/configuracoes_screen.dart' as ent_cfg;
import 'package:padoca_express/features/entregador/suporte/presentation/ui/suporte_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      // Rotas que exigem autenticação obrigatória
      const authRequired = [
        '/carrinho',
        '/finalizar_pedido',
        '/cliente/pedidos',
        '/pagamento',
      ];

      final loc = state.matchedLocation;

      final needsAuth = authRequired.any((r) => loc.startsWith(r)) ||
          loc.startsWith('/dashboard_estabelecimento') ||
          loc.startsWith('/dashboard_entregador') ||
          loc.startsWith('/admin/dashboard');

      // Redireciona para login se não autenticado
      if (needsAuth && authRepository.currentUser == null) {
        return '/login';
      }

      // Usuário já autenticado não deve acessar telas de cadastro/login.
      // O banco (SECURITY DEFINER) decide para qual dashboard redirecionar.
      const authForbiddenWhenLoggedIn = [
        '/login',
        '/pre_cadastro',
        '/cadastro_cliente',
        '/cadastro_entregador',
        '/cadastro-estabelecimento',
      ];
      if (authRepository.currentUser != null &&
          authForbiddenWhenLoggedIn.any((r) => loc.startsWith(r))) {
        final route = await ref.read(sessionRouteProvider.future);
        if (route == loc) return null; // evita loop infinito se RPC retornar rota inesperada
        return route;
      }

      // Protege dashboards: verifica uma única vez via RPC cacheada
      const dashboardPrefixes = [
        '/admin/dashboard',
        '/dashboard_estabelecimento',
        '/dashboard_entregador',
      ];
      final matchingPrefix =
          dashboardPrefixes.where((p) => loc.startsWith(p)).firstOrNull;
      if (matchingPrefix != null) {
        final targetRoute = await ref.read(sessionRouteProvider.future);
        if (!targetRoute.startsWith(matchingPrefix)) return targetRoute;
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/esqueceu-senha',
        builder: (context, state) => const EsqueceuSenhaScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const NovaSenhaScreen(),
      ),
      GoRoute(
        path: '/dashboard_estabelecimento',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: DashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/dashboard_entregador',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: EntregadorDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/dashboard',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: AdminDashboardScreen(),
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
        path: '/dashboard_estabelecimento/produtos',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: ProdutosScreen(),
        ),
      ),
      GoRoute(
        path: '/dashboard_estabelecimento/cupons',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: CuponsScreen(),
        ),
      ),
      GoRoute(
        path: '/dashboard_estabelecimento/financeiro',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: FinanceiroScreen(),
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
        path: '/cliente/pedidos',
        builder: (context, state) => const MeusPedidosScreen(),
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
        path: '/pagamento/pix',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return PixPagamentoScreen(
            pedidoId: extra['pedidoId'] as String,
            pixCopiaECola: extra['pixCopiaECola'] as String? ?? '',
            pixQrCodeBase64: extra['pixQrCode'] as String?,
            segundosIniciaisRestantes: extra['segundosRestantes'] as int?,
          );
        },
      ),
      GoRoute(
        path: '/pagamento/sucesso',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return PagamentoSucessoScreen(
              pedidoId: extra['pedidoId'] as String? ?? '');
        },
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

      // ── Entregador sub-rotas ─────────────────────────────────────────────
      GoRoute(
        path: '/dashboard_entregador/financeiro',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: CarteiraScreen(),
        ),
      ),
      GoRoute(
        path: '/dashboard_entregador/historico',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: HistoricoScreen(),
        ),
      ),
      GoRoute(
        path: '/dashboard_entregador/entrega/:pedidoId',
        builder: (context, state) {
          final pedidoId = state.pathParameters['pedidoId']!;
          return EntregaAndamentoScreen(pedidoId: pedidoId);
        },
      ),
      GoRoute(
        path: '/dashboard_entregador/avaliacoes',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: AvaliacoesScreen(),
        ),
      ),
      GoRoute(
        path: '/dashboard_entregador/perfil',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: PerfilScreen(),
        ),
      ),
      GoRoute(
        path: '/dashboard_entregador/configuracoes',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: ent_cfg.ConfiguracoesScreen(),
        ),
      ),
      GoRoute(
        path: '/dashboard_entregador/suporte',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SuporteScreen(),
        ),
      ),
    ],
  );
});
