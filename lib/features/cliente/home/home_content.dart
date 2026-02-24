import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padoca_express/features/cliente/categorias/repositories/categoria_estabelecimento_repository.dart';
import 'package:padoca_express/features/cliente/componentes/bakery_card.dart';
import 'package:padoca_express/features/cliente/componentes/category_item.dart';
import 'package:padoca_express/features/cliente/componentes/promo_banner.dart';
import 'package:padoca_express/features/cliente/padarias/models/padaria_model.dart';
import 'package:padoca_express/core/services/localizacao_service.dart';
import 'package:padoca_express/features/cliente/padarias/providers/padaria_proxima_provider.dart';

class HomeContent extends ConsumerWidget {
  const HomeContent({super.key});

  static const _primaryColor = Color(0xFFFF7034);
  static const _secondaryColor = Color(0xFF7D2D35);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF27272A) : Colors.white;

    final asyncCategorias = ref.watch(categoriasEstabelecimentoProvider);
    final asyncPadarias = ref.watch(padariaProximaProvider);

    return CustomScrollView(
      slivers: [
        // ─── Banner ────────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: PromoBanner(secondaryColor: _secondaryColor),
        ),

        // ─── Título Categorias ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
            child: Text(
              'Categorias',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : _secondaryColor,
              ),
            ),
          ),
        ),

        // ─── Lista horizontal de categorias ────────────────────────────────────
        SliverToBoxAdapter(
          child: SizedBox(
            height: 110,
            child: asyncCategorias.when(
              loading: () => _CategoriasSkeletonList(isDark: isDark),
              error: (_, __) => const SizedBox.shrink(),
              data: (categorias) {
                if (categorias.isEmpty) {
                  return Center(
                    child: Text(
                      'Sem categorias disponíveis',
                      style: GoogleFonts.outfit(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: categorias.length,
                  itemBuilder: (context, index) {
                    final cat = categorias[index];
                    return CategoryItem(
                      title: cat.nome,
                      imageUrl: cat.imagemUrl ?? '',
                      isDark: isDark,
                      onTap: () => context.push(
                        '/categoria/${cat.slug}',
                        extra: cat,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),

        // ─── Título "Padarias próximas" / "Mais bem avaliadas" ────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                asyncPadarias.when(
                  loading: () => Text(
                    'Padarias próximas',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : _secondaryColor,
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (result) => Text(
                    result.temLocalizacao
                        ? 'Padarias próximas'
                        : 'Outras padarias',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : _secondaryColor,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/padarias'),
                  child: Text(
                    'Ver todas',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ─── Banner: "Permitir localização" (Opção 2) ─────────────────────────
        SliverToBoxAdapter(
          child: asyncPadarias.maybeWhen(
            data: (result) => result.temLocalizacao
                ? const SizedBox.shrink()
                : _BannerLocalizacao(isDark: isDark),
            orElse: () => const SizedBox.shrink(),
          ),
        ),

        // ─── Lista de padarias ─────────────────────────────────────────────────
        asyncPadarias.when(
          loading: () => SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                List.generate(3, (_) => _PadariaCardSkeleton(isDark: isDark))
                    .expand((w) => [w, const SizedBox(height: 16)])
                    .toList(),
              ),
            ),
          ),
          error: (_, __) => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Não foi possível carregar as padarias.',
                  style: GoogleFonts.outfit(color: Colors.grey),
                ),
              ),
            ),
          ),
          data: (result) {
            if (result.padarias.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    children: [
                      Icon(Icons.store_outlined,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhuma padaria encontrada por aqui.',
                        style: GoogleFonts.outfit(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index.isOdd) return const SizedBox(height: 16);
                    final padaria = result.padarias[index ~/ 2];
                    return _PadariaCardFromModel(
                      padaria: padaria,
                      isDark: isDark,
                      cardColor: cardColor,
                      temLocalizacao: result.temLocalizacao,
                    );
                  },
                  childCount: result.padarias.length * 2 - 1,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─── Banner: solicitar localização (Opção 2) ──────────────────────────────────
class _BannerLocalizacao extends ConsumerStatefulWidget {
  final bool isDark;
  const _BannerLocalizacao({required this.isDark});

  @override
  ConsumerState<_BannerLocalizacao> createState() => _BannerLocalizacaoState();
}

class _BannerLocalizacaoState extends ConsumerState<_BannerLocalizacao> {
  bool _isLoading = false;

  Future<void> _solicitar() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final pos = await obterLocalizacao();
      if (pos != null) {
        // Obteve localização! Recarregar a lista da Home.
        ref.invalidate(padariaProximaProvider);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Não foi possível obter a localização. Permissão negada ou desativada.'),
              backgroundColor: Color(0xFFFF7034),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading ? null : _solicitar,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:
              widget.isDark ? const Color(0xFF2A2018) : const Color(0xFFFFF3EE),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFFF7034).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_rounded,
                color: Color(0xFFFF7034), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Permitir localização para ver padarias perto de você',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color:
                      widget.isDark ? Colors.white70 : const Color(0xFF7D2D35),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFF7034),
                    ),
                  )
                : Icon(Icons.arrow_forward_ios_rounded,
                    color: const Color(0xFFFF7034).withValues(alpha: 0.5),
                    size: 14),
          ],
        ),
      ),
    );
  }
}

// ─── Card de padaria construído a partir do PadariaModel ─────────────────────
class _PadariaCardFromModel extends StatelessWidget {
  final PadariaModel padaria;
  final bool isDark;
  final Color cardColor;
  final bool temLocalizacao;

  const _PadariaCardFromModel({
    required this.padaria,
    required this.isDark,
    required this.cardColor,
    required this.temLocalizacao,
  });

  @override
  Widget build(BuildContext context) {
    String feeLabel;
    final taxa = padaria.configEntrega?['taxa_entrega_fixa'];
    if (taxa == null) {
      feeLabel = 'Consultar';
    } else {
      final valor = double.tryParse(taxa.toString()) ?? 0.0;
      feeLabel = valor == 0
          ? 'Grátis'
          : 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
    }

    return BakeryCard(
      name: padaria.nome,
      description: padaria.descricao ?? '',
      rating: padaria.avaliacaoMedia.toStringAsFixed(1),
      time: padaria.statusAberto ? padaria.tempoMedioFormatado : 'Fechado',
      fee: padaria.statusAberto ? feeLabel : '',
      imageUrl: padaria.logoUrl ?? '',
      isDark: isDark,
      cardColor: cardColor,
      isClosed: !padaria.statusAberto,
    );
  }
}

// ─── Skeleton loader do card ──────────────────────────────────────────────────
class _PadariaCardSkeleton extends StatefulWidget {
  final bool isDark;
  const _PadariaCardSkeleton({required this.isDark});

  @override
  State<_PadariaCardSkeleton> createState() => _PadariaCardSkeletonState();
}

class _PadariaCardSkeletonState extends State<_PadariaCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isDark ? Colors.white : const Color(0xFF7D2D35);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: 90,
        decoration: BoxDecoration(
          color: baseColor.withValues(alpha: _anim.value * 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

// ─── Skeleton loader para categorias ─────────────────────────────────────────
class _CategoriasSkeletonList extends StatefulWidget {
  final bool isDark;
  const _CategoriasSkeletonList({required this.isDark});

  @override
  State<_CategoriasSkeletonList> createState() =>
      _CategoriasSkeletonListState();
}

class _CategoriasSkeletonListState extends State<_CategoriasSkeletonList>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _shimmer = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: 5,
          itemBuilder: (context, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: (widget.isDark
                              ? Colors.white
                              : const Color(0xFF7D2D35))
                          .withValues(alpha: _shimmer.value * 0.15),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 52,
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: (widget.isDark
                              ? Colors.white
                              : const Color(0xFF7D2D35))
                          .withValues(alpha: _shimmer.value * 0.12),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
