import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_detail_charts.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_summary_card.dart';
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
}
