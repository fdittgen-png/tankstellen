import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_detail_body.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_detail_charts.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_summary_card.dart';
import 'package:tankstellen/features/profile/providers/gamification_enabled_provider.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';

import '../../../../helpers/pump_app.dart';

/// #561 — widget coverage for [TripDetailBody], the scrollable composition
/// that wires the summary card together with the speed / fuel-rate / RPM
/// charts on the trip detail screen.
///
/// The body is a pure StatelessWidget — no Riverpod, no async — so these
/// tests pump it directly inside [pumpApp] and assert on widget presence,
/// the conditional RPM section, and the well-known scroll key.

TripHistoryEntry _entry({
  String id = 'trip-1',
  String? vehicleId,
  double distanceKm = 12.3,
  DateTime? startedAt,
  DateTime? endedAt,
}) {
  return TripHistoryEntry(
    id: id,
    vehicleId: vehicleId,
    summary: TripSummary(
      distanceKm: distanceKm,
      maxRpm: 0,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
      startedAt: startedAt,
      endedAt: endedAt,
      distanceSource: 'virtual',
    ),
  );
}

const _vehicle = VehicleProfile(
  id: 'v1',
  name: 'Peugeot 308',
  type: VehicleType.combustion,
);

TripDetailSample _sampleNoRpm(int sec, double speed) => TripDetailSample(
      timestamp: DateTime.utc(2026, 4, 22, 10, 0, sec),
      speedKmh: speed,
    );

TripDetailSample _sampleWithRpm(int sec, double speed, double rpm) =>
    TripDetailSample(
      timestamp: DateTime.utc(2026, 4, 22, 10, 0, sec),
      speedKmh: speed,
      rpm: rpm,
    );

/// Default overrides for [TripDetailBody] tests. Now that the body
/// reads [gamificationEnabledProvider] (#1194), every test must seed a
/// value so the underlying active-profile chain isn't traversed (those
/// tests don't set up Hive).
final List<Object> _defaultOverrides = [
  gamificationEnabledProvider.overrideWith((ref) => true),
];

Future<void> _pump(WidgetTester tester, Widget body) =>
    pumpApp(tester, body, overrides: _defaultOverrides);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TripDetailBody — scroll container', () {
    testWidgets('exposes the trip_detail_scroll key on the SingleChildScrollView',
        (tester) async {
      await _pump(
        tester,
        TripDetailBody(
          entry: _entry(),
          vehicle: _vehicle,
          samples: const [],
          isEv: false,
        ),
      );

      final scrollFinder = find.byKey(const Key('trip_detail_scroll'));
      expect(scrollFinder, findsOneWidget);
      expect(
        tester.widget<SingleChildScrollView>(scrollFinder),
        isA<SingleChildScrollView>(),
      );
    });
  });

  group('TripDetailBody — always-mounted sections', () {
    testWidgets('mounts the summary card and the speed + fuel-rate charts',
        (tester) async {
      await _pump(
        tester,
        TripDetailBody(
          entry: _entry(),
          vehicle: _vehicle,
          samples: const [],
          isEv: false,
        ),
      );

      expect(find.byType(TripSummaryCard), findsOneWidget);
      expect(find.byType(TripDetailSpeedChart), findsOneWidget);
      expect(find.byType(TripDetailFuelRateChart), findsOneWidget);
    });

    testWidgets('renders the localized speed and fuel-rate section titles',
        (tester) async {
      await _pump(
        tester,
        TripDetailBody(
          entry: _entry(),
          vehicle: _vehicle,
          samples: const [],
          isEv: false,
        ),
      );

      // English locale (pumpApp default) — section titles come from ARB.
      expect(find.text('Speed (km/h)'), findsOneWidget);
      expect(find.text('Fuel rate (L/h)'), findsOneWidget);
    });
  });

  group('TripDetailBody — RPM section visibility', () {
    testWidgets('mounts the RPM chart when at least one sample has rpm',
        (tester) async {
      await _pump(
        tester,
        TripDetailBody(
          entry: _entry(),
          vehicle: _vehicle,
          samples: [
            _sampleNoRpm(0, 30),
            _sampleWithRpm(1, 35, 1800.0),
            _sampleNoRpm(2, 40),
          ],
          isEv: false,
        ),
      );

      expect(find.byType(TripDetailRpmChart), findsOneWidget);
      expect(find.text('RPM'), findsOneWidget);
    });

    testWidgets('hides the RPM chart when every sample has null rpm',
        (tester) async {
      await _pump(
        tester,
        TripDetailBody(
          entry: _entry(),
          vehicle: _vehicle,
          samples: [
            _sampleNoRpm(0, 30),
            _sampleNoRpm(1, 35),
            _sampleNoRpm(2, 40),
          ],
          isEv: false,
        ),
      );

      expect(find.byType(TripDetailRpmChart), findsNothing);
      expect(find.text('RPM'), findsNothing);
    });

    testWidgets('hides the RPM chart when samples is empty', (tester) async {
      await _pump(
        tester,
        TripDetailBody(
          entry: _entry(),
          vehicle: _vehicle,
          samples: const [],
          isEv: false,
        ),
      );

      expect(find.byType(TripDetailRpmChart), findsNothing);
      expect(find.text('RPM'), findsNothing);
    });
  });

  group('TripDetailBody — section ordering', () {
    testWidgets(
        'renders summary, speed, fuel rate, then RPM in that vertical order',
        (tester) async {
      await _pump(
        tester,
        TripDetailBody(
          entry: _entry(),
          vehicle: _vehicle,
          samples: [
            _sampleWithRpm(0, 30, 1500.0),
            _sampleWithRpm(1, 35, 1700.0),
          ],
          isEv: false,
        ),
      );

      final summaryY =
          tester.getTopLeft(find.byType(TripSummaryCard)).dy;
      final speedY =
          tester.getTopLeft(find.byType(TripDetailSpeedChart)).dy;
      final fuelY =
          tester.getTopLeft(find.byType(TripDetailFuelRateChart)).dy;
      final rpmY =
          tester.getTopLeft(find.byType(TripDetailRpmChart)).dy;

      expect(summaryY, lessThan(speedY));
      expect(speedY, lessThan(fuelY));
      expect(fuelY, lessThan(rpmY));
    });
  });

  group('TripDetailBody — EV mode', () {
    testWidgets('still mounts speed and fuel-rate sections when isEv is true',
        (tester) async {
      // The body itself doesn't gate sections on isEv — it only forwards
      // the flag to the summary card. This guards against a future change
      // accidentally hiding charts on EV trips.
      await _pump(
        tester,
        TripDetailBody(
          entry: _entry(),
          vehicle: _vehicle,
          samples: const [],
          isEv: true,
        ),
      );

      expect(find.byType(TripSummaryCard), findsOneWidget);
      expect(find.byType(TripDetailSpeedChart), findsOneWidget);
      expect(find.byType(TripDetailFuelRateChart), findsOneWidget);
    });
  });
}
