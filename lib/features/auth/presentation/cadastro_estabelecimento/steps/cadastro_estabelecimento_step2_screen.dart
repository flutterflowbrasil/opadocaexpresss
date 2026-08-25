import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:padoca_express/core/services/localizacao_service.dart';
import 'package:padoca_express/features/cliente/localizacao/adicionar_endereco_formulario.dart';
import 'package:padoca_express/features/cliente/localizacao/localizacao_repository.dart';
import 'package:padoca_express/features/estabelecimento/componentes/app_bar_estabelecimento.dart';
import 'package:padoca_express/features/auth/presentation/cadastro_estabelecimento/cadastro_estabelecimento_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CadastroEstabelecimentoStep2Screen extends ConsumerStatefulWidget {
  const CadastroEstabelecimentoStep2Screen({super.key});

  @override
  ConsumerState<CadastroEstabelecimentoStep2Screen> createState() =>
      _CadastroEstabelecimentoStep2ScreenState();
}

class _CadastroEstabelecimentoStep2ScreenState
    extends ConsumerState<CadastroEstabelecimentoStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  final _cepController = TextEditingController();
  final _logradouroController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();
  final _mapController = MapController();
  late final LocalizacaoRepository _localizacaoRepository;

  bool _buscandoCep = false;
  bool _localizando = false;
  bool _mostrandoMapa = false;
  bool _pontoSelecionadoManual = false;
  String? _erroCep;
  double? _latitude;
  double? _longitude;

  final _cepFormatter = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {'#': RegExp(r'[0-9]')},
  );

  // Estado dos horários (simplificado para Seg-Sex, Sab, Dom)
  // Estrutura: {'aberto': bool, 'inicio': String, 'fim': String}
  final Map<String, Map<String, dynamic>> _horarios = {
    'seg': {'aberto': true, 'inicio': '07:00', 'fim': '20:00'},
    'ter': {'aberto': true, 'inicio': '07:00', 'fim': '20:00'},
    'qua': {'aberto': true, 'inicio': '07:00', 'fim': '20:00'},
    'qui': {'aberto': true, 'inicio': '07:00', 'fim': '20:00'},
    'sex': {'aberto': true, 'inicio': '07:00', 'fim': '20:00'},
    'sab': {'aberto': true, 'inicio': '08:00', 'fim': '18:00'},
    'dom': {'aberto': false, 'inicio': '08:00', 'fim': '14:00'},
  };

  @override
  void initState() {
    super.initState();
    _localizacaoRepository = LocalizacaoRepository(Supabase.instance.client);
    final state = ref.read(cadastroEstabelecimentoProvider);
    if (state.cep != null) _cepController.text = state.cep!;
    if (state.logradouro != null) {
      _logradouroController.text = state.logradouro!;
    }
    if (state.numero != null) _numeroController.text = state.numero!;
    if (state.bairro != null) _bairroController.text = state.bairro!;
    if (state.cidade != null) _cidadeController.text = state.cidade!;
    if (state.estado != null) _estadoController.text = state.estado!;
    _latitude = state.latitude;
    _longitude = state.longitude;

    // Se já tiver horários no estado, carregar aqui (omitido para simplificar, usando padrão)
  }

  @override
  void dispose() {
    _cepController.dispose();
    _logradouroController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if ((_latitude == null || _longitude == null) &&
          _cepController.text.replaceAll(RegExp(r'\D'), '').length == 8) {
        await _buscarCep();
      }
      if (!_pontoSelecionadoManual &&
          _cepController.text.replaceAll(RegExp(r'\D'), '').length == 8 &&
          _numeroController.text.trim().isNotEmpty) {
        await _atualizarCoordenadasPorEndereco();
      }

      // Atualizar o map completo de horários com base nos switches visuais
      // (Em um app real, cada dia teria seu controle individual se desejado)
      // Horários já estão atualizados no map _horarios diretamente pelos switches

      ref.read(cadastroEstabelecimentoProvider.notifier).updateStep2(
            cep: _cepController.text,
            logradouro: _logradouroController.text,
            numero: _numeroController.text,
            bairro: _bairroController.text,
            cidade: _cidadeController.text,
            estado: _estadoController.text,
            latitude: _latitude,
            longitude: _longitude,
            horarioFuncionamento: _horarios,
          );

      if (!mounted) return;
      context.push('/cadastro-estabelecimento/step3');
    }
  }

  Future<void> _buscarCep() async {
    final cep = _cepController.text.replaceAll(RegExp(r'\D'), '');
    if (cep.length != 8) {
      setState(() => _erroCep = 'CEP deve ter 8 digitos');
      return;
    }

    setState(() {
      _buscandoCep = true;
      _erroCep = null;
    });

    try {
      final headers = {
        'User-Agent': 'PadocaExpressApp/1.0',
        'Accept': 'application/json',
      };

      Map<String, dynamic> data = {};
      Map<String, double>? apiCoords;
      var found = false;

      try {
        final response = await http
            .get(
              Uri.parse('https://brasilapi.com.br/api/cep/v2/$cep'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 6));

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          if (!body.containsKey('errors')) {
            data = {
              'logradouro': body['street'] ?? '',
              'bairro': body['neighborhood'] ?? '',
              'cidade': body['city'] ?? '',
              'estado': body['state'] ?? '',
            };
            final coordinates =
                (body['location'] as Map<String, dynamic>?)?['coordinates']
                    as Map<String, dynamic>?;
            final lat = double.tryParse('${coordinates?['latitude'] ?? ''}');
            final lng = double.tryParse('${coordinates?['longitude'] ?? ''}');
            if (lat != null && lng != null) {
              apiCoords = {'lat': lat, 'lng': lng};
            }
            found = true;
          }
        }
      } catch (_) {}

      if (!found) {
        try {
          final response = await http
              .get(
                Uri.parse('https://brasilapi.com.br/api/cep/v1/$cep'),
                headers: headers,
              )
              .timeout(const Duration(seconds: 6));

          if (response.statusCode == 200) {
            final body = jsonDecode(response.body) as Map<String, dynamic>;
            if (!body.containsKey('errors')) {
              data = {
                'logradouro': body['street'] ?? '',
                'bairro': body['neighborhood'] ?? '',
                'cidade': body['city'] ?? '',
                'estado': body['state'] ?? '',
              };
              found = true;
            }
          }
        } catch (_) {}
      }

      if (!found) {
        final response = await http
            .get(
              Uri.parse('https://viacep.com.br/ws/$cep/json/'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 6));
        final body = jsonDecode(response.body) as Map<String, dynamic>;

        if (response.statusCode == 200 && body['erro'] != true) {
          data = {
            'logradouro': body['logradouro'] ?? '',
            'bairro': body['bairro'] ?? '',
            'cidade': body['localidade'] ?? '',
            'estado': body['uf'] ?? '',
          };
          found = true;
        }
      }

      if (!found) {
        setState(() => _erroCep = 'CEP nao encontrado');
        return;
      }

      _logradouroController.text = data['logradouro'] as String? ?? '';
      _bairroController.text = data['bairro'] as String? ?? '';
      _cidadeController.text = data['cidade'] as String? ?? '';
      _estadoController.text = data['estado'] as String? ?? '';
      _pontoSelecionadoManual = false;

      final hasStreet = _logradouroController.text.trim().isNotEmpty;
      Map<String, double>? coords;
      if (hasStreet) {
        coords = await _localizacaoRepository.geocodeEndereco(
          cep: cep,
          logradouro: _logradouroController.text,
          bairro: _bairroController.text,
          cidade: _cidadeController.text,
          estado: _estadoController.text,
          numero: _numeroController.text,
        );
      } else {
        coords = apiCoords;
        coords ??= await _localizacaoRepository.geocodeEndereco(
          cep: cep,
          logradouro: _logradouroController.text,
          bairro: _bairroController.text,
          cidade: _cidadeController.text,
          estado: _estadoController.text,
          numero: _numeroController.text,
        );
      }
      if (coords != null && mounted) {
        final lat = coords['lat'];
        final lng = coords['lng'];
        setState(() {
          _latitude = lat;
          _longitude = lng;
        });
      }
    } catch (_) {
      setState(() => _erroCep = 'Erro ao buscar CEP. Verifique sua conexao.');
    } finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
  }

  Future<void> _atualizarCoordenadasPorEndereco() async {
    final coords = await _localizacaoRepository.geocodeEndereco(
      cep: _cepController.text,
      logradouro: _logradouroController.text,
      bairro: _bairroController.text,
      cidade: _cidadeController.text,
      estado: _estadoController.text,
      numero: _numeroController.text,
    );
    if (coords == null || !mounted) return;

    setState(() {
      _latitude = coords['lat'];
      _longitude = coords['lng'];
    });
  }

  Future<void> _usarLocalizacaoAtual() async {
    setState(() => _localizando = true);

    try {
      final pos = await obterLocalizacao();
      if (pos == null) {
        _showMessage('Nao foi possivel obter sua localizacao.', isError: true);
        return;
      }

      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _pontoSelecionadoManual = true;
      });

      await _preencherEnderecoPorCoordenadas(pos.latitude, pos.longitude);
    } finally {
      if (mounted) setState(() => _localizando = false);
    }
  }

  Future<void> _confirmarMapa() async {
    final lat = _latitude ?? -5.0892;
    final lng = _longitude ?? -42.8019;
    await _preencherEnderecoPorCoordenadas(lat, lng);
    if (mounted) {
      setState(() {
        _mostrandoMapa = false;
        _pontoSelecionadoManual = true;
      });
    }
  }

  Future<void> _gpsNoMapa() async {
    final pos = await obterLocalizacao();
    if (pos == null) return;

    setState(() {
      _latitude = pos.latitude;
      _longitude = pos.longitude;
      _pontoSelecionadoManual = true;
    });
    _mapController.move(_mapPoint, 17);
  }

  Future<void> _preencherEnderecoPorCoordenadas(double lat, double lng) async {
    final geo = await _localizacaoRepository.reverseGeocode(lat, lng);
    if (geo == null || !mounted) return;

    setState(() {
      final cep = (geo['cep'] as String? ?? '').trim();
      final logradouro = (geo['logradouro'] as String? ?? '').trim();
      final bairro = (geo['bairro'] as String? ?? '').trim();
      final cidade = (geo['cidade'] as String? ?? '').trim();
      final estado = (geo['estado'] as String? ?? '').trim();

      if (cep.isNotEmpty) _cepController.text = _formatCep(cep);
      if (logradouro.isNotEmpty) _logradouroController.text = logradouro;
      if (bairro.isNotEmpty) _bairroController.text = bairro;
      if (cidade.isNotEmpty) _cidadeController.text = cidade;
      if (estado.isNotEmpty) _estadoController.text = _normalizeEstado(estado);
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
      ),
    );
  }

  String _formatCep(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return value;
    return '${digits.substring(0, 5)}-${digits.substring(5)}';
  }

  String _normalizeEstado(String value) {
    final text = value.trim();
    if (text.length == 2) return text.toUpperCase();

    const estados = {
      'acre': 'AC',
      'alagoas': 'AL',
      'amapa': 'AP',
      'amazonas': 'AM',
      'bahia': 'BA',
      'ceara': 'CE',
      'distrito federal': 'DF',
      'espirito santo': 'ES',
      'goias': 'GO',
      'maranhao': 'MA',
      'mato grosso': 'MT',
      'mato grosso do sul': 'MS',
      'minas gerais': 'MG',
      'para': 'PA',
      'paraiba': 'PB',
      'parana': 'PR',
      'pernambuco': 'PE',
      'piaui': 'PI',
      'rio de janeiro': 'RJ',
      'rio grande do norte': 'RN',
      'rio grande do sul': 'RS',
      'rondonia': 'RO',
      'roraima': 'RR',
      'santa catarina': 'SC',
      'sao paulo': 'SP',
      'sergipe': 'SE',
      'tocantins': 'TO',
    };

    final normalized = text
        .toLowerCase()
        .replaceAll(RegExp(r'[áàãâä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòõôö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ç', 'c');
    return estados[normalized] ?? text;
  }

  LatLng get _mapPoint => LatLng(_latitude ?? -5.0892, _longitude ?? -42.8019);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFFff7033);
    final burgundyColor = const Color(0xFF7d2d35);

    if (_mostrandoMapa) {
      return AdicionarEnderecoMapa(
        lat: _mapPoint.latitude,
        lng: _mapPoint.longitude,
        logradouro: _logradouroController.text,
        bairro: _bairroController.text,
        mapController: _mapController,
        onPositionChanged: (lat, lng) => setState(() {
          _latitude = lat;
          _longitude = lng;
          _pontoSelecionadoManual = true;
        }),
        onVoltar: () => setState(() => _mostrandoMapa = false),
        onConfirmar: _confirmarMapa,
        onGps: _gpsNoMapa,
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF23150f) : const Color(0xFFf9f5f0),
      appBar: const AppBarEstabelecimento(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PASSO 2 DE 3',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: burgundyColor.withValues(alpha: 0.6),
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '66%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: burgundyColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.66,
                      backgroundColor: burgundyColor.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(primaryColor),
                      minHeight: 6,
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'Configurações',
                    style: GoogleFonts.plusJakartaSans(
                      color: isDark ? Colors.white : burgundyColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Configure o endereço e os horários da sua padaria.',
                    style: GoogleFonts.plusJakartaSans(
                      color: isDark
                          ? Colors.grey[400]
                          : burgundyColor.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Endereço
                  _buildSectionTitle(
                    Icons.location_on,
                    'Endereço',
                    isDark,
                    burgundyColor,
                    primaryColor,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _cepController,
                    label: 'CEP',
                    isDark: isDark,
                    hintText: '00000-000',
                    keyboardType: TextInputType.number,
                    inputFormatters: [_cepFormatter],
                    errorText: _erroCep,
                    onFieldSubmitted: (_) => _buscarCep(),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _buscandoCep ? null : _buscarCep,
                          icon: _buscandoCep
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.search),
                          label: const Text('Buscar CEP'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildLocationActions(isDark, primaryColor, burgundyColor),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _logradouroController,
                    label: 'Logradouro',
                    isDark: isDark,
                    hintText: 'Rua, Avenida, Travessa...',
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: _buildTextField(
                          controller: _numeroController,
                          label: 'Número',
                          isDark: isDark,
                          hintText: '123',
                          validator: (v) => v == null || v.isEmpty
                              ? 'Campo obrigatório'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _buildTextField(
                          controller: _bairroController,
                          label: 'Bairro',
                          isDark: isDark,
                          hintText: 'Bairro',
                          validator: (v) => v == null || v.isEmpty
                              ? 'Campo obrigatório'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildTextField(
                          controller: _cidadeController,
                          label: 'Cidade',
                          isDark: isDark,
                          hintText: 'Cidade',
                          validator: (v) => v == null || v.isEmpty
                              ? 'Campo obrigatório'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: _buildTextField(
                          controller: _estadoController,
                          label: 'UF',
                          isDark: isDark,
                          hintText: 'UF',
                          maxLength: 2,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Campo obrigatório'
                              : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Horários
                  _buildSectionTitle(
                    Icons.schedule,
                    'Horário de Funcionamento',
                    isDark,
                    burgundyColor,
                    primaryColor,
                  ),
                  const SizedBox(height: 16),

                  _buildDaySchedule(
                    'Segunda-feira',
                    'seg',
                    _horarios['seg']!['aberto'],
                    (v) => setState(() => _horarios['seg']!['aberto'] = v),
                    isDark,
                    burgundyColor,
                  ),
                  const SizedBox(height: 12),
                  _buildDaySchedule(
                    'Terça-feira',
                    'ter',
                    _horarios['ter']!['aberto'],
                    (v) => setState(() => _horarios['ter']!['aberto'] = v),
                    isDark,
                    burgundyColor,
                  ),
                  const SizedBox(height: 12),
                  _buildDaySchedule(
                    'Quarta-feira',
                    'qua',
                    _horarios['qua']!['aberto'],
                    (v) => setState(() => _horarios['qua']!['aberto'] = v),
                    isDark,
                    burgundyColor,
                  ),
                  const SizedBox(height: 12),
                  _buildDaySchedule(
                    'Quinta-feira',
                    'qui',
                    _horarios['qui']!['aberto'],
                    (v) => setState(() => _horarios['qui']!['aberto'] = v),
                    isDark,
                    burgundyColor,
                  ),
                  const SizedBox(height: 12),
                  _buildDaySchedule(
                    'Sexta-feira',
                    'sex',
                    _horarios['sex']!['aberto'],
                    (v) => setState(() => _horarios['sex']!['aberto'] = v),
                    isDark,
                    burgundyColor,
                  ),
                  const SizedBox(height: 12),
                  _buildDaySchedule(
                    'Sábado',
                    'sab',
                    _horarios['sab']!['aberto'],
                    (v) => setState(() => _horarios['sab']!['aberto'] = v),
                    isDark,
                    burgundyColor,
                  ),
                  const SizedBox(height: 12),
                  _buildDaySchedule(
                    'Domingo',
                    'dom',
                    _horarios['dom']!['aberto'],
                    (v) => setState(() => _horarios['dom']!['aberto'] = v),
                    isDark,
                    burgundyColor,
                  ),

                  const SizedBox(height: 40),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Continuar',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, color: Colors.white),
                        ],
                      ),
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

  Widget _buildSectionTitle(
    IconData icon,
    String title,
    bool isDark,
    Color color,
    Color primary,
  ) {
    return Row(
      children: [
        Icon(icon, color: primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            color: isDark ? Colors.white : color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationActions(
    bool isDark,
    Color primaryColor,
    Color burgundyColor,
  ) {
    final hasPoint = _latitude != null && _longitude != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryColor.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.map_outlined, color: primaryColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasPoint
                      ? '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}'
                      : 'Selecione o ponto exato da loja',
                  style: GoogleFonts.plusJakartaSans(
                    color: isDark ? Colors.white : burgundyColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _localizando ? null : _usarLocalizacaoAtual,
                  icon: _localizando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: const Text('Usar GPS'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _mostrandoMapa = true),
                  icon: const Icon(Icons.edit_location_alt),
                  label: const Text('Abrir mapa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool isDark,
    IconData? icon,
    TextInputType? keyboardType,
    List<dynamic>? inputFormatters,
    String? hintText,
    String? Function(String?)? validator,
    int? maxLength,
    String? errorText,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    final formatters = inputFormatters?.cast<TextInputFormatter>();
    final primaryColor = const Color(0xFFff7033);
    final burgundyColor = const Color(0xFF7d2d35);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFD4D4D8) : burgundyColor,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF27272A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: formatters,
            validator: validator,
            onFieldSubmitted: onFieldSubmitted,
            maxLength: maxLength,
            style: GoogleFonts.plusJakartaSans(
              color: isDark ? Colors.white : burgundyColor,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              errorText: errorText,
              hintStyle: GoogleFonts.plusJakartaSans(
                color: isDark ? Colors.grey[600] : Colors.grey[400],
                fontSize: 14,
              ),
              prefixIcon: icon != null
                  ? Icon(
                      icon,
                      color: isDark
                          ? Colors.grey[600]
                          : burgundyColor.withValues(alpha: 0.4),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.red[400]!),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.red[400]!, width: 2),
              ),
              contentPadding: const EdgeInsets.all(20),
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectTime(
    String dayKey,
    String type,
    String currentValue,
  ) async {
    final parts = currentValue.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).brightness == Brightness.dark
              ? ThemeData.dark().copyWith(
                  colorScheme: ColorScheme.dark(
                    primary: const Color(0xFFff7033),
                    onPrimary: Colors.white,
                    surface: const Color(0xFF23150f),
                    onSurface: Colors.white,
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: ColorScheme.light(
                    primary: const Color(0xFFff7033),
                    onPrimary: Colors.white,
                    surface: const Color(0xFFf9f5f0),
                    onSurface: const Color(0xFF7d2d35),
                  ),
                ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

      setState(() {
        _horarios[dayKey]![type] = formattedTime;
      });
    }
  }

  Widget _buildDaySchedule(
    String title,
    String dayKey, // Adicionado para identificar qual dia alterar
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark,
    Color burgundyColor, {
    bool isGroup = false,
  }) {
    // Para exibição, usamos o primeiro dia do grupo ou o próprio dia
    final displayDay = isGroup ? 'ter' : dayKey;
    final startTime = _horarios[displayDay]!['inicio'];
    final endTime = _horarios[displayDay]!['fim'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: burgundyColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: isDark ? Colors.white : burgundyColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                thumbColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? const Color(0xFFff7033)
                      : null,
                ),
                trackColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? const Color(0xFFff7033).withValues(alpha: 0.5)
                      : null,
                ),
              ),
            ],
          ),
          if (value) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTimeInput(
                    'Início',
                    startTime,
                    isDark,
                    burgundyColor,
                    () => _selectTime(dayKey, 'inicio', startTime),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeInput(
                    'Fim',
                    endTime,
                    isDark,
                    burgundyColor,
                    () => _selectTime(dayKey, 'fim', endTime),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeInput(
    String label,
    String value,
    bool isDark,
    Color burgundyColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: burgundyColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : const Color(0xFFF9F5F0).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? Colors.white24
                    : burgundyColor.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    color: isDark ? Colors.white : burgundyColor,
                    fontSize: 14,
                  ),
                ),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: isDark
                      ? Colors.white54
                      : burgundyColor.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
