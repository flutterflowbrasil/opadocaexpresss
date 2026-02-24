import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:padoca_express/core/services/localizacao_service.dart';
import 'package:padoca_express/features/cliente/padarias/models/padaria_model.dart';
import 'package:padoca_express/features/cliente/componentes/home_header.dart';

// ─── Provider de estabelecimentos por categoria ───────────────────────────────
final estabelecimentosPorCategoriaProvider =
    FutureProvider.family<List<PadariaModel>, String>((ref, categoriaId) async {
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
        .map((json) => PadariaModel.fromJson(json as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
});

class CategoriaEstabelecimentosScreen extends ConsumerStatefulWidget {
  final String categoriaId;
  final String categoriaNome;
  final String categoriaImagemUrl;

  const CategoriaEstabelecimentosScreen({
    super.key,
    required this.categoriaId,
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
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
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
      appBar: ClienteAppBar(isDark: isDark),
      body: CustomScrollView(
        slivers: [
          // ─── AppBar com imagem da categoria ──────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF1C1917) : _secondaryColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _CategoriaAppBarBackground(
                isDark: isDark,
                imagemUrl: widget.categoriaImagemUrl,
                nome: widget.categoriaNome,
              ),
              titlePadding: const EdgeInsets.only(left: 20, bottom: 56),
              title: Text(
                widget.categoriaNome,
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
          Consumer(
            builder: (context, ref, _) {
              final asyncData = ref.watch(
                  estabelecimentosPorCategoriaProvider(widget.categoriaId));

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
                      estabelecimentosPorCategoriaProvider(widget.categoriaId),
                    ),
                  ),
                ),
                data: (estabelecimentos) {
                  // ── Aplicar filtros ──────────────────────────────────────
                  var filtered = estabelecimentos;

                  if (_filtroAberto) {
                    filtered = filtered.where((e) => e.statusAberto).toList();
                  }

                  if (_filtroProximos && _userLat != null && _userLng != null) {
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
                      if (e.latitude == null || e.longitude == null)
                        return true;

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
                          nome: widget.categoriaNome,
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
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                            child: Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: List.generate(filtered.length, (index) {
                                final estabelecimento = filtered[index];
                                return SizedBox(
                                  width: cardWidth,
                                  child: AnimatedBuilder(
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
                                    child: _EstabelecimentoCard(
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
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _EstabelecimentoCard(
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

  _FiltroChip({
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

        // Overlay escuro para legibilidade do título
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.2),
                Colors.black.withValues(alpha: 0.6),
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

// ─── Card do estabelecimento ──────────────────────────────────────────────────
class _EstabelecimentoCard extends StatelessWidget {
  final PadariaModel estabelecimento;
  final bool isDark;
  final Color cardColor;

  static const _primaryColor = Color(0xFFFF7034);
  static const _secondaryColor = Color(0xFF7D2D35);

  const _EstabelecimentoCard({
    required this.estabelecimento,
    required this.isDark,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // TODO: navegar para detalhes do estabelecimento
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Em breve: detalhes de ${estabelecimento.nome}'),
              backgroundColor: _primaryColor,
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                child: Stack(
                  children: [
                    Container(
                      height: 90,
                      width: double.infinity,
                      color: isDark
                          ? const Color(0xFF3A3A3A)
                          : const Color(0xFFEDE8E3),
                      child: estabelecimento.bannerUrl != null
                          ? Image.network(
                              estabelecimento.bannerUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _PlaceholderBanner(isDark: isDark),
                            )
                          : estabelecimento.logoUrl != null
                              ? Image.network(
                                  estabelecimento.logoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _PlaceholderBanner(isDark: isDark),
                                )
                              : _PlaceholderBanner(isDark: isDark),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _StatusBadge(isOpen: estabelecimento.statusAberto),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.15),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Infos
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (estabelecimento.logoUrl != null)
                      Container(
                        width: 48,
                        height: 48,
                        margin: const EdgeInsets.only(right: 12, top: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _primaryColor.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            estabelecimento.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFEDE8E3),
                              child: const Icon(Icons.store_rounded,
                                  size: 24, color: Color(0x337D2D35)),
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            estabelecimento.nome,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : _secondaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (estabelecimento.descricao != null &&
                              estabelecimento.descricao!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                estabelecimento.descricao!,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 15, color: Colors.amber),
                              const SizedBox(width: 3),
                              Text(
                                estabelecimento.avaliacaoMedia
                                    .toStringAsFixed(1),
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber[700],
                                ),
                              ),
                              _dot(),
                              const Icon(Icons.access_time_rounded,
                                  size: 13, color: Colors.grey),
                              const SizedBox(width: 3),
                              Text(
                                estabelecimento.statusAberto
                                    ? estabelecimento.tempoMedioFormatado
                                    : 'Fechado',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: estabelecimento.statusAberto
                                      ? Colors.grey[500]
                                      : Colors.red[400],
                                  fontWeight: estabelecimento.statusAberto
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                              ),
                              _dot(),
                              const Icon(Icons.delivery_dining_rounded,
                                  size: 13, color: Colors.grey),
                              const SizedBox(width: 3),
                              Text(
                                estabelecimento.taxaEntregaFormatada,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: estabelecimento.taxaEntregaFormatada ==
                                          'Grátis'
                                      ? Colors.green[600]
                                      : Colors.grey[500],
                                  fontWeight:
                                      estabelecimento.taxaEntregaFormatada ==
                                              'Grátis'
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          if (estabelecimento.bairro.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                children: [
                                  Icon(Icons.location_on_rounded,
                                      size: 13,
                                      color:
                                          _primaryColor.withValues(alpha: 0.7)),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      '${estabelecimento.bairro}'
                                      '${estabelecimento.cidade.isNotEmpty ? ' - ${estabelecimento.cidade}' : ''}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.grey,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(
          color: Colors.grey[400],
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isOpen;
  const _StatusBadge({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green[600] : Colors.red[700],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isOpen ? Colors.green : Colors.red).withValues(alpha: 0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        isOpen ? '● Aberto' : '● Fechado',
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _PlaceholderBanner extends StatelessWidget {
  final bool isDark;
  const _PlaceholderBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFEDE8E3),
      child: Center(
        child: Icon(
          Icons.store_rounded,
          size: 56,
          color: isDark
              ? Colors.white24
              : const Color(0xFF7D2D35).withValues(alpha: 0.2),
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
