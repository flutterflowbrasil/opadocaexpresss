// ============================================================
// entrega_andamento_screen.dart — Entrega em Andamento
// Ôpadoca Express · App do Entregador
// Rota: /dashboard_entregador/entrega/:pedidoId
// Tabelas: pedidos, entregadores, rastreamento_entregadores,
//          entregador_localizacao_atual
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

const _bg0 = Color(0xFF0A0704);
const _bg3 = Color(0xFF251C14);
const _card = Color(0xFF1A1510);
const _orange = Color(0xFFF97316);
const _green = Color(0xFF22C55E);
const _red = Color(0xFFEF4444);
const _text1 = Color(0xFFFAFAF9);
const _text2 = Color(0xA6FAFAF9);
const _text3 = Color(0x59FAFAF9);
const _border = Color(0x12FFFFFF);

// ─── Status do pedido ──────────────────────────────────────────────────────
enum StatusEntrega { confirmado, emColeta, coletado, emEntrega, entregue }

extension StatusEntregaExt on StatusEntrega {
  String get label {
    switch (this) {
      case StatusEntrega.confirmado:
        return 'Pedido aceito';
      case StatusEntrega.emColeta:
        return 'A caminho do estabelecimento';
      case StatusEntrega.coletado:
        return 'Pedido coletado';
      case StatusEntrega.emEntrega:
        return 'Entregando ao cliente';
      case StatusEntrega.entregue:
        return 'Entrega concluída!';
    }
  }

  String get dbStatus {
    switch (this) {
      case StatusEntrega.confirmado:
        return 'confirmado';
      case StatusEntrega.emColeta:
        return 'preparando';
      case StatusEntrega.coletado:
        return 'pronto';
      case StatusEntrega.emEntrega:
        return 'em_entrega';
      case StatusEntrega.entregue:
        return 'entregue';
    }
  }

  String get emoji {
    switch (this) {
      case StatusEntrega.confirmado:
        return '✅';
      case StatusEntrega.emColeta:
        return '🛵';
      case StatusEntrega.coletado:
        return '📦';
      case StatusEntrega.emEntrega:
        return '🚀';
      case StatusEntrega.entregue:
        return '🎉';
    }
  }

  StatusEntrega? get proximo {
    switch (this) {
      case StatusEntrega.confirmado:
        return StatusEntrega.emColeta;
      case StatusEntrega.emColeta:
        return StatusEntrega.coletado;
      case StatusEntrega.coletado:
        return StatusEntrega.emEntrega;
      case StatusEntrega.emEntrega:
        return null; // Requer confirmação especial
      case StatusEntrega.entregue:
        return null;
    }
  }

