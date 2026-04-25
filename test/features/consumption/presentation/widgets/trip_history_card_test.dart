import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_history_card.dart';

import '../../../../helpers/pump_app.dart';

/// Builds a [TripHistoryEntry] with sensible defaults so each test
/// only spells out the field it cares about. Mirrors the shape the
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

void main() {
  group('TripHistoryCard — always-rendered fields', () {
    testWidgets('renders the route leading icon', (tester) async {
      await pumpApp(
        tester,
        TripHistoryCard(entry: _entry()),
      );
      // The leading slot uses Icons.route; the chip row also uses
      // Icons.route for the distance chip, so we expect at least
      // two occurrences (leading + chip).
      expect(find.byIcon(Icons.route), findsNWidgets(2));
    });

    testWidgets('renders the distance chip with one-decimal formatting',
        (tester) async {
      await pumpApp(
        tester,
        TripHistoryCard(entry: _entry(distanceKm: 12.3)),
      );
      expect(find.text('12.3 km'), findsOneWidget);
    });

    testWidgets('rounds distance to one decimal place', (tester) async {
      await pumpApp(
        tester,
        TripHistoryCard(entry: _entry(distanceKm: 12.37)),
      );
      // 12.37 → 12.4 via toStringAsFixed(1)
      expect(find.text('12.4 km'), findsOneWidget);
    });
  });

  group('TripHistoryCard — title rendering', () {
    testWidgets('falls back to "Unknown date" when startedAt is null',
        (tester) async {
      await pumpApp(
        tester,
        TripHistoryCard(entry: _entry(startedAt: null)),
      );
      expect(find.text('Unknown date'), findsOneWidget);
    });

    testWidgets('formats startedAt as YYYY-MM-DD HH:mm', (tester) async {
      await pumpApp(
        tester,
        TripHistoryCard(
          entry: _entry(startedAt: DateTime(2026, 4, 25, 14, 30)),
        ),
      );
      expect(find.text('2026-04-25 14:30'), findsOneWidget);
    });

    testWidgets('zero-pads single-digit month/day/hour/minute',
        (tester) async {
      await pumpApp(
        tester,
        TripHistoryCard(
          entry: _entry(startedAt: DateTime(2026, 1, 2, 3, 4)),
        ),
      );
      expect(find.text('2026-01-02 03:04'), findsOneWidget);
    });
  });

  group('TripHistoryCard — avg L/100km chip', () {
    testWidgets('renders chip when avgLPer100Km is set', (tester) async {
      await pumpApp(
        tester,
        TripHistoryCard(entry: _entry(avgLPer100Km: 6.4)),
      );
      expect(find.text('6.4 L/100km'), findsOneWidget);
      expect(find.byIcon(Icons.eco), findsOneWidget);
    });

    testWidgets('hides chip when avgLPer100Km is null', (tester) async {
      await pumpApp(
        tester,
        TripHistoryCard(entry: _entry(avgLPer100Km: null)),
      );
      expect(find.byIcon(Icons.eco), findsNothing);
      expect(find.textContaining('L/100km'), findsNothing);
    });
  });

  group('TripHistoryCard — duration chip', () {
    testWidgets('hides chip when there is no duration (no endedAt)',
        (tester) async {
      await pumpApp(
        tester,
        TripHistoryCard(
          entry: _entry(
            startedAt: DateTime(2026, 4, 25, 14, 0),
            endedAt: null,
          ),
        ),
      );
      expect(find.byIcon(Icons.timer), findsNothing);
    });

    testWidgets('hides chip when duration is zero seconds', (tester) async {
      final t = DateTime(2026, 4, 25, 14, 0);
      await pumpApp(
        tester,
        TripHistoryCard(
          entry: _entry(startedAt: t, endedAt: t),
        ),
      );
      expect(find.byIcon(Icons.timer), findsNothing);
    });

    testWidgets('formats sub-hour duration as "Xm" only', (tester) async {
      await pumpApp(
        tester,
        TripHistoryCard(
          entry: _entry(
            startedAt: DateTime(2026, 4, 25, 14, 0),
            endedAt: DateTime(2026, 4, 25, 14, 25),
          ),
        ),
      );
      expect(find.text('25m'), findsOneWidget);
      expect(find.byIcon(Icons.timer), findsOneWidget);
    });

    testWidgets('formats multi-hour duration as "Xh Ym"', (tester) async {
      await pumpApp(
        tester,
        TripHistoryCard(
          entry: _entry(
            startedAt: DateTime(2026, 4, 25, 14, 0),
            endedAt: DateTime(2026, 4, 25, 16, 15),
          ),
        ),
      );
      expect(find.text('2h 15m'), findsOneWidget);
    });
  });

  group('TripHistoryCard — harsh events chip', () {
    testWidgets('hides chip when harsh totals are zero', (tester) async {
      await pumpApp(
        tester,
        TripHistoryCard(
          entry: _entry(harshBrakes: 0, harshAccelerations: 0),
        ),
      );
      expect(find.byIcon(Icons.warning_amber), findsNothing);
    });

    testWidgets('renders chip with summed total when > 0', (tester) async {
      await pumpApp(
        tester,
        TripHistoryCard(
          entry: _entry(harshBrakes: 2, harshAccelerations: 3),
        ),
      );
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('uses error color for warning chip', (tester) async {
      await pumpApp(
        tester,
        TripHistoryCard(
          entry: _entry(harshBrakes: 1, harshAccelerations: 0),
        ),
      );
      // Locate the Icon widget for the warning chip and assert it
      // uses the theme's error color (the chip's "warning" branch).
      final warnIcon =
          tester.widget<Icon>(find.byIcon(Icons.warning_amber));
      final BuildContext ctx = tester.element(find.byType(TripHistoryCard));
      expect(warnIcon.color, Theme.of(ctx).colorScheme.error);
    });
  });
}
