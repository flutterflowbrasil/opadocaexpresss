import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'componentes_dash/sidebar_menu.dart';

final avaliacoesEstabelecimentoProvider = StateNotifierProvider.autoDispose<
    AvaliacoesEstabelecimentoController, AvaliacoesEstabelecimentoState>(
  (ref) => AvaliacoesEstabelecimentoController(
    AvaliacoesEstabelecimentoRepository(Supabase.instance.client),
  )..carregar(),
);

const _primary = Color(0xFFF97316);
const _surface = Color(0xFFF5F4F1);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _border = Color(0xFFE5E7EB);
const _green = Color(0xFF10B981);
const _red = Color(0xFFEF4444);

class AvaliacoesEstabelecimentoScreen extends ConsumerWidget {
  const AvaliacoesEstabelecimentoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(avaliacoesEstabelecimentoProvider);
    final notifier = ref.read(avaliacoesEstabelecimentoProvider.notifier);
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: _surface,
      drawer: isMobile
          ? SidebarMenu(activeId: 'reviews', onItemSelected: (_) {})
          : null,
      body: Builder(
        builder: (scaffoldContext) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMobile)
              SidebarMenu(activeId: 'reviews', onItemSelected: (_) {}),
            Expanded(
              child: Column(
                children: [
                  _Header(
                    isMobile: isMobile,
                    total: state.avaliacoes.length,
                    onMenu: () => Scaffold.of(scaffoldContext).openDrawer(),
                    onRefresh: notifier.carregar,
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: _primary,
                      onRefresh: notifier.carregar,
                      child: state.isLoading && state.avaliacoes.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : ListView(
                              padding: const EdgeInsets.all(24),
                              children: [
                                if (state.error != null)
                                  _ErrorBox(
                                    message: state.error!,
                                    onRetry: notifier.carregar,
                                  ),
                                _MetricsGrid(state: state),
                                const SizedBox(height: 18),
                                _Filters(
                                  selected: state.filtro,
                                  onChanged: notifier.alterarFiltro,
                                ),
                                const SizedBox(height: 14),
                                if (state.avaliacoesFiltradas.isEmpty)
                                  _EmptyState(filter: state.filtro)
                                else
                                  for (final avaliacao
                                      in state.avaliacoesFiltradas)
                                    _AvaliacaoCard(
                                      avaliacao: avaliacao,
                                      onResponder: () => _showRespostaDialog(
                                        context,
                                        ref,
                                        avaliacao,
                                      ),
                                    ),
                              ],
                            ),
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

  Future<void> _showRespostaDialog(
    BuildContext parentContext,
    WidgetRef ref,
    AvaliacaoEstabelecimento avaliacao,
  ) async {
    final controller = TextEditingController(
      text: avaliacao.respostaEstabelecimento ?? '',
    );
    bool isSaving = false;

    try {
      await showDialog<void>(
        context: parentContext,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setStateDialog) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Responder avaliação'),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      avaliacao.comentarioEstabelecimento?.trim().isNotEmpty ==
                              true
                          ? avaliacao.comentarioEstabelecimento!
                          : 'Cliente não deixou comentário.',
                      style: const TextStyle(color: _muted),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      minLines: 4,
                      maxLines: 6,
                      enabled: !isSaving,
                      decoration: InputDecoration(
                        labelText: 'Resposta da loja',
                        hintText: 'Agradeça ou esclareça a experiência...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: _primary, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSaving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final resposta = controller.text.trim();
                          if (resposta.isEmpty) {
                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              const SnackBar(
                                content: Text('Informe uma resposta.'),
                                backgroundColor: _red,
                              ),
                            );
                            return;
                          }

                          setStateDialog(() => isSaving = true);
                          final success = await ref
                              .read(avaliacoesEstabelecimentoProvider.notifier)
                              .responder(avaliacao.id, resposta);

                          if (!parentContext.mounted) return;
                          if (success) {
                            Navigator.pop(dialogContext);
                          } else {
                            setStateDialog(() => isSaving = false);
                          }

                          final error =
                              ref.read(avaliacoesEstabelecimentoProvider).error;
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? 'Resposta salva com sucesso.'
                                  : error ?? 'Não foi possível salvar.'),
                              backgroundColor: success ? _green : _red,
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Salvar resposta'),
                ),
              ],
            ),
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }
}

class AvaliacoesEstabelecimentoController
    extends StateNotifier<AvaliacoesEstabelecimentoState> {
  final AvaliacoesEstabelecimentoRepository _repository;

  AvaliacoesEstabelecimentoController(this._repository)
      : super(const AvaliacoesEstabelecimentoState());

  Future<void> carregar() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final avaliacoes = await _repository.buscarAvaliacoes();
      state = state.copyWith(isLoading: false, avaliacoes: avaliacoes);
    } catch (e, stack) {
      debugPrint('Erro ao buscar avaliações: $e\n$stack');
      state = state.copyWith(
        isLoading: false,
        error: 'Não foi possível carregar as avaliações.',
      );
    }
  }

  void alterarFiltro(AvaliacoesFiltro filtro) {
    state = state.copyWith(filtro: filtro, error: null);
  }

  Future<bool> responder(String avaliacaoId, String resposta) async {
    state = state.copyWith(error: null);
    try {
      final updated = await _repository.responder(avaliacaoId, resposta);
      state = state.copyWith(
        avaliacoes: [
          for (final avaliacao in state.avaliacoes)
            avaliacao.id == avaliacaoId ? updated : avaliacao,
        ],
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        error: 'Não foi possível salvar a resposta. Tente novamente.',
      );
      return false;
    }
  }
}

