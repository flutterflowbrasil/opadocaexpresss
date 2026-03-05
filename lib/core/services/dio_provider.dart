import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// B2: Provider do Dio configurado para a API Asaas com timeouts adequados.
///
/// - connectTimeout: 10s — tempo máximo para estabelecer conexão
/// - receiveTimeout: 30s — tempo máximo para receber resposta completa
///
/// Uso:
/// ```dart
/// final dio = ref.read(dioProvider);
/// final response = await dio.get('/customers');
/// ```
final dioProvider = Provider<Dio>((ref) {
  final baseUrl = dotenv.maybeGet('ASAAS_BASE_URL') ?? '';
  final apiKey = dotenv.maybeGet('ASAAS_API_KEY') ?? '';

  return Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'access_token': apiKey,
        'Content-Type': 'application/json',
      },
    ),
  );
});
