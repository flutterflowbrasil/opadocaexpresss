abstract interface class CpfOfficialValidationService {
  Future<CpfOfficialValidationResult> validateCpf(String cpf);
}

class CpfOfficialValidationResult {
  final bool isValid;
  final bool? isAdult;
  final String? message;

  const CpfOfficialValidationResult({
    required this.isValid,
    this.isAdult,
    this.message,
  });
}

class LocalCpfOfficialValidationService implements CpfOfficialValidationService {
  const LocalCpfOfficialValidationService();

  @override
  Future<CpfOfficialValidationResult> validateCpf(String cpf) async {
    return CpfOfficialValidationResult(
      isValid: BrazilianDocumentValidator.isValidCpf(cpf),
      message: BrazilianDocumentValidator.isValidCpf(cpf)
          ? null
          : BrazilianDocumentValidator.invalidCpfMessage,
    );
  }
}

class BrazilianDocumentValidator {
  static const invalidCpfMessage = 'Insira um CPF válido';
  static const invalidCnpjMessage = 'Insira um CNPJ válido';
  static const invalidCpfOrCnpjMessage = 'Insira um CPF ou CNPJ válido';
  static const underageMessage = 'É necessário ter 18 anos ou mais';

  const BrazilianDocumentValidator._();

  static String onlyDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  static bool isValidCpf(String value) {
    final digits = onlyDigits(value);
    if (digits.length != 11 || RegExp(r'^(\d)\1{10}$').hasMatch(digits)) {
      return false;
    }

    for (final check in [9, 10]) {
      var sum = 0;
      for (var i = 0; i < check; i++) {
        sum += int.parse(digits[i]) * (check + 1 - i);
      }
      var digit = (sum * 10) % 11;
      if (digit == 10) digit = 0;
      if (digit != int.parse(digits[check])) return false;
    }
    return true;
  }

  static bool isValidCnpj(String value) {
    final digits = onlyDigits(value);
    if (digits.length != 14 || RegExp(r'^(\d)\1{13}$').hasMatch(digits)) {
      return false;
    }

    const weights1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    const weights2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

    bool validateDigit(List<int> weights, int position) {
      var sum = 0;
      for (var i = 0; i < weights.length; i++) {
        sum += int.parse(digits[i]) * weights[i];
      }
      final remainder = sum % 11;
      final expected = remainder < 2 ? 0 : 11 - remainder;
      return expected == int.parse(digits[position]);
    }

    return validateDigit(weights1, 12) && validateDigit(weights2, 13);
  }

  static bool isValidCpfOrCnpj(String value) {
    final digits = onlyDigits(value);
    if (digits.length == 11) return isValidCpf(digits);
    if (digits.length == 14) return isValidCnpj(digits);
    return false;
  }

  static DateTime? parseBrazilianDate(String value) {
    final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(value.trim());
    if (match == null) return null;

    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final year = int.tryParse(match.group(3)!);
    if (day == null || month == null || year == null) return null;

    final date = DateTime(year, month, day);
    if (date.day != day || date.month != month || date.year != year) {
      return null;
    }
    return date;
  }

  static bool isAdult(
    DateTime birthDate, {
    int minimumAge = 18,
    DateTime? referenceDate,
  }) {
    final reference = referenceDate ?? DateTime.now();
    var age = reference.year - birthDate.year;
    final hasBirthdayPassed = reference.month > birthDate.month ||
        (reference.month == birthDate.month && reference.day >= birthDate.day);
    if (!hasBirthdayPassed) age--;
    return age >= minimumAge;
  }

  static String? cpfFormValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty || !isValidCpf(text)) return invalidCpfMessage;
    return null;
  }

  static String? cnpjFormValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty || !isValidCnpj(text)) return invalidCnpjMessage;
    return null;
  }

  static String? cpfOrCnpjFormValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty || !isValidCpfOrCnpj(text)) {
      return invalidCpfOrCnpjMessage;
    }
    return null;
  }

  static String? optionalCpfFormValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    return isValidCpf(text) ? null : invalidCpfMessage;
  }

  static String? adultBrazilianDateFormValidator(String? value) {
    final text = value?.trim() ?? '';
    final date = parseBrazilianDate(text);
    if (date == null) return 'Data inválida';
    if (date.isAfter(DateTime.now())) return 'Data inválida';
    if (!isAdult(date)) return underageMessage;
    return null;
  }

  static String? optionalAdultBrazilianDateFormValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    return adultBrazilianDateFormValidator(text);
  }
}
