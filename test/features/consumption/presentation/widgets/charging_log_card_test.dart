import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/charging_log_card.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_log.dart';

import '../../../../helpers/pump_app.dart';

/// Builds a [ChargingLog] with sensible defaults so each test only
/// spells out the field it cares about. Mirrors the entity defined
/// in `lib/features/ev/domain/entities/charging_log.dart`.
ChargingLog _log({
  String id = 'log-1',
  String vehicleId = 'veh-1',
  DateTime? date,
  double kWh = 22.5,
  double costEur = 7.85,
  int chargeTimeMin = 35,
  int odometerKm = 12345,
  String? stationName = 'Ionity Castelnau',
  String? chargingStationId,
}) {
  return ChargingLog(
    id: id,
    vehicleId: vehicleId,
    date: date ?? DateTime(2026, 4, 25),
    kWh: kWh,
    costEur: costEur,
    chargeTimeMin: chargeTimeMin,
    odometerKm: odometerKm,
    stationName: stationName,
    chargingStationId: chargingStationId,
  );
}

void main() {
  group('ChargingLogCard — base structure', () {
    testWidgets('renders a Card and ListTile', (tester) async {
      await pumpApp(tester, ChargingLogCard(log: _log()));
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('renders the ev_station_outlined leading icon',
        (tester) async {
      await pumpApp(tester, ChargingLogCard(log: _log()));
      expect(find.byIcon(Icons.ev_station_outlined), findsOneWidget);
    });

    testWidgets('leading icon uses the theme primary color', (tester) async {
      await pumpApp(tester, ChargingLogCard(log: _log()));
      final icon = tester.widget<Icon>(find.byIcon(Icons.ev_station_outlined));
      final ctx = tester.element(find.byType(ChargingLogCard));
      expect(icon.color, Theme.of(ctx).colorScheme.primary);
    });
  });

  group('ChargingLogCard — title (stationName + fallback)', () {
    testWidgets('uses stationName when non-empty', (tester) async {
      await pumpApp(
        tester,
        ChargingLogCard(log: _log(stationName: 'Ionity Castelnau')),
      );
      expect(find.text('Ionity Castelnau'), findsOneWidget);
    });

    testWidgets('falls back to localized "Station (optional)" when stationName is null',
        (tester) async {
      await pumpApp(
        tester,
        ChargingLogCard(log: _log(stationName: null)),
      );
      // pumpApp installs AppLocalizations (en) so the localized string
      // wins over the hard-coded 'Station' default.
      expect(find.text('Station (optional)'), findsOneWidget);
    });

    testWidgets('falls back when stationName is whitespace only',
        (tester) async {
      await pumpApp(
        tester,
        ChargingLogCard(log: _log(stationName: '   ')),
      );
      expect(find.text('Station (optional)'), findsOneWidget);
    });

    testWidgets('falls back when stationName is empty string', (tester) async {
      await pumpApp(
        tester,
        ChargingLogCard(log: _log(stationName: '')),
      );
      expect(find.text('Station (optional)'), findsOneWidget);
    });
  });

  group('ChargingLogCard — subtitle formatting', () {
    testWidgets('formats date as YYYY-MM-DD with zero-padding',
        (tester) async {
      await pumpApp(
        tester,
        ChargingLogCard(log: _log(date: DateTime(2026, 4, 5))),
      );
      // Single-digit month + day must zero-pad → 2026-04-05.
      expect(find.textContaining('2026-04-05'), findsOneWidget);
    });

    testWidgets('renders kWh with one decimal, cost with two, and time',
        (tester) async {
      await pumpApp(
        tester,
        ChargingLogCard(
          log: _log(
            date: DateTime(2026, 4, 25),
            kWh: 22.5,
            costEur: 7.85,
            chargeTimeMin: 35,
          ),
        ),
      );
      expect(
        find.text('2026-04-25  •  22.5 kWh  •  7.85 €  •  35 min'),
        findsOneWidget,
      );
    });

    testWidgets('rounds kWh to one decimal and pads cost to two decimals',
        (tester) async {
      await pumpApp(
        tester,
        ChargingLogCard(
          log: _log(
            date: DateTime(2026, 4, 25),
            kWh: 22.47,
            costEur: 7.8,
            chargeTimeMin: 12,
          ),
        ),
      );
      // 22.47 → 22.5 via toStringAsFixed(1); 7.8 → 7.80 via toStringAsFixed(2).
      expect(
        find.text('2026-04-25  •  22.5 kWh  •  7.80 €  •  12 min'),
        findsOneWidget,
      );
    });
  });

  group('ChargingLogCard — trailing odometer', () {
    testWidgets('renders odometer as "{km} km"', (tester) async {
      await pumpApp(
        tester,
        ChargingLogCard(log: _log(odometerKm: 12345)),
      );
      expect(find.text('12345 km'), findsOneWidget);
    });
  });

  group('ChargingLogCard — accessibility', () {
    testWidgets('exposes a merged Semantics label combining title + subtitle',
        (tester) async {
      await pumpApp(
        tester,
        ChargingLogCard(
          log: _log(
            stationName: 'Ionity Castelnau',
            date: DateTime(2026, 4, 25),
            kWh: 22.5,
            costEur: 7.85,
            chargeTimeMin: 35,
          ),
        ),
      );
      const expectedLabel =
          'Ionity Castelnau, 2026-04-25  •  22.5 kWh  •  7.85 €  •  35 min';
      expect(
        find.bySemanticsLabel(expectedLabel),
        findsOneWidget,
      );
    });
  });
}
