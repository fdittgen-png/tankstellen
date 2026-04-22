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
