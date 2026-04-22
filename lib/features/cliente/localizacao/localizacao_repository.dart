import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'endereco_model.dart';

/// Repository de localização — único ponto de acesso ao Supabase.
/// Nunca acesse o SupabaseClient fora desta classe.
///
/// RLS garante isolamento por usuário:
/// - enderecos_clientes: ALL permitido para o próprio cliente
/// - A FK cliente_id é resolvida via `clientes.usuario_id = auth.uid()`
class LocalizacaoRepository {
  final SupabaseClient _supabase;

  LocalizacaoRepository(this._supabase);

  // ── Buscar ID do cliente atual (necessário para INSERT) ───────────────────
  Future<String?> _getClienteId() async {
    try {
      final data = await _supabase
          .from('clientes')
          .select('id')
          .maybeSingle();
      return data?['id'] as String?;
    } catch (e) {
      debugPrint('[LocalizacaoRepository] Erro ao obter clienteId: $e');
      return null;
    }
  }

  // ── Listar endereços do cliente autenticado ───────────────────────────────
  /// O RLS filtra automaticamente por `clientes.usuario_id = auth.uid()`.
  Future<List<EnderecoCliente>> buscarEnderecos() async {
    final clienteId = await _getClienteId();
    if (clienteId == null) return [];

    final data = await _supabase
        .from('enderecos_clientes')
        .select()
        .eq('cliente_id', clienteId)
        .order('is_padrao', ascending: false)
        .order('created_at', ascending: false);

    return [for (final e in data) EnderecoCliente.fromJson(e)];
  }

  // ── Salvar um novo endereço ───────────────────────────────────────────────
  Future<EnderecoCliente?> salvarEndereco(EnderecoCliente endereco) async {
    final clienteId = await _getClienteId();
    if (clienteId == null) return null;

    final payload = endereco.toJson()..['cliente_id'] = clienteId;

    final result = await _supabase
        .from('enderecos_clientes')
        .insert(payload)
        .select()
        .single();

    final saved = EnderecoCliente.fromJson(result);

    // ── Atualizar campo PostGIS geo via RPC ──────────────────────────────
    // O campo `geo` (Geography Point) não pode ser inserido diretamente pelo
    // cliente Dart (tipo PostGIS). Usamos a função SQL criada na migration.
    try {
      await _supabase.rpc('update_endereco_geo', params: {
        'p_endereco_id': saved.id,
        'p_lat': endereco.latitude,
        'p_lng': endereco.longitude,
      });
    } catch (e) {
      // Falha não-crítica: o endereço foi salvo, só o campo geo não foi populado.
      debugPrint('[LocalizacaoRepository] update_endereco_geo erro: $e');
    }

    return saved;
  }

  // ── Definir um endereço como padrão ──────────────────────────────────────
  Future<void> definirPadrao(String enderecoId) async {
    final clienteId = await _getClienteId();
    if (clienteId == null) return;

    // Primeiro remove is_padrao de todos
    await _supabase
        .from('enderecos_clientes')
        .update({'is_padrao': false})
        .eq('cliente_id', clienteId);

    // Depois marca apenas o escolhido
    await _supabase
        .from('enderecos_clientes')
        .update({'is_padrao': true})
        .eq('id', enderecoId);
  }

  // ── Atualizar endereço existente ─────────────────────────────────────────
  Future<EnderecoCliente?> atualizarEndereco(EnderecoCliente endereco) async {
    if (endereco.id == null) return null;

    final payload = endereco.toJson();

    final result = await _supabase
        .from('enderecos_clientes')
        .update(payload)
        .eq('id', endereco.id!)
        .select()
        .single();

    final updated = EnderecoCliente.fromJson(result);

    // Atualizar campo PostGIS geo via RPC
    try {
      await _supabase.rpc('update_endereco_geo', params: {
        'p_endereco_id': updated.id,
        'p_lat': endereco.latitude,
        'p_lng': endereco.longitude,
      });
    } catch (e) {
      debugPrint('[LocalizacaoRepository] update_endereco_geo erro: $e');
    }

    return updated;
  }

  // ── Excluir endereço ─────────────────────────────────────────────────────
  Future<void> excluirEndereco(String enderecoId) async {
    await _supabase
        .from('enderecos_clientes')
        .delete()
        .eq('id', enderecoId);
  }

