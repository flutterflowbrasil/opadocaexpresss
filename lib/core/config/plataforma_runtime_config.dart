import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Versão do app (alinhar com pubspec.yaml). Usada no gate de versão mínima.
const kAppVersion = '1.0.0';

class PlataformaRuntimeConfig {
  final String plataformaNome;
  final bool plataformaAtiva;
  final bool modoManutencao;
  final String versaoMinimaApp;
  final bool permiteCadastroEstab;
  final bool permiteCadastroEntregador;
  final String suporteEmail;
  final String suporteWhatsapp;
  final double entregaBaseKm;
  final double entregaBaseValor;
  final double entregaKmExcedente;
  final double raioMaximoKm;
  final double pedidoMinimo;
  final double entregaGratisAcimaDe;
  final bool permiteEntregaGratis;
  final int tempoMedioPreparoMin;
  final int tempoMedioEntregaMin;
  final double taxaServicoAppPct;
  final bool cuponsAtivos;
  final bool permitePercentual;
  final bool permiteValorFixo;
  final double valorMinimoPadraoCupom;
  final int limitePorClienteCupom;
  final int limiteTotalCampanha;
  final double saqueValorMinimo;
  final double saqueTarifaFixa;
  final double saqueLimiteDiario;
  final bool saquePixInstantaneo;
  final int tempoRespostaSeg;

  const PlataformaRuntimeConfig({
    this.plataformaNome = 'Ôpadoca Express',
    this.plataformaAtiva = true,
    this.modoManutencao = false,
    this.versaoMinimaApp = '',
    this.permiteCadastroEstab = true,
    this.permiteCadastroEntregador = true,
    this.suporteEmail = '',
    this.suporteWhatsapp = '',
    this.entregaBaseKm = 5,
    this.entregaBaseValor = 8.5,
    this.entregaKmExcedente = 1.6,
    this.raioMaximoKm = 10,
    this.pedidoMinimo = 0,
    this.entregaGratisAcimaDe = 0,
    this.permiteEntregaGratis = true,
    this.tempoMedioPreparoMin = 20,
    this.tempoMedioEntregaMin = 30,
    this.taxaServicoAppPct = 5,
    this.cuponsAtivos = true,
    this.permitePercentual = true,
    this.permiteValorFixo = true,
    this.valorMinimoPadraoCupom = 0,
    this.limitePorClienteCupom = 1,
    this.limiteTotalCampanha = 0,
    this.saqueValorMinimo = 10,
    this.saqueTarifaFixa = 0,
    this.saqueLimiteDiario = 3,
    this.saquePixInstantaneo = true,
    this.tempoRespostaSeg = 30,
  });

  bool get emManutencao => modoManutencao || !plataformaAtiva;

  factory PlataformaRuntimeConfig.fromMap(Map<String, String> m) {
    bool b(String k, {bool fallback = true}) {
      final v = (m[k] ?? '').toLowerCase();
      if (v.isEmpty) return fallback;
      return !const {'false', '0', 'nao', 'off'}.contains(v);
    }

    double n(String k, double fallback) =>
        double.tryParse((m[k] ?? '').replaceAll(',', '.')) ?? fallback;

    int i(String k, int fallback) =>
        int.tryParse(m[k] ?? '') ?? n(k, fallback.toDouble()).round();

    return PlataformaRuntimeConfig(
      plataformaNome: (m['plataforma_nome'] ?? '').trim().isEmpty
          ? 'Ôpadoca Express'
          : m['plataforma_nome']!.trim(),
      plataformaAtiva: b('plataforma_ativa'),
      modoManutencao: b('modo_manutencao', fallback: false),
      versaoMinimaApp: (m['versao_minima_app'] ?? '').trim(),
      permiteCadastroEstab: b('permite_cadastro_estab'),
      permiteCadastroEntregador: b('permite_cadastro_entregador'),
      suporteEmail: m['suporte_email'] ?? '',
      suporteWhatsapp: m['suporte_whatsapp'] ?? '',
      entregaBaseKm: n('entrega_base_km', 5),
      entregaBaseValor: n('entrega_base_valor', 8.5),
      entregaKmExcedente: n('entrega_valor_km_excedente', 1.6),
      raioMaximoKm: n('raio_maximo_km', 10),
      pedidoMinimo: n('pedido_minimo', 0),
      entregaGratisAcimaDe: n('entrega_gratis_acima_de', 0),
      permiteEntregaGratis: b('permite_entrega_gratis'),
      tempoMedioPreparoMin: i('tempo_medio_preparo_min', 20),
      tempoMedioEntregaMin: i('tempo_medio_entrega_min', 30),
      taxaServicoAppPct: n('taxa_servico_app_pct', 5),
      cuponsAtivos: b('cupons_ativos'),
      permitePercentual: b('permite_percentual'),
      permiteValorFixo: b('permite_valor_fixo'),
      valorMinimoPadraoCupom: n('valor_minimo_padrao', 0),
      limitePorClienteCupom: i('limite_por_cliente', 1),
      limiteTotalCampanha: i('limite_total_campanha', 0),
      saqueValorMinimo: n('saque_valor_minimo', 10),
      saqueTarifaFixa: n('saque_tarifa_fixa', 0),
      saqueLimiteDiario: n('saque_limite_diario', 3),
      saquePixInstantaneo: b('saque_pix_instantaneo'),
      tempoRespostaSeg: i('tempo_resposta_seg', 30),
    );
  }

