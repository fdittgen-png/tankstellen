// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/presentation/screens/consumption_screen.dart';
import 'package:tankstellen/features/consumption/providers/charging_logs_provider.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/consumption/providers/trip_history_provider.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_log.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../helpers/pump_app.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #889 / #1901 — the Trajets surface (OBD2 trip history).
///
/// #1901 — Trajets is no longer a tab of [ConsumptionScreen]; it is
/// its own bottom-bar destination, reached by pumping the screen with
/// `section: ConsumptionSection.trajets`. The screen renders
/// [TrajetsTab] directly — no in-screen tab bar. #2494 — the
/// "Start / Resume recording" CTA floats in the Scaffold FAB slot
/// (`TrajetsRecordFab`), matching the Carburant tab's add-fill-up FAB.
///
/// These tests verify the empty-state CTA, the newest-first sort, and
/// the navigation target of a row tap. Whether the Trajets destination
/// is *visible at all* is a shell-level concern gated by `showTrajets`
/// in `resolveShellDestinations` — see `shell_destinations_test.dart`
/// and `shell_nav_vehicle_gating_test.dart`; #1901 moved that gate out
/// of this screen, so the per-flag tab-gating tests that used to live
/// here were dropped.

/// Enables the consumption surface. The Trajets section renders its
/// trip list regardless of flags now (#1901) — visibility gating
/// moved to the shell — but a feature-flag override keeps the pump
/// path identical to the rest of the suite.
class _ObdEnabledFlags extends FeatureFlags {
  @override
  Set<Feature> build() => <Feature>{
    Feature.showConsumptionTab,
    Feature.obd2TripRecording,
  };
}

class _FixedFillUpList extends FillUpList {
  final List<FillUp> _value;
  _FixedFillUpList(this._value);

  @override
  List<FillUp> build() => _value;
}

class _FixedChargingLogs extends ChargingLogs {
  final List<ChargingLog> _value;
  _FixedChargingLogs(this._value);

  @override
  Future<List<ChargingLog>> build() async => _value;
}

class _FixedActiveVehicle extends ActiveVehicleProfile {
  final VehicleProfile? _value;
  _FixedActiveVehicle(this._value);

  @override
  VehicleProfile? build() => _value;
}

class _FixedVehicleProfileList extends VehicleProfileList {
  final List<VehicleProfile> _value;
  _FixedVehicleProfileList(this._value);

  @override
  List<VehicleProfile> build() => _value;
}

class _FixedTripHistoryList extends TripHistoryList {
  final List<TripHistoryEntry> _value;
  _FixedTripHistoryList(this._value);

  @override
  List<TripHistoryEntry> build() => _value;
}

/// Build a [TripHistoryEntry] with a minimal [TripSummary].
TripHistoryEntry _entry({
  required String id,
  required String vehicleId,
  required DateTime startedAt,
  DateTime? endedAt,
  double distanceKm = 0.0,
  double? avgLPer100Km,
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
      avgLPer100Km: avgLPer100Km,
      startedAt: startedAt,
      endedAt: endedAt ?? startedAt.add(const Duration(minutes: 30)),
    ),
  );
}

// Tracks which trip id the router landed on via `/trip/:id`, so the
// row-tap test can assert on the exact path segment.
String? _lastTripIdVisited;

