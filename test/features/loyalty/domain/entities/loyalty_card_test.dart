import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/loyalty/domain/entities/loyalty_card.dart';

LoyaltyCard _makeCard({
  String id = 'card-1',
  LoyaltyBrand brand = LoyaltyBrand.totalEnergies,
  double discountPerLiter = 0.05,
  String label = 'Personal',
  DateTime? addedAt,
  bool enabled = true,
}) {
  return LoyaltyCard(
    id: id,
    brand: brand,
    discountPerLiter: discountPerLiter,
    label: label,
    addedAt: addedAt ?? DateTime.utc(2026, 3, 15, 12),
    enabled: enabled,
  );
}

void main() {
  group('LoyaltyBrand enum', () {
    test('has exactly 5 values', () {
      expect(LoyaltyBrand.values, hasLength(5));
    });

    test('exposes documented canonical brand strings', () {
      expect(LoyaltyBrand.totalEnergies.canonicalBrand, 'TotalEnergies');
      expect(LoyaltyBrand.aral.canonicalBrand, 'Aral');
      expect(LoyaltyBrand.shell.canonicalBrand, 'Shell');
      expect(LoyaltyBrand.bp.canonicalBrand, 'BP');
      expect(LoyaltyBrand.esso.canonicalBrand, 'Esso');
    });
  });

  group('LoyaltyBrand.fromCanonical', () {
    test('returns null for null input', () {
      expect(LoyaltyBrand.fromCanonical(null), isNull);
    });

    test('returns the matching brand for each canonical string', () {
      expect(
        LoyaltyBrand.fromCanonical('TotalEnergies'),
        LoyaltyBrand.totalEnergies,
      );
      expect(LoyaltyBrand.fromCanonical('Aral'), LoyaltyBrand.aral);
      expect(LoyaltyBrand.fromCanonical('Shell'), LoyaltyBrand.shell);
      expect(LoyaltyBrand.fromCanonical('BP'), LoyaltyBrand.bp);
      expect(LoyaltyBrand.fromCanonical('Esso'), LoyaltyBrand.esso);
    });

    test('returns null for an unknown canonical string', () {
      expect(LoyaltyBrand.fromCanonical('Unknown'), isNull);
    });

    test('is case-sensitive (lowercase variant is not matched)', () {
      expect(LoyaltyBrand.fromCanonical('totalenergies'), isNull);
    });

    test('returns null for the empty string', () {
      expect(LoyaltyBrand.fromCanonical(''), isNull);
    });
  });

  group('LoyaltyCard construction', () {
    test('accepts all required fields with default enabled = true', () {
      final card = LoyaltyCard(
        id: 'card-1',
        brand: LoyaltyBrand.totalEnergies,
        discountPerLiter: 0.05,
        label: 'Personal',
        addedAt: DateTime.utc(2026, 3, 15),
      );

      expect(card.id, 'card-1');
      expect(card.brand, LoyaltyBrand.totalEnergies);
      expect(card.discountPerLiter, 0.05);
      expect(card.label, 'Personal');
      expect(card.addedAt, DateTime.utc(2026, 3, 15));
      expect(card.enabled, isTrue);
    });

    test('accepts an explicit enabled = false override', () {
      final card = _makeCard(enabled: false);
      expect(card.enabled, isFalse);
    });
  });

  group('LoyaltyCard equality (freezed)', () {
    test('two cards built from identical field values are equal', () {
      final a = _makeCard();
      final b = _makeCard();

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('differs on id', () {
      final a = _makeCard();
      final b = a.copyWith(id: 'card-2');
      expect(a, isNot(equals(b)));
    });

    test('differs on brand', () {
      final a = _makeCard();
      final b = a.copyWith(brand: LoyaltyBrand.shell);
      expect(a, isNot(equals(b)));
    });

    test('differs on discountPerLiter', () {
      final a = _makeCard();
      final b = a.copyWith(discountPerLiter: 0.07);
      expect(a, isNot(equals(b)));
    });

    test('differs on label', () {
      final a = _makeCard();
      final b = a.copyWith(label: 'Company');
      expect(a, isNot(equals(b)));
    });

    test('differs on addedAt', () {
      final a = _makeCard();
      final b = a.copyWith(addedAt: DateTime.utc(2027, 1, 1));
      expect(a, isNot(equals(b)));
    });

    test('differs on enabled', () {
      final a = _makeCard();
      final b = a.copyWith(enabled: false);
      expect(a, isNot(equals(b)));
    });
  });

  group('LoyaltyCard JSON', () {
    test('round-trips through toJson / fromJson with all fields populated', () {
      final original = LoyaltyCard(
        id: 'card-42',
        brand: LoyaltyBrand.aral,
        discountPerLiter: 0.08,
        label: 'Company',
        addedAt: DateTime.utc(2026, 4, 1, 8, 30, 15),
        enabled: false,
      );

      final json = original.toJson();
      final restored = LoyaltyCard.fromJson(json);

      expect(restored, equals(original));
    });

    test('honors the enabled default (true) when missing from JSON', () {
      final restored = LoyaltyCard.fromJson(<String, dynamic>{
        'id': 'card-7',
        'brand': 'totalEnergies',
        'discountPerLiter': 0.05,
        'label': 'Personal',
        'addedAt': DateTime.utc(2026, 3, 15).toIso8601String(),
      });

      expect(restored.enabled, isTrue);
    });
  });
}
