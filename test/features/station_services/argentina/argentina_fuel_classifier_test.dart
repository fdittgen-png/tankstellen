import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/station_services/argentina/argentina_fuel_classifier.dart';

void main() {
  group('classifyArgentinaProduct', () {
    test('classifies real CSV strings from Secretaría de Energía', () {
      expect(classifyArgentinaProduct('Nafta (premium) de más de 95 Ron'),
          ArgentinaFuelCategory.naftaPremium);
      expect(classifyArgentinaProduct('Nafta (súper) entre 92 y 95 Ron'),
          ArgentinaFuelCategory.naftaRegular);
      expect(classifyArgentinaProduct('Gas Oil Grado 2'),
          ArgentinaFuelCategory.dieselRegular);
      expect(classifyArgentinaProduct('Gas Oil Grado 3'),
          ArgentinaFuelCategory.dieselPremium);
      expect(classifyArgentinaProduct('GNC'), ArgentinaFuelCategory.gnc);
    });

    test('super marker wins over 95 ron octane hint (regression)', () {
      // "Nafta (súper) entre 92 y 95 Ron" contains both "súper" AND "95 ron" —
      // the super marker is the authoritative signal.
      expect(classifyArgentinaProduct('Nafta (súper) entre 92 y 95 Ron'),
          ArgentinaFuelCategory.naftaRegular);
      expect(classifyArgentinaProduct('Nafta super 92 y 95'),
          ArgentinaFuelCategory.naftaRegular);
    });

    test('95 ron without super marker → premium', () {
      expect(classifyArgentinaProduct('Nafta de 95 Ron'),
          ArgentinaFuelCategory.naftaPremium);
      expect(classifyArgentinaProduct('Nafta 95 Ron'),
          ArgentinaFuelCategory.naftaPremium);
    });

    test('grado 3 → premium, grado 2 → regular', () {
      expect(classifyArgentinaProduct('Nafta grado 3'),
          ArgentinaFuelCategory.naftaPremium);
      expect(classifyArgentinaProduct('Nafta grado 2'),
          ArgentinaFuelCategory.naftaRegular);
      expect(classifyArgentinaProduct('Gas Oil Grado 3 premium'),
          ArgentinaFuelCategory.dieselPremium);
    });

    test('is case-insensitive and whitespace-tolerant', () {
      expect(classifyArgentinaProduct('NAFTA PREMIUM'),
          ArgentinaFuelCategory.naftaPremium);
      expect(classifyArgentinaProduct('  gnc  '), ArgentinaFuelCategory.gnc);
      expect(classifyArgentinaProduct('Gas  Oil\tGrado 2'),
          ArgentinaFuelCategory.dieselRegular);
    });

    test('handles gasoil as one word', () {
      expect(classifyArgentinaProduct('Gasoil'),
          ArgentinaFuelCategory.dieselRegular);
      expect(classifyArgentinaProduct('Gasoil premium'),
          ArgentinaFuelCategory.dieselPremium);
    });

    test('bare "nafta" with no marker → regular', () {
      expect(classifyArgentinaProduct('Nafta'),
          ArgentinaFuelCategory.naftaRegular);
    });

    test('unknown products → null', () {
      expect(classifyArgentinaProduct('Kerosene'), isNull);
      expect(classifyArgentinaProduct('Hidrógeno'), isNull);
      expect(classifyArgentinaProduct(''), isNull);
    });
  });
}
