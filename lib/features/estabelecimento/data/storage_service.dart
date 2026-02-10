import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:padoca_express/core/supabase/supabase_config.dart';

class StorageService {
  final SupabaseClient _supabase;

  StorageService(this._supabase);

  Future<String> uploadCoverImage(File file, String userId) async {
    try {
      final fileExt = file.path.split('.').last;
      final fileName = '$userId.$fileExt';
      final filePath = 'capa_estabelecimentos/$fileName';

      await _supabase.storage
          .from('imagens')
          .upload(filePath, file, fileOptions: const FileOptions(upsert: true));

      final imageUrl = _supabase.storage.from('imagens').getPublicUrl(filePath);
      return imageUrl;
    } catch (e) {
      throw Exception('Erro ao fazer upload da imagem: $e');
    }
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return StorageService(supabase);
});