  double taxaEntrega({double distanciaKm = 0, double subtotal = 0}) {
    if (permiteEntregaGratis &&
        entregaGratisAcimaDe > 0 &&
        subtotal >= entregaGratisAcimaDe) {
      return 0;
    }
    if (distanciaKm <= entregaBaseKm) return entregaBaseValor;
    return entregaBaseValor +
        ((distanciaKm - entregaBaseKm) * entregaKmExcedente);
  }

  String get taxaAPartirDeLabel {
    if (entregaBaseValor <= 0) return 'Grátis';
    return 'A partir de R\$ ${entregaBaseValor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String get tempoMedioLabel =>
      '$tempoMedioPreparoMin-${tempoMedioPreparoMin + 15} min';

  bool appAbaixoDaMinima({String versaoAtual = kAppVersion}) {
    final min = versaoMinimaApp.trim();
    if (min.isEmpty) return false;
    return _compareSemver(versaoAtual, min) < 0;
  }
}

int _compareSemver(String a, String b) {
  List<int> parts(String v) => v
      .split('+')
      .first
      .split('.')
      .map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
      .toList();
  final pa = parts(a);
  final pb = parts(b);
  final len = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < len; i++) {
    final xa = i < pa.length ? pa[i] : 0;
    final xb = i < pb.length ? pb[i] : 0;
    if (xa != xb) return xa.compareTo(xb);
  }
  return 0;
}

/// Espelha `fn_distancia_km_coords` no Postgres (coords inválidas ou > 200 km = 0).
const kDistanciaKmCap = 200.0;

double distanciaKmCoords({
  required double lat1,
  required double lng1,
  required double lat2,
  required double lng2,
}) {
  if (lat1.abs() > 90 || lat2.abs() > 90 || lng1.abs() > 180 || lng2.abs() > 180) {
    return 0;
  }
  const kmPorGrau = 111.045;
  final lat1r = lat1 * math.pi / 180;
  final lat2r = lat2 * math.pi / 180;
  final cosVal = (math.cos(lat1r) * math.cos(lat2r) * math.cos((lng2 - lng1) * math.pi / 180) +
          math.sin(lat1r) * math.sin(lat2r))
      .clamp(-1.0, 1.0);
  final km = kmPorGrau * math.acos(cosVal) * 180 / math.pi;
  if (km > kDistanciaKmCap) return 0;
  return km;
}

/// Distância usada na taxa: rota se passar na sanidade, senão Haversine.
/// Espelha `fn_distancia_entrega_km` no Postgres.
double distanciaEntregaKm({
  required double haversineKm,
  double? rotaKm,
}) {
  if (rotaKm == null) return haversineKm;
  if (rotaKm <= 0 || rotaKm > kDistanciaKmCap) return haversineKm;
  if (rotaKm > haversineKm * 1.5 + 2) return haversineKm;
  return (rotaKm * 100).round() / 100;
}

final plataformaRuntimeConfigProvider =
    FutureProvider<PlataformaRuntimeConfig>((ref) async {
  try {
    final rows = await Supabase.instance.client
        .from('v_plataforma_config_publica')
        .select('chave, valor');
    final map = <String, String>{};
    for (final row in rows as List) {
      final chave = row['chave']?.toString();
      if (chave == null || chave.isEmpty) continue;
      map[chave] = row['valor']?.toString() ?? '';
    }
    return PlataformaRuntimeConfig.fromMap(map);
  } catch (_) {
    return const PlataformaRuntimeConfig();
  }
});
