import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Constantes de cor ──────────────────────────────────────────────────────
const bg0 = Color(0xFF0A0704);
const bg1 = Color(0xFF120E08);
const bg2 = Color(0xFF1C1510);
const bg3 = Color(0xFF251C14);
const cardColor = Color(0xFF1A1510);
const orangeColor = Color(0xFFF97316);
const orangeDColor = Color(0xFFEA580C);
const greenColor = Color(0xFF22C55E);
const greenDColor = Color(0xFF16A34A);
const yellowColor = Color(0xFFFBBF24);
const redColor = Color(0xFFEF4444);
const text1 = Color(0xFFFAFAF9);
const text2 = Color(0xA6FAFAF9);
const text3 = Color(0x59FAFAF9);
const borderColor = Color(0x12FFFFFF);

// ═══════════════════════════════════════════════════════════════════════════
// HEADER
// ═══════════════════════════════════════════════════════════════════════════
class DashboardHeader extends StatelessWidget {
  final String nome;
  final String tipoVeiculo;
  final bool online;

  const DashboardHeader({
    super.key,
    required this.nome,
    required this.tipoVeiculo,
    required this.online,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [orangeColor, orangeDColor]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: orangeColor.withOpacity(.35), blurRadius: 12)
            ],
          ),
          child:
              const Center(child: Text('🧑', style: TextStyle(fontSize: 18))),
        ),
        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nome,
                style: GoogleFonts.outfit(
                    fontSize: 15, fontWeight: FontWeight.w800, color: text1),
              ),
              Text(
                online ? '● Online · Aguardando' : 'Entregador · $tipoVeiculo',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: online ? greenColor : text3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Notificações
        Stack(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bg2,
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                  child: Text('🔔', style: TextStyle(fontSize: 16))),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: orangeColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: bg0, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TOGGLE CARD
// ═══════════════════════════════════════════════════════════════════════════
class DashboardToggleCard extends StatelessWidget {
  final bool online;
  final bool loading;
  final VoidCallback onToggle;

  const DashboardToggleCard({
    super.key,
    required this.online,
    required this.loading,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: online
              ? [const Color(0xFF0D1F12), const Color(0xFF071509)]
              : [const Color(0xFF1A1510), const Color(0xFF130F0A)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: online ? greenColor.withOpacity(.2) : borderColor),
        boxShadow: online
            ? [
                BoxShadow(
                    color: greenColor.withOpacity(.08),
                    blurRadius: 40,
                    spreadRadius: 0)
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label de status
          Text(
            'STATUS ATUAL',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: online ? greenColor : text3,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 14),

          // Linha principal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                online ? 'Online' : 'Offline',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: online ? text1 : text3,
                ),
              ),
              // Switch
              GestureDetector(
                onTap: () {
                  if (!loading) {
                    HapticFeedback.mediumImpact();
                    onToggle();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeInOut,
                  width: 72,
                  height: 40,
                  decoration: BoxDecoration(
                    color: online ? greenColor : bg3,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: online ? greenColor : borderColor),
                    boxShadow: online
                        ? [
                            BoxShadow(
                                color: greenColor.withOpacity(.3),
                                blurRadius: 16)
                          ]
                        : [],
                  ),
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 380),
                        curve: const ElasticOutCurve(0.9),
                        left: online ? 36 : 4,
                        top: 4,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (online ? greenColor : Colors.black)
                                    .withOpacity(.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Center(
                            child: loading
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: orangeColor),
                                  )
                                : Text(
                                    online ? '🟢' : '😴',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            online
                ? 'Você está visível para pedidos na sua região.'
                : 'Ative para começar a receber pedidos na sua região.',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              height: 1.5,
              color: online ? greenColor.withOpacity(.7) : text3,
            ),
          ),

          // Pulso animado quando online
          if (online) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: greenColor.withOpacity(.08),
                border: Border.all(color: greenColor.withOpacity(.15)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const DashboardPulseDot(),
                  const SizedBox(width: 8),
                  Text(
                    'AGUARDANDO PEDIDOS...',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: greenColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PULSE DOT
// ═══════════════════════════════════════════════════════════════════════════
class DashboardPulseDot extends StatefulWidget {
  const DashboardPulseDot({super.key});

  @override
  State<DashboardPulseDot> createState() => _DashboardPulseDotState();
}

class _DashboardPulseDotState extends State<DashboardPulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
    _scale = Tween<double>(begin: 1, end: 1.4)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: greenColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: greenColor.withOpacity(.4), blurRadius: 6)
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STATS ROW
// ═══════════════════════════════════════════════════════════════════════════
class DashboardStatsRow extends StatelessWidget {
  final double ganhoHoje;
  final double avaliacao;
  final int entregasHoje;

  const DashboardStatsRow({
    super.key,
    required this.ganhoHoje,
    required this.entregasHoje,
    required this.avaliacao,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DashboardStatCard(
            icon: '💰',
            value: 'R\$${ganhoHoje.toStringAsFixed(0)}',
            label: 'Hoje',
            valueColor: orangeColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DashboardStatCard(
            icon: '🛵',
            value: '$entregasHoje',
            label: 'Entregas',
            valueColor: text1,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DashboardStatCard(
            icon: '⭐',
            value: avaliacao.toStringAsFixed(1),
            label: 'Avaliação',
            valueColor: yellowColor,
          ),
        ),
      ],
    );
  }
}

class DashboardStatCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Color valueColor;

  const DashboardStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: valueColor,
                height: 1),
          ),
          const SizedBox(height: 3),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.dmSans(
                fontSize: 9,
                color: text3,
                fontWeight: FontWeight.w700,
                letterSpacing: .4),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EARNINGS BANNER
// ═══════════════════════════════════════════════════════════════════════════
class DashboardEarningsBanner extends StatelessWidget {
  final double ganhoHoje;
  final double raioBusca;
  final int entregasHoje;

  const DashboardEarningsBanner({
    super.key,
    required this.ganhoHoje,
    required this.entregasHoje,
    required this.raioBusca,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1F12), Color(0xFF071509)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: greenColor.withOpacity(.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GANHOS DE HOJE',
            style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: greenColor.withOpacity(.6),
                letterSpacing: .8),
          ),
          const SizedBox(height: 4),
          Text(
            'R\$ ${ganhoHoje.toStringAsFixed(2)}',
            style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: greenColor,
                height: 1),
          ),
          const SizedBox(height: 4),
          Text(
            '$entregasHoje entregas concluídas',
            style: GoogleFonts.dmSans(fontSize: 11, color: text3),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              DashboardEbChip('🛵 ${raioBusca.toStringAsFixed(0)} km raio'),
              const SizedBox(width: 8),
              const DashboardEbChip('⭐ Prioridade alta'),
            ],
          ),
        ],
      ),
    );
  }
}

