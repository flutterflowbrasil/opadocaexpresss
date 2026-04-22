import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'endereco_model.dart';
import 'localizacao_controller.dart';
import 'localizacao_repository.dart';
import 'adicionar_endereco_widgets.dart';
import 'adicionar_endereco_formulario.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enumera as etapas do fluxo
// ─────────────────────────────────────────────────────────────────────────────
enum _Etapa { cep, formulario, mapa }

// ─────────────────────────────────────────────────────────────────────────────
// AdicionarEnderecoModal
//
// Modal estilo iFood com 3 etapas (adicionar) ou 1 etapa (editar):
//   1. Busca por CEP ou GPS        [somente no modo adicionar]
//   2. Formulário de detalhes + mini-mapa
//   3. Ajuste de pin no mapa fullscreen
//
// Uso — adicionar:
//   final endereco = await AdicionarEnderecoModal.show(context);
//
// Uso — editar:
//   final endereco = await AdicionarEnderecoModal.show(
//     context, enderecoParaEditar: endereco,
//   );
// ─────────────────────────────────────────────────────────────────────────────
class AdicionarEnderecoModal extends ConsumerStatefulWidget {
  final EnderecoCliente? enderecoParaEditar;

  const AdicionarEnderecoModal._({this.enderecoParaEditar});

  /// Exibe o modal e retorna o [EnderecoCliente] salvo/atualizado, ou null.
  /// Passe [enderecoParaEditar] para abrir em modo de edição.
  static Future<EnderecoCliente?> show(
    BuildContext context, {
    EnderecoCliente? enderecoParaEditar,
  }) =>
      showModalBottomSheet<EnderecoCliente>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: AdicionarEnderecoModal._(
              enderecoParaEditar: enderecoParaEditar,
            ),
          ),
        ),
      );

  @override
  ConsumerState<AdicionarEnderecoModal> createState() =>
      _AdicionarEnderecoModalState();
}

