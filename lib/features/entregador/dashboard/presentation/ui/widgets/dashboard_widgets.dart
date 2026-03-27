import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../controllers/dashboard_state.dart';

// ─── Cores ───────────────────────────────────────────────────────────────────
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
const blueColor = Color(0xFF3B82F6);
const text1 = Color(0xFFFAFAF9);
const text2 = Color(0xA6FAFAF9);
const text3 = Color(0x59FAFAF9);
const borderColor = Color(0x12FFFFFF);

// ═══════════════════════════════════════════════════════════════════════════
// SHIMMER — loading inicial
// ═══════════════════════════════════════════════════════════════════════════
class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: bg2,
      highlightColor: bg3,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header shimmer
            Row(children: [
              _ShimmerBox(w: 44, h: 44, radius: 14),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(w: 140, h: 14, radius: 6),
                    const SizedBox(height: 6),
                    _ShimmerBox(w: 90, h: 10, radius: 4),
                  ],
                ),
              ),
              _ShimmerBox(w: 36, h: 36, radius: 10),
            ]),
            const SizedBox(height: 20),
            _ShimmerBox(w: double.infinity, h: 80, radius: 16),
            const SizedBox(height: 12),
            _ShimmerBox(w: double.infinity, h: 100, radius: 20),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _ShimmerBox(w: double.infinity, h: 70, radius: 14)),
              const SizedBox(width: 8),
              Expanded(child: _ShimmerBox(w: double.infinity, h: 70, radius: 14)),
              const SizedBox(width: 8),
              Expanded(child: _ShimmerBox(w: double.infinity, h: 70, radius: 14)),
            ]),
            const SizedBox(height: 12),
            _ShimmerBox(w: double.infinity, h: 72, radius: 14),
            const SizedBox(height: 20),
            _ShimmerBox(w: 120, h: 14, radius: 6),
            const SizedBox(height: 12),
            _ShimmerBox(w: double.infinity, h: 60, radius: 14),
            const SizedBox(height: 8),
            _ShimmerBox(w: double.infinity, h: 60, radius: 14),
            const SizedBox(height: 8),
            _ShimmerBox(w: double.infinity, h: 60, radius: 14),
          ],
        ),
      ),
    );
  }
}

class DashboardDeliveriesShimmer extends StatelessWidget {
  const DashboardDeliveriesShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: bg2,
      highlightColor: bg3,
      child: Column(
        children: List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ShimmerBox(w: double.infinity, h: 62, radius: 14),
          ),
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double w;
  final double h;
  final double radius;
  const _ShimmerBox({required this.w, required this.h, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: bg2,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HEADER
// ═══════════════════════════════════════════════════════════════════════════
class DashboardHeader extends StatelessWidget {
  final String nome;
  final String tipoVeiculo;
  final bool online;
  final String? fotoPerfilUrl;

  const DashboardHeader({
    super.key,
    required this.nome,
    required this.tipoVeiculo,
    required this.online,
    this.fotoPerfilUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient:
                const LinearGradient(colors: [orangeColor, orangeDColor]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: orangeColor.withValues(alpha: .3), blurRadius: 14)
            ],
          ),
          child: fotoPerfilUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(fotoPerfilUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                          child: Text('🧑',
                              style: TextStyle(fontSize: 20)))),
                )
              : const Center(
                  child: Text('🧑', style: TextStyle(fontSize: 20))),
        ),
        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nome.isNotEmpty ? nome : 'Entregador',
                style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: text1),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 5),
                    decoration: BoxDecoration(
                      color: online ? greenColor : text3,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(
                    online ? 'Online · Aguardando' : 'Offline · $tipoVeiculo',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: online ? greenColor : text3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Notificações
        Stack(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bg2,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
                child: Text('🔔', style: TextStyle(fontSize: 17))),
          ),
          Positioned(
            top: 7,
            right: 7,
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
        ]),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SALDO CARD
// ═══════════════════════════════════════════════════════════════════════════
class SaldoCard extends StatelessWidget {
  final double saldoDisponivel;
  final double saldoBloqueado;
  final VoidCallback onSaque;

