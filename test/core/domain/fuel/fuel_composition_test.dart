// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel/fuel_composition.dart';

/// #4274 — the canonical composition contract.
///
/// The criterion these cases exist for is the one that is easiest to lose:
/// **`unknown` must never be equivalent to an exact zero.** A composition
/// that does not know whether it contains ethanol is a different fact from
/// one that knows it contains none, and a model that collapses the two
/// will happily report "0 % ethanol" about a tank nobody characterised.
///
/// `exactFraction` is where that distinction lives: it answers `null` —
/// not `0` — whenever an uncharacterized part could contain the component.
void main() {
  group('construction validates the invariant', () {
    test('fractions must sum to one', () {
      expect(
        () => FuelComposition({
          FuelComponent.petrol: 0.5,
          FuelComponent.ethanol: 0.2,
        }),
        throwsArgumentError,
        reason: 'a composition that sums to 0.7 describes no real tank',
      );
    });

    test('a sum within floating-point tolerance is accepted', () {
      // Three components that cannot be represented exactly in binary.
      final composition = FuelComposition({
        FuelComponent.petrol: 1 / 3,
        FuelComponent.ethanol: 1 / 3,
        FuelComponent.diesel: 1 / 3,
      });

      expect(composition.fractions.length, 3);
    });

    test('an empty map is rejected', () {
      expect(() => FuelComposition(const {}), throwsArgumentError,
          reason: 'no components at all is not the same as unknown — '
              'FuelComposition.unknown() is how that is spelled');
    });

    test('a negative or >1 fraction is rejected', () {
      expect(
        () => FuelComposition({
          FuelComponent.petrol: 1.5,
          FuelComponent.ethanol: -0.5,
        }),
        throwsArgumentError,
      );
    });

    test('a non-finite fraction is rejected', () {
      expect(
        () => FuelComposition({FuelComponent.petrol: double.nan}),
        throwsArgumentError,
        reason: 'NaN would slip past a naive sum check',
      );
    });

    test('the fraction map is unmodifiable', () {
      final composition = FuelComposition({FuelComponent.petrol: 1});

      expect(
        () => composition.fractions[FuelComponent.ethanol] = 0.1,
        throwsUnsupportedError,
      );
    });
  });

  group('unknown is not zero (#4274)', () {
    test('a fully unknown composition reports no exact fractions', () {
      final unknown = FuelComposition.unknown();

      expect(unknown.unknownFraction, 1);
      expect(unknown.exactFraction(FuelComponent.ethanol), isNull,
          reason: 'null means "could be anything", which is the whole point; '
              '0 would be a claim this composition cannot support');
      expect(unknown.exactFraction(FuelComponent.petrol), isNull);
    });

    test('a partly unknown composition still refuses exact answers', () {
      // Half characterised as petrol, half never identified.
      final partial = FuelComposition({
        FuelComponent.petrol: 0.5,
        FuelComponent.unknown: 0.5,
      });

      expect(partial.unknownFraction, 0.5);
      expect(partial.exactFraction(FuelComponent.ethanol), isNull,
          reason: 'the uncharacterized half could be entirely ethanol');
      expect(partial.exactFraction(FuelComponent.petrol), isNull,
          reason: 'even a component that IS present has no exact fraction '
              'while part of the volume is unidentified — there may be more '
              'petrol hiding in the unknown part');
    });

    test('a fully characterised composition answers exactly, including zero',
        () {
      final known = FuelComposition({
        FuelComponent.petrol: 0.9,
        FuelComponent.ethanol: 0.1,
      });

      expect(known.unknownFraction, 0);
      expect(known.exactFraction(FuelComponent.ethanol), 0.1);
      expect(known.exactFraction(FuelComponent.diesel), 0,
          reason: 'with nothing unknown, an absent component really is zero — '
              'this is the case that makes null meaningful elsewhere');
    });
  });

  group('JSON', () {
    test('round-trips a characterised composition', () {
      final original = FuelComposition({
        FuelComponent.petrol: 0.85,
        FuelComponent.ethanol: 0.15,
      });

      final decoded = FuelComposition.fromJson(original.toJson());

      expect(decoded.fractions, original.fractions);
      expect(decoded.exactFraction(FuelComponent.ethanol), 0.15);
    });

    test('round-trips the unknown composition', () {
      final decoded = FuelComposition.fromJson(FuelComposition.unknown().toJson());

      expect(decoded.unknownFraction, 1);
      expect(decoded.exactFraction(FuelComponent.petrol), isNull);
    });

    test('omits components that were never recorded', () {
      final json = FuelComposition({FuelComponent.diesel: 1}).toJson();

      expect(json.keys, ['diesel'],
          reason: 'an absent key and a zero value must stay distinguishable '
              'on the wire too');
    });

    test('a component name this build does not know folds into unknown', () {
      // A record written by a NEWER model version that learned about a
      // component this build has never heard of.
      final decoded = FuelComposition.fromJson(const {
        'petrol': 0.6,
        'biobutanol': 0.4,
      });

      expect(decoded.unknownFraction, 0.4,
          reason: 'the unidentifiable part is exactly what unknown means');
      expect(decoded.exactFraction(FuelComponent.petrol), isNull,
          reason: 'and its presence makes every answer inexact again');
    });

    test('several unrecognized components fold additively', () {
      // Two unknown names plus an explicit unknown must still sum to 1,
      // which only works if folding accumulates rather than overwrites.
      final decoded = FuelComposition.fromJson(const {
        'petrol': 0.4,
        'biobutanol': 0.3,
        'methanol': 0.2,
        'unknown': 0.1,
      });

      expect(decoded.unknownFraction, closeTo(0.6, 1e-9),
          reason: 'overwriting instead of accumulating would leave the '
              'fractions summing to 0.5 and throw');
    });

    test('a forward-version record does not throw', () {
      // The regression this guards: `FuelComponent.values.byName()` throws
      // on an unrecognized name, which would make a record written by a
      // newer model version permanently unreadable.
      expect(
        () => FuelComposition.fromJson(const {'something_new': 1}),
        returnsNormally,
      );
    });
  });
}
