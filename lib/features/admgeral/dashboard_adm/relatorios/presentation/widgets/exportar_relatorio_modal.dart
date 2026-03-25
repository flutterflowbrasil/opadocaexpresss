import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/relatorio_adm_model.dart';

import '_download_helper.dart';

// ── Paleta (local) ────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF8B5CF6);
const _kGreen = Color(0xFF10B981);
const _kRed = Color(0xFFEF4444);
const _kAmber = Color(0xFFF59E0B);
const _kBorder = Color(0xFFEAE8E4);
const _kText = Color(0xFF1A0910);
const _kHint = Color(0xFF9CA3AF);
const _kSub = Color(0xFF6B7280);

// ─────────────────────────────────────────────────────────────────────────────
//  Modal de exportação
// ─────────────────────────────────────────────────────────────────────────────

class ExportarRelatorioModal extends StatefulWidget {
  final RelatorioSnapshot? snapshot;

  const ExportarRelatorioModal({super.key, required this.snapshot});

  @override
  State<ExportarRelatorioModal> createState() => _ExportarRelatorioModalState();
}

class _ExportarRelatorioModalState extends State<ExportarRelatorioModal> {
  bool _exporting = false;

  // ── CSV builder ─────────────────────────────────────────────────────────────
  String _buildCsv(RelatorioSnapshot snap) {
    final buf = StringBuffer();

    buf.writeln('## RELATÓRIO PADOCA EXPRESS');
    buf.writeln('Gerado em,${DateTime.now().toIso8601String()}');
    buf.writeln();

    buf.writeln('## KPIs GERAIS');
    buf.writeln('Métrica,Valor');
    buf.writeln('Receita Total,${snap.receitaTotal.toStringAsFixed(2)}');
    buf.writeln(
        'Receita Plataforma,${snap.plataformaTotal.toStringAsFixed(2)}');
    buf.writeln('Total Pedidos,${snap.pedidos.length}');
    buf.writeln('Ticket Médio,${snap.ticketMedio.toStringAsFixed(2)}');
    buf.writeln('Taxa Conversão,${snap.taxaConversao.toStringAsFixed(1)}%');
    buf.writeln(
        'Taxa Cancelamento,${snap.taxaCancelamento.toStringAsFixed(1)}%');
    buf.writeln('Total Usuários,${snap.totalUsuarios}');
    buf.writeln('Total Clientes,${snap.totalClientes}');
    buf.writeln('Total Entregadores,${snap.totalEntregadores}');
    buf.writeln('Total Estabelecimentos,${snap.totalEstabs}');
    buf.writeln();

    buf.writeln('## PEDIDOS');
    buf.writeln(
        'Status,Pag. Status,Método,Subtotal(R\$),Taxa Entrega(R\$),Taxa App(R\$),Desconto(R\$),Total(R\$),Split,Data');
    for (final p in snap.pedidos) {
      buf.writeln(
        '${p.status},${p.pagamentoStatus ?? ""},${p.pagamentoMetodo ?? ""},'
        '${p.subtotalProdutos.toStringAsFixed(2)},${p.taxaEntrega.toStringAsFixed(2)},${p.taxaServicApp.toStringAsFixed(2)},'
        '${p.descontoCupom.toStringAsFixed(2)},${p.total.toStringAsFixed(2)},${p.splitProcessado ? "Sim" : "Não"},'
        '${p.createdAt.toIso8601String()}',
      );
    }
    buf.writeln();

    buf.writeln('## USUÁRIOS');
    buf.writeln('Tipo,Status,Email Verif.,Telefone Verif.,Data');
    for (final u in snap.usuarios) {
      buf.writeln(
        '${u.tipoUsuario},${u.status},${u.emailVerificado ? "Sim" : "Não"},${u.telefoneVerificado ? "Sim" : "Não"},'
        '${u.createdAt.toIso8601String()}',
      );
    }
    buf.writeln();

    buf.writeln('## ESTABELECIMENTOS');
    buf.writeln('Nome,Status,Pedidos,Faturamento(R\$),Avaliação,Data Cadastro');
    for (final e in snap.estabelecimentos) {
      buf.writeln(
        '${e.nomeFantasia},${e.statusCadastro},${e.totalPedidos},'
        '${e.faturamentoTotal.toStringAsFixed(2)},${e.avaliacaoMedia.toStringAsFixed(1)},'
        '${e.createdAt?.toIso8601String() ?? ""}',
      );
    }
    buf.writeln();

    buf.writeln('## ENTREGADORES');
    buf.writeln('Status,Veículo,Entregas,Ganhos(R\$),Avaliação,Online');
    for (final e in snap.entregadores) {
      buf.writeln(
        '${e.statusCadastro},${e.tipoVeiculo},${e.totalEntregas},'
        '${e.ganhosTotal.toStringAsFixed(2)},${e.avaliacaoMedia.toStringAsFixed(1)},${e.statusOnline ? "Sim" : "Não"}',
      );
    }
    buf.writeln();

    buf.writeln('## AVALIAÇÕES');
    buf.writeln('Nota Estab.,Nota Entregador,Data');
    for (final a in snap.avaliacoes) {
      buf.writeln(
        '${a.notaEstabelecimento ?? ""},${a.notaEntregador ?? ""},'
        '${a.createdAt.toIso8601String()}',
      );
    }
    buf.writeln();

    buf.writeln('## CHAMADOS');
    buf.writeln('Categoria,Status,Prioridade,Data');
    for (final c in snap.chamados) {
      buf.writeln(
        '${c.categoria},${c.status},${c.prioridade},'
        '${c.createdAt.toIso8601String()}',
      );
    }

    return buf.toString();
  }

