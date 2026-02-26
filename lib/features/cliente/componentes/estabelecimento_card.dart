import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padoca_express/features/cliente/home/models/estabelecimento_model.dart';

// ─── Card do estabelecimento ──────────────────────────────────────────────────
class EstabelecimentoCard extends StatelessWidget {
  final EstabelecimentoModel estabelecimento;
  final bool isDark;
  final Color cardColor;

  static const _primaryColor = Color(0xFFFF7034);
  static const _secondaryColor = Color(0xFF7D2D35);

  const EstabelecimentoCard({
    super.key,
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
          context.push('/estabelecimento/${estabelecimento.id}',
              extra: estabelecimento);
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
                              Flexible(
                                child: Text(
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
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _dot(),
                              const Icon(Icons.delivery_dining_rounded,
                                  size: 13, color: Colors.grey),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  estabelecimento.taxaEntregaFormatada,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color:
                                        estabelecimento.taxaEntregaFormatada ==
                                                'Grátis'
                                            ? Colors.green[600]
                                            : Colors.grey[500],
                                    fontWeight:
                                        estabelecimento.taxaEntregaFormatada ==
                                                'Grátis'
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (estabelecimento.bairro?.isNotEmpty == true)
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
                                      '${(estabelecimento.cidade?.isNotEmpty ?? false) ? ' - ${estabelecimento.cidade}' : ''}',
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
