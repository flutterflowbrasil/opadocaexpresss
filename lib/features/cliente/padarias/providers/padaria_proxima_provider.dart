import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:padoca_express/core/services/localizacao_service.dart';
import 'package:padoca_express/features/cliente/padarias/models/padaria_model.dart';
import 'package:padoca_express/features/cliente/padarias/repositories/padaria_proxima_repository.dart';

/// Resultado do provider: lista de padarias + metadados sobre a localização.
class PadariaProximaResult {
  final List<PadariaModel> padarias;

  /// true = ordenado por distância; false = ordenado por avaliação (fallback)
  final bool temLocalizacao;

  const PadariaProximaResult({
    required this.padarias,
    required this.temLocalizacao,
  });
}

/// Provider principal: busca padarias baseando-se na localização disponível.
///
/// Fluxo:
///   1. Verifica permissão ATUAL (sem pedir ao usuário).
///   2. Se concedida → busca por proximidade.
///   3. Senão → busca as mais bem avaliadas.
final padariaProximaProvider =
    FutureProvider.autoDispose<PadariaProximaResult>((ref) async {
  final repo = ref.watch(padariaProximaRepositoryProvider);

  final temPermissao = await temPermissaoLocalizacao();

  if (temPermissao) {
    final position = await obterLocalizacao();
    if (position != null) {
      final padarias = await repo.buscarProximas(
        lat: position.latitude,
        lng: position.longitude,
      );
      return PadariaProximaResult(padarias: padarias, temLocalizacao: true);
    }
  }

  // Fallback — sem localização
  final padarias = await repo.buscarMelhoresAvaliadas();
  return PadariaProximaResult(padarias: padarias, temLocalizacao: false);
});

/// Provider separado: solicita permissão ao usuário e atualiza o principal.
///
/// Chamado quando o usuário clica no banner "Permitir localização".
final solicitarLocalizacaoProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  final position = await obterLocalizacao(); // este sim pede permissão
  if (position != null) {
    ref.invalidate(padariaProximaProvider); // recarrega a lista
    return true;
  }
  return false;
});
