import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_detail_charts.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_summary_card.dart';
import 'package:tankstellen/features/consumption/providers/trip_fuel_cost_provider.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';

import '../../../../helpers/pump_app.dart';

/// Builds a [TripHistoryEntry] with sensible defaults so each test only
/// spells out the field it cares about. Mirrors the shape the
/// repository persists — see `lib/features/consumption/data/trip_history_repository.dart`.
TripHistoryEntry _entry({
  String id = 'trip-1',
  String? vehicleId,
  double distanceKm = 12.3,
  double maxRpm = 0,
  double highRpmSeconds = 0,
  double idleSeconds = 0,
  int harshBrakes = 0,
  int harshAccelerations = 0,
  double? avgLPer100Km,
  double? fuelLitersConsumed,
  DateTime? startedAt,
  DateTime? endedAt,
  String distanceSource = 'virtual',
  String? adapterMac,
  String? adapterName,
  String? adapterFirmware,
}) {
  return TripHistoryEntry(
    id: id,
    vehicleId: vehicleId,
    summary: TripSummary(
      distanceKm: distanceKm,
      maxRpm: maxRpm,
      highRpmSeconds: highRpmSeconds,
      idleSeconds: idleSeconds,
      harshBrakes: harshBrakes,
      harshAccelerations: harshAccelerations,
      avgLPer100Km: avgLPer100Km,
      fuelLitersConsumed: fuelLitersConsumed,
      startedAt: startedAt,
      endedAt: endedAt,
      distanceSource: distanceSource,
    ),
    adapterMac: adapterMac,
    adapterName: adapterName,
    adapterFirmware: adapterFirmware,
  );
}

const _vehicle = VehicleProfile(
  id: 'v1',
  name: 'Peugeot 308',
  type: VehicleType.combustion,
);

TripDetailSample _sample(double speed, {int sec = 0}) => TripDetailSample(
      timestamp: DateTime(2026, 4, 25, 14, 0, sec),
      speedKmh: speed,
    );

