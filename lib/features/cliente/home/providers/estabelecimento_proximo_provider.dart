import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:padoca_express/core/services/localizacao_service.dart';
import 'package:padoca_express/features/cliente/home/models/estabelecimento_model.dart';

class EstabelecimentoResult {
  final List<EstabelecimentoModel> estabelecimentos;
  final bool temLocalizacao;

  EstabelecimentoResult({
    required this.estabelecimentos,
    this.temLocalizacao = false,
  });
}

final estabelecimentoProximoProvider =
    FutureProvider<EstabelecimentoResult>((ref) async {
  // B1: keepAlive com política de expiração de 10 minutos
  // Evita dados obsoletos (ex: status aberto/fechado que muda ao longo do dia)
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 10), () {
    link.close(); // Permite que o provider seja recriado na próxima consulta
  });
  ref.onDispose(timer.cancel);

  try {
    final response = await Supabase.instance.client
        .from('estabelecimentos')
        .select(
          'id, razao_social, descricao, logo_url, banner_url, '
          'avaliacao_media, total_avaliacoes, status_aberto, '
          'latitude, longitude, config_entrega, endereco, '
          'categoria_estabelecimento_id',
        )
        // M7: Limite de 50 registros para evitar carregar todo o banco em memória
        .order('avaliacao_media', ascending: false)
        .limit(50)
        // A4: Timeout de 15 segundos para evitar loading infinito em redes lentas
        .timeout(const Duration(seconds: 15));

    final List<EstabelecimentoModel> todos = (response as List)
        .map((json) => EstabelecimentoModel.fromJson(json))
        .toList();

    // 1) Tentar obter a localização atual do aparelho com fallback
    final Position? userPos = await obterLocalizacao();

    if (userPos == null) {
      // Sem localização -> retorna do jeito que veio da API (geralmente melhores avaliados primeiro)
      return EstabelecimentoResult(
        estabelecimentos: todos,
        temLocalizacao: false,
      );
    }

    // 2) Se tem localização, separar e ordenar. Aplicar limite de 5km.
    final userLat = userPos.latitude;
    final userLng = userPos.longitude;

    final dentroDoRaio = todos.where((e) {
      if (e.latitude == null || e.longitude == null) return false;
      final distanceInMeters = Geolocator.distanceBetween(
        userLat,
        userLng,
        e.latitude!,
        e.longitude!,
      );
      return distanceInMeters <= 5000.0;
    }).toList();

    int sortByDistance(EstabelecimentoModel a, EstabelecimentoModel b) {
      if (a.latitude == null || a.longitude == null) return 1;
      if (b.latitude == null || b.longitude == null) return -1;

      // Distância Euclidiana simples rápida para ordenação local
      final dLatA = a.latitude! - userLat;
      final dLngA = a.longitude! - userLng;
      final distA = (dLatA * dLatA) + (dLngA * dLngA);

      final dLatB = b.latitude! - userLat;
      final dLngB = b.longitude! - userLng;
      final distB = (dLatB * dLatB) + (dLngB * dLngB);

      return distA.compareTo(distB);
    }

    final abertos = dentroDoRaio.where((e) => e.statusAberto).toList();
    final fechados = dentroDoRaio.where((e) => !e.statusAberto).toList();

    abertos.sort(sortByDistance);
    fechados.sort(sortByDistance);

    // Junta as abertas mais próximas e depois as fechadas mais próximas
    final List<EstabelecimentoModel> combinados = [...abertos, ...fechados];

    return EstabelecimentoResult(
      estabelecimentos: combinados,
      temLocalizacao: true,
    );
  } catch (e) {
    // A4+A5: Log apenas em debug, sem expor dados internos
    if (kDebugMode) {
      debugPrint('Erro em estabelecimentoProximoProvider: $e');
    }
    return EstabelecimentoResult(estabelecimentos: [], temLocalizacao: false);
  }
});
