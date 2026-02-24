import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padoca_express/features/cliente/padarias/models/padaria_model.dart';
import 'package:padoca_express/features/cliente/padarias/repositories/padaria_repository.dart';

class PadariaListScreen extends ConsumerStatefulWidget {
  const PadariaListScreen({super.key});

  @override
  ConsumerState<PadariaListScreen> createState() => _PadariaListScreenState();
}

class _PadariaListScreenState extends ConsumerState<PadariaListScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const _primaryColor = Color(0xFFFF7034);
  static const _secondaryColor = Color(0xFF7D2D35);

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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1917) : const Color(0xFFF9F5F0);
    final cardColor = isDark ? const Color(0xFF27272A) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // ─── AppBar bonita ───────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF1C1917) : _secondaryColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _AppBarBackground(isDark: isDark),
              titlePadding: const EdgeInsets.only(left: 20, bottom: 56),
              title: Text(
                'Padarias',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: _SearchBar(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
          ),

          // ─── Chip de destaque "Mais próximas" ────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                children: [
                  _buildChip(
                    icon: Icons.near_me_rounded,
                    label: 'Mais próximas',
                    selected: true,
                  ),
                  const SizedBox(width: 8),
                  _buildChip(
                    icon: Icons.star_rounded,
                    label: 'Melhor avaliadas',
                    selected: false,
                  ),
                  const SizedBox(width: 8),
                  _buildChip(
                    icon: Icons.local_offer_rounded,
                    label: 'Abertas',
                    selected: false,
                  ),
                ],
              ),
            ),
          ),

          // ─── Lista de padarias ───────────────────────────────────────
          Consumer(
            builder: (context, ref, _) {
              final asyncPadarias = ref.watch(padariaListProvider);

              return asyncPadarias.when(
                loading: () => SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  ),
                ),
                error: (err, _) => SliverFillRemaining(
                  child: _ErrorWidget(
                    onRetry: () => ref.refresh(padariaListProvider),
                  ),
                ),
                data: (padarias) {
                  // Filtra por busca
                  final filtered = padarias
                      .where((p) =>
                          _searchQuery.isEmpty ||
                          p.nome.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ))
                      .toList();

                  if (padarias.isEmpty) {
                    return SliverFillRemaining(
                      child: _EmptyWidget(isDark: isDark),
                    );
                  }

                  if (filtered.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'Nenhuma padaria encontrada\npara "$_searchQuery"',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final padaria = filtered[index];
                          return AnimatedBuilder(
                            animation: _animController,
                            builder: (context, child) {
                              final delay = index * 0.12;
                              final t = (_animController.value - delay)
                                  .clamp(0.0, 1.0);
                              final curved = Curves.easeOutCubic.transform(t);
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
                              child: _PadariaCard(
                                padaria: padaria,
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

  Widget _buildChip({
    required IconData icon,
    required String label,
    required bool selected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? _primaryColor : Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: selected ? Colors.white : Colors.grey),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Background do AppBar ──────────────────────────────────────────────────────
class _AppBarBackground extends StatelessWidget {
  final bool isDark;
  const _AppBarBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
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
      child: Stack(
        children: [
          // Ícone decorativo de fundo
          Positioned(
            right: -20,
            top: -10,
            child: Icon(
              Icons.bakery_dining_rounded,
              size: 180,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Positioned(
            left: -30,
            bottom: 30,
            child: Icon(
              Icons.coffee_rounded,
              size: 120,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SearchBar ────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.outfit(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Buscar padaria...',
          hintStyle: GoogleFonts.outfit(
            color: Colors.white.withValues(alpha: 0.6),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

// ─── Card de Padaria ─────────────────────────────────────────────────────────
class _PadariaCard extends StatelessWidget {
  final PadariaModel padaria;
  final bool isDark;
  final Color cardColor;

  static const _primaryColor = Color(0xFFFF7034);
  static const _secondaryColor = Color(0xFF7D2D35);

  const _PadariaCard({
    required this.padaria,
    required this.isDark,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // TODO: Navegar para o detalhe da padaria
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Em breve: detalhes de ${padaria.nome}'),
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
              // ── Banner / Logo ──────────────────────────────────────────
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                child: Stack(
                  children: [
                    // Imagem banner
                    Container(
                      height: 120,
                      width: double.infinity,
                      color: isDark
                          ? const Color(0xFF3A3A3A)
                          : const Color(0xFFEDE8E3),
                      child: padaria.bannerUrl != null
                          ? Image.network(
                              padaria.bannerUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _PlaceholderBanner(isDark: isDark),
                            )
                          : padaria.logoUrl != null
                              ? Image.network(
                                  padaria.logoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _PlaceholderBanner(isDark: isDark),
                                )
                              : _PlaceholderBanner(isDark: isDark),
                    ),
                    // Badge status
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _StatusBadge(isOpen: padaria.statusAberto),
                    ),
                    // Gradiente
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

              // ── Infos ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo circular
                    if (padaria.logoUrl != null)
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
                            padaria.logoUrl!,
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
                            padaria.nome,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : _secondaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (padaria.descricao != null &&
                              padaria.descricao!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                padaria.descricao!,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          const SizedBox(height: 10),
                          // Linha de info (avaliação + tempo + taxa)
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 15, color: Colors.amber),
                              const SizedBox(width: 3),
                              Text(
                                padaria.avaliacaoMedia.toStringAsFixed(1),
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
                                padaria.statusAberto
                                    ? padaria.tempoMedioFormatado
                                    : 'Fechado',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: padaria.statusAberto
                                      ? Colors.grey[500]
                                      : Colors.red[400],
                                  fontWeight: padaria.statusAberto
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                              ),
                              _dot(),
                              const Icon(Icons.delivery_dining_rounded,
                                  size: 13, color: Colors.grey),
                              const SizedBox(width: 3),
                              Text(
                                padaria.taxaEntregaFormatada,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color:
                                      padaria.taxaEntregaFormatada == 'Grátis'
                                          ? Colors.green[600]
                                          : Colors.grey[500],
                                  fontWeight:
                                      padaria.taxaEntregaFormatada == 'Grátis'
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          if (padaria.bairro.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                children: [
                                  Icon(Icons.location_on_rounded,
                                      size: 13,
                                      color:
                                          _primaryColor.withValues(alpha: 0.7)),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${padaria.bairro}${padaria.cidade.isNotEmpty ? ' - ${padaria.cidade}' : ''}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Seta
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

// ─── Badge de status ──────────────────────────────────────────────────────────
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

// ─── Placeholder Banner ───────────────────────────────────────────────────────
class _PlaceholderBanner extends StatelessWidget {
  final bool isDark;
  const _PlaceholderBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFEDE8E3),
      child: Center(
        child: Icon(
          Icons.bakery_dining_rounded,
          size: 56,
          color: isDark
              ? Colors.white24
              : const Color(0xFF7D2D35).withValues(alpha: 0.2),
        ),
      ),
    );
  }
}

// ─── Estado vazio ─────────────────────────────────────────────────────────────
class _EmptyWidget extends StatelessWidget {
  final bool isDark;
  const _EmptyWidget({required this.isDark});

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
                Icons.bakery_dining_rounded,
                size: 52,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhuma padaria\ncadastrada ainda',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF7D2D35),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Em breve teremos padarias\npróximas a você!',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Estado de erro ───────────────────────────────────────────────────────────
class _ErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorWidget({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar padarias',
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