  // ── Geocodificação via Nominatim (OpenStreetMap) com Fallback ────────────
  // Utilizamos um User-Agent de browser mobile para evitar bloqueios de API 
  // comuns em requisições Dart a partir de IPs de operadoras de celular.
  static const _nominatimHeaders = {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 13; SM-S901B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36',
    'Accept': 'application/json',
    'Accept-Language': 'pt-BR,pt;q=0.9',
  };

  /// Reverse geocode: lat/lng → endereço completo via Nominatim com fallback para Photon.
  Future<Map<String, dynamic>?> reverseGeocode(double lat, double lng) async {
    try {
      // 1. Tenta via Nominatim primário
      try {
        final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
          'lat': '$lat',
          'lon': '$lng',
          'format': 'json',
          'accept-language': 'pt-BR',
          'addressdetails': '1',
        });

        final res = await http
            .get(uri, headers: _nominatimHeaders)
            .timeout(const Duration(seconds: 8));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final address = data['address'] as Map<String, dynamic>?;
          if (address != null) {
            final cep = (address['postcode'] as String? ?? '')
                .replaceAll(RegExp(r'\D'), '');
            final logradouro = address['road'] ??
                address['pedestrian'] ??
                address['cycleway'] ??
                address['path'] ??
                '';
            final bairro = address['suburb'] ??
                address['neighbourhood'] ??
                address['quarter'] ??
                address['district'] ??
                '';
            final cidade = address['city'] ??
                address['town'] ??
                address['village'] ??
                address['municipality'] ??
                '';
            // Recupera o estado (UF). 
            // O Nominatim do Brasil retorna 'ISO3166-2-lvl4' ex: 'BR-SP'
            String estado = '';
            final isoCode = address['ISO3166-2-lvl4'] as String?;
            if (isoCode != null && isoCode.startsWith('BR-')) {
              estado = isoCode.substring(3);
            } else {
              estado = address['state_code'] as String? ?? address['state'] as String? ?? '';
            }

            return {
              'cep': cep,
              'logradouro': logradouro,
              'bairro': bairro,
              'cidade': cidade,
              'estado': estado,
              'formatted': data['display_name'] ?? '',
            };
          }
        }
      } catch (e) {
        debugPrint('[LocalizacaoRepository] Nominatim reverse fail: $e');
      }

      // 2. Tenta via Photon (Komoot) se Nominatim falhar (rate limit ou bloqueio)
      final uriPhoton = Uri.https('photon.komoot.io', '/reverse', {
        'lon': '$lng',
        'lat': '$lat',
      });
      final resPhoton = await http
          .get(uriPhoton, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));

      if (resPhoton.statusCode == 200) {
        final data = jsonDecode(resPhoton.body);
        final features = data['features'] as List?;
        if (features != null && features.isNotEmpty) {
          final prop = features[0]['properties'] as Map<String, dynamic>;
          
          // Trata estado no Photon
          String estadoPhoton = prop['state'] ?? '';
          
          return {
            'cep': (prop['postcode'] as String? ?? '').replaceAll(RegExp(r'\D'), ''),
            'logradouro': prop['street'] ?? prop['name'] ?? '',
            'bairro': prop['district'] ?? prop['locality'] ?? '',
            'cidade': prop['city'] ?? prop['town'] ?? '',
            'estado': estadoPhoton,
            'formatted': prop['name'] ?? '',
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('[LocalizacaoRepository] reverseGeocode fallback erro: $e');
      return null;
    }
  }

  /// Forward geocode: CEP → lat/lng via Nominatim.
  Future<Map<String, double>?> geocodeCep(String cep) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'postalcode': cep,
        'countrycodes': 'br',
        'format': 'json',
        'limit': '1',
        'accept-language': 'pt-BR',
      });

      final res = await http
          .get(uri, headers: _nominatimHeaders)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return null;
      final results = jsonDecode(res.body) as List?;
      if (results == null || results.isEmpty) return null;

      return {
        'lat': double.parse(results[0]['lat'] as String),
        'lng': double.parse(results[0]['lon'] as String),
      };
    } catch (e) {
      debugPrint('[LocalizacaoRepository] geocodeCep erro: $e');
      return null;
    }
  }
}
