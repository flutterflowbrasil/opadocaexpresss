import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_notificacao_model.dart';

class AdminNotificacoesRepository {
  final SupabaseClient _client;

  AdminNotificacoesRepository(this._client);

  Future<List<AdminNotificacaoModel>> fetchAlertas() async {
    final results = await Future.wait([
      _fetchCadastrosPendentes(),
      _fetchChamadosUrgentes(),
      _fetchDocumentosPendentes(),
      _fetchPushFalhos(),
    ]);

    final alertas = results.expand((list) => list).toList();

    // Ordena: urgente → atenção → info, depois por data (mais recente primeiro)
    alertas.sort((a, b) {
      final pComp = a.prioridade.index.compareTo(b.prioridade.index);
      if (pComp != 0) return pComp;
      return b.criadoEm.compareTo(a.criadoEm);
    });

    return alertas;
  }

  Future<List<AdminNotificacaoModel>> _fetchCadastrosPendentes() async {
    final alertas = <AdminNotificacaoModel>[];

    // Entregadores pendentes
    // Usamos o hint da FK para evitar ambiguidade (há duas FKs para usuarios)
    final entregadores = await _client
        .from('entregadores')
        .select('id, created_at, usuarios!entregadores_usuario_id_fkey(nome_completo_fantasia)')
        .eq('status_cadastro', 'pendente')
        .order('created_at', ascending: false)
        .limit(10);

    for (final e in entregadores) {
      final usuarioData = (e['usuarios'] ?? e['entregadores_usuario_id_fkey']) as Map?;
      final nome = usuarioData?['nome_completo_fantasia'] as String? ?? 'Entregador';
      alertas.add(AdminNotificacaoModel(
        id: 'entregador_pendente_${e['id']}',
        tipo: AdminNotificacaoTipo.cadastroPendente,
        prioridade: AdminNotificacaoPrioridade.urgente,
        titulo: 'Entregador aguardando aprovação',
        descricao: nome,
        criadoEm: DateTime.parse(e['created_at'] as String),
        entidadeId: e['id'] as String,
        entidadeTipo: 'entregador',
        rota: 'entregadores',
      ));
    }

    // Estabelecimentos pendentes
    final estabs = await _client
        .from('estabelecimentos')
        .select('id, created_at, nome_fantasia, razao_social')
        .eq('status_cadastro', 'pendente')
        .order('created_at', ascending: false)
        .limit(10);

    for (final e in estabs) {
      final nome =
          (e['nome_fantasia'] ?? e['razao_social'] ?? 'Estabelecimento')
              as String;
      alertas.add(AdminNotificacaoModel(
        id: 'estab_pendente_${e['id']}',
        tipo: AdminNotificacaoTipo.cadastroPendente,
        prioridade: AdminNotificacaoPrioridade.urgente,
        titulo: 'Estabelecimento aguardando aprovação',
        descricao: nome,
        criadoEm: DateTime.parse(e['created_at'] as String),
        entidadeId: e['id'] as String,
        entidadeTipo: 'estabelecimento',
        rota: 'estabelecimentos',
      ));
    }

    return alertas;
  }

  Future<List<AdminNotificacaoModel>> _fetchChamadosUrgentes() async {
    final rows = await _client
        .from('suporte_chamados')
        .select('id, created_at, descricao, prioridade, categoria')
        .eq('status', 'aberto')
        .inFilter('prioridade', ['alta', 'urgente'])
        .order('created_at', ascending: false)
        .limit(10);

    return rows.map<AdminNotificacaoModel>((r) {
      final isUrgente = r['prioridade'] == 'urgente';
      return AdminNotificacaoModel(
        id: 'chamado_${r['id']}',
        tipo: AdminNotificacaoTipo.chamadoUrgente,
        prioridade: isUrgente
            ? AdminNotificacaoPrioridade.urgente
            : AdminNotificacaoPrioridade.atencao,
        titulo: 'Chamado ${isUrgente ? 'urgente' : 'de alta prioridade'}',
        descricao: (r['descricao'] as String? ?? '').length > 60
            ? '${(r['descricao'] as String).substring(0, 60)}...'
            : (r['descricao'] as String? ?? 'Sem descrição'),
        criadoEm: DateTime.parse(r['created_at'] as String),
        entidadeId: r['id'] as String,
        entidadeTipo: 'chamado',
        rota: 'suporte',
      );
    }).toList();
  }

  Future<List<AdminNotificacaoModel>> _fetchDocumentosPendentes() async {
    final alertas = <AdminNotificacaoModel>[];

    // Documentos entregadores pendentes (agregado — conta total)
    final docsEntregador = await _client
        .from('entregador_documentos')
        .select('id')
        .eq('status_validacao', 'pendente');

    if (docsEntregador.isNotEmpty) {
      alertas.add(AdminNotificacaoModel(
        id: 'docs_entregador_pendentes',
        tipo: AdminNotificacaoTipo.documentoPendente,
        prioridade: AdminNotificacaoPrioridade.atencao,
        titulo: 'Documentos de entregadores pendentes',
        descricao: '${docsEntregador.length} documento(s) aguardando validação',
        criadoEm: DateTime.now(),
        rota: 'entregadores',
      ));
    }

    // Documentos estabelecimentos pendentes
    final docsEstab = await _client
        .from('estabelecimento_documentos')
        .select('id')
        .eq('status_validacao', 'pendente');

    if (docsEstab.isNotEmpty) {
      alertas.add(AdminNotificacaoModel(
        id: 'docs_estab_pendentes',
        tipo: AdminNotificacaoTipo.documentoPendente,
        prioridade: AdminNotificacaoPrioridade.atencao,
        titulo: 'Documentos de estabelecimentos pendentes',
        descricao: '${docsEstab.length} documento(s) aguardando validação',
        criadoEm: DateTime.now(),
        rota: 'estabelecimentos',
      ));
    }

    return alertas;
  }

  Future<List<AdminNotificacaoModel>> _fetchPushFalhos() async {
    final rows = await _client
        .from('notificacoes_fila')
        .select('id, created_at, titulo, evento')
        .eq('status', 'falhou')
        .order('created_at', ascending: false)
        .limit(5);

    if (rows.isEmpty) return [];

    return [
      AdminNotificacaoModel(
        id: 'push_falhos_${rows.length}',
        tipo: AdminNotificacaoTipo.pushFalhou,
        prioridade: AdminNotificacaoPrioridade.atencao,
        titulo: 'Falhas no envio de push',
        descricao: '${rows.length} notificação(ões) falharam no envio',
        criadoEm: DateTime.parse(rows.first['created_at'] as String),
        rota: null,
      ),
    ];
  }
}
