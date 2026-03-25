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
    return CobrancaAsaasModel(
      paymentId: json['paymentId'] as String,
      pixQrCode: json['pixQrCode'] as String?,
      pixCopiaECola: json['pixCopiaECola'] as String?,
      invoiceUrl: json['invoiceUrl'] as String?,
    );
  }
}
