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
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../helpers/pump_app.dart';

/// #889 — the ConsumptionScreen grows a Trajets tab between Fuel and
/// Charging, and each row taps through to `/trip/:id`. These tests
/// verify tab rendering, the empty-state CTA, the newest-first sort,
/// and the navigation target of the row tap.

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
  final router = GoRouter(
    initialLocation: '/consumption',
    routes: [
      GoRoute(
        path: '/consumption',
        builder: (_, _) => const ConsumptionScreen(),
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
    MaterialApp.router(routerConfig: router),
    overrides: [
      fillUpListProvider.overrideWith(() => _FixedFillUpList(fillUps)),
      chargingLogsProvider.overrideWith(() => _FixedChargingLogs(chargingLogs)),
      activeVehicleProfileProvider
          .overrideWith(() => _FixedActiveVehicle(activeVehicle)),
      vehicleProfileListProvider
          .overrideWith(() => _FixedVehicleProfileList(vehicles)),
      tripHistoryListProvider
          .overrideWith(() => _FixedTripHistoryList(trips)),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConsumptionScreen Trajets tab (#889)', () {
    const vehicle = VehicleProfile(
      id: 'v1',
      name: 'Test vehicle',
      type: VehicleType.hybrid,
    );

    testWidgets('tab row has Fuel, Trajets, and Charging', (tester) async {
      await _pumpScreen(
        tester,
        activeVehicle: vehicle,
        vehicles: [vehicle],
      );
      // #923 phase 3a — the canonical `TabSwitcher` has no key-per-tab
      // contract, so we assert on the localised label text for each
      // tab entry instead.
      expect(find.text('Fuel'), findsOneWidget);
      expect(find.text('Trips'), findsOneWidget);
      expect(find.text('Charging'), findsOneWidget);
    });

    testWidgets('Trajets empty state renders CTA + "Start recording" button',
        (tester) async {
      await _pumpScreen(
        tester,
        activeVehicle: vehicle,
        vehicles: [vehicle],
      );
      await tester.tap(find.text('Trips'));
      await tester.pumpAndSettle();

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
      await tester.tap(find.text('Trips'));
      await tester.pumpAndSettle();

      // Every trip should render a row.
      expect(find.byKey(const ValueKey('trajet-2026-04-20T09:00:00.000Z')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('trajet-2026-04-21T09:00:00.000Z')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('trajet-2026-04-22T09:00:00.000Z')),
          findsOneWidget);

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
      expect(newestY, lessThan(oldestY),
          reason: 'Newest trip should appear above the oldest');
    });

    testWidgets('tap row navigates to /trip/:id with the correct id',
        (tester) async {
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
      await tester.tap(find.text('Trips'));
      await tester.pumpAndSettle();

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
}
