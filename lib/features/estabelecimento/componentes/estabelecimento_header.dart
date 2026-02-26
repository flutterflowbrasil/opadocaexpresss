import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padoca_express/features/cliente/home/models/estabelecimento_model.dart';

class EstabelecimentoHeader extends StatelessWidget {
  final EstabelecimentoModel estabelecimento;
  final bool isDark;

  const EstabelecimentoHeader({
    super.key,
    required this.estabelecimento,
    required this.isDark,
  });

  static const _primaryColor = Color(0xFFFF7034);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      automaticallyImplyLeading: false, // O ClienteAppBar agora cuida de voltar
      backgroundColor: isDark ? const Color(0xFF1C1917) : Colors.white,
      iconTheme: IconThemeData(
          color: _primaryColor, // Ensure back button is visible
          shadows: [
            Shadow(
              color: isDark ? Colors.black54 : Colors.white70,
              blurRadius: 10,
            )
          ]),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Banner Background
            if (estabelecimento.bannerUrl != null)
              Image.network(
                estabelecimento.bannerUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: isDark
                      ? const Color(0xFF3A3A3A)
                      : const Color(0xFFEDE8E3),
                  child: Center(
                    child: Icon(
                      Icons.storefront_rounded,
                      size: 64,
                      color: isDark ? Colors.white24 : Colors.grey[300],
                    ),
                  ),
                ),
              )
            else
              Container(
                color:
                    isDark ? const Color(0xFF3A3A3A) : const Color(0xFFEDE8E3),
                child: Center(
                  child: Icon(
                    Icons.storefront_rounded,
                    size: 64,
                    color: isDark ? Colors.white24 : Colors.grey[300],
                  ),
                ),
              ),

            // Gradient Overlay
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (isDark ? Colors.black : Colors.white)
                        .withValues(alpha: 0.2),
                    (isDark ? const Color(0xFF1C1917) : Colors.white)
                        .withValues(alpha: 1.0),
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),

            // Content
            Positioned(
              bottom: 16,
              left: 20,
              right: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Logo
                  Hero(
                    tag: 'logo_${estabelecimento.id}',
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0xFF27272A) : Colors.white,
                        border: Border.all(
                          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: estabelecimento.logoUrl != null
                            ? Image.network(
                                estabelecimento.logoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                    Icons.store_rounded,
                                    size: 36,
                                    color: Colors.grey[400]),
                              )
                            : Icon(Icons.store_rounded,
                                size: 36, color: Colors.grey[400]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Text Info
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          estabelecimento.nome,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.white : const Color(0xFF7D2D35),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              estabelecimento.avaliacaoMedia.toStringAsFixed(1),
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[700],
                              ),
                            ),
                            _buildDot(),
                            Icon(Icons.access_time_rounded,
                                size: 14,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              estabelecimento.statusAberto
                                  ? estabelecimento.tempoMedioFormatado
                                  : 'Fechado',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: estabelecimento.statusAberto
                                    ? (isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[700])
                                    : Colors.red[500],
                                fontWeight: estabelecimento.statusAberto
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[400],
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
