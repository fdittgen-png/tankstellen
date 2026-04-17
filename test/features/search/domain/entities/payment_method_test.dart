import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/payment_method.dart';

void main() {
  group('paymentMethodIcon', () {
    test('returns distinct icon for each payment method', () {
      final icons = PaymentMethod.values.map(paymentMethodIcon).toSet();
      expect(icons.length, PaymentMethod.values.length,
          reason: 'Each payment method should have a unique icon');
    });

    test('returns expected icons', () {
      expect(paymentMethodIcon(PaymentMethod.cash), Icons.payments);
      expect(paymentMethodIcon(PaymentMethod.card), Icons.credit_card);
      expect(paymentMethodIcon(PaymentMethod.contactless), Icons.contactless);
      expect(paymentMethodIcon(PaymentMethod.fuelCard), Icons.local_gas_station);
      expect(paymentMethodIcon(PaymentMethod.app), Icons.smartphone);
    });
  });

  group('inferPaymentMethods', () {
    test('empty brand returns a safe cash + card default', () {
      expect(inferPaymentMethods(''),
          {PaymentMethod.cash, PaymentMethod.card});
    });

    test('whitespace brand is treated as empty', () {
      expect(inferPaymentMethods('   '),
          {PaymentMethod.cash, PaymentMethod.card});
    });

    test('independent/unknown brand returns cash + card + contactless', () {
      final result = inferPaymentMethods('Independent Local Station');
      expect(result, {
        PaymentMethod.cash,
        PaymentMethod.card,
        PaymentMethod.contactless,
      });
    });

    test('Shell adds fuel card and app', () {
      final result = inferPaymentMethods('Shell');
      expect(result, contains(PaymentMethod.fuelCard));
      expect(result, contains(PaymentMethod.app));
      expect(result, contains(PaymentMethod.card));
    });

    test('BP adds fuel card and app', () {
      final result = inferPaymentMethods('BP');
      expect(result, contains(PaymentMethod.fuelCard));
      expect(result, contains(PaymentMethod.app));
    });

    test('Aral adds fuel card and app', () {
      expect(inferPaymentMethods('Aral'), contains(PaymentMethod.fuelCard));
      expect(inferPaymentMethods('Aral'), contains(PaymentMethod.app));
    });

    test('TotalEnergies adds fuel card and app', () {
      final result = inferPaymentMethods('TotalEnergies');
      expect(result, contains(PaymentMethod.fuelCard));
      expect(result, contains(PaymentMethod.app));
    });

    test('Cepsa adds fuel card but not app', () {
      final result = inferPaymentMethods('Cepsa');
      expect(result, contains(PaymentMethod.fuelCard));
      expect(result, isNot(contains(PaymentMethod.app)));
    });

    test('brand matching is case-insensitive', () {
      expect(inferPaymentMethods('SHELL'), contains(PaymentMethod.fuelCard));
      expect(inferPaymentMethods('shell'), contains(PaymentMethod.fuelCard));
      expect(inferPaymentMethods('Shell Express'), contains(PaymentMethod.fuelCard));
    });
  });

  group('brandAppName', () {
    test('returns null for unknown brand', () {
      expect(brandAppName('Unknown Brand'), isNull);
      expect(brandAppName(''), isNull);
    });

    test('returns Shell App for Shell', () {
      expect(brandAppName('Shell'), 'Shell App');
      expect(brandAppName('SHELL'), 'Shell App');
    });

    test('returns BPme for BP', () {
      expect(brandAppName('BP'), 'BPme');
    });

    test('returns Aral Pay for Aral', () {
      expect(brandAppName('Aral'), 'Aral Pay');
    });

    test('returns TotalEnergies for Total and TotalEnergies', () {
      expect(brandAppName('Total'), 'TotalEnergies');
      expect(brandAppName('TotalEnergies'), 'TotalEnergies');
    });

    test('returns Waylet for Repsol', () {
      expect(brandAppName('Repsol'), 'Waylet');
    });

    test('prefers more specific brand when substrings overlap', () {
      // TotalEnergies should not collide with Total (both map to TotalEnergies)
      expect(brandAppName('TotalEnergies Station'), 'TotalEnergies');
    });
  });
}