  String get labelBotao {
    switch (this) {
      case StatusEntrega.confirmado:
        return 'Ir ao estabelecimento';
      case StatusEntrega.emColeta:
        return 'Retirei o pedido';
      case StatusEntrega.coletado:
        return 'Iniciar entrega';
      case StatusEntrega.emEntrega:
        return 'Confirmar entrega';
      case StatusEntrega.entregue:
        return 'Concluído';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class EntregaAndamentoScreen extends StatefulWidget {
  final String pedidoId;
  const EntregaAndamentoScreen({super.key, required this.pedidoId});

  @override
  State<EntregaAndamentoScreen> createState() => _EntregaAndamentoScreenState();
}

class _EntregaAndamentoScreenState extends State<EntregaAndamentoScreen>
    with TickerProviderStateMixin {
  StatusEntrega _status = StatusEntrega.confirmado;
  bool _loading = true;
  bool _atualizando = false;

  String _numeroPedido = '';
  String _estabelecimentoNome = '';
  String _estabelecimentoEnd = '';
  String _clienteNome = '';
  String _clienteEnd = '';
  String? _clienteTelefone;
  double _taxaEntrega = 0;
  double _distanciaKm = 0;
  String? _entregadorId;

  double? _estabelecimentoLat;
  double? _estabelecimentoLng;
  double? _clienteLat;
  double? _clienteLng;

  Timer? _cronoTimer;
  int _segundosEntrega = 0;
  DateTime? _inicioEntrega;

  StreamSubscription<Position>? _posStream;
  Position? _posicaoAtual;

  late AnimationController _statusAnim;
  late Animation<double> _statusScale;

  @override
  void initState() {
    super.initState();
    _statusAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _statusScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _statusAnim, curve: Curves.elasticOut),
    );
    _carregarPedido();
  }

  Future<void> _carregarPedido() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    try {
      final entRow = await Supabase.instance.client
          .from('entregadores')
          .select('id')
          .eq('usuario_id', uid)
          .maybeSingle();
      _entregadorId = entRow?['id'];

      final row = await Supabase.instance.client
          .from('pedidos')
          .select('''
            numero_pedido, status, taxa_entrega, distancia_km,
            em_entrega_em,
            endereco_entrega_snapshot,
            estabelecimentos ( nome_fantasia, endereco, telefone_comercial, latitude, longitude ),
            clientes ( usuarios ( nome_completo_fantasia, telefone ) )
          ''')
          .eq('id', widget.pedidoId)
          .maybeSingle();

      if (row == null || !mounted) return;

      final snap = (row['endereco_entrega_snapshot'] as Map?) ?? {};
      final estab = (row['estabelecimentos'] as Map?) ?? {};
      final estabEnd = (estab['endereco'] as Map?) ?? {};
      final cliente = (row['clientes'] as Map?) ?? {};
      final usuario = (cliente['usuarios'] as Map?) ?? {};

      String fmtEnd(Map<dynamic, dynamic> m) {
        final l = m['logradouro'] ?? '';
        final n = m['numero'] ?? '';
        final b = m['bairro'] ?? '';
        return '$l${n.toString().isNotEmpty ? ", $n" : ""}${b.toString().isNotEmpty ? " — $b" : ""}';
      }

      final dbStatus = row['status'] ?? 'confirmado';
      StatusEntrega statusAtual;
      switch (dbStatus) {
        case 'preparando':
          statusAtual = StatusEntrega.emColeta;
          break;
        case 'pronto':
          statusAtual = StatusEntrega.coletado;
          break;
        case 'em_entrega':
          statusAtual = StatusEntrega.emEntrega;
          break;
        case 'entregue':
          statusAtual = StatusEntrega.entregue;
          break;
        default:
          statusAtual = StatusEntrega.confirmado;
      }

      if (!mounted) return;
      setState(() {
        _numeroPedido = '#${row['numero_pedido'] ?? '???'}';
        _estabelecimentoNome = estab['nome_fantasia'] ?? 'Estabelecimento';
        _estabelecimentoEnd = fmtEnd(estabEnd);
        _clienteNome = usuario['nome_completo_fantasia'] ?? 'Cliente';
        _clienteEnd = fmtEnd(snap);
        _clienteTelefone = usuario['telefone'];
        _taxaEntrega = (row['taxa_entrega'] as num?)?.toDouble() ?? 0;
        _distanciaKm = (row['distancia_km'] as num?)?.toDouble() ?? 0;
        _status = statusAtual;
        _loading = false;

        _estabelecimentoLat = (estab['latitude'] as num?)?.toDouble();
        _estabelecimentoLng = (estab['longitude'] as num?)?.toDouble();
        _clienteLat = (snap['latitude'] as num?)?.toDouble();
        _clienteLng = (snap['longitude'] as num?)?.toDouble();

        if (row['em_entrega_em'] != null) {
          _inicioEntrega = DateTime.tryParse(row['em_entrega_em']);
        }
      });

      _statusAnim.forward();
      _iniciarGps();
      if (_status == StatusEntrega.emEntrega) _iniciarCronometro();
    } catch (e) {
      debugPrint('[EntregaAndamento] $e');
    }
  }

