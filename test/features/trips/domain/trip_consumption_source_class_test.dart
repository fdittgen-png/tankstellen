// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/consumption_estimate.dart';
import 'package:tankstellen/features/trips/domain/trip_consumption_source_class.dart';
import 'package:tankstellen/features/trips/domain/trip_fuel_source.dart';

/// #4230 — the parity guard between the trip layer's
/// [TripFuelSourceKind] and the canonical [ConsumptionSourceClass].
///
/// Two enums describe the same four source classes because
/// `feature_boundary_test` pins **core → feature at zero** (#3129), so
/// `core/domain/consumption_estimate.dart` cannot import the trip
/// vocabulary. Parallel declarations drift — that is exactly what
/// `country_fuel_parity_test.dart` was written to police for the two
/// country fuel lists (#2180), where the drift only surfaced as a user
/// seeing a grade the rest of the app could not handle.
///
/// So this asserts the mapping as a **totality** driven off
/// `.values`, rather than as a hand-written list of pairs.
void main() {
  group('TripFuelSourceKind ↔ ConsumptionSourceClass parity (#4230)', () {
    test('the two enums describe the same number of classes', () {
      expect(
        ConsumptionSourceClass.values.length,
        TripFuelSourceKind.values.length,
        reason: 'a value added to either enum without the other leaves the '
            'mapping incomplete. The extension\'s switch is exhaustive over '
            'TripFuelSourceKind, so a new TRIP kind is a compile error; this '
            'catches the other direction — a new CANONICAL class nothing '
            'maps onto.',
      );
    });

    test('every trip kind maps to a distinct canonical class', () {
      final mapped = <ConsumptionSourceClass, List<String>>{};
      for (final kind in TripFuelSourceKind.values) {
        mapped
            .putIfAbsent(kind.asConsumptionSourceClass, () => [])
            .add(kind.name);
      }

      final collisions = mapped.entries
          .where((e) => e.value.length > 1)
          .map((e) => '${e.key.name} <- {${e.value.join(', ')}}')
          .toList();

      expect(collisions, isEmpty,
          reason: 'two trip kinds collapsing onto one canonical class would '
              'make them indistinguishable downstream: ${collisions.join('; ')}');
      expect(mapped.length, TripFuelSourceKind.values.length);
    });

    test('every canonical class is reachable from some trip kind', () {
      final reached =
          TripFuelSourceKind.values.map((k) => k.asConsumptionSourceClass).toSet();
      final unreachable = ConsumptionSourceClass.values
          .where((c) => !reached.contains(c))
          .map((c) => c.name)
          .toList();

      expect(unreachable, isEmpty,
          reason: 'a canonical class no producer can reach is dead weight in '
              'every exhaustive switch downstream: ${unreachable.join(', ')}');
    });

    test('the one deliberate rename is gps → gpsOnly', () {
      expect(TripFuelSourceKind.gps.asConsumptionSourceClass,
          ConsumptionSourceClass.gpsOnly,
          reason: '"gps" beside "measured"/"estimated" reads like a third '
              'quality; it is an input set producing a modelled litre');
    });

    test('the names agree everywhere else', () {
      expect(TripFuelSourceKind.measured.asConsumptionSourceClass,
          ConsumptionSourceClass.measured);
      expect(TripFuelSourceKind.estimated.asConsumptionSourceClass,
          ConsumptionSourceClass.estimated);
      expect(TripFuelSourceKind.none.asConsumptionSourceClass,
          ConsumptionSourceClass.none);
    });
  });

  group('the pump-gain rule survives the mapping (#4222 source semantics)',
      () {
    test('exactly the estimated class may be pump-gain scaled', () {
      // The same invariant `consumption_source_class_gates_test.dart`
      // asserts on the trip side. Pinned across the seam too, so the
      // contract and the trip layer cannot end up disagreeing about which
      // figures may be rescaled.
      final scalable = TripFuelSourceKind.values
          .where((k) => k.asConsumptionSourceClass.pumpGainApplies)
          .map((k) => k.name)
          .toList();

      expect(scalable, ['estimated'],
          reason: 'measured ECU fuel was never multiplied by a gain, and a '
              'GPS-only figure comes from the road-load model the gain does '
              'not calibrate');
    });

    test('a measured trip kind never becomes gain-scalable', () {
      expect(
        TripFuelSourceKind.measured.asConsumptionSourceClass.pumpGainApplies,
        isFalse,
      );
      expect(
        TripFuelSourceKind.measured.asConsumptionSourceClass.isMeasured,
        isTrue,
      );
    });

    test('gps and none are modelled-or-absent, never measured', () {
      for (final kind in [TripFuelSourceKind.gps, TripFuelSourceKind.none]) {
        expect(kind.asConsumptionSourceClass.isMeasured, isFalse,
            reason: '${kind.name} carries no ECU measurement');
        expect(kind.asConsumptionSourceClass.pumpGainApplies, isFalse);
      }
    });
  });
}
