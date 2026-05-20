import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../controllers/produtos_controller.dart';
import '../models/produto_model.dart';
import '../models/produto_preco_tamanho_model.dart';

/// Abre o modal de criação ou edição de produto.
/// Passe [produto] para edição, ou null para novo produto.
void showProdutoFormModal(
  BuildContext context, {
  ProdutoModel? produto,
  String? estabelecimentoId,
}) {
  showGeneralDialog(
    context: context,
    barrierLabel: 'Produto Modal',
    barrierDismissible: true,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, anim1, anim2) => _ProdutoFormModal(
      produto: produto,
      estabelecimentoId: estabelecimentoId,
    ),
    transitionBuilder: (context, anim1, anim2, child) {
      final offset = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic));
      return SlideTransition(position: offset, child: child);
    },
  );
}

class _ProdutoFormModal extends ConsumerStatefulWidget {
  final ProdutoModel? produto;
  final String? estabelecimentoId;

  const _ProdutoFormModal({this.produto, this.estabelecimentoId});

  @override
  ConsumerState<_ProdutoFormModal> createState() => _ProdutoFormModalState();
}

class _ProdutoFormModalState extends ConsumerState<_ProdutoFormModal>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // --- Controladores dos campos ---
  // Tab Básico
  final _nomeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _ordemCtrl = TextEditingController(text: '0');
  String _tipoProduto = 'simples';
  List<String> _categoriaPrincipalIds = [];
  String? _categoriaId;
  bool _ativo = true;
  bool _disponivel = true;
  bool _destaque = false;
  bool _permiteObservacao = true;

  // Tab Preço
  final _precoCtrl = TextEditingController();
  final _precoPromoCtrl = TextEditingController();
  final _custoCtrl = TextEditingController();
  final _tempoPreparoCtrl = TextEditingController(text: '0');
  bool _temPromo = false;

  // Tab Estoque
  bool _controleEstoque = false;
  final _estoqueCtrl = TextEditingController();

  // Tab Opções
  List<Map<String, dynamic>> _opcoes = [];

  bool _categoriaPermiteAdicionais = true;
  bool _categoriaPermiteMultiplosPrecos = false;
  List<ProdutoPrecoTamanhoModel> _tamanhos = [];

  // Foto
  Uint8List? _fotoBytes;
  String _fotoExtensao = 'jpg';
  String? _fotoUrl; // URL existente (edição)

  bool get _isEdicao => widget.produto != null;

  int get _tabCount => _categoriaPermiteAdicionais ? 5 : 4;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);

    if (_isEdicao) {
      final p = widget.produto!;
      _nomeCtrl.text = p.nome;
      _descCtrl.text = p.descricao ?? '';
      _ordemCtrl.text = p.ordemExibicao.toString();
      _tipoProduto = p.tipoProduto;
      _categoriaPrincipalIds = p.categoriaPrincipalIds;
      _categoriaId = p.categoriaCardapioId;
      _ativo = p.ativo;
      _disponivel = p.disponivel;
      _destaque = p.destaque;
      _permiteObservacao = p.permiteObservacao;
      _precoCtrl.text = p.preco.toStringAsFixed(2);
      _precoPromoCtrl.text = p.precoPromocional?.toStringAsFixed(2) ?? '';
      _custoCtrl.text = p.custoEstimado?.toStringAsFixed(2) ?? '';
      _tempoPreparoCtrl.text = p.tempoPreparoAdicionalMin.toString();
      _temPromo = p.precoPromocional != null && p.precoPromocional! > 0;
      _controleEstoque = p.controleEstoque;
      _estoqueCtrl.text = p.quantidadeEstoque?.toString() ?? '';
      _fotoUrl = p.fotoPrincipalUrl;
      _opcoes = p.opcoes
          .whereType<Map>()
          .map((opcao) => Map<String, dynamic>.from(opcao))
          .toList();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _recalcularPermissoesDeCat();
        if (p.id.isNotEmpty) _carregarTamanhos(p.id);
      });
    }
  }

  // ── Seletor de imagem ─────────────────────────────────────────────────────
  Future<void> _pickImagem() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final ext = picked.name.split('.').last.toLowerCase();
    setState(() {
      _fotoBytes = bytes;
      _fotoExtensao = ext.isEmpty ? 'jpg' : ext;
      _fotoUrl = null; // descarta URL antiga; nova imagem tem precedência
    });
  }

  // ── Upload da foto para o Supabase Storage ────────────────────────────────
  Future<String?> _uploadFoto() async {
    if (_fotoBytes == null) return _fotoUrl;
    final path = 'produtos/${const Uuid().v4()}.$_fotoExtensao';
    await Supabase.instance.client.storage.from('imagens').uploadBinary(
          path,
          _fotoBytes!,
          fileOptions: FileOptions(contentType: 'image/$_fotoExtensao'),
        );
    return Supabase.instance.client.storage.from('imagens').getPublicUrl(path);
  }

  List<Map<String, dynamic>>? _normalizarOpcoes({bool mostrarErro = true}) {
    final normalizadas = <Map<String, dynamic>>[];
    final gruposOrdenados = [..._opcoes]
      ..sort((a, b) => _asInt(a['ordem'], 0).compareTo(_asInt(b['ordem'], 0)));

    for (var i = 0; i < gruposOrdenados.length; i++) {
      final grupo = gruposOrdenados[i];
      final nome = (grupo['nome'] ?? '').toString().trim();
      final tipo = grupo['tipo'] == 'unica' ? 'unica' : 'multipla';
      final obrigatorio = grupo['obrigatorio'] == true;
      final ativo = grupo['ativo'] != false;
      final minSelecoes = _asInt(grupo['min_selecoes'], 0);
      final maxSelecoes = tipo == 'unica' ? 1 : _asInt(grupo['max_selecoes'], 1);
      final itensRaw = (grupo['itens'] as List? ?? [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList()
        ..sort((a, b) =>
            _asInt(a['ordem'], 0).compareTo(_asInt(b['ordem'], 0)));

      if (nome.isEmpty) {
        return _opcoesInvalidas('Informe o nome de todos os grupos.',
            mostrarErro: mostrarErro);
      }
      if (obrigatorio && minSelecoes < 1) {
        return _opcoesInvalidas(
          'Grupo obrigatório precisa ter mínimo de seleções maior ou igual a 1.',
          mostrarErro: mostrarErro,
        );
      }
      if (minSelecoes > maxSelecoes) {
        return _opcoesInvalidas(
          'O mínimo de seleções não pode ser maior que o máximo.',
          mostrarErro: mostrarErro,
        );
      }

      final itens = <Map<String, dynamic>>[];
      for (var j = 0; j < itensRaw.length; j++) {
        final item = itensRaw[j];
        final itemNome = (item['nome'] ?? '').toString().trim();
        final descricao = (item['descricao'] ?? '').toString().trim();
        final preco = _asDouble(item['preco'], 0);
        final itemAtivo = item['ativo'] != false;

        if (itemNome.isEmpty) {
          return _opcoesInvalidas('Informe o nome de todos os adicionais.',
              mostrarErro: mostrarErro);
        }
        if (preco < 0) {
          return _opcoesInvalidas('O preço do adicional não pode ser negativo.',
              mostrarErro: mostrarErro);
        }

        itens.add({
          'id': (item['id'] ?? const Uuid().v4()).toString(),
          'nome': itemNome,
          'descricao': descricao.isEmpty ? null : descricao,
          'preco': preco,
          'ativo': itemAtivo,
          'ordem': j + 1,
        });
      }

      if (ativo && !itens.any((item) => item['ativo'] == true)) {
        return _opcoesInvalidas(
          'Grupo ativo precisa ter ao menos um item ativo.',
          mostrarErro: mostrarErro,
        );
      }

      normalizadas.add({
        'id': (grupo['id'] ?? const Uuid().v4()).toString(),
        'nome': nome,
        'tipo': tipo,
        'obrigatorio': obrigatorio,
        'min_selecoes': minSelecoes,
        'max_selecoes': maxSelecoes,
        'ordem': i + 1,
        'ativo': ativo,
        'itens': itens,
      });
    }

    return normalizadas;
  }

  List<Map<String, dynamic>>? _opcoesInvalidas(
    String mensagem, {
    required bool mostrarErro,
  }) {
    if (mostrarErro && mounted) {
      _tabController.animateTo(3);
      _mostrarToast(mensagem, isError: true);
    }
    return null;
  }

  int _asInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double _asDouble(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    return double.tryParse((value?.toString() ?? '').replaceAll(',', '.')) ??
        fallback;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomeCtrl.dispose();
    _descCtrl.dispose();
    _ordemCtrl.dispose();
    _precoCtrl.dispose();
    _precoPromoCtrl.dispose();
    _custoCtrl.dispose();
    _tempoPreparoCtrl.dispose();
    _estoqueCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar({bool fecharAoFim = true}) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      // Se o campo nome está vazio, muda para a aba básico
      _tabController.animateTo(0);
      return;
    }

    final opcoesNormalizadas = _normalizarOpcoes();
    if (opcoesNormalizadas == null) return;

    final temOpcoesAtivas = opcoesNormalizadas.any((grupo) {
      if (grupo['ativo'] != true) return false;
      final itens = grupo['itens'] as List? ?? [];
      return itens.any((item) => item is Map && item['ativo'] == true);
    });
    final tipoProdutoFinal = temOpcoesAtivas ? 'variavel' : _tipoProduto;

    setState(() => _isSaving = true);

    final estabId = widget.estabelecimentoId ??
        widget.produto?.estabelecimentoId ??
        ref
            .read(produtosControllerProvider)
            .produtos
            .firstOrNull
            ?.estabelecimentoId ??
        '';

    // Faz upload da foto (se selecionada) antes de salvar o produto
    String? fotoUrl;
    try {
      fotoUrl = await _uploadFoto();
    } catch (_) {
      // Upload falhou — salva o produto sem a nova foto
      fotoUrl = _fotoUrl;
    }

    final preco = double.tryParse(_precoCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final precoPromo = _temPromo
        ? double.tryParse(_precoPromoCtrl.text.replaceAll(',', '.'))
        : null;
    final custo = double.tryParse(_custoCtrl.text.replaceAll(',', '.'));
    final estoque = _controleEstoque ? int.tryParse(_estoqueCtrl.text) : null;

    final novoProduto = ProdutoModel(
      id: widget.produto?.id ?? '',
      estabelecimentoId: estabId,
      nome: _nomeCtrl.text.trim(),
      descricao: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      preco: preco,
      precoPromocional: precoPromo,
      custoEstimado: custo,
      categoriaPrincipalIds: _categoriaPrincipalIds,
      categoriaCardapioId: _categoriaId,
      tipoProduto: tipoProdutoFinal,
      ativo: _ativo,
      disponivel: _disponivel,
      destaque: _destaque,
      permiteObservacao: _permiteObservacao,
      controleEstoque: _controleEstoque,
      quantidadeEstoque: estoque,
      tempoPreparoAdicionalMin: int.tryParse(_tempoPreparoCtrl.text) ?? 0,
      ordemExibicao: int.tryParse(_ordemCtrl.text) ?? 0,
      fotoPrincipalUrl: fotoUrl,
      totalVendidos: widget.produto?.totalVendidos ?? 0,
      opcoes: opcoesNormalizadas,
    );

    await ref
        .read(produtosControllerProvider.notifier)
        .salvarProduto(
          novoProduto,
          categoriaPermiteAdicionais: _categoriaPermiteAdicionais,
          tamanhos: _tamanhos,
          categoriaPermiteMultiplosPrecos: _categoriaPermiteMultiplosPrecos,
        );

    setState(() => _isSaving = false);

    if (mounted) {
      final err = ref.read(produtosControllerProvider).error;
      if (err == null) {
        _mostrarToast(fecharAoFim
            ? (_isEdicao ? 'Produto atualizado! ✓' : 'Produto criado! ✓')
            : 'Salvo! Editando próximo produto...');
        if (fecharAoFim) Navigator.of(context).pop();
      } else {
        _mostrarToast('Erro: $err', isError: true);
      }
    }
  }

  void _mostrarToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(msg, style: GoogleFonts.publicSans(fontWeight: FontWeight.w600)),
      backgroundColor: isError ? Colors.red.shade700 : const Color(0xFFec5b13),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _onCategoriaPrincipalToggled(String categoriaId) {
    setState(() {
      if (_categoriaPrincipalIds.contains(categoriaId)) {
        _categoriaPrincipalIds =
            _categoriaPrincipalIds.where((id) => id != categoriaId).toList();
      } else {
        _categoriaPrincipalIds = [..._categoriaPrincipalIds, categoriaId];
      }
      _recalcularPermissoesDeCat();
    });
  }

  void _recalcularPermissoesDeCat() {
    final ctrl = ref.read(produtosControllerProvider.notifier);
    final catId =
        _categoriaPrincipalIds.isNotEmpty ? _categoriaPrincipalIds.first : null;
    final cat = ctrl.getCategoriaById(catId);
    _categoriaPermiteAdicionais = cat?.permiteAdicionais ?? true;
    _categoriaPermiteMultiplosPrecos = cat?.permiteMultiplosPrecos ?? false;
    if (!_categoriaPermiteAdicionais) _opcoes = [];
    if (!_categoriaPermiteMultiplosPrecos) {
      _tamanhos = _tamanhos.map((t) => t.copyWith(ativo: false)).toList();
    }
  }

  Future<void> _carregarTamanhos(String produtoId) async {
    final ctrl = ref.read(produtosControllerProvider.notifier);
    final tamanhos = await ctrl.fetchTamanhos(produtoId);
    if (mounted) setState(() => _tamanhos = tamanhos.where((t) => t.ativo).toList());
  }

  @override
  Widget build(BuildContext context) {
    final categorias =
        ref.watch(produtosControllerProvider.select((s) => s.categorias));
    final categoriasPrincipais = ref.watch(
        produtosControllerProvider.select((s) => s.categoriasPrincipais));
    final screenW = MediaQuery.of(context).size.width;
    final modalWidth = screenW < 700 ? screenW : 640.0;

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: modalWidth,
          height: double.infinity,
          color: Colors.white,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // ── Header ──
                _ModalHeader(
                  isEdicao: _isEdicao,
                  isSaving: _isSaving,
                  onClose: () => Navigator.of(context).pop(),
                ),

                // ── Tabs ──
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFFec5b13),
                    unselectedLabelColor: Colors.grey.shade500,
                    indicatorColor: const Color(0xFFec5b13),
                    indicatorWeight: 2.5,
                    labelStyle: GoogleFonts.publicSans(
                        fontSize: 13, fontWeight: FontWeight.bold),
                    unselectedLabelStyle: GoogleFonts.publicSans(fontSize: 13),
                    tabs: [
                      Tab(
                          icon: Icon(Icons.info_outline, size: 18),
                          text: 'Básico'),
                      Tab(
                          icon: Icon(Icons.payments_outlined, size: 18),
                          text: 'Preço'),
                      Tab(
                          icon: Icon(Icons.inventory_2_outlined, size: 18),
                          text: 'Estoque'),
                      if (_categoriaPermiteAdicionais)
                        Tab(icon: Icon(Icons.tune, size: 18), text: 'Opções'),
                      Tab(
                          icon: Text('🍰',
                              style: TextStyle(fontSize: 16)),
                          text: 'Ult. Mordida'),
                    ],
                  ),
                ),

                // ── Conteúdo das Abas ──
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // 1. Básico
                      _TabBasico(
                        nomeCtrl: _nomeCtrl,
                        descCtrl: _descCtrl,
                        ordemCtrl: _ordemCtrl,
                        tipoProduto: _tipoProduto,
                        categoriasPrincipais: categoriasPrincipais,
                        categoriaPrincipalIds: _categoriaPrincipalIds,
                        categorias: categorias,
                        categoriaId: _categoriaId,
                        ativo: _ativo,
                        disponivel: _disponivel,
                        destaque: _destaque,
                        permiteObservacao: _permiteObservacao,
                        fotoBytes: _fotoBytes,
                        fotoUrl: _fotoUrl,
                        onPickFoto: _pickImagem,
                        onTipoChanged: (v) =>
                            setState(() => _tipoProduto = v ?? 'simples'),
                        onCategoriaPrincipalToggled: _onCategoriaPrincipalToggled,
                        onCategoriaChanged: (v) =>
                            setState(() => _categoriaId = v),
                        onAtivoChanged: (v) => setState(() => _ativo = v),
                        onDisponivelChanged: (v) =>
                            setState(() => _disponivel = v),
                        onDestaqueChanged: (v) => setState(() => _destaque = v),
                        onObsChanged: (v) =>
                            setState(() => _permiteObservacao = v),
                      ),
                      // 2. Preço
                      _TabPreco(
                        precoCtrl: _precoCtrl,
                        precoPromoCtrl: _precoPromoCtrl,
                        custoCtrl: _custoCtrl,
                        tempoPreparoCtrl: _tempoPreparoCtrl,
                        temPromo: _temPromo,
                        onTemPromoChanged: (v) => setState(() => _temPromo = v),
                        permiteMultiplosPrecos: _categoriaPermiteMultiplosPrecos,
                        tamanhos: _tamanhos,
                        onAdicionarTamanho: (t) => setState(() {
                          final idx = _tamanhos
                              .indexWhere((x) => x.nomeTamanho == t.nomeTamanho);
                          if (idx >= 0) {
                            _tamanhos = [..._tamanhos]..[idx] = t;
                          } else {
                            _tamanhos = [
                              ..._tamanhos,
                              t.copyWith(ordem: _tamanhos.length)
                            ];
                          }
                        }),
                        onEditarTamanho: (t) => setState(() {
                          _tamanhos =
                              _tamanhos.map((x) => x.id == t.id ? t : x).toList();
                        }),
                        onRemoverTamanho: (t) => setState(() {
                          _tamanhos = _tamanhos
                              .map((x) =>
                                  x.id == t.id ? x.copyWith(ativo: false) : x)
                              .toList();
                        }),
                      ),
                      // 3. Estoque
                      _TabEstoque(
                        controleEstoque: _controleEstoque,
                        estoqueCtrl: _estoqueCtrl,
                        onControleChanged: (v) =>
                            setState(() => _controleEstoque = v),
                      ),
                      // 4. Opções
                      _TabOpcoes(
                        opcoes: _opcoes,
                        onChanged: (opcoes) => setState(() => _opcoes = opcoes),
                      ),
                      // 5. Última Mordida
                      _TabUltimaMordida(produto: widget.produto),
                    ],
                  ),
                ),

                // ── Footer com botões ──
                _ModalFooter(
                  isSaving: _isSaving,
                  isEdicao: _isEdicao,
                  onCancel: () => Navigator.of(context).pop(),
                  onSaveAndContinue: () => _salvar(fecharAoFim: false),
                  onSave: () => _salvar(fecharAoFim: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// HEADER
// ═══════════════════════════════════════════
class _ModalHeader extends StatelessWidget {
  final bool isEdicao;
  final bool isSaving;
  final VoidCallback onClose;

  const _ModalHeader({
    required this.isEdicao,
    required this.isSaving,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdicao ? 'Editar Produto' : 'Novo Produto',
                  style: GoogleFonts.publicSans(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  isEdicao
                      ? 'Atualize as informações do produto'
                      : 'Preencha os dados do novo produto',
                  style: GoogleFonts.publicSans(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          if (isSaving)
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFFec5b13))),
          const SizedBox(width: 12),
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Icon(Icons.close, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// FOOTER
// ═══════════════════════════════════════════
class _ModalFooter extends StatelessWidget {
  final bool isSaving;
  final bool isEdicao;
  final VoidCallback onCancel;
  final VoidCallback onSaveAndContinue;
  final VoidCallback onSave;

  const _ModalFooter({
    required this.isSaving,
    required this.isEdicao,
    required this.onCancel,
    required this.onSaveAndContinue,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: isSaving ? null : onCancel,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            child: Text('Cancelar',
                style: GoogleFonts.publicSans(fontWeight: FontWeight.w600)),
          ),
          const Spacer(),
          if (!isEdicao) ...[
            OutlinedButton(
              onPressed: isSaving ? null : onSaveAndContinue,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFec5b13),
                side: const BorderSide(color: Color(0xFFec5b13)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              child: Text('Salvar e criar outro',
                  style: GoogleFonts.publicSans(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 12),
          ],
          ElevatedButton(
            onPressed: isSaving ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFec5b13),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            child: Text(
              isEdicao ? 'Atualizar Produto' : 'Salvar Produto',
              style: GoogleFonts.publicSans(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// TAB 1 — BÁSICO
// ═══════════════════════════════════════════
class _TabBasico extends StatelessWidget {
  final TextEditingController nomeCtrl;
  final TextEditingController descCtrl;
  final TextEditingController ordemCtrl;
  final String tipoProduto;
  final List categoriasPrincipais;
  final List<String> categoriaPrincipalIds;
  final List categorias;
  final String? categoriaId;
  final bool ativo;
  final bool disponivel;
  final bool destaque;
  final bool permiteObservacao;
  // Foto
  final Uint8List? fotoBytes;
  final String? fotoUrl;
  final VoidCallback onPickFoto;
  final ValueChanged<String?> onTipoChanged;
  final ValueChanged<String> onCategoriaPrincipalToggled;
  final ValueChanged<String?> onCategoriaChanged;
  final ValueChanged<bool> onAtivoChanged;
  final ValueChanged<bool> onDisponivelChanged;
  final ValueChanged<bool> onDestaqueChanged;
  final ValueChanged<bool> onObsChanged;

  const _TabBasico({
    required this.nomeCtrl,
    required this.descCtrl,
    required this.ordemCtrl,
    required this.tipoProduto,
    required this.categoriasPrincipais,
    required this.categoriaPrincipalIds,
    required this.categorias,
    required this.categoriaId,
    required this.ativo,
    required this.disponivel,
    required this.destaque,
    required this.permiteObservacao,
    required this.fotoBytes,
    required this.fotoUrl,
    required this.onPickFoto,
    required this.onTipoChanged,
    required this.onCategoriaPrincipalToggled,
    required this.onCategoriaChanged,
    required this.onAtivoChanged,
    required this.onDisponivelChanged,
    required this.onDestaqueChanged,
    required this.onObsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final temFoto = fotoBytes != null || fotoUrl != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Foto Principal ──
          _SectionLabel('Foto Principal',
              subtitle: 'Recomendado: 1200×900px, JPG ou PNG.'),
          const SizedBox(height: 10),
          Row(
            children: [
              // Preview / Placeholder
              GestureDetector(
                onTap: onPickFoto,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: temFoto
                          ? const Color(0xFFec5b13).withValues(alpha: .5)
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    image: fotoBytes != null
                        ? DecorationImage(
                            image: MemoryImage(fotoBytes!),
                            fit: BoxFit.cover,
                          )
                        : fotoUrl != null
                            ? DecorationImage(
                                image: NetworkImage(fotoUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                  ),
                  child: temFoto
                      ? null
                      : Icon(Icons.add_photo_alternate_outlined,
                          color: Colors.grey.shade400, size: 36),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onPickFoto,
                      icon: const Icon(Icons.upload_rounded, size: 16),
                      label: Text(
                        temFoto ? 'Trocar imagem' : 'Selecionar imagem',
                        style: GoogleFonts.publicSans(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFec5b13),
                        side: const BorderSide(color: Color(0xFFec5b13)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      temFoto
                          ? '✓ Imagem selecionada'
                          : 'Nenhuma imagem selecionada',
                      style: GoogleFonts.publicSans(
                        fontSize: 11,
                        color: temFoto
                            ? Colors.green.shade600
                            : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Nome (obrigatório)
          _SectionLabel('Nome do Produto *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: nomeCtrl,
            style: GoogleFonts.publicSans(fontSize: 14),
            decoration: _inputDecoration('Ex: Pão de Queijo Artesanal'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Nome obrigatório' : null,
          ),
          const SizedBox(height: 16),

          // Descrição
          _SectionLabel('Descrição'),
          const SizedBox(height: 8),
          TextFormField(
            controller: descCtrl,
            style: GoogleFonts.publicSans(fontSize: 14),
            decoration:
                _inputDecoration('Ingredientes, modo de preparo, porção...'),
            maxLines: 3,
            minLines: 2,
          ),
          const SizedBox(height: 16),

          _SectionLabel('Categoria Principal'),
          const SizedBox(height: 8),
          _CategoriaPrincipalDropdown(
            categorias: categoriasPrincipais,
            selectedIds: categoriaPrincipalIds,
            onToggle: onCategoriaPrincipalToggled,
          ),
          const SizedBox(height: 16),

          // Categoria secundária + Tipo Produto
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel('Categoria Secundária'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: categoriaId,
                      style: GoogleFonts.publicSans(
                          fontSize: 14, color: Colors.black87),
                      decoration: _inputDecoration('Selecione'),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Sem categoria',
                              style: GoogleFonts.publicSans(fontSize: 14)),
                        ),
                        ...categorias.map((c) => DropdownMenuItem(
                              value: c.id as String,
                              child: Text(c.nome as String,
                                  style: GoogleFonts.publicSans(fontSize: 14),
                                  overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: onCategoriaChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel('Tipo de Produto'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: tipoProduto,
                      style: GoogleFonts.publicSans(
                          fontSize: 14, color: Colors.black87),
                      decoration: _inputDecoration(null),
                      items: [
                        DropdownMenuItem(
                            value: 'simples',
                            child: Text('Simples',
                                style: GoogleFonts.publicSans(fontSize: 14))),
                        DropdownMenuItem(
                            value: 'variavel',
                            child: Text('Variável',
                                style: GoogleFonts.publicSans(fontSize: 14))),
                      ],
                      onChanged: onTipoChanged,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Ordem de Exibição
          _SectionLabel('Ordem de Exibição'),
          const SizedBox(height: 8),
          SizedBox(
            width: 140,
            child: TextFormField(
              controller: ordemCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.publicSans(fontSize: 14),
              decoration: _inputDecoration('0'),
            ),
          ),
          const SizedBox(height: 24),

          // Toggles
          _SectionLabel('Configurações'),
          const SizedBox(height: 12),
          _ToggleRow(
              title: 'Produto Ativo',
              subtitle: 'Visível no cardápio',
              value: ativo,
              onChanged: onAtivoChanged),
          _ToggleRow(
              title: 'Disponível Agora',
              subtitle: 'Aceita pedidos no momento',
              value: disponivel,
              onChanged: onDisponivelChanged),
          _ToggleRow(
              title: 'Produto em Destaque',
              subtitle: 'Aparece na seção de destaques',
              value: destaque,
              onChanged: onDestaqueChanged),
          _ToggleRow(
              title: 'Aceita Observação',
              subtitle: 'Cliente pode adicionar notas ao pedido',
              value: permiteObservacao,
              onChanged: onObsChanged),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// TAB 2 — PREÇO
// ═══════════════════════════════════════════
class _CategoriaPrincipalDropdown extends StatelessWidget {
  final List categorias;
  final List<String> selectedIds;
  final ValueChanged<String> onToggle;

  const _CategoriaPrincipalDropdown({
    required this.categorias,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final selectedNames = categorias
        .where((c) => selectedIds.contains(c.id as String))
        .map((c) => c.nome as String)
        .toList();

    final label = selectedNames.isEmpty
        ? 'Selecione uma ou mais categorias'
        : selectedNames.join(', ');

    return PopupMenuButton<String>(
      tooltip: 'Selecionar categorias principais',
      onSelected: onToggle,
      constraints: const BoxConstraints(minWidth: 320, maxWidth: 420),
      itemBuilder: (context) {
        if (categorias.isEmpty) {
          return [
            PopupMenuItem<String>(
              enabled: false,
              child: Text(
                'Nenhuma categoria principal ativa',
                style: GoogleFonts.publicSans(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ];
        }

        return categorias
            .map(
              (c) => CheckedPopupMenuItem<String>(
                value: c.id as String,
                checked: selectedIds.contains(c.id as String),
                child: Text(
                  c.nome as String,
                  style: GoogleFonts.publicSans(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList();
      },
      child: InputDecorator(
        decoration: _inputDecoration('Selecione'),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.publicSans(
                  fontSize: 14,
                  color: selectedNames.isEmpty
                      ? Colors.grey.shade500
                      : Colors.black87,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }
}

class _TabPreco extends StatelessWidget {
  final TextEditingController precoCtrl;
  final TextEditingController precoPromoCtrl;
  final TextEditingController custoCtrl;
  final TextEditingController tempoPreparoCtrl;
  final bool temPromo;
  final ValueChanged<bool> onTemPromoChanged;
  final bool permiteMultiplosPrecos;
  final List<ProdutoPrecoTamanhoModel> tamanhos;
  final void Function(ProdutoPrecoTamanhoModel) onAdicionarTamanho;
  final void Function(ProdutoPrecoTamanhoModel) onEditarTamanho;
  final void Function(ProdutoPrecoTamanhoModel) onRemoverTamanho;

  const _TabPreco({
    required this.precoCtrl,
    required this.precoPromoCtrl,
    required this.custoCtrl,
    required this.tempoPreparoCtrl,
    required this.temPromo,
    required this.onTemPromoChanged,
    this.permiteMultiplosPrecos = false,
    this.tamanhos = const [],
    required this.onAdicionarTamanho,
    required this.onEditarTamanho,
    required this.onRemoverTamanho,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preço Normal
          _SectionLabel('Preço Normal (R\$) *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: precoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.publicSans(fontSize: 14),
            decoration: _inputDecoration('0,00').copyWith(
                prefixText: 'R\$ ',
                prefixStyle: GoogleFonts.publicSans(
                    color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
            validator: (v) {
              final val = double.tryParse(v?.replaceAll(',', '.') ?? '');
              if (val == null || val <= 0) return 'Informe um preço válido';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Preço Promocional
          Row(
            children: [
              _SectionLabel('Preço Promocional (R\$)'),
              const Spacer(),
              Transform.scale(
                scale: 0.85,
                child: Switch.adaptive(
                  value: temPromo,
                  activeTrackColor: const Color(0xFFec5b13),
                  onChanged: onTemPromoChanged,
                ),
              ),
              Text('Ativar promoção',
                  style: GoogleFonts.publicSans(
                      fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: temPromo ? 1.0 : 0.4,
            child: IgnorePointer(
              ignoring: !temPromo,
              child: TextFormField(
                controller: precoPromoCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.publicSans(fontSize: 14),
                decoration: _inputDecoration('0,00').copyWith(
                  prefixText: 'R\$ ',
                  prefixStyle: GoogleFonts.publicSans(
                      color: Colors.pink.shade400, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Custo Estimado
          _SectionLabel('Custo Estimado (R\$)',
              subtitle: 'Uso interno — não exibido ao cliente'),
          const SizedBox(height: 8),
          TextFormField(
            controller: custoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.publicSans(fontSize: 14),
            decoration: _inputDecoration('0,00').copyWith(
                prefixText: 'R\$ ',
                prefixStyle: GoogleFonts.publicSans(
                    color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),

          // Tempo Preparo
          _SectionLabel('Tempo de Preparo Adicional (min)',
              subtitle: 'Adicionado ao tempo base do estabelecimento'),
          const SizedBox(height: 8),
          SizedBox(
            width: 160,
            child: TextFormField(
              controller: tempoPreparoCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.publicSans(fontSize: 14),
              decoration: _inputDecoration('0').copyWith(suffixText: ' min'),
            ),
          ),
          const SizedBox(height: 24),

          // Info margem
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFec5b13).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFec5b13).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.trending_up,
                    color: Color(0xFFec5b13), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'A margem de lucro estimada é calculada automaticamente ao informar o preço e o custo estimado do produto.',
                    style: GoogleFonts.publicSans(
                        fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),

          // Tamanhos/Precos (apenas para Pizza)
          if (permiteMultiplosPrecos) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tamanhos e Preços',
                    style: GoogleFonts.publicSans(fontSize: 14, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => _showTamanhoDialog(context, null, onAdicionarTamanho),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text('+ Adicionar',
                      style: GoogleFonts.publicSans(fontSize: 13)),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFec5b13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...tamanhos.where((t) => t.ativo).map((t) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200)),
              child: Row(children: [
                const Icon(Icons.local_pizza_outlined, size: 18, color: Color(0xFFec5b13)),
                const SizedBox(width: 10),
                Expanded(child: Text(t.nomeTamanho,
                    style: GoogleFonts.publicSans(fontWeight: FontWeight.w600))),
                Text('R\$ ${t.preco.toStringAsFixed(2).replaceAll(".",",")}',
                    style: GoogleFonts.publicSans(fontWeight: FontWeight.bold,
                        color: const Color(0xFFec5b13))),
                IconButton(icon: const Icon(Icons.edit_outlined, size: 16),
                  onPressed: () => _showTamanhoDialog(context, t, onEditarTamanho),
                  visualDensity: VisualDensity.compact),
                IconButton(icon: Icon(Icons.delete_outline, size: 16, color: Colors.red.shade400),
                  onPressed: () => onRemoverTamanho(t),
                  visualDensity: VisualDensity.compact),
              ]),
            )),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
void _showTamanhoDialog(
  BuildContext context,
  ProdutoPrecoTamanhoModel? existente,
  void Function(ProdutoPrecoTamanhoModel) onSalvar,
) {
  final nomeCtrl = TextEditingController(text: existente?.nomeTamanho ?? '');
  final precoCtrl = TextEditingController(
      text: existente != null ? existente.preco.toStringAsFixed(2) : '');
  final formKey = GlobalKey<FormState>();
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(existente == null ? 'Novo Tamanho' : 'Editar Tamanho',
          style: GoogleFonts.publicSans(fontWeight: FontWeight.bold)),
      content: Form(
        key: formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            controller: nomeCtrl,
            decoration: InputDecoration(labelText: 'Nome do tamanho',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            textCapitalization: TextCapitalization.words,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null),
          const SizedBox(height: 12),
          TextFormField(
            controller: precoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Preco (R\$)', prefixText: 'R\$ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            validator: (v) {
              final val = double.tryParse(v?.replaceAll(',', '.') ?? '');
              if (val == null || val <= 0) return 'Preco invalido';
              return null;
            }),
        ])),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFec5b13), foregroundColor: Colors.white),
          onPressed: () {
            if (!(formKey.currentState?.validate() ?? false)) return;
            onSalvar(ProdutoPrecoTamanhoModel(
              id: existente?.id ?? '',
              produtoId: existente?.produtoId ?? '',
              nomeTamanho: nomeCtrl.text.trim(),
              preco: double.parse(precoCtrl.text.replaceAll(',', '.')),
              ordem: existente?.ordem ?? 0,
            ));
            Navigator.of(ctx).pop();
          },
          child: Text('Salvar',
              style: GoogleFonts.publicSans(fontWeight: FontWeight.bold))),
      ],
    ),
  );
}

// TAB 3 — ESTOQUE
// ═══════════════════════════════════════════
class _TabEstoque extends StatelessWidget {
  final bool controleEstoque;
  final TextEditingController estoqueCtrl;
  final ValueChanged<bool> onControleChanged;

  const _TabEstoque({
    required this.controleEstoque,
    required this.estoqueCtrl,
    required this.onControleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ToggleRow(
            title: 'Controlar Estoque',
            subtitle: 'Habilita o controle de quantidade disponível',
            value: controleEstoque,
            onChanged: onControleChanged,
            elevated: true,
          ),
          const SizedBox(height: 20),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: controleEstoque ? 1.0 : 0.4,
            child: IgnorePointer(
              ignoring: !controleEstoque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('Quantidade em Estoque'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: estoqueCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: GoogleFonts.publicSans(fontSize: 14),
                    decoration:
                        _inputDecoration('0').copyWith(suffixText: ' unidades'),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.amber.shade700, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Alerta de Estoque Baixo: Você será notificado quando o estoque atingir 5 unidades ou menos. O produto será automaticamente marcado como indisponível ao chegar a zero.',
                            style: GoogleFonts.publicSans(
                                fontSize: 12, color: Colors.amber.shade800),
                          ),
                        ),
                      ],
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

// ═══════════════════════════════════════════
// TAB 4 — OPÇÕES (informativo)
// ═══════════════════════════════════════════
class _TabOpcoes extends StatelessWidget {
  final List<Map<String, dynamic>> opcoes;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  const _TabOpcoes({
    required this.opcoes,
    required this.onChanged,
  });

  void _emit(List<Map<String, dynamic>> next) {
    onChanged(_reordenarGrupos(next));
  }

  void _adicionarGrupo() {
    _emit([
      ...opcoes,
      {
        'id': const Uuid().v4(),
        'nome': '',
        'tipo': 'multipla',
        'obrigatorio': false,
        'min_selecoes': 0,
        'max_selecoes': 5,
        'ordem': opcoes.length + 1,
        'ativo': true,
        'itens': <Map<String, dynamic>>[],
      }
    ]);
  }

  void _atualizarGrupo(int index, String key, dynamic value) {
    final next = _copyOpcoes();
    next[index][key] = value;
    if (key == 'tipo' && value == 'unica') {
      next[index]['max_selecoes'] = 1;
      if (_asIntStatic(next[index]['min_selecoes'], 0) > 1) {
        next[index]['min_selecoes'] = 1;
      }
    }
    _emit(next);
  }

  void _removerGrupo(int index) {
    final next = _copyOpcoes()..removeAt(index);
    _emit(next);
  }

  void _moverGrupo(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= opcoes.length) return;
    final next = _copyOpcoes();
    final item = next.removeAt(index);
    next.insert(target, item);
    _emit(next);
  }

  void _adicionarItem(int grupoIndex) {
    final next = _copyOpcoes();
    final itens = _itens(next[grupoIndex]);
    itens.add({
      'id': const Uuid().v4(),
      'nome': '',
      'descricao': null,
      'preco': 0.0,
      'ativo': true,
      'ordem': itens.length + 1,
    });
    next[grupoIndex]['itens'] = itens;
    _emit(next);
  }

  void _atualizarItem(
    int grupoIndex,
    int itemIndex,
    String key,
    dynamic value,
  ) {
    final next = _copyOpcoes();
    final itens = _itens(next[grupoIndex]);
    itens[itemIndex][key] = value;
    next[grupoIndex]['itens'] = itens;
    _emit(next);
  }

  void _removerItem(int grupoIndex, int itemIndex) {
    final next = _copyOpcoes();
    final itens = _itens(next[grupoIndex])..removeAt(itemIndex);
    next[grupoIndex]['itens'] = _reordenarItens(itens);
    _emit(next);
  }

  void _moverItem(int grupoIndex, int itemIndex, int delta) {
    final next = _copyOpcoes();
    final itens = _itens(next[grupoIndex]);
    final target = itemIndex + delta;
    if (target < 0 || target >= itens.length) return;
    final item = itens.removeAt(itemIndex);
    itens.insert(target, item);
    next[grupoIndex]['itens'] = _reordenarItens(itens);
    _emit(next);
  }

  List<Map<String, dynamic>> _copyOpcoes() {
    return opcoes.map((grupo) {
      final copy = Map<String, dynamic>.from(grupo);
      copy['itens'] = _itens(grupo);
      return copy;
    }).toList();
  }

  static List<Map<String, dynamic>> _itens(Map<String, dynamic> grupo) {
    return (grupo['itens'] as List? ?? [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static List<Map<String, dynamic>> _reordenarGrupos(
    List<Map<String, dynamic>> grupos,
  ) {
    return grupos.asMap().entries.map((entry) {
      final grupo = Map<String, dynamic>.from(entry.value);
      grupo['ordem'] = entry.key + 1;
      grupo['itens'] = _reordenarItens(_itens(grupo));
      return grupo;
    }).toList();
  }

  static List<Map<String, dynamic>> _reordenarItens(
    List<Map<String, dynamic>> itens,
  ) {
    return itens.asMap().entries.map((entry) {
      final item = Map<String, dynamic>.from(entry.value);
      item['ordem'] = entry.key + 1;
      return item;
    }).toList();
  }

  static int _asIntStatic(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SectionLabel(
                  'Adicionais e Opções',
                  subtitle: 'Configure grupos de escolha e adicionais pagos.',
                ),
              ),
              ElevatedButton.icon(
                onPressed: _adicionarGrupo,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Adicionar grupo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFec5b13),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (opcoes.isEmpty)
            _EmptyOpcoesState(onAdd: _adicionarGrupo)
          else
            ...opcoes.asMap().entries.map((entry) {
              return _GrupoOpcoesCard(
                key: ValueKey(entry.value['id']),
                index: entry.key,
                total: opcoes.length,
                grupo: entry.value,
                onMoveUp: () => _moverGrupo(entry.key, -1),
                onMoveDown: () => _moverGrupo(entry.key, 1),
                onRemove: () => _removerGrupo(entry.key),
                onGrupoChanged: (key, value) =>
                    _atualizarGrupo(entry.key, key, value),
                onAddItem: () => _adicionarItem(entry.key),
                onItemChanged: (itemIndex, key, value) =>
                    _atualizarItem(entry.key, itemIndex, key, value),
                onItemRemove: (itemIndex) => _removerItem(entry.key, itemIndex),
                onItemMove: (itemIndex, delta) =>
                    _moverItem(entry.key, itemIndex, delta),
              );
            }),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _TabOpcoesOld extends StatelessWidget {
  const _TabOpcoesOld();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Grupos de Opções / Adicionais'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'As opções são armazenadas como um array JSON no campo opcoes. Cada grupo pode ter tipo radio (escolha única) ou checkbox (múltipla escolha), com limites mín/máx.\n\nEsta funcionalidade estará disponível em breve.',
                    style: GoogleFonts.publicSans(
                        fontSize: 12, color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Icon(Icons.tune, size: 52, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'Opções em breve',
                  style: GoogleFonts.publicSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure tamanhos, adicionais e complementos',
                  style: GoogleFonts.publicSans(
                      fontSize: 12, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════
class _EmptyOpcoesState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyOpcoesState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.tune, size: 44, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(
            'Nenhum grupo cadastrado',
            style: GoogleFonts.publicSans(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Produtos sem adicionais serão salvos com opcoes vazio.',
            textAlign: TextAlign.center,
            style: GoogleFonts.publicSans(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Adicionar grupo'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFec5b13),
              side: const BorderSide(color: Color(0xFFec5b13)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

class _GrupoOpcoesCard extends StatelessWidget {
  final int index;
  final int total;
  final Map<String, dynamic> grupo;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;
  final void Function(String key, dynamic value) onGrupoChanged;
  final VoidCallback onAddItem;
  final void Function(int itemIndex, String key, dynamic value) onItemChanged;
  final ValueChanged<int> onItemRemove;
  final void Function(int itemIndex, int delta) onItemMove;

  const _GrupoOpcoesCard({
    super.key,
    required this.index,
    required this.total,
    required this.grupo,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
    required this.onGrupoChanged,
    required this.onAddItem,
    required this.onItemChanged,
    required this.onItemRemove,
    required this.onItemMove,
  });

  List<Map<String, dynamic>> get _itens {
    return (grupo['itens'] as List? ?? [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  int _asInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final tipo = grupo['tipo'] == 'unica' ? 'unica' : 'multipla';
    final maxSelecoes = tipo == 'unica' ? 1 : _asInt(grupo['max_selecoes'], 1);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Grupo ${index + 1}',
                  style: GoogleFonts.publicSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _IconAction(
                icon: Icons.keyboard_arrow_up,
                tooltip: 'Subir grupo',
                onTap: index == 0 ? null : onMoveUp,
              ),
              _IconAction(
                icon: Icons.keyboard_arrow_down,
                tooltip: 'Descer grupo',
                onTap: index == total - 1 ? null : onMoveDown,
              ),
              _IconAction(
                icon: Icons.delete_outline,
                tooltip: 'Remover grupo',
                onTap: onRemove,
                color: Colors.red.shade600,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionLabel('Nome do grupo *'),
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey('${grupo['id']}-nome'),
            initialValue: (grupo['nome'] ?? '').toString(),
            decoration: _inputDecoration('Ex: Adicionais'),
            onChanged: (value) => onGrupoChanged('nome', value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel('Tipo de escolha'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: tipo,
                      decoration: _inputDecoration(null),
                      items: const [
                        DropdownMenuItem(
                            value: 'unica', child: Text('Escolha única')),
                        DropdownMenuItem(
                            value: 'multipla', child: Text('Múltipla escolha')),
                      ],
                      onChanged: (value) =>
                          onGrupoChanged('tipo', value ?? 'multipla'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InlineSwitchField(
                  title: 'Obrigatório',
                  value: grupo['obrigatorio'] == true,
                  onChanged: (value) => onGrupoChanged('obrigatorio', value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InlineSwitchField(
                  title: 'Ativo',
                  value: grupo['ativo'] != false,
                  onChanged: (value) => onGrupoChanged('ativo', value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  label: 'Mínimo',
                  value: _asInt(grupo['min_selecoes'], 0),
                  onChanged: (value) => onGrupoChanged('min_selecoes', value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NumberField(
                  label: 'Máximo',
                  value: maxSelecoes,
                  enabled: tipo != 'unica',
                  onChanged: (value) => onGrupoChanged('max_selecoes', value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NumberField(
                  label: 'Ordem',
                  value: index + 1,
                  enabled: false,
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SectionLabel(
                  'Itens do grupo',
                  subtitle: '${_itens.length} item(ns) cadastrado(s)',
                ),
              ),
              OutlinedButton.icon(
                onPressed: onAddItem,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Adicionar item'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFec5b13),
                  side: const BorderSide(color: Color(0xFFec5b13)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_itens.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Nenhum item cadastrado neste grupo.',
                style: GoogleFonts.publicSans(
                    fontSize: 12, color: Colors.grey.shade500),
              ),
            )
          else
            ..._itens.asMap().entries.map((entry) => _OpcaoItemCard(
                  key: ValueKey(entry.value['id']),
                  index: entry.key,
                  total: _itens.length,
                  item: entry.value,
                  onChanged: (key, value) =>
                      onItemChanged(entry.key, key, value),
                  onRemove: () => onItemRemove(entry.key),
                  onMoveUp: () => onItemMove(entry.key, -1),
                  onMoveDown: () => onItemMove(entry.key, 1),
                )),
        ],
      ),
    );
  }
}

class _OpcaoItemCard extends StatelessWidget {
  final int index;
  final int total;
  final Map<String, dynamic> item;
  final void Function(String key, dynamic value) onChanged;
  final VoidCallback onRemove;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  const _OpcaoItemCard({
    super.key,
    required this.index,
    required this.total,
    required this.item,
    required this.onChanged,
    required this.onRemove,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value?.toString() ?? '').replaceAll(',', '.')) ??
        0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Item ${index + 1}',
                  style: GoogleFonts.publicSans(
                      fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              _IconAction(
                icon: Icons.keyboard_arrow_up,
                tooltip: 'Subir item',
                onTap: index == 0 ? null : onMoveUp,
              ),
              _IconAction(
                icon: Icons.keyboard_arrow_down,
                tooltip: 'Descer item',
                onTap: index == total - 1 ? null : onMoveDown,
              ),
              _IconAction(
                icon: Icons.delete_outline,
                tooltip: 'Remover item',
                onTap: onRemove,
                color: Colors.red.shade600,
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            key: ValueKey('${item['id']}-nome'),
            initialValue: (item['nome'] ?? '').toString(),
            decoration: _inputDecoration('Nome do adicional *'),
            onChanged: (value) => onChanged('nome', value),
          ),
          const SizedBox(height: 10),
          TextFormField(
            key: ValueKey('${item['id']}-descricao'),
            initialValue: (item['descricao'] ?? '').toString(),
            decoration: _inputDecoration('Descrição opcional'),
            onChanged: (value) => onChanged('descricao', value),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey('${item['id']}-preco'),
                  initialValue: _asDouble(item['preco'])
                      .toStringAsFixed(2)
                      .replaceAll('.', ','),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDecoration('0,00').copyWith(
                    prefixText: 'R\$ ',
                  ),
                  onChanged: (value) => onChanged('preco', value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InlineSwitchField(
                  title: 'Ativo',
                  value: item['ativo'] != false,
                  onChanged: (value) => onChanged('ativo', value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NumberField(
                  label: 'Ordem',
                  value: index + 1,
                  enabled: false,
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _NumberField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          key: ValueKey('$label-$value-$enabled'),
          initialValue: value.toString(),
          enabled: enabled,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _inputDecoration('0'),
          onChanged: (value) => onChanged(int.tryParse(value) ?? 0),
        ),
      ],
    );
  }
}

class _InlineSwitchField extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _InlineSwitchField({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.publicSans(
                  fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: const Color(0xFFec5b13),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? color;

  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 18),
        color: color ?? Colors.grey.shade700,
        disabledColor: Colors.grey.shade300,
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final String? subtitle;

  const _SectionLabel(this.text, {this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text,
            style: GoogleFonts.publicSans(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800)),
        if (subtitle != null)
          Text(subtitle!,
              style: GoogleFonts.publicSans(
                  fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool elevated;

  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: elevated ? Colors.grey.shade50 : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.publicSans(
                        fontSize: 13, fontWeight: FontWeight.bold)),
                Text(subtitle,
                    style: GoogleFonts.publicSans(
                        fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: const Color(0xFFec5b13),
            inactiveTrackColor: Colors.grey.shade200,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration(String? hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFec5b13), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// TAB: ÚLTIMA MORDIDA
// ═══════════════════════════════════════════════════════════════════════════
class _TabUltimaMordida extends ConsumerStatefulWidget {
  final ProdutoModel? produto;
  const _TabUltimaMordida({this.produto});

  @override
  ConsumerState<_TabUltimaMordida> createState() => _TabUltimaMordidaState();
}

class _TabUltimaMordidaState extends ConsumerState<_TabUltimaMordida> {
  final _chamadaCtrl = TextEditingController();
  int? _desconto;
  int? _duracaoHoras;
  bool _loading = false;

  @override
  void dispose() {
    _chamadaCtrl.dispose();
    super.dispose();
  }

  bool get _podeAtivar => widget.produto != null && widget.produto!.id.isNotEmpty;
  bool get _estaAtivo => widget.produto?.ultimaMordida ?? false;

  @override
  Widget build(BuildContext context) {
    if (!_podeAtivar) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🍰', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                'Salve o produto primeiro',
                style: GoogleFonts.publicSans(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'A Última Mordida pode ser ativada após o produto ser cadastrado.',
                textAlign: TextAlign.center,
                style: GoogleFonts.publicSans(
                    fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final produto = widget.produto!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status atual ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _estaAtivo
                  ? const Color(0xFFFFF3E0)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _estaAtivo
                    ? const Color(0xFFE65100)
                    : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Text(_estaAtivo ? '🍰' : '😴',
                    style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _estaAtivo
                            ? 'Última Mordida ATIVA'
                            : 'Última Mordida inativa',
                        style: GoogleFonts.publicSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: _estaAtivo
                              ? const Color(0xFFE65100)
                              : Colors.grey.shade600,
                        ),
                      ),
                      if (_estaAtivo && produto.ultimaMordidaChamada != null)
                        Text(
                          '"${produto.ultimaMordidaChamada}"',
                          style: GoogleFonts.publicSans(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey.shade600),
                        ),
                      if (_estaAtivo && produto.ultimaMordidaPreco != null)
                        Text(
                          '${fmt.format(produto.preco)} → ${fmt.format(produto.ultimaMordidaPreco)}',
                          style: GoogleFonts.publicSans(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (!_estaAtivo) ...[
            // ── Formulário de ativação ──
            Text('Configurar',
                style: GoogleFonts.publicSans(
                    fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _chamadaCtrl,
              decoration: InputDecoration(
                labelText: 'Chamada (opcional)',
                hintText: 'Ex: Última fatia de bolo!',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _desconto,
              decoration: InputDecoration(
                labelText: 'Desconto (%)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('Sem desconto')),
                ...([5, 10, 15, 20, 25, 30, 40, 50]).map(
                  (v) => DropdownMenuItem(value: v, child: Text('$v%')),
                ),
              ],
              onChanged: (v) => setState(() => _desconto = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _duracaoHoras,
              decoration: InputDecoration(
                labelText: 'Duração',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(
                    value: null, child: Text('Sem prazo de expiração')),
                DropdownMenuItem(value: 1, child: Text('1 hora')),
                DropdownMenuItem(value: 2, child: Text('2 horas')),
                DropdownMenuItem(value: 3, child: Text('3 horas')),
                DropdownMenuItem(value: 6, child: Text('6 horas')),
                DropdownMenuItem(value: 12, child: Text('12 horas')),
                DropdownMenuItem(
                    value: 24, child: Text('Até o fim do dia')),
              ],
              onChanged: (v) => setState(() => _duracaoHoras = v),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _loading
                    ? null
                    : () async {
                        setState(() => _loading = true);
                        await ref
                            .read(produtosControllerProvider.notifier)
                            .ativarUltimaMordida(
                              produto.id,
                              descontoPct: _desconto,
                              chamada: _chamadaCtrl.text.trim().isEmpty
                                  ? null
                                  : _chamadaCtrl.text.trim(),
                              duracaoHoras: _duracaoHoras,
                            );
                        setState(() => _loading = false);
                      },
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('🍰 Ativar Última Mordida',
                        style: GoogleFonts.publicSans(
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
          ] else ...[
            // ── Desativar ──
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE65100)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _loading
                    ? null
                    : () async {
                        setState(() => _loading = true);
                        await ref
                            .read(produtosControllerProvider.notifier)
                            .desativarUltimaMordida(produto.id);
                        setState(() => _loading = false);
                      },
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('Desativar Última Mordida',
                        style: GoogleFonts.publicSans(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFE65100))),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