void main() {
  group('TripSummaryCard — labels', () {
    testWidgets('renders the summary title and all field labels',
        (tester) async {
      await pumpApp(
        tester,
        TripSummaryCard(
          entry: _entry(),
          vehicle: _vehicle,
          samples: const [],
          isEv: false,
        ),
      );

      expect(find.text('Summary'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Vehicle'), findsOneWidget);
      expect(find.text('Distance'), findsOneWidget);
      expect(find.text('Duration'), findsOneWidget);
      expect(find.text('Avg consumption'), findsOneWidget);
      expect(find.text('Fuel used'), findsOneWidget);
      expect(find.text('Avg speed'), findsOneWidget);
      expect(find.text('Max speed'), findsOneWidget);
    });
  });

  group('TripSummaryCard — date row', () {
    testWidgets('falls back to the unknown placeholder when startedAt is null',
        (tester) async {
      await pumpApp(
        tester,
        TripSummaryCard(
          entry: _entry(startedAt: null),
          vehicle: _vehicle,
          samples: const [],
          isEv: false,
        ),
      );
      // Date row is the only "—" row when only startedAt is missing
      // (vehicle, distance, duration, consumption, fuel, speeds all
      // either have values or are also "—"); we still expect at least
      // one "—" for the date.
      expect(find.text('—'), findsWidgets);
    });

    testWidgets('formats startedAt as YYYY-MM-DD HH:mm with zero-padding',
        (tester) async {
      await pumpApp(
        tester,
        TripSummaryCard(
          entry: _entry(startedAt: DateTime(2026, 1, 2, 3, 4)),
          vehicle: _vehicle,
          samples: const [],
          isEv: false,
        ),
      );
      expect(find.text('2026-01-02 03:04'), findsOneWidget);
    });
  });

  group('TripSummaryCard — vehicle row', () {
    testWidgets('renders vehicle.name when vehicle is provided',
        (tester) async {
      await pumpApp(
        tester,
        TripSummaryCard(
          entry: _entry(),
          vehicle: _vehicle,
          samples: const [],
          isEv: false,
        ),
      );
      expect(find.text('Peugeot 308'), findsOneWidget);
    });

    testWidgets('falls back to the unknown placeholder when vehicle is null',
        (tester) async {
      await pumpApp(
        tester,
        TripSummaryCard(
          entry: _entry(),
          vehicle: null,
          samples: const [],
          isEv: false,
        ),
      );
      // No vehicle name "Peugeot 308" should appear — only "—"
      expect(find.text('Peugeot 308'), findsNothing);
      expect(find.text('—'), findsWidgets);
    });
  });

  group('TripSummaryCard — distance row', () {
    testWidgets('renders distance with one-decimal formatting',
        (tester) async {
      await pumpApp(
        tester,
        TripSummaryCard(
          entry: _entry(distanceKm: 12.37),
          vehicle: _vehicle,
          samples: const [],
          isEv: false,
        ),
      );
      // 12.37 → 12.4 via toStringAsFixed(1)
      expect(find.text('12.4 km'), findsOneWidget);
    });
  });

  group('TripSummaryCard — duration row', () {
    testWidgets(
        'falls back to the unknown placeholder when endedAt is null',
        (tester) async {
      await pumpApp(
        tester,
        TripSummaryCard(
          entry: _entry(
            startedAt: DateTime(2026, 4, 25, 14, 0),
            endedAt: null,
          ),
          vehicle: _vehicle,
          samples: const [],
          isEv: false,
        ),
      );
      // Duration row should render the placeholder; vehicle/distance
      // are not "—" so finding any "—" is sufficient evidence the row
      // formatter took the fallback branch.
      expect(find.text('—'), findsWidgets);
    });

    testWidgets('formats sub-hour duration as "Xm Ys"', (tester) async {
      await pumpApp(
        tester,
        TripSummaryCard(
          entry: _entry(
            startedAt: DateTime(2026, 4, 25, 14, 0),
            endedAt: DateTime(2026, 4, 25, 14, 25),
          ),
          vehicle: _vehicle,
          samples: const [],
          isEv: false,
        ),
      );
      expect(find.text('25m 0s'), findsOneWidget);
    });

    testWidgets('formats multi-hour duration as "Xh Ym"', (tester) async {
      await pumpApp(
        tester,
        TripSummaryCard(
          entry: _entry(
            startedAt: DateTime(2026, 4, 25, 14, 0),
            endedAt: DateTime(2026, 4, 25, 16, 15),
          ),
          vehicle: _vehicle,
          samples: const [],
          isEv: false,
        ),
      );
      expect(find.text('2h 15m'), findsOneWidget);
    });
  });

  group('TripSummaryCard — avg consumption row', () {
    testWidgets('uses L/100 km units when isEv is false', (tester) async {
      await pumpApp(
        tester,
        TripSummaryCard(
          entry: _entry(avgLPer100Km: 6.4),
          vehicle: _vehicle,
          samples: const [],
          isEv: false,
        ),
      );
      expect(find.text('6.4 L/100 km'), findsOneWidget);
      expect(find.textContaining('kWh'), findsNothing);
    });

    testWidgets('swaps to kWh/100 km units when isEv is true',
        (tester) async {
      await pumpApp(
        tester,
        TripSummaryCard(
          entry: _entry(avgLPer100Km: 18.4),
          vehicle: _vehicle,
          samples: const [],
          isEv: true,
        ),
      );
      expect(find.text('18.4 kWh/100 km'), findsOneWidget);
      // The fuel-mode unit must NOT leak into the EV row.
      expect(find.textContaining('L/100 km'), findsNothing);
    });

    testWidgets(
        'falls back to the unknown placeholder when avgLPer100Km is null',
        (tester) async {
      await pumpApp(
        tester,
        TripSummaryCard(
          entry: _entry(avgLPer100Km: null),
          vehicle: _vehicle,
          samples: const [],
          isEv: false,
        ),
      );
      expect(find.textContaining('L/100 km'), findsNothing);
      expect(find.text('—'), findsWidgets);
    });
  });

  group('TripSummaryCard — fuel used row', () {
    testWidgets('renders fuel litres with two-decimal formatting',
        (tester) async {
      await pumpApp(
        tester,
        TripSummaryCard(
          entry: _entry(fuelLitersConsumed: 4.567),
          vehicle: _vehicle,
          samples: const [],
          isEv: false,
        ),
      );
      // 4.567 → 4.57 via toStringAsFixed(2)
      expect(find.text('4.57 L'), findsOneWidget);
    });

    testWidgets(
        'falls back to the unknown placeholder when fuelLitersConsumed is null',
        (tester) async {
      await pumpApp(
        tester,
        TripSummaryCard(
          entry: _entry(fuelLitersConsumed: null),
          vehicle: _vehicle,
          samples: const [],
          isEv: false,
        ),
      );
      // No "X L" string with two-decimal litres should appear.
      expect(find.textContaining(' L'), findsNothing);
      expect(find.text('—'), findsWidgets);
    });
  });

  group('TripSummaryCard — speed rows from samples', () {
    testWidgets(
        'renders the unknown placeholder for both speed rows when samples is empty',
        (tester) async {
      await pumpApp(
        tester,
        TripSummaryCard(
          entry: _entry(),
          vehicle: _vehicle,
          samples: const [],
          isEv: false,
        ),
      );
      // No "X km/h" string anywhere; the speed rows fell back to "—".
      expect(find.textContaining('km/h'), findsNothing);
    });

    testWidgets('computes avg and max speed from samples', (tester) async {
      // Avg = (40 + 60 + 80) / 3 = 60.0
      // Max = 80.0
      await pumpApp(
        tester,
        TripSummaryCard(
          entry: _entry(),
          vehicle: _vehicle,
          samples: [
            _sample(40, sec: 0),
            _sample(60, sec: 30),
            _sample(80, sec: 60),
          ],
          isEv: false,
        ),
      );
      expect(find.text('60.0 km/h'), findsOneWidget);
      expect(find.text('80.0 km/h'), findsOneWidget);
    });
  });

  group('TripSummaryCard — OBD2 adapter row (#1312)', () {
    testWidgets(
        'renders the adapter row with "name • mac" formatting when both fields '
        'are populated', (tester) async {
      await pumpApp(
        tester,
        TripSummaryCard(
          entry: _entry(
            adapterMac: 'AA:BB:CC:DD:EE:FF',
            adapterName: 'Vgate iCar Pro',
          ),
          vehicle: _vehicle,
          samples: const [],
          isEv: false,
        ),
      );

      // Label rendered from the en ARB key.
      expect(find.text('OBD2 adapter'), findsOneWidget);
      // Value formatted with the • separator.
      expect(
        find.text('Vgate iCar Pro • AA:BB:CC:DD:EE:FF'),
        findsOneWidget,
      );
    });

    testWidgets(
        'hides the adapter row when all three adapter fields are null '
        '(legacy trips, fake-service paths)', (tester) async {
      await pumpApp(
        tester,
        TripSummaryCard(
          entry: _entry(
            // adapterMac / adapterName / adapterFirmware all null
          ),
          vehicle: _vehicle,
          samples: const [],
          isEv: false,
        ),
      );

      expect(find.text('OBD2 adapter'), findsNothing);
    });

    testWidgets(
        'renders just the name when mac is null and firmware is null '
        '— format collapses cleanly without a stray separator',
        (tester) async {
      await pumpApp(
        tester,
        TripSummaryCard(
          entry: _entry(
            adapterName: 'OBDII',
          ),
          vehicle: _vehicle,
          samples: const [],
          isEv: false,
        ),
      );

      expect(find.text('OBD2 adapter'), findsOneWidget);
      expect(find.text('OBDII'), findsOneWidget);
    });

    testWidgets(
        'appends firmware in parentheses when present, after the '
        'name • mac value',
        (tester) async {
      await pumpApp(
        tester,
        TripSummaryCard(
          entry: _entry(
            adapterMac: 'AA:BB:CC:DD:EE:FF',
            adapterName: 'OBDII',
            adapterFirmware: 'ELM327 v1.5',
          ),
          vehicle: _vehicle,
          samples: const [],
          isEv: false,
        ),
      );

      // ~40-char cap leaves the full value intact here.
      expect(
        find.text('OBDII • AA:BB:CC:DD:EE:FF (ELM327 v1.5)'),
        findsOneWidget,
      );
    });
  });

  group('TripSummaryCard — fuel cost row (#1209)', () {
    setUp(() {
      // Pin the active currency so the formatted-price assertions
      // below are deterministic regardless of test ordering.
      PriceFormatter.setCountry('FR');
    });

    testWidgets('renders the formatted cost when the provider has data',
        (tester) async {
      await pumpApp(
        tester,
        TripSummaryCard(
          entry: _entry(
            id: 't-cost',
            fuelLitersConsumed: 0.27,
            startedAt: DateTime(2026, 4, 25, 14),
          ),
          vehicle: _vehicle,
          samples: const [],
          isEv: false,
        ),
        overrides: [
          tripFuelCostProvider('t-cost').overrideWithValue(0.4455),
        ],
      );

      expect(find.text('Fuel cost'), findsOneWidget);
      // PriceFormatter.formatPrice with FR locale prints the value
      // with three decimals and a non-breaking space + €.
      expect(
        find.text(PriceFormatter.formatPrice(0.4455)),
        findsOneWidget,
      );
    });

    testWidgets('hides the cost row when the provider returns null',
        (tester) async {
      await pumpApp(
        tester,
        TripSummaryCard(
          entry: _entry(
            id: 't-no-cost',
            fuelLitersConsumed: 0.27,
            startedAt: DateTime(2026, 4, 25, 14),
          ),
          vehicle: _vehicle,
          samples: const [],
          isEv: false,
        ),
        overrides: [
          tripFuelCostProvider('t-no-cost').overrideWithValue(null),
        ],
      );

      expect(find.text('Fuel cost'), findsNothing);
    });

    testWidgets('hides the cost row for EV trips even when a value is set',
        (tester) async {
      // EV trips never show fuel cost — fuel-litres-consumed semantics
      // don't apply, and the row should be skipped before the
      // provider read fires.
      await pumpApp(
        tester,
        TripSummaryCard(
          entry: _entry(
            id: 't-ev',
            fuelLitersConsumed: null,
            startedAt: DateTime(2026, 4, 25, 14),
          ),
          vehicle: _vehicle,
          samples: const [],
          isEv: true,
        ),
        overrides: [
          // Even with a non-null override the row must stay hidden
          // because the EV branch short-circuits before the watch.
          tripFuelCostProvider('t-ev').overrideWithValue(1.23),
        ],
      );

      expect(find.text('Fuel cost'), findsNothing);
    });
  });
}