Future<void> _pumpScreen(
  WidgetTester tester, {
  List<FillUp> fillUps = const [],
  List<ChargingLog> chargingLogs = const [],
  List<TripHistoryEntry> trips = const [],
  VehicleProfile? activeVehicle,
  List<VehicleProfile> vehicles = const [],
}) async {
  _lastTripIdVisited = null;
  // #1901 — pump the Trajets *section* of ConsumptionScreen directly;
  // it is its own bottom-bar destination now, not a tab.
  final router = GoRouter(
    initialLocation: '/trajets-tab',
    routes: [
      GoRoute(
        path: '/trajets-tab',
        builder: (_, _) =>
            const ConsumptionScreen(section: ConsumptionSection.trajets),
      ),
      GoRoute(path: '/consumption/add', builder: (_, _) => const SizedBox()),
      GoRoute(
        path: '/consumption/pick-station',
        builder: (_, _) => const SizedBox(),
      ),
      GoRoute(path: '/carbon', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/trip-history', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/vehicles/edit', builder: (_, _) => const SizedBox()),
      GoRoute(
        path: '/trip/:id',
        builder: (_, state) {
          _lastTripIdVisited = state.pathParameters['id'];
          return const Scaffold(body: Text('TripDetailStub'));
        },
      ),
    ],
  );

  await pumpApp(
    tester,
    MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
    overrides: [
      fillUpListProvider.overrideWith(() => _FixedFillUpList(fillUps)),
      chargingLogsProvider.overrideWith(() => _FixedChargingLogs(chargingLogs)),
      activeVehicleProfileProvider.overrideWith(
        () => _FixedActiveVehicle(activeVehicle),
      ),
      vehicleProfileListProvider.overrideWith(
        () => _FixedVehicleProfileList(vehicles),
      ),
      tripHistoryListProvider.overrideWith(() => _FixedTripHistoryList(trips)),
      featureFlagsProvider.overrideWith(() => _ObdEnabledFlags()),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // #1901 — the `tab row has Fuel, Trajets, and Charging` test was
  // dropped: its whole point was the in-screen 3-tab ordering, which
  // no longer exists. Trajets is now a standalone destination and the
  // Fuel/Charging switcher is covered by the charging-tab tests.

  group('ConsumptionScreen Trajets section (#889 / #1901)', () {
    const vehicle = VehicleProfile(
      id: 'v1',
      name: 'Test vehicle',
      type: VehicleType.hybrid,
    );

    testWidgets('renders the Trajets section directly — no tab bar, no FAB', (
      tester,
    ) async {
      await _pumpScreen(tester, activeVehicle: vehicle, vehicles: [vehicle]);
      // #1901 — the Trajets destination has no in-screen TabSwitcher
      // and no screen-level FAB (the "Start recording" CTA lives in
      // the tab header).
      expect(find.byType(Tab), findsNothing);
      expect(find.byKey(const Key('fab_add_fillup')), findsNothing);
      expect(find.byKey(const Key('fab_add_charging')), findsNothing);
    });

    testWidgets('Trajets empty state renders CTA + "Start recording" button', (
      tester,
    ) async {
      await _pumpScreen(tester, activeVehicle: vehicle, vehicles: [vehicle]);

      expect(find.byKey(const Key('trajets_empty_state')), findsOneWidget);
      expect(
        find.byKey(const Key('trajets_start_recording_button')),
        findsOneWidget,
      );
      // English button label.
      expect(find.text('Start recording'), findsOneWidget);
      // Empty-state title is also on-screen.
      expect(find.textContaining('No trips yet'), findsOneWidget);
    });

    testWidgets('seeded trips render newest-first', (tester) async {
      // Seed 3 trips for the same vehicle, spaced a day apart. Provide
      // them in *oldest-first* order so the Trajets tab has to do the
      // sort itself — otherwise the test could pass accidentally.
      final trips = <TripHistoryEntry>[
        _entry(
          id: '2026-04-20T09:00:00.000Z',
          vehicleId: 'v1',
          startedAt: DateTime.utc(2026, 4, 20, 9),
          distanceKm: 10.0,
        ),
        _entry(
          id: '2026-04-21T09:00:00.000Z',
          vehicleId: 'v1',
          startedAt: DateTime.utc(2026, 4, 21, 9),
          distanceKm: 20.0,
        ),
        _entry(
          id: '2026-04-22T09:00:00.000Z',
          vehicleId: 'v1',
          startedAt: DateTime.utc(2026, 4, 22, 9),
          distanceKm: 30.0,
        ),
      ];
      // Tall viewport so every row renders without ListView culling.
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpScreen(
        tester,
        trips: trips,
        activeVehicle: vehicle,
        vehicles: [vehicle],
      );

      // Every trip should render a row.
      expect(
        find.byKey(const ValueKey('trajet-2026-04-20T09:00:00.000Z')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('trajet-2026-04-21T09:00:00.000Z')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('trajet-2026-04-22T09:00:00.000Z')),
        findsOneWidget,
      );

      // Newest-first: the April 22nd row must sit above April 20th.
      final newestY = tester
          .getTopLeft(
            find.byKey(const ValueKey('trajet-2026-04-22T09:00:00.000Z')),
          )
          .dy;
      final oldestY = tester
          .getTopLeft(
            find.byKey(const ValueKey('trajet-2026-04-20T09:00:00.000Z')),
          )
          .dy;
      expect(
        newestY,
        lessThan(oldestY),
        reason: 'Newest trip should appear above the oldest',
      );
    });

    testWidgets('tap row navigates to /trip/:id with the correct id', (
      tester,
    ) async {
      final trips = <TripHistoryEntry>[
        _entry(
          id: '2026-04-22T09:00:00.000Z',
          vehicleId: 'v1',
          startedAt: DateTime.utc(2026, 4, 22, 9),
          distanceKm: 25.0,
        ),
      ];
      await _pumpScreen(
        tester,
        trips: trips,
        activeVehicle: vehicle,
        vehicles: [vehicle],
      );

      // Sanity — before tap, the detail stub hasn't been visited.
      expect(_lastTripIdVisited, isNull);

      await tester.tap(
        find.byKey(const ValueKey('trajet-2026-04-22T09:00:00.000Z')),
      );
      await tester.pumpAndSettle();

      expect(_lastTripIdVisited, equals('2026-04-22T09:00:00.000Z'));
      expect(find.text('TripDetailStub'), findsOneWidget);
    });
  });

  // #1901 — the two former gating groups (Trajets tab hidden when
  // obd2TripRecording is off; Trajets gated on ConsoMode #1573) were
  // dropped. Trajets is no longer a tab of this screen, so its
  // visibility is decided by the shell (`resolveShellDestinations`'s
  // `showTrajets` flag) rather than by ConsumptionScreen. That gate is
  // covered by `test/app/shell/shell_destinations_test.dart` and
  // `test/app/shell_nav_vehicle_gating_test.dart`.

  // #2374 — "View all on map" moved from a standalone full-width
  // TextButton.icon row in TrajetsTab into the Trajets AppBar as an
  // IconButton, placed immediately before the download (↓) action.
  group('ConsumptionScreen Trajets — map AppBar action (#2374)', () {
    const vehicle = VehicleProfile(
      id: 'v1',
      name: 'Test vehicle',
      type: VehicleType.combustion,
    );

    testWidgets('map IconButton is present in the AppBar when trips exist', (
      tester,
    ) async {
      final trips = <TripHistoryEntry>[
        _entry(
          id: 'trip-1',
          vehicleId: 'v1',
          startedAt: DateTime.utc(2026, 4, 22, 9),
          distanceKm: 10.0,
        ),
      ];

      await _pumpScreen(
        tester,
        trips: trips,
        activeVehicle: vehicle,
        vehicles: [vehicle],
      );

      // The AppBar map IconButton carries the localized tooltip and
      // the map_outlined icon.
      expect(find.byKey(const Key('trajets_view_all_on_map')), findsOneWidget);
      final btn = tester.widget<IconButton>(
        find.byKey(const Key('trajets_view_all_on_map')),
      );
      expect(btn.tooltip, 'View all on map');
      expect(
        find.descendant(
          of: find.byKey(const Key('trajets_view_all_on_map')),
          matching: find.byIcon(Icons.map_outlined),
        ),
        findsOneWidget,
      );
    });

    testWidgets('map IconButton is present even with an empty trip list', (
      tester,
    ) async {
      await _pumpScreen(tester, activeVehicle: vehicle, vehicles: [vehicle]);

      // The button is always present (empty tripIds list is valid for
      // TrajetsMapScreen — it renders its own empty state).
      expect(find.byKey(const Key('trajets_view_all_on_map')), findsOneWidget);
    });

    testWidgets('standalone TextButton.icon row is absent from the body', (
      tester,
    ) async {
      final trips = <TripHistoryEntry>[
        _entry(
          id: 'trip-2',
          vehicleId: 'v1',
          startedAt: DateTime.utc(2026, 4, 22, 9),
          distanceKm: 5.0,
        ),
      ];
      await _pumpScreen(
        tester,
        trips: trips,
        activeVehicle: vehicle,
        vehicles: [vehicle],
      );

      // Pre-#2374 there was a TextButton.icon with this key in the
      // body scroll area; it must be gone now.
      expect(find.byType(TextButton), findsNothing);
    });
  });
}