  // ── GPS ───────────────────────────────────────────────────────────────────
  void _iniciarGps() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }

      _posStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((pos) {
        if (!mounted) return;
        setState(() => _posicaoAtual = pos);
        _enviarLocalizacao(pos);
      });
    } catch (_) {}
  }

  Future<void> _enviarLocalizacao(Position pos) async {
    if (_entregadorId == null) return;
    try {
      await Supabase.instance.client.from('entregador_localizacao_atual').upsert({
        'entregador_id': _entregadorId,
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'velocidade_kmh': (pos.speed * 3.6).clamp(0, 200),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await Supabase.instance.client.from('rastreamento_entregadores').insert({
        'entregador_id': _entregadorId,
        'pedido_id': widget.pedidoId,
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'velocidade_kmh': (pos.speed * 3.6).clamp(0, 200),
      });

      await Supabase.instance.client
          .from('pedidos')
          .update({
            'localizacao_entregador': {'lat': pos.latitude, 'lng': pos.longitude},
          })
          .eq('id', widget.pedidoId);
    } catch (_) {}
  }

  // ── Cronômetro ────────────────────────────────────────────────────────────
  void _iniciarCronometro() {
    _inicioEntrega ??= DateTime.now();
    _cronoTimer?.cancel();
    _cronoTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _segundosEntrega = DateTime.now().difference(_inicioEntrega!).inSeconds;
      });
    });
  }

  String get _tempoFormatado {
    final m = _segundosEntrega ~/ 60;
    final s = _segundosEntrega % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Avança status ─────────────────────────────────────────────────────────
  Future<void> _avancarStatus() async {
    if (_atualizando) return;

    if (_status == StatusEntrega.emEntrega) {
      _mostrarConfirmacaoEntrega();
      return;
    }

    final proximo = _status.proximo;
    if (proximo == null) return;

    HapticFeedback.mediumImpact();
    setState(() => _atualizando = true);

    try {
      final agora = DateTime.now().toIso8601String();
      final updates = <String, dynamic>{'status': proximo.dbStatus};

      switch (proximo) {
        case StatusEntrega.emColeta:
          updates['confirmado_em'] = agora;
          break;
        case StatusEntrega.emEntrega:
          updates['em_entrega_em'] = agora;
          _inicioEntrega = DateTime.now();
          _iniciarCronometro();
          break;
        default:
          break;
      }

      await Supabase.instance.client
          .from('pedidos')
          .update(updates)
          .eq('id', widget.pedidoId);

      if (!mounted) return;
      _statusAnim.reset();
      setState(() {
        _status = proximo;
        _atualizando = false;
      });
      _statusAnim.forward();
      HapticFeedback.heavyImpact();
    } catch (e) {
      if (!mounted) return;
      setState(() => _atualizando = false);
      _mostrarErro('Erro ao atualizar status.');
    }
  }

  // ── Confirmar entrega ─────────────────────────────────────────────────────
  void _mostrarConfirmacaoEntrega() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ConfirmarEntregaSheet(
        onFoto: () {
          Navigator.pop(context);
          _confirmarComFoto();
        },
        onCodigo: () {
          Navigator.pop(context);
          _mostrarDialogCodigo();
        },
      ),
    );
  }

  Future<void> _confirmarComFoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (img == null) return;

    setState(() => _atualizando = true);
    try {
      final bytes = await img.readAsBytes();
      final path =
          'entregas/${widget.pedidoId}/confirmacao_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await Supabase.instance.client.storage
          .from('documentos-entregador')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      await _finalizarEntrega(fotoPath: path);
    } catch (e) {
      if (mounted) {
        setState(() => _atualizando = false);
        _mostrarErro('Erro ao enviar foto.');
      }
    }
  }

  void _mostrarDialogCodigo() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Código de confirmação',
          style: GoogleFonts.outfit(color: _text1, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Solicite o código de 4 dígitos ao cliente.',
              style: GoogleFonts.dmSans(color: _text2, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: _orange,
              ),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: _bg3,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _orange.withValues(alpha: .3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _orange, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.dmSans(color: _text3)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (ctrl.text.length == 4) {
                Navigator.pop(context);
                _finalizarEntrega(codigo: ctrl.text);
              }
            },
            child: Text(
              'Confirmar',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finalizarEntrega({String? fotoPath, String? codigo}) async {
    setState(() => _atualizando = true);
    _cronoTimer?.cancel();

    try {
      final agora = DateTime.now().toIso8601String();

      await Supabase.instance.client
          .from('pedidos')
          .update({'status': 'entregue', 'entregue_em': agora})
          .eq('id', widget.pedidoId);

      if (_entregadorId != null) {
        await Supabase.instance.client.from('entregadores').update({
          'status_despacho': 'livre',
          'pedido_atual_id': null,
          'ultima_entrega_em': agora,
        }).eq('id', _entregadorId!);
      }

      if (!mounted) return;
      _statusAnim.reset();
      setState(() {
        _status = StatusEntrega.entregue;
        _atualizando = false;
      });
      _statusAnim.forward();
      HapticFeedback.heavyImpact();

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) context.go('/dashboard_entregador');
    } catch (e) {
      if (!mounted) return;
      setState(() => _atualizando = false);
      _mostrarErro('Erro ao confirmar entrega.');
    }
  }

  void _mostrarErro(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _abrirGoogleMaps() async {
    double? lat, lng;
    if (_status == StatusEntrega.confirmado || _status == StatusEntrega.emColeta) {
      lat = _estabelecimentoLat;
      lng = _estabelecimentoLng;
    } else {
      lat = _clienteLat;
      lng = _clienteLng;
    }

    Uri uri;
    if (lat != null && lng != null) {
      uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    } else {
      final dest = (_status == StatusEntrega.confirmado || _status == StatusEntrega.emColeta)
          ? Uri.encodeComponent(_estabelecimentoEnd.isNotEmpty ? _estabelecimentoEnd : _estabelecimentoNome)
          : Uri.encodeComponent(_clienteEnd.isNotEmpty ? _clienteEnd : _clienteNome);
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$dest');
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _posStream?.cancel();
    _cronoTimer?.cancel();
    _statusAnim.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _bg0,
        body: Center(child: CircularProgressIndicator(color: _orange, strokeWidth: 2.5)),
      );
    }

    final concluida = _status == StatusEntrega.entregue;

    return Scaffold(
      backgroundColor: _bg0,
      body: Column(
        children: [
          // Mapa (visualização customizada)
          _MapArea(
            status: _status,
            origem: _estabelecimentoNome,
            destino: _clienteNome,
            posAtual: _posicaoAtual,
            estabelecimentoLat: _estabelecimentoLat,
            estabelecimentoLng: _estabelecimentoLng,
            clienteLat: _clienteLat,
            clienteLng: _clienteLng,
            onNavegar: _abrirGoogleMaps,
          ),

          // Painel deslizante
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: _bg0,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ScaleTransition(
                      scale: _statusScale,
                      child: _StatusCard(
                        status: _status,
                        tempoFormatado: _tempoFormatado,
                        mostrarCrono: _status == StatusEntrega.emEntrega,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ProgressoStepper(statusAtual: _status),
                    const SizedBox(height: 20),
                    _InfoCard(
                      numeroPedido: _numeroPedido,
                      taxaEntrega: _taxaEntrega,
                      distanciaKm: _distanciaKm,
                    ),
                    const SizedBox(height: 14),
                    _RotaSimples(
                      origem: _estabelecimentoEnd.isEmpty
                          ? _estabelecimentoNome
                          : _estabelecimentoEnd,
                      destino: _clienteEnd.isEmpty ? _clienteNome : _clienteEnd,
                    ),
                    const SizedBox(height: 14),
                    if (_clienteTelefone != null)
                      _ContatoCard(
                        nome: _clienteNome,
                        telefone: _clienteTelefone!,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: concluida
          ? null
          : Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: const BoxDecoration(
                color: _bg0,
                border: Border(top: BorderSide(color: _border)),
              ),
              child: GestureDetector(
                onTap: _atualizando ? null : _avancarStatus,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _status == StatusEntrega.emEntrega
                          ? [_green, const Color(0xFF16A34A)]
                          : [_orange, const Color(0xFFEA580C)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (_status == StatusEntrega.emEntrega ? _green : _orange)
                            .withValues(alpha: .3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _atualizando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _status.emoji,
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _status.labelBotao,
                                style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MAP AREA
// ═══════════════════════════════════════════════════════════════════════════
class _MapArea extends StatelessWidget {
  final StatusEntrega status;
  final String origem, destino;
  final Position? posAtual;
  final double? estabelecimentoLat;
  final double? estabelecimentoLng;
  final double? clienteLat;
  final double? clienteLng;
  final VoidCallback onNavegar;

  const _MapArea({
    required this.status,
    required this.origem,
    required this.destino,
    this.posAtual,
    this.estabelecimentoLat,
    this.estabelecimentoLng,
    this.clienteLat,
    this.clienteLng,
    required this.onNavegar,
  });

  @override
  Widget build(BuildContext context) {
    // Determine map center
    ll.LatLng? center;
    if (posAtual != null) {
      center = ll.LatLng(posAtual!.latitude, posAtual!.longitude);
    } else if (estabelecimentoLat != null && estabelecimentoLng != null) {
      center = ll.LatLng(estabelecimentoLat!, estabelecimentoLng!);
    } else {
      center = ll.LatLng(-23.5505, -46.6333); // São Paulo fallback
    }

    final List<Marker> markers = [];
    if (posAtual != null) {
      markers.add(Marker(
        point: ll.LatLng(posAtual!.latitude, posAtual!.longitude),
        width: 32, height: 32,
        child: const Icon(Icons.navigation_rounded, color: _orange, size: 28),
      ));
    }
    if (estabelecimentoLat != null && estabelecimentoLng != null) {
      markers.add(Marker(
        point: ll.LatLng(estabelecimentoLat!, estabelecimentoLng!),
        width: 36, height: 36,
        child: const Icon(Icons.storefront_rounded, color: _orange, size: 28),
      ));
    }
    if (clienteLat != null && clienteLng != null) {
      markers.add(Marker(
        point: ll.LatLng(clienteLat!, clienteLng!),
        width: 36, height: 36,
        child: const Icon(Icons.location_on_rounded, color: _red, size: 28),
      ));
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * .38,
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 15,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.padocaexpress.app',
              ),
              if (markers.isNotEmpty) MarkerLayer(markers: markers),
            ],
          ),
          // Back button overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _bg0.withValues(alpha: .85),
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: _text1, size: 16),
                ),
              ),
            ),
          ),
          // Status label overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _bg0.withValues(alpha: .85),
                border: Border.all(color: _orange.withValues(alpha: .25)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                status.label,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _orange,
                ),
              ),
            ),
          ),
          // "Navigate with Google Maps" button overlay
          Positioned(
            bottom: 12,
            right: 12,
            child: GestureDetector(
              onTap: onNavegar,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _orange,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .4), blurRadius: 10)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Navegar',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
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
// STATUS CARD
// ═══════════════════════════════════════════════════════════════════════════
class _StatusCard extends StatelessWidget {
  final StatusEntrega status;
  final String tempoFormatado;
  final bool mostrarCrono;

  const _StatusCard({
    required this.status,
    required this.tempoFormatado,
    required this.mostrarCrono,
  });

  @override
  Widget build(BuildContext context) {
    final concluida = status == StatusEntrega.entregue;
    final cor = concluida ? _green : _orange;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: concluida
              ? [const Color(0xFF0D1F12), const Color(0xFF071509)]
              : [const Color(0xFF1A1008), const Color(0xFF120A04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: cor.withValues(alpha: .2)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Text(status.emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.label,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _text1,
                  ),
                ),
                Text(
                  concluida
                      ? 'Ganho creditado em breve 💰'
                      : 'GPS ativo · Transmitindo localização',
                  style: GoogleFonts.dmSans(fontSize: 11, color: cor.withValues(alpha: .7)),
                ),
              ],
            ),
          ),
          if (mostrarCrono)
            Column(
              children: [
                Text(
                  tempoFormatado,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: cor,
                  ),
                ),
                Text('tempo', style: GoogleFonts.dmSans(fontSize: 9, color: _text3)),
              ],
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROGRESSO STEPPER
// ═══════════════════════════════════════════════════════════════════════════
class _ProgressoStepper extends StatelessWidget {
  final StatusEntrega statusAtual;
  const _ProgressoStepper({required this.statusAtual});

  @override
  Widget build(BuildContext context) {
    const etapas = [
      StatusEntrega.confirmado,
      StatusEntrega.emColeta,
      StatusEntrega.coletado,
      StatusEntrega.emEntrega,
      StatusEntrega.entregue,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: etapas.asMap().entries.expand((e) {
          final i = e.key;
          final etapa = e.value;
          final concluida = etapa.index <= statusAtual.index;
          final atual = etapa == statusAtual;

          final dot = AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: atual ? 30 : 22,
            height: atual ? 30 : 22,
            decoration: BoxDecoration(
              color: concluida ? _orange : _bg3,
              shape: BoxShape.circle,
              border: Border.all(
                color: atual ? _orange : _border,
                width: atual ? 2 : 1,
              ),
              boxShadow: atual
                  ? [BoxShadow(color: _orange.withValues(alpha: .4), blurRadius: 10)]
                  : [],
            ),
            child: Center(
              child: Text(etapa.emoji, style: TextStyle(fontSize: atual ? 14 : 11)),
            ),
          );

          if (i == etapas.length - 1) return [dot];

          final linhaConcluida = etapa.index < statusAtual.index;
          return [
            dot,
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: linhaConcluida ? _orange : _bg3,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ];
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// INFO CARD
// ═══════════════════════════════════════════════════════════════════════════
class _InfoCard extends StatelessWidget {
  final String numeroPedido;
  final double taxaEntrega, distanciaKm;

  const _InfoCard({
    required this.numeroPedido,
    required this.taxaEntrega,
    required this.distanciaKm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _InfoItem(label: 'PEDIDO', valor: numeroPedido, cor: _text1),
          _InfoDivider(),
          _InfoItem(
            label: 'GANHO',
            valor: 'R\$ ${taxaEntrega.toStringAsFixed(2)}',
            cor: _green,
          ),
          _InfoDivider(),
          _InfoItem(
            label: 'DISTÂNCIA',
            valor: '${distanciaKm.toStringAsFixed(1)} km',
            cor: _orange,
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label, valor;
  final Color cor;
  const _InfoItem({required this.label, required this.valor, required this.cor});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 9,
                color: _text3,
                fontWeight: FontWeight.w700,
                letterSpacing: .5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              valor,
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: cor),
            ),
          ],
        ),
      );
}

class _InfoDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 30, color: _border, margin: const EdgeInsets.symmetric(horizontal: 8));
}

// ═══════════════════════════════════════════════════════════════════════════
// ROTA SIMPLES
// ═══════════════════════════════════════════════════════════════════════════
class _RotaSimples extends StatelessWidget {
  final String origem, destino;
  const _RotaSimples({required this.origem, required this.destino});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _RotaLinha(cor: _orange, label: 'COLETA', endereco: origem),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [Container(width: 2, height: 20, color: _border)],
            ),
          ),
          _RotaLinha(cor: _green, label: 'ENTREGA', endereco: destino),
        ],
      ),
    );
  }
}

