// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/gps_road_usage_card.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/throttle_rpm_histogram_card.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_detail_body.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_detail_charts.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_summary_card.dart';
import 'package:tankstellen/features/profile/providers/gamification_enabled_provider.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';

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

TripDetailSample _sampleWithEngineLoad(int sec, double speed, double load) =>
    TripDetailSample(
      timestamp: DateTime.utc(2026, 4, 22, 10, 0, sec),
      speedKmh: speed,
      engineLoadPercent: load,
    );

TripDetailSample _sampleWithFuelRate(int sec, double speed, double fuelRate) =>
    TripDetailSample(
      timestamp: DateTime.utc(2026, 4, 22, 10, 0, sec),
      speedKmh: speed,
      fuelRateLPerHour: fuelRate,
    );

TripDetailSample _sampleWithEstimatedFuelRate(
        int sec, double speed, double estimate) =>
    TripDetailSample(
      timestamp: DateTime.utc(2026, 4, 22, 10, 0, sec),
      speedKmh: speed,
      estimatedFuelRateLPerHour: estimate,
    );

/// Default overrides for [TripDetailBody] tests. Now that the body
/// reads [gamificationEnabledProvider] (#1194), every test must seed a
/// value so the underlying active-profile chain isn't traversed (those
/// tests don't set up Hive).
final List<Object> _defaultOverrides = [
  gamificationEnabledProvider.overrideWithValue(true),
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
    // #1895 — the per-trip charts now live inside a collapsible
    // [ExpansionTile] that is collapsed by default, so their widgets
    // are offstage on first frame. `maintainState: true` keeps them in
    // the tree regardless of fold state, so `skipOffstage: false`
    // asserts on mounting (the share-to-PNG boundary relies on this).
    testWidgets('mounts the summary card and the speed + fuel-rate charts',
        (tester) async {
      await _pump(
        tester,
        TripDetailBody(
          entry: _entry(),
          vehicle: _vehicle,
          // #2490 — the fuel-rate section is now gated on having at least
          // one measured/estimated fuel-rate sample, so seed one.
          samples: [_sampleWithFuelRate(0, 30, 4.2)],
          isEv: false,
        ),
      );

      expect(find.byType(TripSummaryCard), findsOneWidget);
      expect(find.byType(TripDetailSpeedChart, skipOffstage: false),
          findsOneWidget);
      expect(find.byType(TripDetailFuelRateChart, skipOffstage: false),
          findsOneWidget);
    });

    testWidgets('renders the localized speed and fuel-rate section titles',
        (tester) async {
      await _pump(
        tester,
        TripDetailBody(
          entry: _entry(),
          vehicle: _vehicle,
          samples: [_sampleWithFuelRate(0, 30, 4.2)],
          isEv: false,
        ),
      );

      // English locale (pumpApp default) — section titles come from ARB.
      expect(find.text('Speed (km/h)', skipOffstage: false), findsOneWidget);
      expect(
          find.text('Fuel rate (L/h)', skipOffstage: false), findsOneWidget);
    });
  });

  // #1895 — the charts are grouped under one [ExpansionTile], collapsed
  // by default so the trip summary + insight cards stay the focus.
  group('TripDetailBody — charts fold (#1895)', () {
    testWidgets('charts are collapsed (offstage) by default', (tester) async {
      await _pump(
        tester,
        TripDetailBody(
          entry: _entry(),
          vehicle: _vehicle,
          samples: const [],
          isEv: false,
        ),
      );

      // The collapsible section header is on screen...
      expect(find.text('Charts'), findsOneWidget);
      // ...but the charts themselves are folded away (offstage).
      expect(find.byType(TripDetailSpeedChart), findsNothing);
      expect(find.byType(TripDetailSpeedChart, skipOffstage: false),
          findsOneWidget);
    });

    testWidgets('tapping the section header reveals the charts',
        (tester) async {
      await _pump(
        tester,
        TripDetailBody(
          entry: _entry(),
          vehicle: _vehicle,
          // #2490 — seed a fuel-rate sample so the (now-gated) fuel-rate
          // section is present to reveal.
          samples: [_sampleWithFuelRate(0, 30, 4.2)],
          isEv: false,
        ),
      );

      await tester.ensureVisible(find.text('Charts'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Charts'));
      await tester.pumpAndSettle();

      expect(find.byType(TripDetailSpeedChart), findsOneWidget);
      expect(find.byType(TripDetailFuelRateChart), findsOneWidget);
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

      // #1895 — charts live in a collapsed ExpansionTile; assert on
      // mounting with skipOffstage so the gating logic is what's tested.
      expect(find.byType(TripDetailRpmChart, skipOffstage: false),
          findsOneWidget);
      expect(find.text('RPM', skipOffstage: false), findsOneWidget);
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

  // #1262 phase 3 — engine-load sparkline. Mirrors the RPM-section
  // gating: cars without PID 0x04 emit null engineLoadPercent on every
  // sample, and the body silently drops the section header rather than
  // rendering an empty card. The section title comes from the new
  // `trajetDetailChartEngineLoad` ARB key.
  group('TripDetailBody — engine-load section visibility', () {
    testWidgets('mounts the engine-load chart when at least one sample has it',
        (tester) async {
      await _pump(
        tester,
        TripDetailBody(
          entry: _entry(),
          vehicle: _vehicle,
          samples: [
            _sampleNoRpm(0, 30),
            _sampleWithEngineLoad(1, 35, 42),
            _sampleNoRpm(2, 40),
          ],
          isEv: false,
        ),
      );

      // #1895 — charts live in a collapsed ExpansionTile; assert on
      // mounting with skipOffstage so the gating logic is what's tested.
      expect(find.byType(TripDetailEngineLoadChart, skipOffstage: false),
          findsOneWidget);
      expect(
          find.text('Engine load (%)', skipOffstage: false), findsOneWidget);
    });

    testWidgets(
        'hides the engine-load chart when every sample has null engineLoad',
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

      expect(find.byType(TripDetailEngineLoadChart), findsNothing);
      expect(find.text('Engine load (%)'), findsNothing);
    });

    testWidgets('hides the engine-load chart when samples is empty',
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

      expect(find.byType(TripDetailEngineLoadChart), findsNothing);
      expect(find.text('Engine load (%)'), findsNothing);
    });
  });

  // #2490 — the fuel-rate section used to render UNGATED, so a trip with
  // no measured/estimated fuel-rate data (a GPS-only or no-fuel-PID trip)
  // showed an empty 140-px "Keine Messwerte" card. It now follows the same
  // gating rule as RPM / engine-load: hidden entirely when no sample
  // carries a measured OR estimated fuel rate.
  group('TripDetailBody — fuel-rate section visibility', () {
    testWidgets('mounts the fuel-rate chart when a measured sample exists',
        (tester) async {
      await _pump(
        tester,
        TripDetailBody(
          entry: _entry(),
          vehicle: _vehicle,
          samples: [
            _sampleNoRpm(0, 30),
            _sampleWithFuelRate(1, 35, 4.2),
            _sampleNoRpm(2, 40),
          ],
          isEv: false,
        ),
      );

      expect(find.byType(TripDetailFuelRateChart, skipOffstage: false),
          findsOneWidget);
      expect(find.text('Fuel rate (L/h)', skipOffstage: false),
          findsOneWidget);
    });

    testWidgets(
        'mounts the fuel-rate chart when only an ESTIMATED sample exists',
        (tester) async {
      // GPS-physics estimate (#2431) with no measured PID — the section
      // still renders because the chart plots the estimated series.
      await _pump(
        tester,
        TripDetailBody(
          entry: _entry(),
          vehicle: _vehicle,
          samples: [
            _sampleNoRpm(0, 30),
            _sampleWithEstimatedFuelRate(1, 35, 3.1),
          ],
          isEv: false,
        ),
      );

      expect(find.byType(TripDetailFuelRateChart, skipOffstage: false),
          findsOneWidget);
      expect(find.text('Fuel rate (L/h)', skipOffstage: false),
          findsOneWidget);
    });

    testWidgets(
        'hides the fuel-rate chart when no sample carries a measured or '
        'estimated fuel rate', (tester) async {
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

      expect(find.byType(TripDetailFuelRateChart, skipOffstage: false),
          findsNothing);
      expect(find.text('Fuel rate (L/h)', skipOffstage: false), findsNothing);
    });

    testWidgets('hides the fuel-rate chart when samples is empty',
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

      expect(find.byType(TripDetailFuelRateChart, skipOffstage: false),
          findsNothing);
      expect(find.text('Fuel rate (L/h)', skipOffstage: false), findsNothing);
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
          // #2490 — include a fuel-rate sample so the (now-gated)
          // fuel-rate section renders and the ordering check below
          // (speed < fuel < rpm) has all three sections present.
          samples: [
            TripDetailSample(
              timestamp: DateTime.utc(2026, 4, 22, 10, 0, 0),
              speedKmh: 30,
              rpm: 1500.0,
              fuelRateLPerHour: 4.0,
            ),
            TripDetailSample(
              timestamp: DateTime.utc(2026, 4, 22, 10, 0, 1),
              speedKmh: 35,
              rpm: 1700.0,
              fuelRateLPerHour: 4.5,
            ),
          ],
          isEv: false,
        ),
      );

      // #1895 — expand the collapsible charts section so the chart
      // widgets are laid out and `getTopLeft` returns real positions.
      // ensureVisible first: with insight cards present the section
      // header can sit below the 600-px test-surface fold.
      await tester.ensureVisible(find.text('Charts'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Charts'));
      await tester.pumpAndSettle();

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

  // #2796 C7 — the throttle/RPM histogram is now gated to OBD2/engine-signal
  // trips only. A GPS-only trip (no sample carries RPM) instead gets the
  // speed-only "how you used the road" panel where the engine card would sit.
  group('TripDetailBody — throttle card gated to OBD2, road-use for GPS-only',
      () {
    testWidgets(
        'shows the throttle/RPM card and NOT the road-use panel when a sample '
        'carries RPM (OBD2 trip)', (tester) async {
      await _pump(
        tester,
        TripDetailBody(
          entry: _entry(),
          vehicle: _vehicle,
          samples: [
            _sampleWithRpm(0, 30, 1500.0),
            _sampleWithRpm(1, 35, 1700.0),
            _sampleWithRpm(2, 40, 1900.0),
          ],
          isEv: false,
        ),
      );

      expect(find.byType(ThrottleRpmHistogramCard), findsOneWidget);
      expect(find.byType(GpsRoadUsageCard), findsNothing);
    });

    testWidgets(
        'hides the throttle/RPM card and shows the road-use panel when NO '
        'sample carries RPM (GPS-only trip)', (tester) async {
      await _pump(
        tester,
        TripDetailBody(
          entry: _entry(),
          vehicle: _vehicle,
          // GPS-only: speed track, no engine RPM on any sample, enough
          // samples for GpsDrivingFeatures.from to produce an aggregate.
          samples: [
            _sampleNoRpm(0, 20),
            _sampleNoRpm(1, 35),
            _sampleNoRpm(2, 50),
            _sampleNoRpm(3, 45),
          ],
          isEv: false,
        ),
      );

      expect(find.byType(ThrottleRpmHistogramCard), findsNothing);
      expect(find.byType(GpsRoadUsageCard), findsOneWidget);
      expect(find.text('How you used the road'), findsOneWidget);
    });

    testWidgets('hides BOTH cards for an EV trip', (tester) async {
      await _pump(
        tester,
        TripDetailBody(
          entry: _entry(),
          vehicle: _vehicle,
          samples: [
            _sampleNoRpm(0, 20),
            _sampleNoRpm(1, 35),
            _sampleNoRpm(2, 50),
          ],
          isEv: true,
        ),
      );

      expect(find.byType(ThrottleRpmHistogramCard), findsNothing);
      expect(find.byType(GpsRoadUsageCard), findsNothing);
    });
  });

  group('TripDetailBody — EV mode', () {
    testWidgets('still mounts speed and fuel-rate sections when isEv is true',
        (tester) async {
      // The body doesn't gate the speed/fuel-rate charts on isEv — it
      // only forwards the flag to the summary card. This guards against a
      // future change accidentally hiding those charts on EV trips. #2490
      // — the fuel-rate section is gated on fuel-rate data presence (not
      // on isEv), so seed a fuel-rate sample.
      await _pump(
        tester,
        TripDetailBody(
          entry: _entry(),
          vehicle: _vehicle,
          samples: [_sampleWithFuelRate(0, 30, 3.5)],
          isEv: true,
        ),
      );

      expect(find.byType(TripSummaryCard), findsOneWidget);
      expect(find.byType(TripDetailSpeedChart, skipOffstage: false),
          findsOneWidget);
      expect(find.byType(TripDetailFuelRateChart, skipOffstage: false),
          findsOneWidget);
    });
  });
}
