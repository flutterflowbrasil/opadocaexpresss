import 'package:flutter_test/flutter_test.dart';
import 'package:padoca_express/core/utils/brazilian_document_validator.dart';

void main() {
  group('BrazilianDocumentValidator', () {
    test('validates CPF with and without mask', () {
      expect(BrazilianDocumentValidator.isValidCpf('529.982.247-25'), isTrue);
      expect(BrazilianDocumentValidator.isValidCpf('52998224725'), isTrue);
    });

    test('rejects invalid CPFs', () {
      expect(BrazilianDocumentValidator.isValidCpf('123'), isFalse);
      expect(BrazilianDocumentValidator.isValidCpf('111.111.111-11'), isFalse);
      expect(BrazilianDocumentValidator.isValidCpf('529.982.247-26'), isFalse);
    });

    test('validates and rejects CNPJ', () {
      expect(
        BrazilianDocumentValidator.isValidCnpj('11.222.333/0001-81'),
        isTrue,
      );
      expect(BrazilianDocumentValidator.isValidCnpj('11.111.111/1111-11'), isFalse);
      expect(BrazilianDocumentValidator.isValidCnpj('11.222.333/0001-82'), isFalse);
    });

    test('validates CPF or CNPJ automatically', () {
      expect(
        BrazilianDocumentValidator.isValidCpfOrCnpj('529.982.247-25'),
        isTrue,
      );
      expect(
        BrazilianDocumentValidator.isValidCpfOrCnpj('11.222.333/0001-81'),
        isTrue,
      );
      expect(BrazilianDocumentValidator.isValidCpfOrCnpj('123456'), isFalse);
    });

    test('parses Brazilian dates and rejects impossible dates', () {
      expect(
        BrazilianDocumentValidator.parseBrazilianDate('25/04/2000'),
        DateTime(2000, 4, 25),
      );
      expect(BrazilianDocumentValidator.parseBrazilianDate('31/02/2000'), isNull);
      expect(BrazilianDocumentValidator.parseBrazilianDate('2000-04-25'), isNull);
    });

    test('calculates adult age around birthday', () {
      final birthday = DateTime(2008, 4, 25);

      expect(
        BrazilianDocumentValidator.isAdult(
          birthday,
          referenceDate: DateTime(2026, 4, 24),
        ),
        isFalse,
      );
      expect(
        BrazilianDocumentValidator.isAdult(
          birthday,
          referenceDate: DateTime(2026, 4, 25),
        ),
        isTrue,
      );
      expect(
        BrazilianDocumentValidator.isAdult(
          birthday,
          referenceDate: DateTime(2026, 4, 26),
        ),
        isTrue,
      );
    });

    test('returns standardized form validation messages', () {
      expect(
        BrazilianDocumentValidator.cpfFormValidator('111.111.111-11'),
        BrazilianDocumentValidator.invalidCpfMessage,
      );
      expect(
        BrazilianDocumentValidator.cnpjFormValidator('11.111.111/1111-11'),
        BrazilianDocumentValidator.invalidCnpjMessage,
      );
      expect(
        BrazilianDocumentValidator.cpfOrCnpjFormValidator('123456'),
        BrazilianDocumentValidator.invalidCpfOrCnpjMessage,
      );
      expect(
        BrazilianDocumentValidator.adultBrazilianDateFormValidator('25/04/2010'),
        BrazilianDocumentValidator.underageMessage,
      );
    });
  });
}