class _RotaLinha extends StatelessWidget {
  final Color cor;
  final String label, endereco;
  const _RotaLinha({required this.cor, required this.label, required this.endereco});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: cor,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: cor.withValues(alpha: .4), blurRadius: 6)],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: cor,
                  letterSpacing: .5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                endereco,
                style: GoogleFonts.dmSans(fontSize: 12, color: _text1),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CONTATO CARD
// ═══════════════════════════════════════════════════════════════════════════
class _ContatoCard extends StatelessWidget {
  final String nome, telefone;
  const _ContatoCard({required this.nome, required this.telefone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: Text('👤', style: TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _text1,
                  ),
                ),
                Text(telefone, style: GoogleFonts.dmSans(fontSize: 11, color: _text3)),
              ],
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _green.withValues(alpha: .1),
              border: Border.all(color: _green.withValues(alpha: .25)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: Text('📞', style: TextStyle(fontSize: 16))),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHEET CONFIRMAR ENTREGA
// ═══════════════════════════════════════════════════════════════════════════
class _ConfirmarEntregaSheet extends StatelessWidget {
  final VoidCallback onFoto, onCodigo;
  const _ConfirmarEntregaSheet({required this.onFoto, required this.onCodigo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          Text(
            'Como confirmar a entrega?',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: _text1),
          ),
          const SizedBox(height: 6),
          Text(
            'Escolha o método de confirmação com o cliente.',
            style: GoogleFonts.dmSans(fontSize: 13, color: _text2),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onFoto,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _bg3,
                border: Border.all(color: _orange.withValues(alpha: .25)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Text('📸', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tirar foto da entrega',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _text1,
                          ),
                        ),
                        Text(
                          'Fotografe o pedido na porta do cliente',
                          style: GoogleFonts.dmSans(fontSize: 12, color: _text3),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: _text3),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onCodigo,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _bg3,
                border: Border.all(color: _orange.withValues(alpha: .25)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Text('🔢', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Código de confirmação',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _text1,
                          ),
                        ),
                        Text(
                          'Cliente informa o código de 4 dígitos',
                          style: GoogleFonts.dmSans(fontSize: 12, color: _text3),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: _text3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
