// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/core/utils/unit_formatter.dart';
import 'package:tankstellen/features/trips/data/trip_history_entry.dart';
import 'package:tankstellen/features/trips/domain/trip_summary.dart';
import 'package:tankstellen/features/trips/presentation/widgets/trajet_row.dart';
import 'package:tankstellen/features/trips/presentation/widgets/trip_summary_card.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/pump_app.dart';

/// #4233 — the trip card and the trip row read the L/100 km through the
/// canonical adapter. #4330 took the product decision ADR 0024 §7 left
/// open: the estimate marker now comes from the contract's provenance
/// instead of from "is the stored avg null", and it is the `≈` of the
/// shared `DataValue.qualify` rather than an ad-hoc `~`.
///
/// What changed, and why each pin moved:
///   * measured (PID 5E) — unchanged, plain. A figure the ECU reported
///     must not be hedged.
///   * estimated (MAF / speed-density) — was plain, now `≈`. It is an
///     estimate; only the accident of a non-null stored `avg` hid that.
///   * GPS **batch** (`gpsOnly` with a stored avg) — was plain, now `≈`.
///     This is the case #4330 names: the adapter classed it estimated and
///     the surfaces rendered it as though it were measured.
///   * GPS **live** estimate (`eAvg` only) — was `~`, now `≈`. Same
///     meaning, one glyph across the app.
///   * no figure — unchanged (no L/100 km rendered at all).
TripHistoryEntry _entry({
  double? avg,
  double? eAvg,
  String? dfs,
  double? pg,
  TripKind kind = TripKind.gpsPlusObd2,
}) =>
    TripHistoryEntry(
      id: 'trip-${avg}_${eAvg}_$kind',
      vehicleId: 'v1',
      summary: TripSummary(
        distanceKm: 18.2,
        maxRpm: kind == TripKind.gpsOnly ? 0 : 2800,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        avgLPer100Km: avg,
        fuelLitersConsumed: avg == null ? null : avg * 0.182,
        estimatedAvgLPer100Km: eAvg,
        dominantFuelSource: dfs,
        pumpGainApplied: pg,
        kind: kind,
        startedAt: DateTime.utc(2026, 9, 1, 19, 22),
        endedAt: DateTime.utc(2026, 9, 1, 20, 5),
      ),
    );

const _gain11 = VehicleProfile(
  id: 'v1',
  name: 'Clio',
  type: VehicleType.combustion,
  pumpGain: 1.1,
  pumpGainSamples: 4,
);

/// (case, entry, vehicle, the L/100 km a surface shows or null, `~`?).
/// Strings are built with the app's own formatters, so the pin follows the
/// test locale's decimal separator rather than hard-coding one.
final _cases = <(String, TripHistoryEntry, VehicleProfile?, double?, bool)>[
  ('measured stays plain', _entry(avg: 6.4, dfs: 'pid5E', pg: 1.1), _gain11,
      6.4, false),
  ('estimated re-expressed is marked',
      _entry(avg: 7.0, dfs: 'maf', pg: 1.0), _gain11, 7.7, true),
  ('GPS batch is marked (#4330)', _entry(avg: 5.5, kind: TripKind.gpsOnly),
      null, 5.5, true),
  ('GPS live estimate is marked', _entry(eAvg: 5.9, kind: TripKind.gpsOnly),
      null, 5.9, true),
  ('no figure', _entry(), null, null, false),
];

void main() {
  for (final (name, entry, vehicle, value, estimated) in _cases) {
    // The one marker, from the shared `dataApproximate` ARB string — so
    // the pin follows the copy rather than hard-coding the glyph twice.
    String mark(String formatted) => estimated ? '≈ $formatted' : formatted;
    testWidgets('trip summary card — $name', (tester) async {
      await pumpApp(
        tester,
        TripSummaryCard(
          entry: entry,
          vehicle: vehicle,
          samples: const [],
          isEv: false,
        ),
      );
      if (value == null) {
        expect(find.textContaining('L/100 km'), findsNothing);
      } else {
        expect(
            find.text(
                mark(UnitFormatter.formatConsumption(value, isEv: false))),
            findsOneWidget);
      }
    });

    testWidgets('trajet row — $name', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => TrajetRow(
            entry: entry,
            vehicle: vehicle,
            l: AppLocalizations.of(context),
            theme: Theme.of(context),
            onTap: () {},
          ),
        ),
      );
      if (value == null) {
        expect(find.textContaining('L/100 km'), findsNothing);
      } else {
        expect(
            find.text('${mark(UnitFormatter.formatDecimal(value))} L/100 km'),
            findsOneWidget);
      }
    });
  }
}
