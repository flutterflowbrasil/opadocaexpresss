import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padoca_express/features/cliente/busca/busca_repository.dart';
import 'package:padoca_express/features/cliente/busca/models/resultado_busca_model.dart';

class BuscaResultadosScreen extends ConsumerStatefulWidget {
  final String termoInicial;

  const BuscaResultadosScreen({super.key, required this.termoInicial});

  @override
  ConsumerState<BuscaResultadosScreen> createState() =>
      _BuscaResultadosScreenState();
}

class _BuscaResultadosScreenState extends ConsumerState<BuscaResultadosScreen> {
  late final TextEditingController _controller;
  String _termo = '';

  static const _primaryColor = Color(0xFFFF7034);
  static const _secondaryColor = Color(0xFF7D2D35);

  @override
  void initState() {
    super.initState();
    _termo = widget.termoInicial;
    _controller = TextEditingController(text: _termo);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSubmit(String value) {
    setState(() => _termo = value.trim());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1917) : const Color(0xFFF9F5F0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF1C1917) : const Color(0xFFF9F5F0),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : _secondaryColor,
          ),
          onPressed: () => context.pop(),
        ),
        title: _BuscaTextField(
          controller: _controller,
          isDark: isDark,
          onSubmit: _onSubmit,
          autofocus: widget.termoInicial.isEmpty,
        ),
        titleSpacing: 0,
      ),
      body: _termo.isEmpty
          ? _EmptyPrompt(isDark: isDark)
          : _ResultadosBusca(
              termo: _termo,
              isDark: isDark,
            ),
    );
  }
}

// ─── Campo de busca no AppBar ──────────────────────────────────────────────────
class _BuscaTextField extends StatefulWidget {
  final TextEditingController controller;
  final bool isDark;
  final ValueChanged<String> onSubmit;
  final bool autofocus;

  const _BuscaTextField({
    required this.controller,
    required this.isDark,
    required this.onSubmit,
    required this.autofocus,
  });

  @override
  State<_BuscaTextField> createState() => _BuscaTextFieldState();
}

class _BuscaTextFieldState extends State<_BuscaTextField> {
  static const _primaryColor = Color(0xFFFF7034);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  void _submitSearch() {
    final texto = widget.controller.text.trim();
    if (texto.isNotEmpty) {
      FocusScope.of(context).unfocus();
      widget.onSubmit(texto);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;

    return Container(
      height: 42,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF27272A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        autofocus: widget.autofocus,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _submitSearch(),
        style: GoogleFonts.outfit(
          color: widget.isDark ? Colors.white : const Color(0xFF1C1917),
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Buscar padarias, doces, salgados...',
          hintStyle: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Colors.grey,
            size: 20,
          ),
          suffixIcon: hasText
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botão X — limpar
                    IconButton(
                      icon:
                          const Icon(Icons.close, size: 18, color: Colors.grey),
                      tooltip: 'Limpar',
                      onPressed: () {
                        widget.controller.clear();
                        widget.onSubmit('');
                      },
                    ),
                    // Botão buscar — dispara a pesquisa (Enter alternativo)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Material(
                        color: _primaryColor,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: _submitSearch,
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.search_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        ),
      ),
    );
  }
}

// ─── Resultados ───────────────────────────────────────────────────────────────
class _ResultadosBusca extends ConsumerWidget {
  final String termo;
  final bool isDark;

  const _ResultadosBusca({required this.termo, required this.isDark});

  static const _primaryColor = Color(0xFFFF7034);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(buscaProvider(termo));
    final cardColor = isDark ? const Color(0xFF27272A) : Colors.white;

    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: _primaryColor),
      ),
      error: (_, __) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Erro ao buscar. Tente novamente.',
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ],
        ),
      ),
      data: (resultados) {
        if (resultados.isEmpty) {
          return _EmptyResult(isDark: isDark, termo: termo);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          itemCount: resultados.length,
          itemBuilder: (context, index) {
            final item = resultados[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ResultadoCard(
                item: item,
                isDark: isDark,
                cardColor: cardColor,
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Card de resultado ────────────────────────────────────────────────────────
class _ResultadoCard extends StatelessWidget {
  final ResultadoBuscaModel item;
  final bool isDark;
  final Color cardColor;

  static const _primaryColor = Color(0xFFFF7034);
  static const _secondaryColor = Color(0xFF7D2D35);

  const _ResultadoCard({
    required this.item,
    required this.isDark,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // TODO: Navegar para detalhes do estabelecimento
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Em breve: detalhes de ${item.nome}'),
              backgroundColor: _primaryColor,
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Logo
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(20),
                ),
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: item.logoUrl != null
                      ? Image.network(
                          item.logoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _PlaceholderLogo(isDark: isDark),
                        )
                      : _PlaceholderLogo(isDark: isDark),
                ),
              ),

              // Info
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge de categoria
                      if (item.categoriaNome != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.categoriaNome!,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _primaryColor,
                            ),
                          ),
                        ),

                      Text(
                        item.nome,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : _secondaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      if (item.descricao != null && item.descricao!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            item.descricao!,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          // Status
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: item.statusAberto
                                  ? Colors.green[50]
                                  : Colors.red[50],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.statusAberto ? '● Aberto' : '● Fechado',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: item.statusAberto
                                    ? Colors.green[700]
                                    : Colors.red[700],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Avaliação
                          const Icon(Icons.star_rounded,
                              size: 13, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            item.avaliacaoMedia.toStringAsFixed(1),
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[700],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Taxa
                          if (item.taxaEntregaFormatada.isNotEmpty) ...[
                            const Icon(Icons.delivery_dining_rounded,
                                size: 13, color: Colors.grey),
                            const SizedBox(width: 2),
                            Text(
                              item.taxaEntregaFormatada,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: item.taxaEntregaFormatada == 'Grátis'
                                    ? Colors.green[600]
                                    : Colors.grey[500],
                                fontWeight:
                                    item.taxaEntregaFormatada == 'Grátis'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderLogo extends StatelessWidget {
  final bool isDark;
  const _PlaceholderLogo({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFEDE8E3),
      child: Center(
        child: Icon(
          Icons.store_rounded,
          size: 36,
          color: isDark
              ? Colors.white24
              : const Color(0xFF7D2D35).withValues(alpha: 0.2),
        ),
      ),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  final bool isDark;
  final String termo;
  const _EmptyResult({required this.isDark, required this.termo});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              'Nenhum resultado para\n"$termo"',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : const Color(0xFF7D2D35),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tente buscar por padarias, doces,\nsalgados ou outros produtos.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPrompt extends StatelessWidget {
  final bool isDark;
  const _EmptyPrompt({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_rounded, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'O que você está procurando?',
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
