// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/core/domain/refuel_economics.dart';
import 'package:tankstellen/core/utils/data_value_labels.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fuel_consumption_figure.dart';
import 'package:tankstellen/features/obd2/domain/trip_distance_resolver.dart';
import 'package:tankstellen/features/obd2/domain/trip_distance_source.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #4160 — one shape for measured / estimated / stale / unknown.
///
/// The point of the sealed type is that provenance cannot be dropped on
/// the way to a widget, so the tests that matter are the ones where
/// dropping it used to be possible: mapping a value, rendering one, and
/// the four existing mechanisms whose flag lived beside their number.
void main() {
  group('provenance survives the operations that used to lose it', () {
    test('map keeps the provenance, and cannot launder an unknown', () {
      expect(const DataValue.measured(2.0).map((v) => v * 2),
          const DataValue.measured(4.0));
      expect(
        const DataValue.estimated(2.0, basis: DataBasis.fleetAverage)
            .map((v) => v * 2),
        const DataValue.estimated(4.0, basis: DataBasis.fleetAverage),
      );
      const missing = DataValue<double>.unknown(
        reason: DataUnknownReason.missingVehicleData,
      );
      expect(
        missing.map((v) => v * 2),
        const DataValue<double>.unknown(
          reason: DataUnknownReason.missingVehicleData,
        ),
        reason: 'a transform must not be able to turn "we do not know" '
            'into a number, nor lose WHY we do not know',
      );
    });

    test('valueOrNull is for arithmetic and says nothing about trust', () {
      expect(const DataValue.measured(1.5).valueOrNull, 1.5);
      expect(
          const DataValue.estimated(1.5, basis: DataBasis.derived).valueOrNull,
          1.5);
      expect(
          const DataValue.stale(1.5, age: Duration(days: 2)).valueOrNull, 1.5);
      expect(
          const DataValue<double>.unknown(
            reason: DataUnknownReason.unreadable,
          ).valueOrNull,
          isNull);
    });

    test('isQualified marks exactly the two that need a caveat', () {
      expect(const DataValue.measured(1).isQualified, isFalse);
      expect(const DataValue.estimated(1, basis: DataBasis.derived).isQualified,
          isTrue);
      expect(const DataValue.stale(1, age: Duration(hours: 1)).isQualified,
          isTrue);
    });
  });

  group('rendering — the ≈ is a property of the type', () {
    late AppLocalizations l;

    setUpAll(() async {
      l = await AppLocalizations.delegate.load(const Locale('en'));
    });

    String fmt(double v) => v.toStringAsFixed(2);

    test('a measured figure is shown unadorned', () {
      // A number the user produced should not be decorated as though we
      // were hedging about it.
      expect(const DataValue.measured(6.50).qualify(l, fmt), '6.50');
    });

    test('an estimate comes back qualified whether or not the author '
        'thought about it', () {
      final shown = const DataValue.estimated(6.50,
              basis: DataBasis.fleetAverage)
          .qualify(l, fmt);
      expect(shown, contains('6.50'));
      expect(shown, isNot('6.50'),
          reason: 'trust rule 2: an explanation built on a model must read '
              'as one, and this is where that stops depending on the call '
              'site remembering');
    });

    test('an unknown renders its REASON, never an empty figure', () {
      final shown = const DataValue<double>.unknown(
        reason: DataUnknownReason.notPublishedByProvider,
      ).qualify(l, fmt);
      expect(shown, isNotEmpty);
      expect(shown, l.dataUnknownProvider);
    });

    test('every reason and every basis has ARB text, not developer prose',
        () async {
      // The load-bearing proof is that the text CHANGES with the locale.
      // A hard-coded English literal passes any "is it non-empty" check
      // and fails this one, which is the whole reason HARD RULE #1
      // exists.
      final de = await AppLocalizations.delegate.load(const Locale('de'));
      for (final reason in DataUnknownReason.values) {
        expect(reason.label(l), isNotEmpty, reason: reason.name);
        expect(reason.label(de), isNot(reason.label(l)),
            reason: '${reason.name} reads the same in German — it is a '
                'literal, not an ARB key');
      }
      for (final basis in DataBasis.values) {
        expect(basis.label(l), isNotEmpty, reason: basis.name);
        expect(basis.label(de), isNot(basis.label(l)),
            reason: '${basis.name} reads the same in German');
      }
    });

    test('the caveat line carries the qualification when the figure must '
        'stay bare', () {
      // #3950's stat figures are a tied visual grammar that a ≈ inside
      // would break, so they take the caveat as its own line.
      expect(const DataValue.measured(1).caveat(l), isNull);
      expect(
          const DataValue.estimated(1, basis: DataBasis.vehicleCatalog)
              .caveat(l),
          l.dataBasisCatalog);
      expect(
          const DataValue.stale(1, age: Duration(hours: 2)).caveat(l),
          isNotEmpty);
    });
  });

  group('the four existing mechanisms now speak one shape', () {
    test('FuelConsumptionFigure — an estimate is a CLASS average', () {
      expect(const FuelConsumptionFigure.measured(6.2).asDataValue,
          const DataValue.measured(6.2));
      expect(const FuelConsumptionFigure.estimated(6.2).asDataValue,
          const DataValue.estimated(6.2, basis: DataBasis.fleetAverage));
    });

    test('RefuelProfile — the flag can no longer be dropped beside the '
        'number', () {
      expect(const RefuelProfile(consumptionLPer100km: 6.5).consumption,
          const DataValue.measured(6.5));
      expect(
        const RefuelProfile(
          consumptionLPer100km: 6.5,
          consumptionIsEstimated: true,
        ).consumption,
        const DataValue.estimated(6.5, basis: DataBasis.fleetAverage),
      );
    });

    test('RefuelProfile — a null consumption names WHICH input is missing',
        () {
      // Trust rule 1. A nullable double could not say why it was null,
      // and the UI then had to guess a sentence for it.
      expect(
        const RefuelProfile().consumption,
        const DataValue<double>.unknown(
          reason: DataUnknownReason.notMeasuredYet,
        ),
      );
    });

    test('trip distance — GPS is an instrument, the virtual odometer is a '
        'model', () {
      expect(
          TripDistanceResolver.distanceAsDataValue(12.0, kDistanceSourceReal),
          const DataValue.measured(12.0));
      expect(
          TripDistanceResolver.distanceAsDataValue(12.0, kDistanceSourceGps),
          const DataValue.measured(12.0));
      expect(
        TripDistanceResolver.distanceAsDataValue(12.0, kDistanceSourceVirtual),
        const DataValue.estimated(12.0, basis: DataBasis.derived),
      );
    });

    test('an unrecognised distance source is unreadable, never promoted', () {
      // A backup written by a future version must not have its distance
      // silently become a measurement.
      expect(
        TripDistanceResolver.distanceAsDataValue(12.0, 'lidar'),
        const DataValue<double>.unknown(
          reason: DataUnknownReason.unreadable,
        ),
      );
    });
  });
}
