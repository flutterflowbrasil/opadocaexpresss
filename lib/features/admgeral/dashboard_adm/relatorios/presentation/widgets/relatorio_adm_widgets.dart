import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

// ── Paleta ────────────────────────────────────────────────────────────────────
const _kPrimary  = Color(0xFF8B5CF6);
const _kGreen    = Color(0xFF10B981);
const _kOrange   = Color(0xFFF97316);
const _kBlue     = Color(0xFF3B82F6);
const _kRed      = Color(0xFFEF4444);
const _kAmber    = Color(0xFFF59E0B);
const _kBorder   = Color(0xFFEAE8E4);
const _kText     = Color(0xFF1A0910);
const _kHint     = Color(0xFF9CA3AF);
const _kSub      = Color(0xFF6B7280);
const _kBg       = Color(0xFFF4F2EF);

// ── Formatters ────────────────────────────────────────────────────────────────
String fmtBrl(double v) {
  if (v >= 1000) {
    return 'R\$ ${(v / 1000).toStringAsFixed(1)}k';
  }
  return 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';
}

String fmtN(int v) => v.toString();
String fmtPct(double v) => '${v.toStringAsFixed(1)}%';

// ── Shimmer skeleton ──────────────────────────────────────────────────────────
class _Skel extends StatelessWidget {
  final double h;
  final double? w;
  const _Skel({this.h = 14, this.w});

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: const Color(0xFFF3F4F6),
        highlightColor: const Color(0xFFE5E7EB),
        child: Container(
          height: h,
          width: w,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      );
}

