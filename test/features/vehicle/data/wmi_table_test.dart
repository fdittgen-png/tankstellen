import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/data/wmi_table.dart';

/// Spot-check the offline WMI table. Exhaustive coverage would bloat
/// the suite for no extra confidence — five representative prefixes
/// across the main producing regions (Europe / USA / Japan / Korea)
/// and an explicit unknown-prefix negative are enough to catch
/// table-wide regressions (wrong column order, case-sensitivity bugs,
/// accidental deletions).
void main() {
  group('wmi lookup', () {
    test('VF3 → Peugeot, France', () {
      final entry = lookup('VF38HKFVZ6R123456');
      expect(entry, isNotNull);
      expect(entry!.brand, 'Peugeot');
      expect(entry.country, 'France');
    });

    test('WBA → BMW, Germany', () {
      final entry = lookup('WBA3B1C50DF123456');
      expect(entry, isNotNull);
      expect(entry!.brand, 'BMW');
      expect(entry.country, 'Germany');
    });

    test('JTD → Toyota, Japan', () {
      final entry = lookup('JTDKB20U487123456');
      expect(entry, isNotNull);
      expect(entry!.brand, 'Toyota');
      expect(entry.country, 'Japan');
    });

    test('5YJ → Tesla, United States', () {
      final entry = lookup('5YJ3E1EA7KF123456');
      expect(entry, isNotNull);
      expect(entry!.brand, 'Tesla');
      expect(entry.country, 'United States');
    });

    test('KMH → Hyundai, South Korea', () {
      final entry = lookup('KMHCT41DAEU123456');
      expect(entry, isNotNull);
      expect(entry!.brand, 'Hyundai');
      expect(entry.country, 'South Korea');
    });

    test('unknown prefix → null', () {
      expect(lookup('ZZZ1234567890ZZZZ'), isNull);
    });

    test('input shorter than 3 characters → null (no crash)', () {
      expect(lookup(''), isNull);
      expect(lookup('VF'), isNull);
    });

    test('lookup is case-insensitive (lower-case input still resolves)', () {
      final entry = lookup('vf38hkfvz6r123456');
      expect(entry, isNotNull);
      expect(entry!.brand, 'Peugeot');
    });

    test('mixed-case input still resolves (toUpperCase normalisation)', () {
      final entry = lookup('Wba3B1c50dF123456');
      expect(entry, isNotNull);
      expect(entry!.brand, 'BMW');
      expect(entry.country, 'Germany');
    });

    test('exactly 3-character input resolves to the matching entry', () {
      // The lookup only consults the first 3 chars, so a bare prefix
      // must succeed even though it isn't a real 17-char VIN.
      final entry = lookup('WVW');
      expect(entry, isNotNull);
      expect(entry!.brand, 'Volkswagen');
      expect(entry.country, 'Germany');
    });

    test('WF0 → Ford, Germany (European Ford plant)', () {
      final entry = lookup('WF0AXXGCDAEU12345');
      expect(entry, isNotNull);
      expect(entry!.brand, 'Ford');
      expect(entry.country, 'Germany');
    });

    test('1FA → Ford, United States (US Ford plant)', () {
      final entry = lookup('1FAFP404X4F123456');
      expect(entry, isNotNull);
      expect(entry!.brand, 'Ford');
      expect(entry.country, 'United States');
    });

    test('WVW → Volkswagen, Germany', () {
      final entry = lookup('WVWZZZ1JZ3W123456');
      expect(entry, isNotNull);
      expect(entry!.brand, 'Volkswagen');
      expect(entry.country, 'Germany');
    });

    test('17-char real-world VIN — only 3-char prefix is consulted', () {
      // Two distinct full VINs that share the WAU prefix must resolve
      // to the same WmiEntry, proving characters 4-17 are ignored.
      final a = lookup('WAUZZZ8K9BA123456');
      final b = lookup('WAUFFAFL0BN999999');
      expect(a, isNotNull);
      expect(b, isNotNull);
      expect(a!.brand, 'Audi');
      expect(b!.brand, 'Audi');
      expect(a.country, 'Germany');
      expect(b.country, 'Germany');
    });

    test('single-char and two-char inputs return null', () {
      expect(lookup('W'), isNull);
      expect(lookup('WB'), isNull);
    });
  });

  group('WmiEntry', () {
    test('constructor exposes country and brand verbatim', () {
      const entry = WmiEntry(country: 'France', brand: 'Peugeot');
      expect(entry.country, 'France');
      expect(entry.brand, 'Peugeot');
    });

    test('lookup hit returns a WmiEntry whose fields are accessible', () {
      final entry = lookup('VF3');
      expect(entry, isA<WmiEntry>());
      expect(entry!.country, isA<String>());
      expect(entry.brand, isA<String>());
      expect(entry.country, 'France');
      expect(entry.brand, 'Peugeot');
    });
  });

  group('wmiTable integrity', () {
    test('every key is exactly 3 upper-case characters', () {
      for (final key in wmiTable.keys) {
        expect(key.length, 3, reason: 'Key "$key" must be 3 chars');
        expect(key, key.toUpperCase(), reason: 'Key "$key" must be upper-case');
      }
    });

    test('every entry has a non-empty brand and country', () {
      for (final e in wmiTable.entries) {
        expect(e.value.brand, isNotEmpty, reason: 'Brand empty for ${e.key}');
        expect(e.value.country, isNotEmpty,
            reason: 'Country empty for ${e.key}');
      }
    });
  });
}
