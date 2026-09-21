// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel/fuel_grade.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';

/// #4274 — commercial grades, and the vehicle approval contract.
///
/// [FuelGrade] is a second fuel structure beside the sealed [FuelType],
/// which is the situation `country_fuel_parity_test.dart` was written to
/// police for the two country fuel lists (#2180): two parallel
/// declarations drift, silently, and the drift only surfaces as a user
/// seeing a grade the rest of the app cannot handle.
///
/// So the mapping is asserted as a **totality** driven off
/// [FuelType.values] rather than as a hand-written list of pairs. Adding a
/// twelfth fuel type fails here, naming it, instead of quietly resolving
/// to [FuelGrade.unknown] wherever the new model is consulted.
void main() {
  group('FuelGrade <-> FuelType mapping is total (#4274)', () {
    test('every FuelType.apiValue resolves to a real grade', () {
      final unmapped = <String>[];
      for (final type in FuelType.values) {
        if (FuelGrade.fromKey(type.apiValue) == FuelGrade.unknown) {
          unmapped.add(type.apiValue);
        }
      }

      expect(
        unmapped,
        isEmpty,
        reason: 'FuelGrade has no key for these FuelType.apiValues, so the '
            'blend model silently treats them as unknown. Add the grade to '
            'lib/core/domain/fuel/fuel_grade.dart (the keys must match '
            'FuelType.apiValue exactly). Offenders: ${unmapped.join(', ')}',
      );
    });

    test('distinct fuel types never collapse onto one grade', () {
      // A duplicated key would make two fuels indistinguishable in the
      // blend model while still looking fine in the UI.
      final byGrade = <FuelGrade, List<String>>{};
      for (final type in FuelType.values) {
        byGrade
            .putIfAbsent(FuelGrade.fromKey(type.apiValue), () => [])
            .add(type.apiValue);
      }
      final collisions = byGrade.entries
          .where((e) => e.value.length > 1)
          .map((e) => '${e.key.name} <- {${e.value.join(', ')}}')
          .toList();

      expect(collisions, isEmpty,
          reason: 'these FuelTypes share a FuelGrade: '
              '${collisions.join('; ')}');
    });

    test('every grade key round-trips back through FuelType', () {
      final broken = <String>[];
      for (final grade in FuelGrade.values) {
        // `unknown` is the one grade with no FuelType counterpart: the
        // sealed FuelType has no unknown member and documents `all` as its
        // parse fallback. Asserted explicitly below rather than skipped.
        if (grade == FuelGrade.unknown) continue;
        if (FuelType.fromString(grade.key).apiValue != grade.key) {
          broken.add(grade.key);
        }
      }

      expect(broken, isEmpty,
          reason: 'these FuelGrade keys do not survive a FuelType round '
              'trip: ${broken.join(', ')}');
    });

    test('FuelGrade.unknown has no FuelType counterpart, by design', () {
      // FuelType.fromString returns `all` for anything it cannot parse.
      // That is the documented contract, not a bug — but it means an
      // unknown grade must never be handed to FuelType and trusted.
      expect(FuelType.fromString(FuelGrade.unknown.key), FuelType.all);
      expect(FuelGrade.fromKey('definitely-not-a-fuel'), FuelGrade.unknown,
          reason: 'FuelGrade degrades to unknown where FuelType degrades to '
              'the search wildcard — the asymmetry is why the two must not '
              'be used interchangeably');
    });

    test('the wildcard maps both ways', () {
      expect(FuelGrade.fromKey('all'), FuelGrade.wildcard);
      expect(FuelType.fromString(FuelGrade.wildcard.key), FuelType.all);
    });

    test('both legacy camelCase spellings of diesel premium are accepted',
        () {
      // Old Hive/JSON records wrote the enum name, not the apiValue.
      // FuelType.fromString handles this; FuelGrade must agree or stored
      // data decodes to two different things depending which type reads it.
      for (final legacy in ['dieselPremium', 'dieselpremium']) {
        expect(FuelGrade.fromKey(legacy), FuelGrade.dieselPremium,
            reason: '$legacy must survive, like FuelType.fromString');
        expect(FuelType.fromString(legacy), FuelType.dieselPremium);
      }
    });

    test('key lookup is case-insensitive', () {
      expect(FuelGrade.fromKey('DIESEL_PREMIUM'), FuelGrade.dieselPremium);
      expect(FuelGrade.fromKey('E85'), FuelGrade.e85);
    });
  });

  group('grade semantics are not blend percentages (#4274)', () {
    test('E98 is an octane rating, not 98 % ethanol', () {
      // The criterion in #4274's own words: "E5/E10 semantics cannot be
      // confused with arbitrary ethanol percentages". Nothing on a grade
      // exposes an ethanol fraction, and that absence is the guarantee —
      // composition lives in FuelComposition, sourced from evidence.
      expect(FuelGrade.e98.key, 'e98');
      expect(FuelGrade.e98, isNot(FuelGrade.e85));
    });

    test('E85, E98 and diesel are three different grades', () {
      final distinct = {FuelGrade.e85, FuelGrade.e98, FuelGrade.diesel};

      expect(distinct.length, 3, reason: 'never interchangeable (#4274)');
    });

    test('E5 and E10 are distinct grades, not one octane family', () {
      expect(FuelGrade.e5, isNot(FuelGrade.e10));
    });

    test('isLiquid separates pumped fuels from cng/hydrogen/electric', () {
      for (final liquid in [
        FuelGrade.e5,
        FuelGrade.e10,
        FuelGrade.e98,
        FuelGrade.e85,
        FuelGrade.diesel,
        FuelGrade.dieselPremium,
        FuelGrade.lpg,
      ]) {
        expect(liquid.isLiquid, isTrue, reason: '${liquid.key} is pumped');
      }
      for (final other in [
        FuelGrade.cng,
        FuelGrade.hydrogen,
        FuelGrade.electric,
        FuelGrade.wildcard,
        FuelGrade.unknown,
      ]) {
        expect(other.isLiquid, isFalse,
            reason: '${other.key} is not a litre of liquid — a blend volume '
                'in litres is meaningless for it');
      }
    });
  });

  group('VehicleFuelCapability — approval is explicit (#4274)', () {
    test('unknown capability is distinct from approving nothing', () {
      const unknown = VehicleFuelCapability.unknown();

      expect(unknown.isUnknown, isTrue);
      expect(unknown.permits(FuelGrade.e10), isFalse,
          reason: '"not known to be approved" — never a silent yes');
      expect(unknown.approvedGrades, isEmpty);
    });

    test('an empty approval set is rejected, not silently treated as unknown',
        () {
      // The confusion #4274 forbids: an empty set that constructs fine
      // makes "approves nothing" and "we do not know" the same value.
      expect(
        () => VehicleFuelCapability(
            approvedGrades: const [], provenance: 'manual'),
        throwsArgumentError,
      );
    });

    test('a real capability permits only what it lists', () {
      final capability = VehicleFuelCapability(
        approvedGrades: const [FuelGrade.e5, FuelGrade.e10],
        provenance: 'owner manual',
      );

      expect(capability.isUnknown, isFalse);
      expect(capability.permits(FuelGrade.e10), isTrue);
      expect(capability.permits(FuelGrade.e85), isFalse,
          reason: 'E85 approval is never inferred from an E5/E10 sibling '
              'mapping — the explicit #4274 rule. A petrol car physically '
              'accepts E85 and is damaged by it.');
    });

    test('the sentinel grades can never be approved', () {
      for (final bad in [FuelGrade.unknown, FuelGrade.wildcard]) {
        expect(
          () => VehicleFuelCapability(
              approvedGrades: [bad], provenance: 'manual'),
          throwsArgumentError,
          reason: '${bad.key} is not something a manufacturer approves',
        );
      }
    });

    test('provenance is required — an approval with no source is not one', () {
      expect(
        () => VehicleFuelCapability(
            approvedGrades: const [FuelGrade.diesel], provenance: ''),
        throwsArgumentError,
      );
    });

    test('the approval set is unmodifiable', () {
      final capability = VehicleFuelCapability(
        approvedGrades: const [FuelGrade.diesel],
        provenance: 'manual',
      );

      expect(() => capability.approvedGrades.add(FuelGrade.e85),
          throwsUnsupportedError);
    });

    group('JSON', () {
      test('round-trips a real capability', () {
        final original = VehicleFuelCapability(
          approvedGrades: const [FuelGrade.e10, FuelGrade.e5],
          provenance: 'owner manual',
        );

        final decoded = VehicleFuelCapability.fromJson(original.toJson());

        expect(decoded.approvedGrades, original.approvedGrades);
        expect(decoded.provenance, 'owner manual');
        expect(decoded.isUnknown, isFalse);
      });

      test('the encoded grade list is sorted, so records are stable', () {
        final json = VehicleFuelCapability(
          approvedGrades: const [FuelGrade.lpg, FuelGrade.diesel],
          provenance: 'manual',
        ).toJson();

        expect(json['approvedGrades'], ['diesel', 'lpg']);
      });

      test('an unrecognized grade key is dropped, not decoded as a sentinel',
          () {
        // The regression this guards: fromKey returns FuelGrade.unknown for
        // an unfamiliar key, and the constructor REJECTS that sentinel — so
        // a record from a newer model version used to crash on decode.
        final decoded = VehicleFuelCapability.fromJson(const {
          'approvedGrades': ['e10', 'some_future_grade'],
          'provenance': 'owner manual',
        });

        expect(decoded.approvedGrades, {FuelGrade.e10});
        expect(decoded.permits(FuelGrade.e10), isTrue);
        expect(decoded.isUnknown, isFalse);
      });

      test('a record of only unrecognized grades decodes as unknown', () {
        final decoded = VehicleFuelCapability.fromJson(const {
          'approvedGrades': ['some_future_grade'],
          'provenance': 'owner manual',
        });

        expect(decoded.isUnknown, isTrue,
            reason: 'nothing survived, so nothing is known — and crucially '
                'not "approves nothing"');
      });

      test('a forward-version record never throws', () {
        expect(
          () => VehicleFuelCapability.fromJson(const {
            'approvedGrades': ['unknown', 'all', 'not_a_grade'],
            'provenance': '',
          }),
          returnsNormally,
          reason: 'sentinels and junk alike must degrade, not crash — an '
              'unreadable record is as lost as a deleted one',
        );
      });
    });
  });
}