class AvaliacoesEstabelecimentoRepository {
  final SupabaseClient _client;

  const AvaliacoesEstabelecimentoRepository(this._client);

  Future<List<AvaliacaoEstabelecimento>> buscarAvaliacoes() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    final estabelecimento = await _client
        .from('estabelecimentos')
        .select('id')
        .eq('usuario_id', user.id)
        .maybeSingle();

    final estabelecimentoId = estabelecimento?['id'] as String?;
    if (estabelecimentoId == null) {
      throw Exception('Estabelecimento não encontrado');
    }

    final data = await _client
        .from('avaliacoes')
        .select('''
          id,
          pedido_id,
          cliente_id,
          nota_estabelecimento,
          comentario_estabelecimento,
          resposta_estabelecimento,
          respondido_em,
          tags,
          created_at,
          clientes(usuarios(nome_completo_fantasia)),
          pedidos(numero_pedido)
        ''')
        .eq('estabelecimento_id', estabelecimentoId)
        .not('nota_estabelecimento', 'is', null)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((item) =>
            AvaliacaoEstabelecimento.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AvaliacaoEstabelecimento> responder(
    String avaliacaoId,
    String resposta,
  ) async {
    final data = await _client
        .from('avaliacoes')
        .update({
          'resposta_estabelecimento': resposta,
          'respondido_em': DateTime.now().toIso8601String(),
        })
        .eq('id', avaliacaoId)
        .select('''
          id,
          pedido_id,
          cliente_id,
          nota_estabelecimento,
          comentario_estabelecimento,
          resposta_estabelecimento,
          respondido_em,
          tags,
          created_at,
          clientes(nome_completo_fantasia),
          pedidos(numero_pedido)
        ''')
        .single();

    return AvaliacaoEstabelecimento.fromJson(data);
  }
}

class AvaliacoesEstabelecimentoState {
  final bool isLoading;
  final String? error;
  final List<AvaliacaoEstabelecimento> avaliacoes;
  final AvaliacoesFiltro filtro;

  const AvaliacoesEstabelecimentoState({
    this.isLoading = false,
    this.error,
    this.avaliacoes = const [],
    this.filtro = AvaliacoesFiltro.todas,
  });

  List<AvaliacaoEstabelecimento> get avaliacoesFiltradas {
    switch (filtro) {
      case AvaliacoesFiltro.todas:
        return avaliacoes;
      case AvaliacoesFiltro.semResposta:
        return avaliacoes.where((a) => !a.respondida).toList();
      case AvaliacoesFiltro.comResposta:
        return avaliacoes.where((a) => a.respondida).toList();
      case AvaliacoesFiltro.criticas:
        return avaliacoes.where((a) => a.nota <= 3).toList();
      case AvaliacoesFiltro.altas:
        return avaliacoes.where((a) => a.nota >= 4).toList();
    }
  }

