import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// --- FORMATADORES ---
String fmtMoeda(double v) {
  return NumberFormat.currency(locale: 'pt_BR', symbol: r'R$').format(v);
}

String fmtNum(int v) {
  return NumberFormat.decimalPattern('pt_BR').format(v);
}

String fmtDataShort(DateTime d) {
  return DateFormat('dd/MM').format(d);
}

// --- CARD BASE ---
class CardContainer extends StatelessWidget {
  final Widget child;
  const CardContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEBEB)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}

class CardHead extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? right;
  final String? sub;

  const CardHead(
      {super.key, required this.title, this.icon, this.right, this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
                const SizedBox(width: 8),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.publicSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF111827))),
                  if (sub != null)
                    Text(sub!,
                        style: GoogleFonts.publicSans(
                            fontSize: 10, color: const Color(0xFF9CA3AF))),
                ],
              ),
            ],
          ),
          if (right != null) right!,
        ],
      ),
    );
  }
}

// --- KPI CARD ---
class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final Color color;
  final Color bg;
  final IconData icon;
  final List<double>? sparkData;
  final bool loading;

  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    this.sub,
    required this.color,
    required this.bg,
    required this.icon,
    this.sparkData,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                      color: bg, borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 18),
                ),
                if (sparkData != null && sparkData!.isNotEmpty)
                  SizedBox(
                    width: 60,
                    height: 36,
                    child: CustomPaint(
                      painter: SparklinePainter(data: sparkData!, color: color),
                    ),
                  )
              ],
            ),
            const SizedBox(height: 8),
            if (loading) ...[
              Container(
                  height: 28,
                  width: 80,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 6),
              Container(
                  height: 12,
                  width: 60,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(5))),
            ] else ...[
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value,
                    style: GoogleFonts.publicSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                        height: 1)),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: GoogleFonts.publicSans(
                        fontSize: 11, color: const Color(0xFF9CA3AF))),
              ),
              if (sub != null)
                Flexible(
                  child: Text(sub!,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: GoogleFonts.publicSans(
                          fontSize: 10, color: const Color(0xFF9CA3AF))),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// Sparkline Painter
class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    if (data.length == 1) {
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), 3, Paint()..color = color);
      return;
    }

    final maxVal = data.reduce(max) == 0 ? 1 : data.reduce(max);
    final minVal = data.reduce(min);
    final range = (maxVal - minVal) == 0 ? 1 : (maxVal - minVal);

    final path = Path();
    final fillPath = Path();

    final dx = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * dx;
      final y =
          size.height - (((data[i] - minVal) / range) * (size.height - 4)) - 2;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      if (i == data.length - 1) {
        fillPath.lineTo(x, size.height);

        // Draw last dot
        canvas.drawCircle(Offset(x, y), 3, Paint()..color = color);
      }
    }

    fillPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.0)],
    );

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader =
            gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- BAR CHART ---
class BarChartItem {
  final String label;
  final double value;
  BarChartItem(this.label, this.value);
}

class BarChartWidget extends StatelessWidget {
  final List<BarChartItem> data;
  final Color color;
  final double height;

  const BarChartWidget(
      {super.key, required this.data, required this.color, this.height = 100});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
          height: height,
          decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8)));
    }

    final maxVal = data.map((e) => e.value).reduce(max);
    final safeMax = maxVal == 0 ? 1 : maxVal;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((d) {
          final pct = d.value / safeMax;
          final barH = max<double>(pct * (height - 24), d.value > 0 ? 4 : 0);

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                        width: double.infinity,
                        height: barH,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.9),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  d.label,
                  style: GoogleFonts.publicSans(
                      fontSize: 9, color: const Color(0xFF9CA3AF)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// --- DONUT CHART (CustomPainter Simple) ---
class DonutSlice {
  final double value;
  final Color color;
  DonutSlice(this.value, this.color);
}

class DonutChartPainter extends CustomPainter {
  final List<DonutSlice> slices;

  DonutChartPainter(this.slices);

  @override
  void paint(Canvas canvas, Size size) {
    if (slices.isEmpty) return;

    final total = slices.fold(0.0, (sum, s) => sum + s.value);
    final safeTotal = total == 0 ? 1 : total;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    double startAngle = -pi / 2; // Começa de cima

    for (var slice in slices) {
      final sweepAngle = (slice.value / safeTotal) * 2 * pi;

      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