// ── KPI Card ─────────────────────────────────────────────────────────────────
class KpiCardRelatorio extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;
  final Color bg;
  final String icon;
  final double? trend;
  final bool loading;

  const KpiCardRelatorio({
    super.key,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.bg,
    required this.icon,
    this.trend,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _kHint,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(icon, style: const TextStyle(fontSize: 18)),
            ],
          ),
          const SizedBox(height: 10),
          loading
              ? const _Skel(h: 26, w: 90)
              : Text(
                  value,
                  style: GoogleFonts.dmSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (trend != null) ...[
                Icon(
                  trend! > 0 ? Icons.trending_up : Icons.trending_down,
                  size: 13,
                  color: trend! > 0 ? _kGreen : _kRed,
                ),
                const SizedBox(width: 3),
                Text(
                  '${trend!.abs().toStringAsFixed(0)}%',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: trend! > 0 ? _kGreen : _kRed,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  sub,
                  style: GoogleFonts.dmSans(fontSize: 10, color: _kHint),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Seção container ───────────────────────────────────────────────────────────
class SecaoRelatorio extends StatelessWidget {
  final String titulo;
  final String? sub;
  final Widget child;
  final Widget? action;

  const SecaoRelatorio({
    super.key,
    required this.titulo,
    this.sub,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kText,
                      ),
                    ),
                    if (sub != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        sub!,
                        style: GoogleFonts.dmSans(fontSize: 11, color: _kHint),
                      ),
                    ],
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ── Seletor de Período ────────────────────────────────────────────────────────
class RelatorioFilterBar extends StatelessWidget {
  final String periodo;
  final ValueChanged<String> onChanged;

  const RelatorioFilterBar({
    super.key,
    required this.periodo,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const opcoes = [
      ('7d', '7 dias'),
      ('30d', '30 dias'),
      ('12m', '12 meses'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: opcoes.map((o) {
          final isActive = o.$1 == periodo;
          return GestureDetector(
            onTap: () => onChanged(o.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: isActive
                    ? Border.all(color: _kPrimary.withValues(alpha: 0.3))
                    : null,
                boxShadow: isActive
                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)]
                    : null,
              ),
              child: Text(
                o.$2,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive ? _kPrimary : _kSub,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Funil de conversão ────────────────────────────────────────────────────────
class FunilConversao extends StatelessWidget {
  final List<Map<String, dynamic>> funil;

  const FunilConversao({super.key, required this.funil});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: funil.map((f) {
        final pct = (f['pct'] as int).toDouble();
        final color = pct == 100
            ? _kGreen
            : pct >= 50
                ? _kOrange
                : _kRed;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    f['etapa'] as String,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${f['valor']}',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _kText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${pct.toInt()}%',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFF3F1EE),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Barra de distribuição pagamento ──────────────────────────────────────────
class DistribuicaoPagamento extends StatelessWidget {
  final Map<String, int> dist;

  const DistribuicaoPagamento({super.key, required this.dist});

  @override
  Widget build(BuildContext context) {
    final cores = {
      'PIX': _kGreen,
      'Crédito': _kBlue,
      'Débito': _kPrimary,
      'Dinheiro': _kAmber,
    };
    final total = dist.values.fold(0, (a, b) => a + b);

    return Column(
      children: dist.entries.map((e) {
        final pct = total > 0 ? e.value / total : 0.0;
        final cor = cores[e.key] ?? _kHint;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: cor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Text(
                  e.key,
                  style: GoogleFonts.dmSans(fontSize: 11, color: _kSub),
                ),
              ),
              Expanded(
                flex: 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFF3F1EE),
                    valueColor: AlwaysStoppedAnimation(cor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${e.value}',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _kText,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Ranking card ──────────────────────────────────────────────────────────────
class RankingRow extends StatelessWidget {
  final int posicao;
  final String nome;
  final String sub;
  final String badge;
  final Color badgeColor;
  final Color badgeBg;

  const RankingRow({
    super.key,
    required this.posicao,
    required this.nome,
    required this.sub,
    required this.badge,
    required this.badgeColor,
    required this.badgeBg,
  });

  @override
  Widget build(BuildContext context) {
    final posColors = [_kOrange, _kHint, const Color(0xFFCD7F32)];
    final bgColor = posicao < 3 ? posColors[posicao] : _kHint;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F8F7),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              '${posicao + 1}',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kText,
                  ),
                ),
                Text(sub,
                    style: GoogleFonts.dmSans(fontSize: 10, color: _kHint)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge,
              style: GoogleFonts.dmSans(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class RelatorioEmptyState extends StatelessWidget {
  final String emoji;
  final String titulo;
  final String subtitulo;

  const RelatorioEmptyState({
    super.key,
    required this.emoji,
    required this.titulo,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 10),
            Text(
              titulo,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitulo,
              style: GoogleFonts.dmSans(fontSize: 11, color: _kHint),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}

// ── Barras simples verticais ──────────────────────────────────────────────────
class SimpleBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String xKey;
  final List<({String key, Color color, String label})> bars;
  final double height;

  const SimpleBarChart({
    super.key,
    required this.data,
    required this.xKey,
    required this.bars,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text('Sem dados', style: TextStyle(color: _kHint, fontSize: 12)),
        ),
      );
    }

    double maxVal = 1;
    for (final b in bars) {
      for (final d in data) {
        final v = (d[b.key] as num?)?.toDouble() ?? 0;
        if (v > maxVal) maxVal = v;
      }
    }

    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((d) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: bars.map((b) {
                            final v = (d[b.key] as num?)?.toDouble() ?? 0;
                            final barH = maxVal > 0
                                ? ((v / maxVal) * (height - 28)).clamp(2.0, height - 28)
                                : 2.0;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 1),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                  child: Container(height: barH, color: b.color),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: data.map((d) {
              return Expanded(
                child: Text(
                  '${d[xKey]}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(fontSize: 9, color: _kHint),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Legenda de série ──────────────────────────────────────────────────────────
class SeriesLegend extends StatelessWidget {
  final List<({Color color, String label})> series;

  const SeriesLegend({super.key, required this.series});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 12,
        children: series.map((s) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: s.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(s.label,
                  style: GoogleFonts.dmSans(fontSize: 10, color: _kHint)),
            ],
          );
        }).toList(),
      );
}
