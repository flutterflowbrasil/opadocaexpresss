import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/categoria_model.dart';

class CategoriasRepository {
  final SupabaseClient _supabase;

  CategoriasRepository(this._supabase);

  Future<List<CategoriaModel>> getCategorias() async {
    final res = await _supabase
        .from('categorias_estabelecimento')
        .select()
        .order('ordem_exibicao', ascending: true)
        .order('nome', ascending: true);

    return res.map((e) => CategoriaModel.fromJson(e)).toList();
  }

  Future<CategoriaModel> createCategoria(Map<String, dynamic> data) async {
    final res = await _supabase
        .from('categorias_estabelecimento')
        .insert(data)
        .select()
        .single();
    
    return CategoriaModel.fromJson(res);
  }

  Future<CategoriaModel> updateCategoria(String id, Map<String, dynamic> data) async {
    final res = await _supabase
        .from('categorias_estabelecimento')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    
    return CategoriaModel.fromJson(res);
  }

  Future<void> deleteCategoria(String id) async {
    await _supabase.from('categorias_estabelecimento').delete().eq('id', id);
  }

  Future<String> uploadImagem(String categoriaId, File file) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'categorias/$categoriaId/categoria_$timestamp.jpg';

    await _supabase.storage.from('imagens').upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );

    return _supabase.storage.from('imagens').getPublicUrl(path);
  }
}
