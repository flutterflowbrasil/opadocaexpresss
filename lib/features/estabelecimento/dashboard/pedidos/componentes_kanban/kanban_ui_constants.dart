import 'package:flutter/material.dart';

class KanbanColors {
  // Pendente
  static const Color pendenteColor = Color(0xFFF59E0B);
  static const Color pendenteBg = Color(0xFFFFFBEB);
  static const Color pendenteBorder = Color(0xFFFDE68A);
  static const Color pendenteDark = Color(0xFF92400E);

  // Confirmado
  static const Color confirmadoColor = Color(0xFF3B82F6);
  static const Color confirmadoBg = Color(0xFFEFF6FF);
  static const Color confirmadoBorder = Color(0xFFBFDBFE);
  static const Color confirmadoDark = Color(0xFF1E40AF);

  // Preparando
  static const Color preparandoColor = Color(0xFF8B5CF6);
  static const Color preparandoBg = Color(0xFFF5F3FF);
  static const Color preparandoBorder = Color(0xFFDDD6FE);
  static const Color preparandoDark = Color(0xFF5B21B6);

  // Pronto
  static const Color prontoColor = Color(0xFF10B981);
  static const Color prontoBg = Color(0xFFECFDF5);
  static const Color prontoBorder = Color(0xFFA7F3D0);
  static const Color prontoDark = Color(0xFF065F46);

  // Em Entrega
  static const Color emEntregaColor = Color(0xFFF97316);
  static const Color emEntregaBg = Color(0xFFFFF7ED);
  static const Color emEntregaBorder = Color(0xFFFED7AA);
  static const Color emEntregaDark = Color(0xFFC2410C);

  // Pagamentos
  static const Color pgtoPix = Color(0xFF10B981);
  static const Color pgtoCredito = Color(0xFF3B82F6);
  static const Color pgtoDebito = Color(0xFF8B5CF6);
}

class StatusMeta {
  final String label;
  final Color color;
  final Color bg;
  final Color border;
  final Color dark;

  const StatusMeta({
    required this.label,
    required this.color,
    required this.bg,
    required this.border,
    required this.dark,
  });

  static StatusMeta fromStatus(String status) {
    switch (status) {
      case 'pendente':
        return const StatusMeta(
            label: 'Pendente',
            color: KanbanColors.pendenteColor,
            bg: KanbanColors.pendenteBg,
            border: KanbanColors.pendenteBorder,
            dark: KanbanColors.pendenteDark);
      case 'confirmado':
        return const StatusMeta(
            label: 'Confirmado',
            color: KanbanColors.confirmadoColor,
            bg: KanbanColors.confirmadoBg,
            border: KanbanColors.confirmadoBorder,
            dark: KanbanColors.confirmadoDark);
      case 'preparando':
        return const StatusMeta(
            label: 'Preparando',
            color: KanbanColors.preparandoColor,
            bg: KanbanColors.preparandoBg,
            border: KanbanColors.preparandoBorder,
            dark: KanbanColors.preparandoDark);
      case 'pronto':
        return const StatusMeta(
            label: 'Pronto p/ Entrega',
            color: KanbanColors.prontoColor,
            bg: KanbanColors.prontoBg,
            border: KanbanColors.prontoBorder,
            dark: KanbanColors.prontoDark);
      case 'em_entrega':
        return const StatusMeta(
            label: 'Em Entrega',
            color: KanbanColors.emEntregaColor,
            bg: KanbanColors.emEntregaBg,
            border: KanbanColors.emEntregaBorder,
            dark: KanbanColors.emEntregaDark);
      default:
        return const StatusMeta(
            label: 'Desconhecido',
            color: Colors.grey,
            bg: Color(0xFFF3F4F6),
            border: Color(0xFFE5E7EB),
            dark: Color(0xFF374151));
    }
  }
}

class PgtoMeta {
  final String label;
  final Color color;
  final IconData icon;

  const PgtoMeta(
      {required this.label, required this.color, required this.icon});

  static PgtoMeta fromKey(String pgto) {
    switch (pgto) {
      case 'pix':
        return const PgtoMeta(
            label: 'Pix', color: KanbanColors.pgtoPix, icon: Icons.pix);
      case 'credito':
        return const PgtoMeta(
            label: 'Crédito',
            color: KanbanColors.pgtoCredito,
            icon: Icons.credit_card);
      case 'debito':
        return const PgtoMeta(
            label: 'Débito',
            color: KanbanColors.pgtoDebito,
            icon: Icons.credit_card_outlined);
      default:
        return const PgtoMeta(
            label: 'Dinheiro', color: Colors.grey, icon: Icons.money);
    }
  }
}
