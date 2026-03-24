import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/relatorio_adm_model.dart';

final relatorioAdmRepositoryProvider = Provider<RelatorioAdmRepository>(
  (ref) => RelatorioAdmRepository(Supabase.instance.client),
);

class RelatorioAdmRepository {
  final SupabaseClient _client;
  const RelatorioAdmRepository(this._client);

  Future<RelatorioSnapshot> fetchSnapshot(String periodo) async {
    final gte = _getTimeFilter(periodo);

    // Executa 6 queries em paralelo com fallback individual
    final futures = await Future.wait<List<Map<String, dynamic>>>([
      _fetchUsuarios().catchError((_) => <Map<String, dynamic>>[]),
      _fetchPedidos(gte).catchError((_) => <Map<String, dynamic>>[]),
      _fetchEntregadores().catchError((_) => <Map<String, dynamic>>[]),
      _fetchEstabelecimentos().catchError((_) => <Map<String, dynamic>>[]),
      _fetchAvaliacoes().catchError((_) => <Map<String, dynamic>>[]),
      _fetchChamados().catchError((_) => <Map<String, dynamic>>[]),
    ]);

    return RelatorioSnapshot(
      usuarios:        futures[0].map(UsuarioResumo.fromMap).toList(),
      pedidos:         futures[1].map(PedidoResumo.fromMap).toList(),
      entregadores:    futures[2].map(EntregadorResumo.fromMap).toList(),
      estabelecimentos:futures[3].map(EstabelecimentoResumo.fromMap).toList(),
      avaliacoes:      futures[4].map(AvaliacaoResumo.fromMap).toList(),
      chamados:        futures[5].map(ChamadoResumo.fromMap).toList(),
    );
  }



  Future<List<Map<String, dynamic>>> _fetchUsuarios() async {
    final r = await _client
        .from('usuarios')
        .select('id,tipo_usuario,status,email_verificado,telefone_verificado,created_at')
        .order('created_at', ascending: true);
    return r.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> _fetchPedidos(String? gte) async {
    var q = _client.from('pedidos').select(
        'id,status,pagamento_status,pagamento_metodo,'
        'subtotal_produtos,taxa_entrega,taxa_servico_app,'
        'desconto_cupom,total,split_processado,entregador_id,created_at');
    if (gte != null) q = q.gte('created_at', gte);
    final r = await q.order('created_at', ascending: true);
    return r.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> _fetchEntregadores() async {
    final r = await _client.from('entregadores').select(
        'id,status_cadastro,tipo_veiculo,total_entregas,avaliacao_media,ganhos_total,status_online,usuario_id');
    return r.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> _fetchEstabelecimentos() async {
    final r = await _client
        .from('estabelecimentos')
        .select('id,nome_fantasia,status_cadastro,total_pedidos,faturamento_total,avaliacao_media,created_at')
        .order('total_pedidos', ascending: false);
    return r.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> _fetchAvaliacoes() async {
    final r = await _client
        .from('avaliacoes')
        .select('id,nota_estabelecimento,nota_entregador,created_at')
        .order('created_at', ascending: false)
        .limit(200);
    return r.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> _fetchChamados() async {
    final r = await _client
        .from('suporte_chamados')
        .select('id,categoria,status,prioridade,created_at')
        .order('created_at', ascending: false)
        .limit(200);
    return r.cast<Map<String, dynamic>>();
  }


  String? _getTimeFilter(String periodo) {
    final now = DateTime.now().toUtc();
    return switch (periodo) {
      '7d' => now.subtract(const Duration(days: 7)).toIso8601String(),
      '30d' => now.subtract(const Duration(days: 30)).toIso8601String(),
      '12m' => DateTime(now.year - 1, now.month, now.day).toIso8601String(),
      _ => null,
    };
  }
}
