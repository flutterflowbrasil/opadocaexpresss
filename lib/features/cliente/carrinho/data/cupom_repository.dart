// lib/features/cliente/carrinho/data/cupom_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:padoca_express/core/supabase/supabase_config.dart';
import 'package:padoca_express/features/cliente/carrinho/models/cupom_model.dart';

sealed class CupomResultado {
  const CupomResultado();
}

class CupomValido extends CupomResultado {
  final CupomModel cupom;
  const CupomValido(this.cupom);
}

class CupomInvalido extends CupomResultado {
  final String mensagem;
  const CupomInvalido(this.mensagem);
}

class CupomRepository {
  final SupabaseClient _supabase;
  CupomRepository(this._supabase);

  /// Verifica o cupom pelo código e retorna [CupomValido] ou [CupomInvalido]
  /// com todas as regras de negócio já validadas no cliente.
  Future<CupomResultado> validarCupom({
    required String codigo,
    required double subtotalProdutos,
    required String? estabelecimentoId,
  }) async {
    try {
      final codigoNorm = codigo.trim().toUpperCase();

      final rows = await _supabase
          .from('cupons')
          .select(
              'id, estabelecimento_id, codigo, descricao, tipo, valor, valor_minimo_pedido, '
              'limite_usos, usos_atuais, limite_usos_por_cliente, '
              'data_inicio, data_fim, ativo')
          .eq('codigo', codigoNorm)
          .eq('ativo', true)
          .limit(1);

      if (rows.isEmpty) {
        return const CupomInvalido('Cupom não encontrado ou inativo.');
      }

      final cupom = CupomModel.fromJson(rows.first);

      // 1. Cupom é exclusivo do estabelecimento?
      if (cupom.estabelecimentoId != null &&
          cupom.estabelecimentoId != estabelecimentoId) {
        return const CupomInvalido(
            'Este cupom não é válido para este estabelecimento.');
      }

      // 2. Validade temporal
      final agora = DateTime.now();
      if (cupom.dataInicio != null && agora.isBefore(cupom.dataInicio!)) {
        return const CupomInvalido('Este cupom ainda não está vigente.');
      }
      if (cupom.dataFim != null && agora.isAfter(cupom.dataFim!)) {
        return const CupomInvalido('Este cupom já expirou.');
      }

      // 3. Limite total de usos
      if (cupom.limiteUsos != null && cupom.usosAtuais >= cupom.limiteUsos!) {
        return const CupomInvalido('Este cupom já atingiu o limite de usos.');
      }

      // 4. Valor mínimo de pedido
      if (subtotalProdutos < cupom.valorMinimoPedido) {
        final minFmt =
            'R\$ ${cupom.valorMinimoPedido.toStringAsFixed(2).replaceAll('.', ',')}';
        return CupomInvalido(
            'Pedido mínimo de $minFmt para usar este cupom.');
      }

      return CupomValido(cupom);
    } catch (e) {
      return CupomInvalido('Erro ao validar cupom: ${e.toString()}');
    }
  }
}

final cupomRepositoryProvider = Provider<CupomRepository>((ref) {
  return CupomRepository(ref.watch(supabaseClientProvider));
});
