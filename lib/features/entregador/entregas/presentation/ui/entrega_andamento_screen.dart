// ============================================================
// entrega_andamento_screen.dart â€” Entrega em Andamento
// Ã”padoca Express Â· App do Entregador
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
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:padoca_express/services/entregador/entregador_gps_service.dart';
import 'package:padoca_express/services/map_service.dart' as mapsvc;

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

// â”€â”€â”€ Status do pedido â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
        return 'Entrega concluÃ­da!';
    }
  }

  String get dbStatus {
    switch (this) {
      case StatusEntrega.confirmado:
        return 'confirmado';
      case StatusEntrega.emColeta:
        return 'a_caminho_coleta';
      case StatusEntrega.coletado:
        return 'coletado';
      case StatusEntrega.emEntrega:
        return 'em_entrega';
      case StatusEntrega.entregue:
        return 'entregue';
    }
  }

  String get emoji {
    switch (this) {
      case StatusEntrega.confirmado:
        return 'âœ…';
      case StatusEntrega.emColeta:
        return 'ðŸ›µ';
      case StatusEntrega.coletado:
        return 'ðŸ“¦';
      case StatusEntrega.emEntrega:
        return 'ðŸš€';
      case StatusEntrega.entregue:
        return 'ðŸŽ‰';
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
        return null; // Requer confirmaÃ§Ã£o especial
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
        return 'ConcluÃ­do';
    }
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// SCREEN
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
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
  String? _distanciaRotaTexto;
  String? _etaRotaTexto;
  String? _entregadorId;

  double? _estabelecimentoLat;
  double? _estabelecimentoLng;
  double? _clienteLat;
  double? _clienteLng;

  Timer? _cronoTimer;
  int _segundosEntrega = 0;
  DateTime? _inicioEntrega;

  Position? _posicaoAtual;
  bool _checkinFeito = false;

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
            em_entrega_em, codigo_coleta_balcao, codigo_confirmacao_entrega,
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
        return '$l${n.toString().isNotEmpty ? ", $n" : ""}${b.toString().isNotEmpty ? " â€” $b" : ""}';
      }

      final dbStatus = row['status'] ?? 'confirmado';
      StatusEntrega statusAtual;
      switch (dbStatus) {
        case 'a_caminho_coleta':
        case 'no_estabelecimento':
        case 'preparando':
          statusAtual = StatusEntrega.emColeta;
          _checkinFeito = dbStatus == 'no_estabelecimento';
          break;
        case 'coletado':
        case 'pronto':
          statusAtual = StatusEntrega.coletado;
          break;
        case 'a_caminho_cliente':
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
  Future<void> _iniciarGps() async {
    final ok = await EntregadorGpsService.instance.ensurePermission(
      requestAlways: true,
    );
    if (!ok) {
      if (mounted) {
        _mostrarErro('Ative a localização para rastrear a entrega.');
      }
      return;
    }

    EntregadorGpsService.instance.startDeliveryTracking((pos) {
      if (!mounted) return;
      setState(() => _posicaoAtual = pos);
      _enviarLocalizacao(pos);
    });
  }

  DateTime? _ultimoGpsEnviado;

  Future<void> _enviarLocalizacao(Position pos) async {
    if (_entregadorId == null) return;
    final agora = DateTime.now();
    if (_ultimoGpsEnviado != null &&
        agora.difference(_ultimoGpsEnviado!) < const Duration(seconds: 8)) {
      return;
    }
    _ultimoGpsEnviado = agora;
    try {
      await _rpcOk('fn_atualizar_localizacao_entrega', {
        'p_pedido_id': widget.pedidoId,
        'p_lat': pos.latitude,
        'p_lng': pos.longitude,
        'p_velocidade_kmh': (pos.speed * 3.6).clamp(0, 200),
      });
      await _talvezCheckinEstabelecimento(pos);
    } catch (_) {}
  }

  Future<void> _talvezCheckinEstabelecimento(Position pos) async {
    if (_checkinFeito) return;
    if (_status != StatusEntrega.emColeta) return;
    if (_estabelecimentoLat == null || _estabelecimentoLng == null) return;
    final dist = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      _estabelecimentoLat!,
      _estabelecimentoLng!,
    );
    if (dist > 150) return;
    try {
      await _rpcOk('fn_checkin_estabelecimento', {
        'p_pedido_id': widget.pedidoId,
        'p_lat': pos.latitude,
        'p_lng': pos.longitude,
      });
      _checkinFeito = true;
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _rpcOk(
    String fn,
    Map<String, dynamic> params,
  ) async {
    final response = await Supabase.instance.client.rpc(fn, params: params);
    final data = Map<String, dynamic>.from(response as Map);
    if (data['ok'] != true) {
      final erro = data['erro'] ?? data['mensagem'] ?? 'Operacao recusada.';
      final tentativas = data['tentativas_restantes'];
      if (tentativas != null) {
        throw Exception('$erro (tentativas restantes: $tentativas)');
      }
      throw Exception(erro);
    }
    return data;
  }

  // â”€â”€ CronÃ´metro â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  // â”€â”€ AvanÃ§a status â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _avancarStatus() async {
    if (_atualizando) return;

    // Retirada no estabelecimento: exige cÃ³digo do balcÃ£o
    if (_status == StatusEntrega.emColeta) {
      _mostrarDialogCodigoEstabelecimento();
      return;
    }

    // ConfirmaÃ§Ã£o da entrega ao cliente
    if (_status == StatusEntrega.emEntrega) {
      _mostrarConfirmacaoEntrega();
      return;
    }

    final proximo = _status.proximo;
    if (proximo == null) return;

    HapticFeedback.mediumImpact();
    setState(() => _atualizando = true);

    try {
      if (proximo == StatusEntrega.emColeta) {
        await _rpcOk('fn_iniciar_coleta', {'p_pedido_id': widget.pedidoId});
      } else if (proximo == StatusEntrega.emEntrega) {
        await _rpcOk('fn_saiu_para_cliente', {'p_pedido_id': widget.pedidoId});
        _inicioEntrega = DateTime.now();
        _iniciarCronometro();
      } else {
        throw Exception('Transicao nao suportada.');
      }

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

  // â”€â”€ CÃ³digo do balcÃ£o (estabelecimento â†’ entregador) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _mostrarDialogCodigoEstabelecimento() {
    final ctrl = TextEditingController();
    String? erroMsg;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ðŸª', style: TextStyle(fontSize: 28)),
              const SizedBox(height: 8),
              Text(
                'CÃ³digo de retirada',
                style: GoogleFonts.outfit(
                    color: _text1, fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Solicite o cÃ³digo no balcÃ£o do estabelecimento e digite abaixo.',
                style: GoogleFonts.dmSans(color: _text2, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: _orange,
                  letterSpacing: 6,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _bg3,
                  hintText: 'â€¢ â€¢ â€¢ â€¢',
                  hintStyle: GoogleFonts.outfit(
                      color: _text3, fontSize: 26, letterSpacing: 6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _orange.withValues(alpha: .3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _orange, width: 2),
                  ),
                  errorText: erroMsg,
                  errorStyle:
                      GoogleFonts.dmSans(color: _red, fontSize: 12),
                ),
                onChanged: (_) {
                  if (erroMsg != null) setDlg(() => erroMsg = null);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar',
                  style: GoogleFonts.dmSans(color: _text3)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final entrada = ctrl.text.trim().toUpperCase();
                if (entrada.isEmpty) {
                  setDlg(() => erroMsg = 'Digite o cÃ³digo.');
                  return;
                }
                try {
                  await _rpcOk('fn_validar_codigo_balcao', {
                    'p_pedido_id': widget.pedidoId,
                    'p_codigo': entrada,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _avancarParaColetado();
                } catch (e) {
                  setDlg(() => erroMsg = e.toString().replaceFirst('Exception: ', ''));
                  HapticFeedback.heavyImpact();
                }
              },
              child: Text('Confirmar retirada',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _avancarParaColetado() async {
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    _statusAnim.reset();
    setState(() {
      _status = StatusEntrega.coletado;
      _atualizando = false;
    });
    _statusAnim.forward();
    HapticFeedback.heavyImpact();
  }

  // â”€â”€ Confirmar entrega â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

      if (!mounted) return;
      setState(() => _atualizando = false);
      _mostrarDialogCodigo(fotoPath: path);
    } catch (e) {
      if (mounted) {
        setState(() => _atualizando = false);
        _mostrarErro('Erro ao enviar foto.');
      }
    }
  }

  void _mostrarDialogCodigo({String? fotoPath}) {
    final ctrl = TextEditingController();
    String? erroMsg;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: _card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ðŸ“¦', style: TextStyle(fontSize: 28)),
              const SizedBox(height: 8),
              Text(
                'CÃ³digo do cliente',
                style: GoogleFonts.outfit(
                    color: _text1,
                    fontWeight: FontWeight.w800,
                    fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Solicite o cÃ³digo de confirmaÃ§Ã£o ao cliente para finalizar a entrega.',
                style: GoogleFonts.dmSans(color: _text2, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: _green,
                  letterSpacing: 6,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: _bg3,
                  hintText: 'â€¢ â€¢ â€¢ â€¢',
                  hintStyle: GoogleFonts.outfit(
                      color: _text3, fontSize: 28, letterSpacing: 6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: _green.withValues(alpha: .3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _green, width: 2),
                  ),
                  errorText: erroMsg,
                  errorStyle:
                      GoogleFonts.dmSans(color: _red, fontSize: 12),
                ),
                onChanged: (_) {
                  if (erroMsg != null) setDlg(() => erroMsg = null);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  Text('Cancelar', style: GoogleFonts.dmSans(color: _text3)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final entrada = ctrl.text.trim().toUpperCase();
                if (entrada.isEmpty) {
                  setDlg(() => erroMsg = 'Digite o cÃ³digo.');
                  return;
                }
                try {
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _finalizarEntrega(codigo: entrada, fotoPath: fotoPath);
                } catch (e) {
                  setDlg(() => erroMsg =
                      e.toString().replaceFirst('Exception: ', ''));
                  HapticFeedback.heavyImpact();
                }
              },
              child: Text(
                'Confirmar entrega',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finalizarEntrega({required String codigo, String? fotoPath}) async {
    setState(() => _atualizando = true);
    _cronoTimer?.cancel();

    try {
      await _rpcOk('fn_confirmar_entrega', {
        'p_pedido_id': widget.pedidoId,
        'p_codigo': codigo,
        'p_foto_path': fotoPath,
      });

      if (!mounted) return;
      _statusAnim.reset();
      setState(() {
        _status = StatusEntrega.entregue;
        _atualizando = false;
      });
      _statusAnim.forward();
      HapticFeedback.heavyImpact();

      if (!mounted) return;
      await _mostrarResumoEntrega();
      if (mounted) context.go('/dashboard_entregador');
    } catch (e) {
      if (!mounted) return;
      setState(() => _atualizando = false);
      _mostrarErro(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _mostrarResumoEntrega() async {
    final valor = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
        .format(_taxaEntrega);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Entrega concluída!',
          style: GoogleFonts.outfit(
            color: _green,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Valor da entrega: $valor',
                style: GoogleFonts.dmSans(color: _text1)),
            if (_distanciaRotaTexto != null)
              Text('Distância: $_distanciaRotaTexto',
                  style: GoogleFonts.dmSans(color: _text2)),
            Text('Tempo: $_tempoFormatado',
                style: GoogleFonts.dmSans(color: _text2)),
            const SizedBox(height: 8),
            Text(
              'Repasse Asaas será processado após validação.',
              style: GoogleFonts.dmSans(fontSize: 11, color: _text3),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Continuar',
                style: GoogleFonts.dmSans(color: _orange)),
          ),
        ],
      ),
    );
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

  void _atualizarResumoRota(String? distancia, String? eta) {
    if (!mounted) return;
    if (_distanciaRotaTexto == distancia && _etaRotaTexto == eta) return;
    setState(() {
      _distanciaRotaTexto = distancia;
      _etaRotaTexto = eta;
    });
  }

  @override
  void dispose() {
    EntregadorGpsService.instance.stopDeliveryTracking();
    _cronoTimer?.cancel();
    _statusAnim.dispose();
    super.dispose();
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // BUILD
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
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
          // Mapa (visualizaÃ§Ã£o customizada)
          _GoogleMapArea(
            status: _status,
            origem: _estabelecimentoNome,
            destino: _clienteNome,
            posAtual: _posicaoAtual,
            estabelecimentoLat: _estabelecimentoLat,
            estabelecimentoLng: _estabelecimentoLng,
            clienteLat: _clienteLat,
            clienteLng: _clienteLng,
            onNavegar: _abrirGoogleMaps,
            onRotaAtualizada: _atualizarResumoRota,
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
                      distanciaTexto: _distanciaRotaTexto,
                      etaTexto: _etaRotaTexto,
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

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// MAP AREA â€” com rota dinÃ¢mica via MapService
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _GoogleMapArea extends StatefulWidget {
  final StatusEntrega status;
  final String origem, destino;
  final Position? posAtual;
  final double? estabelecimentoLat;
  final double? estabelecimentoLng;
  final double? clienteLat;
  final double? clienteLng;
  final VoidCallback onNavegar;
  final void Function(String? distancia, String? eta)? onRotaAtualizada;

  const _GoogleMapArea({
    required this.status,
    required this.origem,
    required this.destino,
    this.posAtual,
    this.estabelecimentoLat,
    this.estabelecimentoLng,
    this.clienteLat,
    this.clienteLng,
    required this.onNavegar,
    this.onRotaAtualizada,
  });

  @override
  State<_GoogleMapArea> createState() => _GoogleMapAreaState();
}

class _GoogleMapAreaState extends State<_GoogleMapArea> {
  gm.GoogleMapController? _mapController;
  List<gm.LatLng> _rota = [];
  bool _carregandoRota = false;
  String? _ultimaRotaKey;

  bool get _indoEstabelecimento =>
      widget.status == StatusEntrega.confirmado ||
      widget.status == StatusEntrega.emColeta;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarRota());
  }

  @override
  void didUpdateWidget(covariant _GoogleMapArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    final statusMudou = oldWidget.status != widget.status;
    final primeiroGps = oldWidget.posAtual == null && widget.posAtual != null;
    final moveuBastante =
        _moveuDistanciaRelevante(oldWidget.posAtual, widget.posAtual);
    final destinoMudou =
        oldWidget.estabelecimentoLat != widget.estabelecimentoLat ||
        oldWidget.estabelecimentoLng != widget.estabelecimentoLng ||
        oldWidget.clienteLat != widget.clienteLat ||
        oldWidget.clienteLng != widget.clienteLng;

    if (statusMudou || primeiroGps || moveuBastante || destinoMudou) {
      _carregarRota();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  bool _moveuDistanciaRelevante(Position? anterior, Position? atual) {
    if (anterior == null || atual == null) return false;
    final metros = Geolocator.distanceBetween(
      anterior.latitude,
      anterior.longitude,
      atual.latitude,
      atual.longitude,
    );
    return metros >= 60;
  }

  gm.LatLng? _destinoAtivo() {
    final lat = _indoEstabelecimento ? widget.estabelecimentoLat : widget.clienteLat;
    final lng = _indoEstabelecimento ? widget.estabelecimentoLng : widget.clienteLng;
    if (lat == null || lng == null) return null;
    return gm.LatLng(lat, lng);
  }

  gm.LatLng? _origemAtiva() {
    if (widget.posAtual != null) {
      return gm.LatLng(widget.posAtual!.latitude, widget.posAtual!.longitude);
    }
    if (!_indoEstabelecimento &&
        widget.estabelecimentoLat != null &&
        widget.estabelecimentoLng != null) {
      return gm.LatLng(widget.estabelecimentoLat!, widget.estabelecimentoLng!);
    }
    return null;
  }

  Future<void> _carregarRota() async {
    if (_carregandoRota) return;

    final origem = _origemAtiva();
    final destino = _destinoAtivo();
    if (origem == null || destino == null) {
      widget.onRotaAtualizada?.call(null, null);
      return;
    }

    final rotaKey =
        '${widget.status.name}|${origem.latitude.toStringAsFixed(5)},'
        '${origem.longitude.toStringAsFixed(5)}|'
        '${destino.latitude.toStringAsFixed(5)},'
        '${destino.longitude.toStringAsFixed(5)}';
    if (rotaKey == _ultimaRotaKey) return;

    setState(() => _carregandoRota = true);
    _ultimaRotaKey = rotaKey;

    try {
      final info = await mapsvc.MapService.instance.buscarRotaDetalhada(
        origem: mapsvc.LatLng(origem.latitude, origem.longitude),
        destino: mapsvc.LatLng(destino.latitude, destino.longitude),
      );

      if (!mounted) return;
      final pontos = info.pontos
          .map((p) => gm.LatLng(p.latitude, p.longitude))
          .toList();

      setState(() {
        _rota = pontos;
        _carregandoRota = false;
      });
      widget.onRotaAtualizada?.call(info.distanciaTexto, info.duracaoTexto);
      await _enquadrarRota(pontos.isEmpty ? [origem, destino] : pontos);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rota = [origem, destino];
        _carregandoRota = false;
      });
      widget.onRotaAtualizada?.call(null, null);
      await _enquadrarRota(_rota);
    }
  }

  Future<void> _enquadrarRota(List<gm.LatLng> pontos) async {
    final controller = _mapController;
    if (controller == null || pontos.isEmpty) return;

    try {
      if (pontos.length == 1) {
        await controller.animateCamera(
          gm.CameraUpdate.newLatLngZoom(pontos.first, 15),
        );
        return;
      }

      var minLat = pontos.first.latitude;
      var maxLat = pontos.first.latitude;
      var minLng = pontos.first.longitude;
      var maxLng = pontos.first.longitude;
      for (final ponto in pontos) {
        if (ponto.latitude < minLat) minLat = ponto.latitude;
        if (ponto.latitude > maxLat) maxLat = ponto.latitude;
        if (ponto.longitude < minLng) minLng = ponto.longitude;
        if (ponto.longitude > maxLng) maxLng = ponto.longitude;
      }

      if (minLat == maxLat && minLng == maxLng) {
        await controller.animateCamera(
          gm.CameraUpdate.newLatLngZoom(gm.LatLng(minLat, minLng), 15),
        );
        return;
      }

      await controller.animateCamera(
        gm.CameraUpdate.newLatLngBounds(
          gm.LatLngBounds(
            southwest: gm.LatLng(minLat, minLng),
            northeast: gm.LatLng(maxLat, maxLng),
          ),
          56,
        ),
      );
    } catch (_) {}
  }

  Set<gm.Marker> _markers() {
    final markers = <gm.Marker>{};

    if (widget.posAtual != null) {
      markers.add(
        gm.Marker(
          markerId: const gm.MarkerId('entregador'),
          position: gm.LatLng(widget.posAtual!.latitude, widget.posAtual!.longitude),
          icon: gm.BitmapDescriptor.defaultMarkerWithHue(
            gm.BitmapDescriptor.hueOrange,
          ),
          infoWindow: const gm.InfoWindow(title: 'Entregador'),
        ),
      );
    }

    if (widget.estabelecimentoLat != null && widget.estabelecimentoLng != null) {
      markers.add(
        gm.Marker(
          markerId: const gm.MarkerId('estabelecimento'),
          position: gm.LatLng(widget.estabelecimentoLat!, widget.estabelecimentoLng!),
          icon: gm.BitmapDescriptor.defaultMarkerWithHue(
            _indoEstabelecimento
                ? gm.BitmapDescriptor.hueOrange
                : gm.BitmapDescriptor.hueYellow,
          ),
          infoWindow: gm.InfoWindow(title: widget.origem),
        ),
      );
    }

    if (widget.clienteLat != null && widget.clienteLng != null) {
      markers.add(
        gm.Marker(
          markerId: const gm.MarkerId('cliente'),
          position: gm.LatLng(widget.clienteLat!, widget.clienteLng!),
          icon: gm.BitmapDescriptor.defaultMarkerWithHue(
            _indoEstabelecimento
                ? gm.BitmapDescriptor.hueRose
                : gm.BitmapDescriptor.hueRed,
          ),
          infoWindow: gm.InfoWindow(title: widget.destino),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final destino = _destinoAtivo();
    final origem = _origemAtiva();
    final center = origem ??
        destino ??
        (widget.estabelecimentoLat != null && widget.estabelecimentoLng != null
            ? gm.LatLng(widget.estabelecimentoLat!, widget.estabelecimentoLng!)
            : const gm.LatLng(-23.5505, -46.6333));

    return SizedBox(
      height: MediaQuery.of(context).size.height * .38,
      child: Stack(
        children: [
          gm.GoogleMap(
            initialCameraPosition: gm.CameraPosition(target: center, zoom: 15),
            markers: _markers(),
            polylines: {
              if (_rota.length >= 2)
                gm.Polyline(
                  polylineId: const gm.PolylineId('rota_entrega'),
                  points: _rota,
                  color: _indoEstabelecimento
                      ? const Color(0xFF3B82F6)
                      : _green,
                  width: 5,
                ),
            },
            myLocationEnabled: widget.posAtual != null,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              if (_rota.isNotEmpty) {
                _enquadrarRota(_rota);
              } else {
                _carregarRota();
              }
            },
          ),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_carregandoRota) ...[
                    const SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: _orange,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    widget.status.label,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _bg0.withValues(alpha: .85),
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _indoEstabelecimento
                          ? const Color(0xFF3B82F6)
                          : _green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _indoEstabelecimento
                        ? 'Rota até estabelecimento'
                        : 'Rota até cliente',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _text2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: GestureDetector(
              onTap: widget.onNavegar,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _orange,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .4),
                      blurRadius: 10,
                    ),
                  ],
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

// STATUS CARD
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
                      ? 'Ganho creditado em breve ðŸ’°'
                      : 'GPS ativo Â· Transmitindo localizaÃ§Ã£o',
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

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// PROGRESSO STEPPER
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
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

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// INFO CARD
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _InfoCard extends StatelessWidget {
  final String numeroPedido;
  final double taxaEntrega, distanciaKm;
  final String? distanciaTexto;
  final String? etaTexto;

  const _InfoCard({
    required this.numeroPedido,
    required this.taxaEntrega,
    required this.distanciaKm,
    this.distanciaTexto,
    this.etaTexto,
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
            label: 'DISTÃ‚NCIA',
            valor: distanciaTexto ?? '${distanciaKm.toStringAsFixed(1)} km',
            cor: _orange,
          ),
          _InfoDivider(),
          _InfoItem(
            label: 'ETA',
            valor: etaTexto ?? '--',
            cor: _text1,
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

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// ROTA SIMPLES
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
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

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// CONTATO CARD
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
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
            child: const Center(child: Text('ðŸ‘¤', style: TextStyle(fontSize: 16))),
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
            child: const Center(child: Text('ðŸ“ž', style: TextStyle(fontSize: 16))),
          ),
        ],
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// SHEET CONFIRMAR ENTREGA
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
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
            'Escolha o mÃ©todo de confirmaÃ§Ã£o com o cliente.',
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
                  const Text('ðŸ“¸', style: TextStyle(fontSize: 24)),
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
                  const Text('ðŸ”¢', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CÃ³digo de confirmaÃ§Ã£o',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _text1,
                          ),
                        ),
                        Text(
                          'Cliente informa o cÃ³digo de 4 dÃ­gitos',
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
