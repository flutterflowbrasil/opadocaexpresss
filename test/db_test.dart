import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  test('DEBUG GET UUID', () async {
    try {
      await dotenv.load(fileName: '.env');
      final url = dotenv.get('SUPABASE_URL');
      final key = dotenv.maybeGet('SUPABASE_PUBLISHABLE_KEY') ??
          dotenv.get('SUPABASE_ANON_KEY');

      final supabase = SupabaseClient(url, key);

      final data =
          await supabase.from('estabelecimentos').select('id').limit(1);
      final clientData =
          await supabase.from('clientes').select('id, usuario_id').limit(1);
      final addressData =
          await supabase.from('enderecos_clientes').select('id').limit(1);

      print('====== INICIO DUMP ======');
      print('EstID:${data.isNotEmpty ? data.first["id"] : "null"}');
      print(
          'CliID:${clientData.isNotEmpty ? clientData.first["id"] : "null"}');
      print(
          'EndID:${addressData.isNotEmpty ? addressData.first["id"] : "null"}');

      throw Exception(
          'FORCING ERROR TO PRINT: Estabelecimento: ${data.isNotEmpty ? data.first["id"] : "null"}, Cliente: ${clientData.isNotEmpty ? clientData.first["id"] : "null"}');
    } catch (e) {
      print('DEBUG ERROR: $e');
      rethrow;
    }
  });
}