class DashboardEbChip extends StatelessWidget {
  final String text;
  const DashboardEbChip(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: greenColor.withOpacity(.08),
        border: Border.all(color: greenColor.withOpacity(.15)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: GoogleFonts.dmSans(
              fontSize: 10, fontWeight: FontWeight.w700, color: greenColor)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// META CARD
// ═══════════════════════════════════════════════════════════════════════════
class DashboardMetaCard extends StatelessWidget {
  final double ganhoSemana;
  final double metaSemana;

  const DashboardMetaCard({
    super.key,
    required this.ganhoSemana,
    required this.metaSemana,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (ganhoSemana / metaSemana).clamp(0.0, 1.0);
    final dias = ['Seg', 'Ter', 'Qua', 'Hoje', 'Sex', 'Sáb', 'Dom'];
    final hojeDia = DateTime.now().weekday - 1; // 0=Seg

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: cardColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'R\$ ${ganhoSemana.toStringAsFixed(0)} / R\$ ${metaSemana.toStringAsFixed(0)}',
                style: GoogleFonts.outfit(
                    fontSize: 13, fontWeight: FontWeight.w700, color: text1),
              ),
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: orangeColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: bg3,
              valueColor: const AlwaysStoppedAnimation(orangeColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: dias
                .asMap()
                .entries
                .map((e) => Text(
                      e.value,
                      style: GoogleFonts.dmSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: e.key == hojeDia ? orangeColor : text3,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MAP PLACEHOLDER
// ═══════════════════════════════════════════════════════════════════════════
class DashboardMapPlaceholder extends StatelessWidget {
  const DashboardMapPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1A0D),
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Grid placeholder
            CustomPaint(painter: _GridPainter(), size: Size.infinite),
            // Anel de raio
            Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: orangeColor.withOpacity(.25), width: 1.5),
                ),
              ),
            ),
            // Pin
            const Center(child: Text('📍', style: TextStyle(fontSize: 22))),
            // Label
            Positioned(
              bottom: 10,
              left: 12,
              child: Text(
                'Aguardando no Raio',
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: greenColor.withOpacity(.5),
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = greenColor.withOpacity(0.04)
      ..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double j = 0; j < size.height; j += 20) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DashboardSectionHeader extends StatelessWidget {
  final String titulo;
  final String linkLabel;
  final VoidCallback onLink;

  const DashboardSectionHeader({
    super.key,
    required this.titulo,
    required this.linkLabel,
    required this.onLink,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            titulo,
            style: GoogleFonts.outfit(
                fontSize: 16, fontWeight: FontWeight.w800, color: text1),
          ),
          GestureDetector(
            onTap: onLink,
            child: Text(
              linkLabel,
              style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: orangeColor),
            ),
          ),
        ],
      ),
    );
  }
}