class _AdicionarEnderecoModalState
    extends ConsumerState<AdicionarEnderecoModal> {
  late _Etapa _etapa;

  // ID do endereço sendo editado (null = novo)
  String? _enderecoId;

  // Controllers
  final _cepCtrl         = TextEditingController();
  final _logradouroCtrl  = TextEditingController();
  final _numeroCtrl      = TextEditingController();
  final _complementoCtrl = TextEditingController();
  final _bairroCtrl      = TextEditingController();
  final _cidadeCtrl      = TextEditingController();
  final _estadoCtrl      = TextEditingController();
  final _referenciaCtrl  = TextEditingController();
  final _formKey         = GlobalKey<FormState>();

  final _cepMask = MaskTextInputFormatter(
    mask: '#####-###', filter: {'#': RegExp(r'[0-9]')});

  // Estados locais do modal (não precisam de StateNotifier)
  bool    _buscandoCep    = false;
  bool    _localizandoGps = false;
  String? _erroCep;

  // Coords do pin
  double _lat = -5.0892;
  double _lng = -42.8019;
  final _mapCtrl = MapController();

  late final LocalizacaoRepository _repo;

  // Atalho: está em modo edição?
  bool get _modoEdicao => _enderecoId != null;

  @override
  void initState() {
    super.initState();
    _repo = LocalizacaoRepository(Supabase.instance.client);

    final editar = widget.enderecoParaEditar;
    if (editar != null) {
      // ── Modo edição: pré-preenche campos e vai direto ao formulário ────
      _enderecoId        = editar.id;
      _etapa             = _Etapa.formulario;
      _lat               = editar.latitude;
      _lng               = editar.longitude;
      _cepCtrl.text      = editar.cep;
      _logradouroCtrl.text  = editar.logradouro;
      _numeroCtrl.text      = editar.numero;
      _complementoCtrl.text = editar.complemento ?? '';
      _bairroCtrl.text      = editar.bairro;
      _cidadeCtrl.text      = editar.cidade;
      _estadoCtrl.text      = editar.estado;
      _referenciaCtrl.text  = editar.pontoReferencia ?? '';
    } else {
      // ── Modo adicionar: começa na etapa CEP ───────────────────────────
      _etapa = _Etapa.cep;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _cepCtrl, _logradouroCtrl, _numeroCtrl,
      _complementoCtrl, _bairroCtrl, _cidadeCtrl,
      _estadoCtrl, _referenciaCtrl,
    ]) { c.dispose(); }
    _mapCtrl.dispose();
    super.dispose();
  }

  // ── Busca CEP via API (BrasilAPI com Fallback para ViaCEP) ───────────────
  Future<void> _buscarCep() async {
    final cep = _cepCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (cep.length != 8) {
      setState(() => _erroCep = 'CEP deve ter 8 dígitos');
      return;
    }
    setState(() { _buscandoCep = true; _erroCep = null; });
    
    try {
      // Usamos Headers genéricos para evitar bloqueio em mobile (ex: ViaCEP restringe Dart)
      final headers = {
        'User-Agent': 'PadocaExpressApp/1.0',
        'Accept': 'application/json',
      };

      Map<String, dynamic> data = {};
      bool found = false;

      // Tentativa 1: BrasilAPI
      try {
        final res = await http
            .get(Uri.parse('https://brasilapi.com.br/api/cep/v1/$cep'), headers: headers)
            .timeout(const Duration(seconds: 6));
        
        if (res.statusCode == 200) {
          final resData = jsonDecode(res.body) as Map<String, dynamic>;
          if (!resData.containsKey('errors')) {
            data = {
              'logradouro': resData['street'] ?? '',
              'bairro': resData['neighborhood'] ?? '',
              'localidade': resData['city'] ?? '',
              'uf': resData['state'] ?? '',
            };
            found = true;
          }
        }
      } catch (_) {
        // Falhou BrasilAPI, tentaremos ViaCEP
      }

      // Tentativa 2: ViaCEP (Fallback) se BrasilAPI falhar
      if (!found) {
        final res = await http
            .get(Uri.parse('https://viacep.com.br/ws/$cep/json/'), headers: headers)
            .timeout(const Duration(seconds: 6));
            
        final resData = jsonDecode(res.body) as Map<String, dynamic>;
        if (resData['erro'] != true && res.statusCode == 200) {
          data = {
            'logradouro': resData['logradouro'] ?? '',
            'bairro': resData['bairro'] ?? '',
            'localidade': resData['localidade'] ?? '',
            'uf': resData['uf'] ?? '',
          };
          found = true;
        }
      }

      if (!found) {
        setState(() => _erroCep = 'CEP não encontrado');
        return;
      }

      _logradouroCtrl.text = data['logradouro'] ?? '';
      _bairroCtrl.text     = data['bairro']     ?? '';
      _cidadeCtrl.text     = data['localidade'] ?? '';
      _estadoCtrl.text     = data['uf']         ?? '';

      // Forward geocode para obter lat/lng
      final coords = await _repo.geocodeCep(cep);
      if (coords != null) {
        setState(() {
          _lat = coords['lat']!;
          _lng = coords['lng']!;
        });
      }
      setState(() => _etapa = _Etapa.formulario);
    } catch (_) {
      setState(() => _erroCep = 'Erro ao buscar CEP. Verifique sua conexão.');
    } finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
  }

  // ── GPS ────────────────────────────────────────────────────────────────────
  Future<void> _pegarLocalizacaoAtual() async {
    setState(() => _localizandoGps = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _snack('Ative o GPS do dispositivo', isError: true);
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        _snack('Permissão de localização negada', isError: true);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high));
      setState(() { _lat = pos.latitude; _lng = pos.longitude; });

      final geo = await _repo.reverseGeocode(pos.latitude, pos.longitude);
      if (geo != null && mounted) {
        setState(() {
          if ((geo['cep'] as String).isNotEmpty) {
            _cepCtrl.text = geo['cep']!;
          }
          _logradouroCtrl.text = geo['logradouro'] ?? '';
          _bairroCtrl.text     = geo['bairro']     ?? '';
          _cidadeCtrl.text     = geo['cidade']     ?? '';
          _estadoCtrl.text     = geo['estado']     ?? '';
        });
      }
      setState(() => _etapa = _Etapa.formulario);
    } catch (_) {
      _snack('Não foi possível obter sua localização', isError: true);
    } finally {
      if (mounted) setState(() => _localizandoGps = false);
    }
  }

  // ── Confirmar pin no mapa ─────────────────────────────────────────────────
  Future<void> _confirmarMapa() async {
    final geo = await _repo.reverseGeocode(_lat, _lng);
    if (geo != null && mounted) {
      setState(() {
        final logradouro = (geo['logradouro'] as String? ?? '').trim();
        final bairro     = (geo['bairro']     as String? ?? '').trim();
        final cidade     = (geo['cidade']     as String? ?? '').trim();
        final estado     = (geo['estado']     as String? ?? '').trim();
        final cep        = (geo['cep']        as String? ?? '').trim();

        if (logradouro.isNotEmpty) _logradouroCtrl.text = logradouro;
        if (bairro.isNotEmpty)     _bairroCtrl.text     = bairro;
        if (cidade.isNotEmpty)     _cidadeCtrl.text     = cidade;
        if (estado.isNotEmpty)     _estadoCtrl.text     = estado;
        if (cep.isNotEmpty)        _cepCtrl.text        = cep;
      });
    }
    if (mounted) setState(() => _etapa = _Etapa.formulario);
  }

  // ── Salvar ou atualizar endereço ─────────────────────────────────────────
  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final endereco = EnderecoCliente(
      id:              _enderecoId,
      apelido:         widget.enderecoParaEditar?.apelido,
      cep:             _cepCtrl.text.replaceAll(RegExp(r'\D'), ''),
      logradouro:      _logradouroCtrl.text.trim(),
      numero:          _numeroCtrl.text.trim(),
      complemento:     _complementoCtrl.text.trim().isEmpty
          ? null
          : _complementoCtrl.text.trim(),
      bairro:          _bairroCtrl.text.trim(),
      cidade:          _cidadeCtrl.text.trim(),
      estado:          _estadoCtrl.text.trim(),
      latitude:        _lat,
      longitude:       _lng,
      pontoReferencia: _referenciaCtrl.text.trim().isEmpty
          ? null
          : _referenciaCtrl.text.trim(),
      isPadrao:        widget.enderecoParaEditar?.isPadrao ?? false,
    );

    final notifier = ref.read(localizacaoControllerProvider.notifier);
    final result = _modoEdicao
        ? await notifier.atualizar(endereco)
        : await notifier.salvar(endereco);

    if (!mounted) return;

    if (result != null) {
      Navigator.of(context).pop(result);
      _snack(_modoEdicao
          ? 'Endereço atualizado com sucesso!'
          : 'Endereço salvo com sucesso!');
    } else {
      _snack('Erro ao salvar. Tente novamente.', isError: true);
    }
  }

  // ── GPS no mapa fullscreen ────────────────────────────────────────────────
  Future<void> _gpsNoMapa() async {
    try {
      final p = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high));
      setState(() { _lat = p.latitude; _lng = p.longitude; });
      _mapCtrl.move(LatLng(p.latitude, p.longitude), 17);
    } catch (_) {}
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit()),
      backgroundColor: isError ? Colors.red[600] : Colors.green[600],
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ──────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_etapa == _Etapa.mapa) {
      return AdicionarEnderecoMapa(
        lat:              _lat,
        lng:              _lng,
        logradouro:       _logradouroCtrl.text,
        bairro:           _bairroCtrl.text,
        mapController:    _mapCtrl,
        onPositionChanged: (lat, lng) =>
            setState(() { _lat = lat; _lng = lng; }),
        onVoltar:         () => setState(() => _etapa = _Etapa.formulario),
        onConfirmar:      _confirmarMapa,
        onGps:            _gpsNoMapa,
      );
    }

    return _buildSheet(isDark);
  }

  // ── DraggableScrollableSheet ──────────────────────────────────────────────
  Widget _buildSheet(bool isDark) {
    final bgColor =
        isDark ? const Color(0xFF1C1917) : Colors.white;
    final handleColor =
        isDark ? Colors.grey[700]! : Colors.grey[300]!;
    final dividerColor =
        isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[200]!;

    return DraggableScrollableSheet(
      initialChildSize: _etapa == _Etapa.cep ? 0.58 : 0.93,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, sc) => Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: handleColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Row(
                children: [
                  // No modo edição não há etapa CEP, então o voltar fecha.
                  // No modo adicionar e etapa formulário, volta para o CEP.
                  if (_etapa == _Etapa.formulario && !_modoEdicao)
                    GestureDetector(
                      onTap: () => setState(() => _etapa = _Etapa.cep),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(Icons.arrow_back_ios,
                            size: 18, color: kVinho),
                      ),
                    ),
                  Text(
                    _modoEdicao ? 'Editar endereço' : 'Adicionar endereço',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : kVinho,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close,
                          size: 18,
                          color:
                              isDark ? Colors.white70 : Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: dividerColor),
            Expanded(
              child: SingleChildScrollView(
                controller: sc,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: _etapa == _Etapa.cep
                      ? KeyedSubtree(
                          key: const ValueKey('cep'),
                          child: _buildEtapaCep(),
                        )
                      : KeyedSubtree(
                          key: const ValueKey('form'),
                          child: AdicionarEnderecoFormulario(
                            logradouroCtrl: _logradouroCtrl,
                            numeroCtrl:     _numeroCtrl,
                            complementoCtrl: _complementoCtrl,
                            bairroCtrl:     _bairroCtrl,
                            cidadeCtrl:     _cidadeCtrl,
                            estadoCtrl:     _estadoCtrl,
                            referenciaCtrl: _referenciaCtrl,
                            formKey:        _formKey,
                            lat:            _lat,
                            lng:            _lng,
                            onAbrirMapa: () =>
                                setState(() => _etapa = _Etapa.mapa),
                            onSalvar:    _salvar,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Etapa 1: CEP ─────────────────────────────────────────────────────────
  Widget _buildEtapaCep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgField =
        isDark ? const Color(0xFF2A2A2A) : kBgLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Botão GPS
        BotaoGpsCard(
          isLoading: _localizandoGps,
          onTap: _pegarLocalizacaoAtual,
        ),

        const SizedBox(height: 22),

        // Divisor "ou informe o CEP"
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey[300])),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'ou informe o CEP',
                style: GoogleFonts.outfit(
                    fontSize: 12, color: Colors.grey[400]),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey[300])),
          ],
        ),

        const SizedBox(height: 22),

        // Campo CEP + botão Buscar
        LblWidget('CEP'),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _cepCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [_cepMask],
                onFieldSubmitted: (_) => _buscarCep(),
                style: GoogleFonts.outfit(
                    fontSize: 15, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: '00000-000',
                  hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.location_on_outlined,
                      color: kOrange, size: 20),
                  errorText: _erroCep,
                  filled: true,
                  fillColor: bgField,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: kOrange, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _buscandoCep ? null : _buscarCep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kOrange,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22),
                ),
                child: _buscandoCep
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Text(
                        'Buscar',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),
        Text(
          'Não sei meu CEP → consulte nos Correios',
          style:
              GoogleFonts.outfit(fontSize: 12, color: Colors.grey[400]),
        ),
      ],
    );
  }
}
