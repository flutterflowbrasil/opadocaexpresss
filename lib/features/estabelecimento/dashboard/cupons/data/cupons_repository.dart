import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cupom_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:padoca_express/core/supabase/supabase_config.dart';

final cuponsRepositoryProvider = Provider<CuponsRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return CuponsRepository(supabase);
});

class CuponsRepository {
  final SupabaseClient _supabase;

  CuponsRepository(this._supabase);

  Future<List<CupomModel>> fetchCupons(String estabelecimentoId) async {
    final response = await _supabase
        .from('cupons')
        .select()
        .eq('estabelecimento_id', estabelecimentoId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => CupomModel.fromJson(json)).toList();
  }

  Future<CupomModel> criarCupom(CupomModel cupom) async {
    final response =
        await _supabase.from('cupons').insert(cupom.toJson()).select().single();

    return CupomModel.fromJson(response);
  }

  Future<CupomModel> atualizarCupom(CupomModel cupom) async {
    final response = await _supabase
        .from('cupons')
        .update(cupom.toJson(isUpdate: true))
        .eq('id', cupom.id)
        .select()
        .single();

    return CupomModel.fromJson(response);
  }

  Future<void> excluirCupom(String cupomId) async {
    await _supabase.from('cupons').delete().eq('id', cupomId);
  }

  Future<void> toggleAtivo(String cupomId, bool ativoAtual) async {
    await _supabase
        .from('cupons')
        .update({'ativo': !ativoAtual}).eq('id', cupomId);
  }
}
