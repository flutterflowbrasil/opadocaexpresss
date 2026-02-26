import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:padoca_express/core/services/localizacao_service.dart';
import 'package:padoca_express/features/cliente/home/models/estabelecimento_model.dart';
import 'package:padoca_express/features/cliente/componentes/home_header.dart';
import 'package:padoca_express/features/cliente/componentes/estabelecimento_card.dart';

// ─── Provider de estabelecimentos por categoria ───────────────────────────────
final estabelecimentosPorCategoriaProvider =
    FutureProvider.family<List<EstabelecimentoModel>, String>(
        (ref, categoriaId) async {
  try {
    final response = await Supabase.instance.client
        .from('estabelecimentos')
        .select(
          'id, razao_social, descricao, logo_url, banner_url, '
          'avaliacao_media, total_avaliacoes, status_aberto, '
          'latitude, longitude, config_entrega, endereco',
        )
        .eq('categoria_estabelecimento_id', categoriaId)
        .order('avaliacao_media', ascending: false);

    return (response as List)
        .map((json) =>
            EstabelecimentoModel.fromJson(json as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
});

class CategoriaEstabelecimentosScreen extends ConsumerStatefulWidget {
  final String? categoriaId;
  final String categoriaSlug;
  final String categoriaNome;
  final String categoriaImagemUrl;

  const CategoriaEstabelecimentosScreen({
    super.key,
    this.categoriaId,
    required this.categoriaSlug,
    required this.categoriaNome,
    required this.categoriaImagemUrl,
  });

  @override
  ConsumerState<CategoriaEstabelecimentosScreen> createState() =>
      _CategoriaEstabelecimentosScreenState();
}

class _CategoriaEstabelecimentosScreenState
    extends ConsumerState<CategoriaEstabelecimentosScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _filtroAberto = false;
  bool _filtroProximos = false;
  double? _userLat;
  double? _userLng;

  late String _categoriaNome;
  late String _categoriaImagemUrl;
  String? _categoriaIdResolved;
  bool _carregandoCategoria = false;

  static const _primaryColor = Color(0xFFFF7034);
  static const _secondaryColor = Color(0xFF7D2D35);

  bool get _temFiltro => _filtroAberto || _filtroProximos;

  Future<void> _toggleFiltroProximos() async {
    if (_filtroProximos) {
      // Se estava ativo, apenas desliga
      setState(() => _filtroProximos = false);
      return;
    }

    // Tentar ligar o filtro buscando a localização
    setState(() => _filtroProximos = true); // UI reativa rápido

    final position = await obterLocalizacao();
    if (!mounted) return;

    if (position != null) {
      setState(() {
        _userLat = position.latitude;
        _userLng = position.longitude;
      });
    } else {
      // Se negou/falhou, reverte o filtro e avisa
      setState(() => _filtroProximos = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permita a localização para ordenar por proximidade.'),
          backgroundColor: _secondaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _categoriaNome = widget.categoriaNome;
    _categoriaImagemUrl = widget.categoriaImagemUrl;
    _categoriaIdResolved = widget.categoriaId;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    // Se viemos por link direto (ex: recarregar a página ou usar o botão voltar do navegador)
    // a rota no app_router.dart passa 'Categoria' e sem ID definido. Vamos buscar os dados reais via slug.
    if (_categoriaIdResolved == null ||
        _categoriaIdResolved!.isEmpty ||
        _categoriaNome == 'Categoria') {
      _carregarCategoriaDetalhes();
    }
  }

  Future<void> _carregarCategoriaDetalhes() async {
    setState(() => _carregandoCategoria = true);
    try {
      final response = await Supabase.instance.client
          .from('categorias_estabelecimento')
          .select('id, nome, imagem_url')
          .eq('slug', widget.categoriaSlug)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _categoriaIdResolved = response['id'] as String;
          _categoriaNome = response['nome'] as String;
          _categoriaImagemUrl = (response['imagem_url'] as String?) ?? '';
        });
      }
    } catch (_) {
      // Falha silenciosa: usa os fallbacks
    } finally {
      if (mounted) setState(() => _carregandoCategoria = false);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1917) : const Color(0xFFF9F5F0);
    final cardColor = isDark ? const Color(0xFF27272A) : Colors.white;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final isDesktop = screenWidth >= 900;
    final useGrid = isTablet || isDesktop;
    final crossAxisCount = isDesktop ? 3 : 2;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: ClienteAppBar(isDark: isDark, showBackButton: true),
      body: CustomScrollView(
        slivers: [
          // ─── AppBar com imagem da categoria ──────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: isDark ? const Color(0xFF1C1917) : _secondaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: _CategoriaAppBarBackground(
                isDark: isDark,
                imagemUrl: _categoriaImagemUrl,
                nome: _categoriaNome,
              ),
              titlePadding: const EdgeInsets.only(left: 20, bottom: 56),
              title: _carregandoCategoria
                  ? const SizedBox()
                  : Text(
                      _categoriaNome,
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          const Shadow(
                            color: Colors.black54,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
            ),
          ),

          // ─── Chips de filtro ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FiltroChip(
                      label: 'Abertos agora',
                      icon: Icons.access_time_rounded,
                      ativo: _filtroAberto,
                      isDark: isDark,
                      onTap: () =>
                          setState(() => _filtroAberto = !_filtroAberto),
                    ),
                    const SizedBox(width: 8),
                    _FiltroChip(
                      label: 'Mais próximos',
                      icon: Icons.near_me_rounded,
                      ativo: _filtroProximos,
                      isDark: isDark,
                      onTap: _toggleFiltroProximos,
                    ),
                    if (_temFiltro) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() {
                          _filtroAberto = false;
                          _filtroProximos = false;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.close_rounded,
                                  size: 14,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                'Limpar filtros',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ─── Lista de estabelecimentos ────────────────────────────────────
          if (_carregandoCategoria || _categoriaIdResolved == null)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: _primaryColor),
              ),
            )
          else
            Consumer(
              builder: (context, ref, _) {
                final asyncData = ref.watch(
                    estabelecimentosPorCategoriaProvider(
                        _categoriaIdResolved!));

                return asyncData.when(
                  loading: () => const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: _primaryColor,
                      ),
                    ),
                  ),
                  error: (err, _) => SliverFillRemaining(
                    child: _CategoriaErrorWidget(
                      onRetry: () => ref.refresh(
                        estabelecimentosPorCategoriaProvider(
                            _categoriaIdResolved!),
                      ),
                    ),
                  ),
                  data: (estabelecimentos) {
                    // ── Aplicar filtros ──────────────────────────────────────
                    var filtered = estabelecimentos;

                    if (_filtroAberto) {
                      filtered = filtered.where((e) => e.statusAberto).toList();
                    }

                    if (_filtroProximos &&
                        _userLat != null &&
                        _userLng != null) {
                      filtered = [...filtered];
                      filtered.sort((a, b) {
                        double distA = double.maxFinite;
                        double distB = double.maxFinite;
                        if (a.latitude != null && a.longitude != null) {
                          final dlat = a.latitude! - _userLat!;
                          final dlng = a.longitude! - _userLng!;
                          distA = dlat * dlat + dlng * dlng;
                        }
                        if (b.latitude != null && b.longitude != null) {
                          final dlat = b.latitude! - _userLat!;
                          final dlng = b.longitude! - _userLng!;
                          distB = dlat * dlat + dlng * dlng;
                        }
                        return distA.compareTo(distB);
                      });

                      // Extra limitando raio (5km), usando Geolocator built-in utility
                      filtered.removeWhere((e) {
                        if (e.latitude == null || e.longitude == null) {
                          return true;
                        }

                        final distanceInMeters = Geolocator.distanceBetween(
                          _userLat!,
                          _userLng!,
                          e.latitude!,
                          e.longitude!,
                        );

                        return distanceInMeters > 5000.0; // raio de 5km = 5000m
                      });
                    }

                    if (estabelecimentos.isEmpty) {
                      return SliverList(
                        delegate: SliverChildListDelegate([
                          _CategoriaEmptyWidget(
                            isDark: isDark,
                            nome: _categoriaNome,
                          ),
                          if (_filtroProximos && _userLat == null)
                            _BannerLocalizacao(
                              isDark: isDark,
                              onLocationGranted: (lat, lng) {
                                setState(() {
                                  _userLat = lat;
                                  _userLng = lng;
                                });
                              },
                            )
                        ]),
                      );
                    }

                    if (filtered.isEmpty && _filtroProximos) {
                      return SliverList(
                        delegate: SliverChildListDelegate([
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 40, horizontal: 20),
                            child: Center(
                              child: Text(
                                'Nenhum estabelecimento num raio de 5km.',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          if (_userLat == null)
                            _BannerLocalizacao(
                              isDark: isDark,
                              onLocationGranted: (lat, lng) {
                                setState(() {
                                  _userLat = lat;
                                  _userLng = lng;
                                });
                              },
                            ),
                        ]),
                      );
                    }

                    final gap = 16.0;
                    final hPad = 20.0;
                    const maxCardWidth = 340.0;
                    final totalWidth = MediaQuery.of(context).size.width;
                    final cardWidth = min(
                      (totalWidth - hPad * 2 - gap * (crossAxisCount - 1)) /
                          crossAxisCount,
                      maxCardWidth,
                    );

                    return useGrid
                        // ── Grade (tablet / desktop) — altura pelo conteúdo ──
                        ? SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 12, 20, 24),
                              child: Wrap(
                                spacing: gap,
                                runSpacing: gap,
                                children:
                                    List.generate(filtered.length, (index) {
                                  final estabelecimento = filtered[index];
                                  return SizedBox(
                                    width: cardWidth,
                                    child: AnimatedBuilder(
                                      animation: _animController,
                                      builder: (context, child) {
                                        final delay = index * 0.10;
                                        final t =
                                            (_animController.value - delay)
                                                .clamp(0.0, 1.0);
                                        final curved =
                                            Curves.easeOutCubic.transform(t);
                                        return Opacity(
                                          opacity: curved,
                                          child: Transform.translate(
                                            offset:
                                                Offset(0, 30 * (1 - curved)),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: EstabelecimentoCard(
                                        estabelecimento: estabelecimento,
                                        isDark: isDark,
                                        cardColor: cardColor,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          )
                        // ── Lista (mobile) ─────────────────────────────────────
                        : SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final estabelecimento = filtered[index];
                                  return AnimatedBuilder(
                                    animation: _animController,
                                    builder: (context, child) {
                                      final delay = index * 0.10;
                                      final t = (_animController.value - delay)
                                          .clamp(0.0, 1.0);
                                      final curved =
                                          Curves.easeOutCubic.transform(t);
                                      return Opacity(
                                        opacity: curved,
                                        child: Transform.translate(
                                          offset: Offset(0, 30 * (1 - curved)),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16),
                                      child: EstabelecimentoCard(
                                        estabelecimento: estabelecimento,
                                        isDark: isDark,
                                        cardColor: cardColor,
                                      ),
                                    ),
                                  );
                                },
                                childCount: filtered.length,
                              ),
                            ),
                          );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

// ─── Chip de filtro ───────────────────────────────────────────────────────────
class _FiltroChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool ativo;
  final bool isDark;
  final VoidCallback onTap;

  static const _primaryColor = Color(0xFFFF7034);

  const _FiltroChip({
    required this.label,
    required this.icon,
    required this.ativo,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgAtivo = _primaryColor;
    final bgInativo = isDark ? const Color(0xFF3A3A3A) : Colors.white;
    final borderColor = ativo
        ? Colors.transparent
        : (isDark ? Colors.grey[700]! : Colors.grey[300]!);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: ativo ? bgAtivo : bgInativo,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: ativo
              ? [
                  BoxShadow(
                    color: _primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: ativo
                  ? Colors.white
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: ativo ? FontWeight.w600 : FontWeight.w500,
                color: ativo
                    ? Colors.white
                    : (isDark ? Colors.grey[300] : Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── AppBar Background com imagem da categoria ───────────────────────────────
class _CategoriaAppBarBackground extends StatelessWidget {
  final bool isDark;
  final String? imagemUrl;
  final String nome;

  const _CategoriaAppBarBackground({
    required this.isDark,
    required this.imagemUrl,
    required this.nome,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Imagem ou gradiente fallback
        if (imagemUrl != null && imagemUrl!.isNotEmpty)
          Image.network(
            imagemUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _gradientFallback(isDark),
          )
        else
          _gradientFallback(isDark),

        // ─── Nome e Overlay ──────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.2),
                Colors.black.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _gradientFallback(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF3D1515), const Color(0xFF1C0E0E)]
              : [const Color(0xFF9B1515), const Color(0xFF7D2D35)],
        ),
      ),
    );
  }
}

// ─── Banner: solicitar localização (Opção 2) ──────────────────────────────────
class _BannerLocalizacao extends ConsumerStatefulWidget {
  final bool isDark;
  final Function(double lat, double lng)? onLocationGranted;

  const _BannerLocalizacao({
    required this.isDark,
    this.onLocationGranted,
  });

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
        if (widget.onLocationGranted != null) {
          widget.onLocationGranted!(pos.latitude, pos.longitude);
          return;
        }
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
            if (_isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFFF7034),
                ),
              )
            else
              Icon(Icons.arrow_forward_ios_rounded,
                  color: const Color(0xFFFF7034).withValues(alpha: 0.5),
                  size: 14),
          ],
        ),
      ),
    );
  }
}

class _CategoriaEmptyWidget extends StatelessWidget {
  final bool isDark;
  final String nome;
  const _CategoriaEmptyWidget({required this.isDark, required this.nome});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF7034), Color(0xFF7D2D35)],
                ),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                Icons.store_rounded,
                size: 52,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhum estabelecimento cadastrado ainda!',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF7D2D35),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Em breve teremos novidades\nnessa categoria!',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriaErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;
  const _CategoriaErrorWidget({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar estabelecimentos',
            style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7034),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