  // ── Trigger CSV download ────────────────────────────────────────────────────
  void _downloadCsv() {
    if (widget.snapshot == null || !kIsWeb) return;
    setState(() => _exporting = true);
    try {
      final csv = _buildCsv(widget.snapshot!);
      downloadBytes(
        utf8.encode(csv),
        'text/csv;charset=utf-8',
        'relatorio_padoca_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // ── Trigger PDF (impressão via browser) ─────────────────────────────────────
  // Gera HTML com o relatório e abre no navegador para imprimir como PDF.
  // No mobile este botão fica desabilitado (kIsWeb guard).
  void _downloadPdf() {
    if (widget.snapshot == null || !kIsWeb) return;
    setState(() => _exporting = true);
    try {
      final snap = widget.snapshot!;
      final now = DateTime.now().toString().substring(0, 16);

      final htmlContent = '''<!DOCTYPE html><html><head>
<meta charset="UTF-8"><title>Relatório Padoca Express</title>
<style>
  body{font-family:Arial,sans-serif;padding:24px;color:#1a0910;}
  h1{color:#8b5cf6;} h2{color:#374151;border-bottom:2px solid #eae8e4;padding-bottom:4px;margin-top:24px;}
  table{width:100%;border-collapse:collapse;margin-bottom:20px;font-size:12px;}
  th{background:#f4f2ef;padding:6px 10px;text-align:left;border:1px solid #eae8e4;}
  td{padding:5px 10px;border:1px solid #eae8e4;}
  .kpi-grid{display:flex;flex-wrap:wrap;gap:12px;margin:16px 0;}
  .kpi{background:#f5f3ff;border-radius:8px;padding:12px 16px;min-width:140px;}
  .kpi-val{font-size:20px;font-weight:800;color:#8b5cf6;}
  .kpi-lbl{font-size:11px;color:#6b7280;}
  @media print{body{-webkit-print-color-adjust:exact;print-color-adjust:exact;}}
</style></head><body>
<h1>📊 Relatório Completo Padoca Express</h1>
<p style="color:#9ca3af;font-size:12px;">Gerado em $now</p>

<h2>KPIs Gerais</h2>
<div class="kpi-grid">
  <div class="kpi"><div class="kpi-val">R\$ ${snap.receitaTotal.toStringAsFixed(2)}</div><div class="kpi-lbl">Receita Total</div></div>
  <div class="kpi"><div class="kpi-val">R\$ ${snap.plataformaTotal.toStringAsFixed(2)}</div><div class="kpi-lbl">Receita Plataforma</div></div>
  <div class="kpi"><div class="kpi-val">${snap.pedidos.length}</div><div class="kpi-lbl">Total Pedidos</div></div>
  <div class="kpi"><div class="kpi-val">R\$ ${snap.ticketMedio.toStringAsFixed(2)}</div><div class="kpi-lbl">Ticket Médio</div></div>
  <div class="kpi"><div class="kpi-val">${snap.taxaConversao.toStringAsFixed(1)}%</div><div class="kpi-lbl">Taxa Conversão</div></div>
  <div class="kpi"><div class="kpi-val">${snap.taxaCancelamento.toStringAsFixed(1)}%</div><div class="kpi-lbl">Taxa Cancelamento</div></div>
  <div class="kpi"><div class="kpi-val">${snap.totalUsuarios}</div><div class="kpi-lbl">Total Usuários</div></div>
  <div class="kpi"><div class="kpi-val">${snap.totalEstabs}</div><div class="kpi-lbl">Estabelecimentos</div></div>
  <div class="kpi"><div class="kpi-val">${snap.totalEntregadores}</div><div class="kpi-lbl">Entregadores</div></div>
</div>

<h2>Top Estabelecimentos</h2>
<table><tr><th>Nome</th><th>Status</th><th>Pedidos</th><th>Faturamento</th><th>Avaliação</th></tr>
${snap.estabelecimentos.take(15).map((e) => '<tr><td>${e.nomeFantasia}</td><td>${e.statusCadastro}</td><td>${e.totalPedidos}</td><td>R\$ ${e.faturamentoTotal.toStringAsFixed(2)}</td><td>${e.avaliacaoMedia.toStringAsFixed(1)}</td></tr>').join('\n')}
</table>

<h2>Entregadores</h2>
<table><tr><th>Status</th><th>Veículo</th><th>Entregas</th><th>Ganhos</th><th>Avaliação</th><th>Online</th></tr>
${snap.entregadores.take(15).map((e) => '<tr><td>${e.statusCadastro}</td><td>${e.tipoVeiculo}</td><td>${e.totalEntregas}</td><td>R\$ ${e.ganhosTotal.toStringAsFixed(2)}</td><td>${e.avaliacaoMedia.toStringAsFixed(1)}</td><td>${e.statusOnline ? "Sim" : "Não"}</td></tr>').join('\n')}
</table>

<h2>Últimos Pedidos</h2>
<table><tr><th>Status</th><th>Pagamento</th><th>Subtotal</th><th>Tx Entrega</th><th>Total</th><th>Data</th></tr>
${(snap.pedidos.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt))).take(15).map((p) => '<tr><td>${p.status}</td><td>${p.pagamentoMetodo ?? p.pagamentoStatus ?? "—"}</td><td>R\$ ${p.subtotalProdutos.toStringAsFixed(2)}</td><td>R\$ ${p.taxaEntrega.toStringAsFixed(2)}</td><td>R\$ ${p.total.toStringAsFixed(2)}</td><td>${p.createdAt.toString().substring(0, 16)}</td></tr>').join('\n')}
</table>

<script>window.onload = function(){ window.print(); };</script>
</body></html>''';

      downloadBytes(
        utf8.encode(htmlContent),
        'text/html;charset=utf-8',
        'relatorio_padoca_${DateTime.now().millisecondsSinceEpoch}.html',
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // ── UI ──────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final hasData = widget.snapshot != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 480,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(22, 20, 14, 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF3F1EE))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.download_rounded,
                        color: _kPrimary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exportar Relatório',
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _kText,
                          ),
                        ),
                        Text(
                          hasData
                              ? '${widget.snapshot!.pedidos.length} pedidos · ${widget.snapshot!.totalUsuarios} usuários'
                              : 'Aguarde o carregamento dos dados',
                          style:
                              GoogleFonts.dmSans(fontSize: 11, color: _kHint),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: _kHint),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            // ── Opções ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _ExportOption(
                    icon: Icons.table_chart_rounded,
                    iconBg: const Color(0xFFECFDF5),
                    iconColor: _kGreen,
                    titulo: 'Planilha CSV',
                    descricao:
                        'Todos os dados em formato tabular: pedidos, usuários, estabelecimentos, entregadores, avaliações e chamados.',
                    badge: 'Recomendado',
                    badgeColor: _kGreen,
                    onTap:
                        hasData && !_exporting && kIsWeb ? _downloadCsv : null,
                    loading: _exporting,
                  ),
                  const SizedBox(height: 10),
                  _ExportOption(
                    icon: Icons.picture_as_pdf_rounded,
                    iconBg: const Color(0xFFFEF2F2),
                    iconColor: _kRed,
                    titulo: 'PDF / Impressão',
                    descricao:
                        'Abre uma nova aba com o relatório formatado e dispara o diálogo de impressão do navegador (use Salvar como PDF).',
                    badge: 'Via browser',
                    badgeColor: _kHint,
                    onTap:
                        hasData && !_exporting && kIsWeb ? _downloadPdf : null,
                    loading: _exporting,
                  ),
                  if (!hasData)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 14, color: _kAmber),
                          const SizedBox(width: 6),
                          Text(
                            'Aguarde o fim do carregamento para exportar.',
                            style: GoogleFonts.dmSans(
                                fontSize: 11, color: _kAmber),
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
}

// ── Opção individual ──────────────────────────────────────────────────────────
class _ExportOption extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String titulo;
  final String descricao;
  final String badge;
  final Color badgeColor;
  final VoidCallback? onTap;
  final bool loading;

  const _ExportOption({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.titulo,
    required this.descricao,
    required this.badge,
    required this.badgeColor,
    required this.onTap,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFFF9F8F7) : const Color(0xFFF3F1EE),
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: enabled ? _kBorder : const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          titulo,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _kText,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.1),
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
                    const SizedBox(height: 4),
                    Text(
                      descricao,
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: _kHint, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _kPrimary),
                )
              else
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: enabled ? _kSub : _kHint,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