  const SaldoCard({
    super.key,
    required this.saldoDisponivel,
    required this.saldoBloqueado,
    required this.onSaque,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1000), Color(0xFF0F0A04)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: orangeColor.withValues(alpha: .15)),
        boxShadow: [
          BoxShadow(
              color: orangeColor.withValues(alpha: .06),
              blurRadius: 24,
              spreadRadius: 0)
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SALDO DISPONÍVEL',
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: orangeColor.withValues(alpha: .7),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'R\$ ${saldoDisponivel.toStringAsFixed(2)}',
                  style: GoogleFonts.dmSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: text1,
                    height: 1,
                  ),
                ),
                if (saldoBloqueado > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Bloqueado: R\$ ${saldoBloqueado.toStringAsFixed(2)}',
                    style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: yellowColor.withValues(alpha: .7)),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: onSaque,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [orangeColor, orangeDColor]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: orangeColor.withValues(alpha: .3),
                      blurRadius: 12)
                ],
              ),
              child: Text(
                'Sacar',
                style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: online
              ? [const Color(0xFF0D1F12), const Color(0xFF071509)]
              : [const Color(0xFF1A1510), const Color(0xFF130F0A)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: online
                ? greenColor.withValues(alpha: .2)
                : borderColor),
        boxShadow: online
            ? [
                BoxShadow(
                    color: greenColor.withValues(alpha: .07),
                    blurRadius: 32,
                    spreadRadius: 0)
              ]
            : [],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STATUS ATUAL',
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: online ? greenColor : text3,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                online ? 'Online' : 'Offline',
                style: GoogleFonts.dmSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: online ? text1 : text3,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                online
                    ? 'Visível para pedidos na região'
                    : 'Ative para receber pedidos',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: online
                      ? greenColor.withValues(alpha: .7)
                      : text3,
                ),
              ),
            ],
          ),
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
              width: 68,
              height: 38,
              decoration: BoxDecoration(
                color: online ? greenColor : bg3,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(
                    color: online ? greenColor : borderColor),
                boxShadow: online
                    ? [
                        BoxShadow(
                            color: greenColor.withValues(alpha: .3),
                            blurRadius: 14)
                      ]
                    : [],
              ),
              child: Stack(children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 380),
                  curve: const ElasticOutCurve(0.9),
                  left: online ? 33 : 4,
                  top: 4,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (online ? greenColor : Colors.black)
                              .withValues(alpha: .3),
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
                              style: const TextStyle(fontSize: 13),
                            ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STATS ROW
// ═══════════════════════════════════════════════════════════════════════════
class DashboardStatsRow extends StatelessWidget {
  final double ganhoHoje;
  final int entregasHoje;
  final double avaliacao;
  final int totalEntregas;

