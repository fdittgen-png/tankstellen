import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/payment/domain/qr_payment_decoder.dart';

void main() {
  group('QrPaymentDecoder (#587)', () {
    test('https URL → QrPaymentUrl', () {
      final r = QrPaymentDecoder.decode('https://example.com/pay?id=42');
      expect(r, isA<QrPaymentUrl>());
      expect((r as QrPaymentUrl).url, 'https://example.com/pay?id=42');
    });

    test('http URL is still classified as URL (fuel-station bills)', () {
      expect(
        QrPaymentDecoder.decode('http://pump-legacy.example.com/receipt/7'),
        isA<QrPaymentUrl>(),
      );
    });

    test('payconiq://… → QrPaymentAppLink with a human label', () {
      final r = QrPaymentDecoder.decode(
        'payconiq://payment/abc123',
      );
      expect(r, isA<QrPaymentAppLink>());
      expect((r as QrPaymentAppLink).schemeLabel, 'Payconiq');
    });

    test('twint scheme routes to TWINT', () {
      final r = QrPaymentDecoder.decode('twint://pay?amount=10');
      expect(r, isA<QrPaymentAppLink>());
      expect((r as QrPaymentAppLink).schemeLabel, 'TWINT');
    });

    test('regional EU schemes — Wero/MobilePay/Vipps/Swish/MBWay/Blik (#723)', () {
      const cases = {
        'wero://pay/abc': 'Wero',
        'mobilepay://send?x=1': 'MobilePay',
        'vipps://pay?id=7': 'Vipps',
        'swish://payment?data=eyJ...': 'Swish',
        'mbway://transfer?x=1': 'MB Way',
        'blik://pay?code=123456': 'Blik',
      };
      for (final entry in cases.entries) {
        final r = QrPaymentDecoder.decode(entry.key);
        expect(r, isA<QrPaymentAppLink>(),
            reason: 'expected app link for ${entry.key}');
        expect((r as QrPaymentAppLink).schemeLabel, entry.value);
      }
    });

    test('scheme match is case-insensitive', () {
      final r = QrPaymentDecoder.decode('PAYCONIQ://ok');
      expect(r, isA<QrPaymentAppLink>());
    });

    test('EPC SEPA Girocode → QrPaymentEpc with parsed fields', () {
      // Canonical EPC QR example from the spec.
      const epc = 'BCD\n'
          '002\n'
          '1\n'
          'SCT\n'
          'BFSWDE33MUE\n'
          'ACME GmbH\n'
          'DE89370400440532013000\n'
          'EUR42.50\n'
          'GDDS\n'
          'Invoice 2026-04';
      final r = QrPaymentDecoder.decode(epc);
      expect(r, isA<QrPaymentEpc>());
      final e = r as QrPaymentEpc;
      expect(e.beneficiary, 'ACME GmbH');
      expect(e.iban, 'DE89370400440532013000');
      expect(e.amountEur, closeTo(42.50, 1e-6));
    });

    test('EPC without amount still parses beneficiary + IBAN', () {
      const epc = 'BCD\n'
          '002\n'
          '1\n'
          'SCT\n'
          '\n'
          'ACME GmbH\n'
          'DE89370400440532013000';
      final r = QrPaymentDecoder.decode(epc);
      expect(r, isA<QrPaymentEpc>());
      final e = r as QrPaymentEpc;
      expect(e.amountEur, isNull);
      expect(e.iban, 'DE89370400440532013000');
    });

    test('plain text / unknown scheme → QrPaymentUnknown', () {
      expect(QrPaymentDecoder.decode('hello world'),
          isA<QrPaymentUnknown>());
      expect(QrPaymentDecoder.decode('barclay://pay'),
          isA<QrPaymentUnknown>());
    });

    test('empty / whitespace input → QrPaymentUnknown', () {
      expect(QrPaymentDecoder.decode(''), isA<QrPaymentUnknown>());
      expect(QrPaymentDecoder.decode('   '), isA<QrPaymentUnknown>());
    });
  });
}
