import 'package:flutter/foundation.dart';

/// Resposta da Edge Function `criar-cobranca-asaas`.
class CobrancaAsaasModel {
  final String paymentId;
  final String? pixQrCode;     // base64 da imagem do QR Code
  final String? pixCopiaECola; // texto para copia-e-cola PIX
  final String? invoiceUrl;    // link de fatura para cartão

  const CobrancaAsaasModel({
    required this.paymentId,
    this.pixQrCode,
    this.pixCopiaECola,
    this.invoiceUrl,
  });

  factory CobrancaAsaasModel.fromJson(Map<String, dynamic> json) {
    try {
      // Se a Edge function retorna 'id' invés de 'paymentId'
      final extractedId = json['paymentId'] ?? json['id'] ?? '';
      
      if (extractedId.toString().isEmpty) {
        debugPrint('[CobrancaAsaasModel] ATENÇÃO: Nenhum ID de pagamento encontrado. JSON: $json');
        if (json.containsKey('error')) {
          throw Exception(json['error']);
        }
      }

      return CobrancaAsaasModel(
        paymentId: extractedId.toString(),
        pixQrCode: json['pixQrCode'] as String?,
        pixCopiaECola: json['pixCopiaECola'] as String?,
        invoiceUrl: json['invoiceUrl'] ?? json['invoiceUrl'] as String?,
      );
    } catch (e, st) {
      debugPrint('[CobrancaAsaasModel.fromJson] ERRO: $e\nJSON: $json\n$st');
      rethrow;
    }
  }
}