  const DashboardStatsRow({
    super.key,
    required this.ganhoHoje,
    required this.entregasHoje,
    required this.avaliacao,
    required this.totalEntregas,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: '💰',
            value: 'R\$${ganhoHoje.toStringAsFixed(0)}',
            label: 'Hoje',
            valueColor: orangeColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: '🛵',
            value: '$entregasHoje',
            label: 'Hoje',
            sub: '$totalEntregas total',
            valueColor: text1,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
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

class _StatCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final String? sub;
  final Color valueColor;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.sub,
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
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: valueColor,
                height: 1),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.dmSans(
                fontSize: 9,
                color: text3,
                fontWeight: FontWeight.w700,
                letterSpacing: .4),
          ),
          if (sub != null)
            Text(
              sub!,
              style: GoogleFonts.dmSans(fontSize: 9, color: text3),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// META SEMANAL
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
    final dias = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
    final nomes = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    final hoje = DateTime.now().weekday - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'META DA SEMANA',
                    style: GoogleFonts.dmSans(
                        fontSize: 9,
                        color: text3,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .6),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'R\$ ${ganhoSemana.toStringAsFixed(0)} / R\$ ${metaSemana.toStringAsFixed(0)}',
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: text1),
                  ),
                ],
              ),
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: pct >= 1.0 ? greenColor : orangeColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: bg3,
              valueColor: AlwaysStoppedAnimation(
                  pct >= 1.0 ? greenColor : orangeColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              7,
              (i) => Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: i == hoje
                          ? orangeColor.withValues(alpha: .15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        dias[i],
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: i == hoje ? orangeColor : text3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nomes[i],
                    style: GoogleFonts.dmSans(
                      fontSize: 8,
                      color: i == hoje ? orangeColor : text3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DESPACHO RECEBIDO
// ═══════════════════════════════════════════════════════════════════════════
class DespachoRecebidoCard extends StatefulWidget {
  final DespachoRecebido despacho;
  final bool isResponding;
  final VoidCallback onAceitar;
  final VoidCallback onRejeitar;

  const DespachoRecebidoCard({
    super.key,
    required this.despacho,
    required this.isResponding,
    required this.onAceitar,
    required this.onRejeitar,
  });

  @override
  State<DespachoRecebidoCard> createState() => _DespachoRecebidoCardState();
}

class _DespachoRecebidoCardState extends State<DespachoRecebidoCard> {
  Timer? _timer;
  int _segundosRestantes = 45; // 45 segundos padrão a partir do recebimento

  @override
  void initState() {
    super.initState();
    _segundosRestantes = 45;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) { return; }
      setState(() {
        _segundosRestantes--;
      });
      if (_segundosRestantes <= 0) {
        _timer?.cancel();
        widget.onRejeitar(); // expirado = auto-rejeitar
      }
    });
    HapticFeedback.vibrate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const int totalSec = 45;
    final pct = (_segundosRestantes / totalSec).clamp(0.0, 1.0);
    final urgente = _segundosRestantes <= 10;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: urgente
              ? [const Color(0xFF1F0D0D), const Color(0xFF150707)]
              : [const Color(0xFF0D1A0D), const Color(0xFF071209)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: (urgente ? redColor : greenColor).withValues(alpha: .3)),
        boxShadow: [
          BoxShadow(
              color: (urgente ? redColor : greenColor).withValues(alpha: .12),
              blurRadius: 24,
              spreadRadius: 0)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (urgente ? redColor : greenColor)
                      .withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  urgente ? '⚡ URGENTE' : '🔔 NOVO PEDIDO',
                  style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: urgente ? redColor : greenColor,
                      letterSpacing: .5),
                ),
              ),
              const Spacer(),
              Text(
                '$_segundosRestantes s',
                style: GoogleFonts.dmSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: urgente ? redColor : text1,
                    height: 1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _DespachoChip(
                  icon: '📍',
                  label:
                      '${widget.despacho.distanciaKm.toStringAsFixed(1)} km'),
              const SizedBox(width: 8),
              _DespachoChip(
                  icon: '💵',
                  label:
                      'R\$ ${widget.despacho.valorEntrega.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: bg3,
              valueColor: AlwaysStoppedAnimation(
                  urgente ? redColor : greenColor),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: widget.isResponding ? null : widget.onRejeitar,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: bg3,
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Recusar',
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: text2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: widget.isResponding ? null : widget.onAceitar,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [greenColor, greenDColor]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: greenColor.withValues(alpha: .3),
                            blurRadius: 12)
                      ],
                    ),
                    child: Center(
                      child: widget.isResponding
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'Aceitar',
                              style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DespachoChip extends StatelessWidget {
  final String icon;
  final String label;
  const _DespachoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: greenColor.withValues(alpha: .08),
        border: Border.all(color: greenColor.withValues(alpha: .15)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: greenColor)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PEDIDO ATIVO CARD
// ═══════════════════════════════════════════════════════════════════════════
class PedidoAtivoCard extends StatelessWidget {
  final PedidoAtivo pedido;
  final VoidCallback onConfirmar;

  const PedidoAtivoCard({
    super.key,
    required this.pedido,
    required this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1220), Color(0xFF070C15)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: blueColor.withValues(alpha: .25)),
        boxShadow: [
          BoxShadow(
              color: blueColor.withValues(alpha: .08),
              blurRadius: 24,
              spreadRadius: 0)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: blueColor.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '🚀 EM ENTREGA',
                  style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: blueColor,
                      letterSpacing: .5),
                ),
              ),
              const Spacer(),
              if (pedido.numeroPedido != null)
                Text(
                  '#${pedido.numeroPedido}',
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: text3),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            pedido.nomeEstabelecimento,
            style: GoogleFonts.dmSans(
                fontSize: 15, fontWeight: FontWeight.w800, color: text1),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text('📍', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  pedido.enderecoEntrega,
                  style: GoogleFonts.dmSans(fontSize: 12, color: text2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: GestureDetector(
              onTap: onConfirmar,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [blueColor, Color(0xFF2563EB)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: blueColor.withValues(alpha: .3),
                        blurRadius: 12)
                  ],
                ),
                child: Center(
                  child: Text(
                    'Confirmar Entrega',
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ENTREGA RECENTE CARD
// ═══════════════════════════════════════════════════════════════════════════
class EntregaRecenteCard extends StatelessWidget {
  final EntregaRecente entrega;

  const EntregaRecenteCard({super.key, required this.entrega});

  String _tempo() {
    if (entrega.entregueEm == null) { return ''; }
    final diff = DateTime.now().difference(entrega.entregueEm!);
    if (diff.inMinutes < 60) { return 'há ${diff.inMinutes}min'; }
    if (diff.inHours < 24) { return 'há ${diff.inHours}h'; }
    return 'há ${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bg2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: entrega.logoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(entrega.logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                            child:
                                Text('🏪', style: TextStyle(fontSize: 18)))),
                  )
                : const Center(
                    child: Text('🏪', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entrega.nomeEstabelecimento,
                  style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: text1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (entrega.numeroPedido != null) ...[
                      Text(
                        '#${entrega.numeroPedido}',
                        style: GoogleFonts.dmSans(
                            fontSize: 11, color: text3),
                      ),
                      const SizedBox(width: 6),
                      Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                              color: text3, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      _tempo(),
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: text3),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Text(
            '+ R\$ ${entrega.valorEntregador.toStringAsFixed(2)}',
            style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: greenColor),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ═══════════════════════════════════════════════════════════════════════════
class DashboardEmptyDeliveries extends StatelessWidget {
  const DashboardEmptyDeliveries({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Center(child: Text('🛵', style: TextStyle(fontSize: 36))),
          const SizedBox(height: 10),
          Text(
            'Nenhuma entrega ainda',
            style: GoogleFonts.dmSans(
                fontSize: 14, fontWeight: FontWeight.w700, color: text2),
          ),
          const SizedBox(height: 4),
          Text(
            'Fique online para começar a receber pedidos.',
            style: GoogleFonts.dmSans(fontSize: 12, color: text3),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SECTION HEADER
// ═══════════════════════════════════════════════════════════════════════════
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
            style: GoogleFonts.dmSans(
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
