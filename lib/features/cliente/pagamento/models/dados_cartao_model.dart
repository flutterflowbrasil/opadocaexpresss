/// Value object com dados do cartão coletados no modal.
/// Nunca é persistido em disco — usado apenas durante o fluxo de pagamento.
class DadosCartaoModel {
  final String numero;        // apenas dígitos, 16 chars
  final String nomeTitular;
  final String vencimentoMes; // "MM"
  final String vencimentoAno; // "AA"
  final String cvv;
  final String apelido;       // rótulo opcional, ex: "Nubank pessoal"
  final String cpfCnpj;       // apenas dígitos, validado mod-11
  final bool isCredito;       // true = crédito, false = débito

  const DadosCartaoModel({
    required this.numero,
    required this.nomeTitular,
    required this.vencimentoMes,
    required this.vencimentoAno,
    required this.cvv,
    required this.apelido,
    required this.cpfCnpj,
    required this.isCredito,
  });

  /// Serialização para enviar à Edge Function (nunca ao client storage).
  Map<String, dynamic> toJson() => {
        'numero': numero,
        'nomeTitular': nomeTitular,
        'vencimento': '$vencimentoMes/$vencimentoAno',
        'cvv': cvv,
        'apelido': apelido,
        'cpfCnpj': cpfCnpj,
        'tipo': isCredito ? 'CREDIT' : 'DEBIT',
      };
}