  double get media {
    if (avaliacoes.isEmpty) return 0;
    final total = avaliacoes.fold<double>(0, (sum, item) => sum + item.nota);
    return total / avaliacoes.length;
  }

  int get semResposta => avaliacoes.where((a) => !a.respondida).length;
  int get criticas => avaliacoes.where((a) => a.nota <= 3).length;

  AvaliacoesEstabelecimentoState copyWith({
    bool? isLoading,
    String? error,
    List<AvaliacaoEstabelecimento>? avaliacoes,
    AvaliacoesFiltro? filtro,
  }) {
    return AvaliacoesEstabelecimentoState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      avaliacoes: avaliacoes ?? this.avaliacoes,
      filtro: filtro ?? this.filtro,
    );
  }
}

enum AvaliacoesFiltro { todas, semResposta, comResposta, criticas, altas }

class AvaliacaoEstabelecimento {
  final String id;
  final String pedidoId;
  final String clienteId;
  final double nota;
  final String? comentarioEstabelecimento;
  final String? respostaEstabelecimento;
  final DateTime? respondidoEm;
  final List<String> tags;
  final DateTime? createdAt;
  final String clienteNome;
  final String? numeroPedido;

  const AvaliacaoEstabelecimento({
    required this.id,
    required this.pedidoId,
    required this.clienteId,
    required this.nota,
    required this.comentarioEstabelecimento,
    required this.respostaEstabelecimento,
    required this.respondidoEm,
    required this.tags,
    required this.createdAt,
    required this.clienteNome,
    required this.numeroPedido,
  });

  bool get respondida => respostaEstabelecimento?.trim().isNotEmpty == true;

