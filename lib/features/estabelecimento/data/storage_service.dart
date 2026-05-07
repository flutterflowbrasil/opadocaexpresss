import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:padoca_express/core/supabase/supabase_config.dart';

class StorageService {
  final SupabaseClient _supabase;

  StorageService(this._supabase);

  Future<String> uploadStoreLogo({
    required Uint8List bytes,
    required String estabelecimentoId,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath =
        'logo_estabelecimentos/$estabelecimentoId/logo_$timestamp.jpg';

    await _supabase.storage.from('imagens').uploadBinary(
          filePath,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );

    return _supabase.storage.from('imagens').getPublicUrl(filePath);
  }

  Future<String> uploadStoreBanner({
    required Uint8List bytes,
    required String estabelecimentoId,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath =
        'capa_estabelecimentos/$estabelecimentoId/capa_$timestamp.jpg';

    await _supabase.storage.from('imagens').uploadBinary(
          filePath,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );

    return _supabase.storage.from('imagens').getPublicUrl(filePath);
  }

  Future<String> uploadCoverImage(Object fileOrPath, String userId) async {
    try {
      final file = fileOrPath is File ? fileOrPath : File(fileOrPath as String);
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