  factory AvaliacaoEstabelecimento.fromJson(Map<String, dynamic> json) {
    final cliente = json['clientes'] as Map<String, dynamic>?;
    final pedido = json['pedidos'] as Map<String, dynamic>?;
    final tagsRaw = json['tags'];

    String? clienteNome;
    if (cliente != null && cliente['usuarios'] is Map) {
      clienteNome = cliente['usuarios']['nome_completo_fantasia'] as String?;
    }

    return AvaliacaoEstabelecimento(
      id: json['id'] as String,
      pedidoId: json['pedido_id'] as String,
      clienteId: json['cliente_id'] as String,
      nota: (json['nota_estabelecimento'] as num?)?.toDouble() ?? 0,
      comentarioEstabelecimento:
          json['comentario_estabelecimento'] as String?,
      respostaEstabelecimento:
          json['resposta_estabelecimento'] as String?,
      respondidoEm: json['respondido_em'] != null
          ? DateTime.parse(json['respondido_em'] as String)
          : null,
      tags: tagsRaw is List ? tagsRaw.map((e) => '$e').toList() : const [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      clienteNome: clienteNome ?? 'Cliente',
      numeroPedido: pedido?['numero_pedido']?.toString(),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isMobile;
  final int total;
  final VoidCallback onMenu;
  final Future<void> Function() onRefresh;

  const _Header({
    required this.isMobile,
    required this.total,
    required this.onMenu,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          if (isMobile) ...[
            IconButton(onPressed: onMenu, icon: const Icon(Icons.menu)),
            const SizedBox(width: 8),
          ],
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.star_rounded, color: _primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Avaliações',
                  style: GoogleFonts.publicSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _text,
                  ),
                ),
                Text(
                  '$total avaliações do estabelecimento',
                  style: const TextStyle(color: _muted, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final AvaliacoesEstabelecimentoState state;

  const _MetricsGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 1000
            ? 4
            : constraints.maxWidth > 620
                ? 2
                : 1;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 3.4,
          children: [
            _MetricCard(
              title: 'Nota média',
              value: state.media.toStringAsFixed(1),
              icon: Icons.star_rounded,
              color: _primary,
            ),
            _MetricCard(
              title: 'Avaliações',
              value: '${state.avaliacoes.length}',
              icon: Icons.rate_review_rounded,
              color: const Color(0xFF3B82F6),
            ),
            _MetricCard(
              title: 'Sem resposta',
              value: '${state.semResposta}',
              icon: Icons.chat_bubble_outline_rounded,
              color: const Color(0xFF8B5CF6),
            ),
            _MetricCard(
              title: 'Críticas',
              value: '${state.criticas}',
              icon: Icons.priority_high_rounded,
              color: _red,
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(color: _muted)),
                Text(
                  value,
                  style: GoogleFonts.publicSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final AvaliacoesFiltro selected;
  final ValueChanged<AvaliacoesFiltro> onChanged;

  const _Filters({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const items = [
      (AvaliacoesFiltro.todas, 'Todas'),
      (AvaliacoesFiltro.semResposta, 'Sem resposta'),
      (AvaliacoesFiltro.comResposta, 'Respondidas'),
      (AvaliacoesFiltro.criticas, 'Críticas'),
      (AvaliacoesFiltro.altas, '4-5 estrelas'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          ChoiceChip(
            label: Text(item.$2),
            selected: selected == item.$1,
            selectedColor: _primary.withValues(alpha: 0.14),
            labelStyle: TextStyle(
              color: selected == item.$1 ? _primary : _muted,
              fontWeight: FontWeight.w700,
            ),
            side: BorderSide(
              color: selected == item.$1
                  ? _primary.withValues(alpha: 0.35)
                  : _border,
            ),
            onSelected: (_) => onChanged(item.$1),
          ),
      ],
    );
  }
}

class _AvaliacaoCard extends StatelessWidget {
  final AvaliacaoEstabelecimento avaliacao;
  final VoidCallback onResponder;

  const _AvaliacaoCard({
    required this.avaliacao,
    required this.onResponder,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
    final createdAt = avaliacao.createdAt != null
        ? dateFormat.format(avaliacao.createdAt!.toLocal())
        : 'Sem data';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: _primary.withValues(alpha: 0.14),
                foregroundColor: _primary,
                child: Text(_initials(avaliacao.clienteNome)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      avaliacao.clienteNome,
                      style: GoogleFonts.publicSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _text,
                      ),
                    ),
                    Text(
                      [
                        if (avaliacao.numeroPedido != null)
                          'Pedido #${avaliacao.numeroPedido}',
                        createdAt,
                      ].join(' • '),
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _RatingPill(nota: avaliacao.nota),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            avaliacao.comentarioEstabelecimento?.trim().isNotEmpty == true
                ? avaliacao.comentarioEstabelecimento!
                : 'Cliente avaliou sem comentário.',
            style: const TextStyle(
              color: _text,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          if (avaliacao.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in avaliacao.tags)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ],
          if (avaliacao.respondida) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _green.withValues(alpha: 0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resposta da loja',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF047857),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    avaliacao.respostaEstabelecimento!,
                    style: const TextStyle(color: _text, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onResponder,
              icon: Icon(
                avaliacao.respondida
                    ? Icons.edit_note_rounded
                    : Icons.reply_rounded,
              ),
              label: Text(avaliacao.respondida ? 'Editar resposta' : 'Responder'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: const BorderSide(color: _primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'CL';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _RatingPill extends StatelessWidget {
  final double nota;

  const _RatingPill({required this.nota});

  @override
  Widget build(BuildContext context) {
    final color = nota >= 4 ? _green : nota >= 3 ? _primary : _red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            nota.toStringAsFixed(1),
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AvaliacoesFiltro filter;

  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Icon(Icons.reviews_outlined, color: Colors.grey[400], size: 46),
          const SizedBox(height: 12),
          Text(
            filter == AvaliacoesFiltro.todas
                ? 'Nenhuma avaliação recebida ainda'
                : 'Nenhuma avaliação nesse filtro',
            style: GoogleFonts.publicSans(
              fontWeight: FontWeight.w800,
              color: _text,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'As avaliações feitas pelos clientes aparecerão aqui.',
            style: TextStyle(color: _muted),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _red.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _red),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: _text))),
          TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}
