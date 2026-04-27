import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/core/widgets/empty_state.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connection_errors.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trajets_tab.dart';
import 'package:tankstellen/features/consumption/providers/trip_history_provider.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../helpers/pump_app.dart';

/// Widget tests for [TrajetsTab] (#561 zero-coverage backlog).
///
/// The tab is a thin shell over three providers:
///   * [tripHistoryListProvider] — the list of past trips.
///   * [tripRecordingProvider] — drives the Start recording CTA.
///   * [vehicleProfileListProvider] / [activeVehicleProfileProvider] —
///     looked up only to format the per-trip avg consumption unit.
///
/// We avoid the OBD2 picker/Bluetooth path entirely by overriding
/// `tripRecordingProvider` with a fake whose `startTrip()` either
/// records the call and throws a typed error (so the snackbar branch
/// fires) or returns `alreadyActive` (which would push the recording
/// screen — out of scope, see comments in the relevant test).

class _FixedTripHistoryList extends TripHistoryList {
  _FixedTripHistoryList(this._value);
  final List<TripHistoryEntry> _value;

  @override
  List<TripHistoryEntry> build() => _value;
}

class _FixedVehicleProfileList extends VehicleProfileList {
  _FixedVehicleProfileList(this._value);
  final List<VehicleProfile> _value;

  @override
  List<VehicleProfile> build() => _value;
}

class _FixedActiveVehicle extends ActiveVehicleProfile {
  _FixedActiveVehicle(this._value);
  final VehicleProfile? _value;

  @override
  VehicleProfile? build() => _value;
}

/// Records every [startTrip] call and surfaces a typed connection
/// error so the SnackBar branch in `_onStartRecording` runs without
/// having to mount the full OBD2 picker / BLE stack.
class _RecordingThrowsTripRecording extends TripRecording {
  int startTripCallCount = 0;

  @override
  TripRecordingState build() => const TripRecordingState();

  @override
  Future<StartTripOutcome> startTrip({
    String? vehicleId,
    String? adapterMac,
    Obd2Service? service,
  }) async {
    startTripCallCount++;
    // Surfacing an Obd2ScanTimeout exercises the `on Obd2ConnectionError`
    // catch arm — TrajetsTab should swallow it into a SnackBar.
    throw const Obd2ScanTimeout('No OBD2 adapter found in range');
  }
}

/// Default no-op fake — used when the test only needs to render the
/// widget and doesn't tap the CTA.
class _IdleTripRecording extends TripRecording {
  @override
  TripRecordingState build() => const TripRecordingState();

  @override
  Future<StartTripOutcome> startTrip({
    String? vehicleId,
    String? adapterMac,
    Obd2Service? service,
  }) async {
    return StartTripOutcome.alreadyActive;
  }
}

/// Builds a [TripHistoryEntry] with sensible defaults so each test
/// only spells out the fields it cares about.
TripHistoryEntry _entry({
  required String id,
  String? vehicleId,
  DateTime? startedAt,
  DateTime? endedAt,
  double distanceKm = 5.0,
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
      endedAt: endedAt,
    ),
  );
}

/// Most-recent path the router landed on via `/trip/:id`.
String? _lastTripIdVisited;

Future<void> _pumpTab(
  WidgetTester tester, {
  required String? vehicleId,
  List<TripHistoryEntry> trips = const [],
  List<VehicleProfile> vehicles = const [],
  VehicleProfile? activeVehicle,
  TripRecording Function()? recordingFactory,
}) async {
  _lastTripIdVisited = null;
  final router = GoRouter(
    initialLocation: '/trajets',
    routes: [
      GoRoute(
        path: '/trajets',
        builder: (_, _) => Scaffold(body: TrajetsTab(vehicleId: vehicleId)),
      ),
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
      tripHistoryListProvider.overrideWith(() => _FixedTripHistoryList(trips)),
      vehicleProfileListProvider
          .overrideWith(() => _FixedVehicleProfileList(vehicles)),
      activeVehicleProfileProvider
          .overrideWith(() => _FixedActiveVehicle(activeVehicle)),
      tripRecordingProvider
          .overrideWith(recordingFactory ?? () => _IdleTripRecording()),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const combustionVehicle = VehicleProfile(
    id: 'v1',
    name: 'Daily Driver',
    type: VehicleType.combustion,
  );
  const evVehicle = VehicleProfile(
    id: 'ev1',
    name: 'EV',
    type: VehicleType.ev,
  );

  group('TrajetsTab — empty list', () {
    testWidgets('renders the EmptyState with localized copy', (tester) async {
      await _pumpTab(tester, vehicleId: null, trips: const []);

      expect(find.byKey(const Key('trajets_empty_state')), findsOneWidget);
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('No trips yet'), findsOneWidget);
      expect(
        find.text('Tap Start recording to begin logging your drives.'),
        findsOneWidget,
      );
      // Header CTA still visible above the empty-state body.
      expect(
        find.byKey(const Key('trajets_start_recording_button')),
        findsOneWidget,
      );
      // ListView is the populated branch — must not render here.
      expect(find.byKey(const Key('trajets_list')), findsNothing);
      // Phase-4 monthly card is gated behind "trips exist" — empty
      // state shows the CTA only, not the card.
      expect(
        find.byKey(const ValueKey('monthly_insights_card')),
        findsNothing,
      );
    });
  });

  group('TrajetsTab — monthly insights card slot (#1041 phase 4)', () {
    testWidgets('renders the card above the trip list when trips exist',
        (tester) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final trips = [
        _entry(
          id: 'trip-x',
          vehicleId: 'v1',
          startedAt: DateTime(2026, 4, 22, 9),
          endedAt: DateTime(2026, 4, 22, 9, 30),
          distanceKm: 12.0,
        ),
      ];

      await _pumpTab(
        tester,
        vehicleId: null,
        trips: trips,
        vehicles: [combustionVehicle],
        activeVehicle: combustionVehicle,
      );

      expect(
        find.byKey(const ValueKey('monthly_insights_card')),
        findsOneWidget,
      );
      // The card carries the localized title — confirms wiring
      // through `aggregateMonthlyInsights` produced a renderable
      // summary, not a crashed widget that bailed before the title.
      expect(find.text('This month vs last month'), findsOneWidget);
    });
  });

  group('TrajetsTab — populated list', () {
    testWidgets('renders one row per trip when no vehicleId is set',
        (tester) async {
      final trips = [
        _entry(
          id: 'trip-a',
          vehicleId: 'v1',
          startedAt: DateTime(2026, 4, 22, 9),
          distanceKm: 10.0,
        ),
        _entry(
          id: 'trip-b',
          vehicleId: 'v2',
          startedAt: DateTime(2026, 4, 21, 9),
          distanceKm: 20.0,
        ),
        _entry(
          id: 'trip-c',
          vehicleId: null,
          startedAt: DateTime(2026, 4, 20, 9),
          distanceKm: 30.0,
        ),
      ];

      await _pumpTab(
        tester,
        vehicleId: null,
        trips: trips,
        vehicles: [combustionVehicle],
        activeVehicle: combustionVehicle,
      );

      expect(find.byKey(const Key('trajets_empty_state')), findsNothing);
      expect(find.byKey(const Key('trajets_list')), findsOneWidget);
      // All three rows render — null vehicleId widget keeps every trip.
      expect(find.byKey(const ValueKey('trajet-trip-a')), findsOneWidget);
      expect(find.byKey(const ValueKey('trajet-trip-b')), findsOneWidget);
      expect(find.byKey(const ValueKey('trajet-trip-c')), findsOneWidget);
    });

    testWidgets('newest-first sort is applied even on un-sorted input',
        (tester) async {
      // Seed in oldest-first order — the tab must sort by startedAt
      // descending itself.
      final trips = [
        _entry(
          id: 'trip-old',
          vehicleId: 'v1',
          startedAt: DateTime(2026, 4, 1, 9),
          distanceKm: 5.0,
        ),
        _entry(
          id: 'trip-new',
          vehicleId: 'v1',
          startedAt: DateTime(2026, 4, 22, 9),
          distanceKm: 10.0,
        ),
      ];
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpTab(
        tester,
        vehicleId: null,
        trips: trips,
        vehicles: [combustionVehicle],
        activeVehicle: combustionVehicle,
      );

      final newestY = tester
          .getTopLeft(find.byKey(const ValueKey('trajet-trip-new')))
          .dy;
      final oldestY = tester
          .getTopLeft(find.byKey(const ValueKey('trajet-trip-old')))
          .dy;
      expect(newestY, lessThan(oldestY),
          reason: 'Newest trip should appear above the oldest');
    });
  });

  group('TrajetsTab — vehicle filtering', () {
    testWidgets('drops trips whose vehicleId differs from widget.vehicleId',
        (tester) async {
      final trips = [
        // Matching vehicle — must show.
        _entry(
          id: 'trip-mine',
          vehicleId: 'v1',
          startedAt: DateTime(2026, 4, 22, 9),
        ),
        // Different vehicle — must be filtered out.
        _entry(
          id: 'trip-other',
          vehicleId: 'v2',
          startedAt: DateTime(2026, 4, 21, 9),
        ),
        // Untagged trip (no vehicleId) — must show. Pre-#889 trips
        // weren't tagged with a vehicle and should still be visible.
        _entry(
          id: 'trip-legacy',
          vehicleId: null,
          startedAt: DateTime(2026, 4, 20, 9),
        ),
      ];

      await _pumpTab(
        tester,
        vehicleId: 'v1',
        trips: trips,
        vehicles: [combustionVehicle],
        activeVehicle: combustionVehicle,
      );

      expect(find.byKey(const ValueKey('trajet-trip-mine')), findsOneWidget);
      expect(find.byKey(const ValueKey('trajet-trip-legacy')), findsOneWidget);
      expect(find.byKey(const ValueKey('trajet-trip-other')), findsNothing);
    });
  });

  group('TrajetsTab — Start recording CTA', () {
    testWidgets('renders with the localized label', (tester) async {
      await _pumpTab(tester, vehicleId: null, trips: const []);
      expect(
        find.byKey(const Key('trajets_start_recording_button')),
        findsOneWidget,
      );
      expect(find.text('Start recording'), findsOneWidget);
    });

    testWidgets('tapping the CTA invokes TripRecording.startTrip',
        (tester) async {
      final notifier = _RecordingThrowsTripRecording();
      await _pumpTab(
        tester,
        vehicleId: null,
        trips: const [],
        recordingFactory: () => notifier,
      );

      expect(notifier.startTripCallCount, 0);

      await tester.tap(
        find.byKey(const Key('trajets_start_recording_button')),
      );
      // Settle pumps the post-throw setState so `_starting` flips back
      // and the SnackBar lands.
      await tester.pumpAndSettle();

      expect(notifier.startTripCallCount, 1);
    });

    testWidgets(
        'a thrown Obd2ConnectionError surfaces a SnackBar with its message',
        (tester) async {
      await _pumpTab(
        tester,
        vehicleId: null,
        trips: const [],
        recordingFactory: () => _RecordingThrowsTripRecording(),
      );

      await tester.tap(
        find.byKey(const Key('trajets_start_recording_button')),
      );
      await tester.pump(); // schedule the future
      await tester.pump(const Duration(milliseconds: 50));

      // SnackBarHelper.showError uses a plain SnackBar with the typed
      // error's message. A long duration (5 s) is fine — we just need
      // to find it before it animates out.
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('No OBD2 adapter found in range'),
        findsOneWidget,
      );
    });
  });

  group('TrajetsTab — row tap navigation', () {
    testWidgets('tapping a trip row pushes /trip/:id with the row id',
        (tester) async {
      final trips = [
        _entry(
          id: '2026-04-22T09:00:00.000Z',
          vehicleId: 'v1',
          startedAt: DateTime.utc(2026, 4, 22, 9),
          distanceKm: 12.0,
        ),
      ];

      await _pumpTab(
        tester,
        vehicleId: null,
        trips: trips,
        vehicles: [combustionVehicle],
        activeVehicle: combustionVehicle,
      );

      expect(_lastTripIdVisited, isNull);

      await tester.tap(
        find.byKey(const ValueKey('trajet-2026-04-22T09:00:00.000Z')),
      );
      await tester.pumpAndSettle();

      expect(_lastTripIdVisited, '2026-04-22T09:00:00.000Z');
      expect(find.text('TripDetailStub'), findsOneWidget);
    });
  });

  group('TrajetsTab — per-row avg consumption unit', () {
    testWidgets('combustion vehicle renders avg as L/100 km', (tester) async {
      final trips = [
        _entry(
          id: 'trip-fuel',
          vehicleId: 'v1',
          startedAt: DateTime(2026, 4, 22, 9),
          distanceKm: 10.0,
          avgLPer100Km: 6.4,
        ),
      ];
      await _pumpTab(
        tester,
        vehicleId: null,
        trips: trips,
        vehicles: [combustionVehicle],
        activeVehicle: combustionVehicle,
      );

      expect(find.text('6.4 L/100 km'), findsOneWidget);
      expect(find.textContaining('kWh'), findsNothing);
    });

    testWidgets('EV vehicle renders avg with kWh/100 km unit', (tester) async {
      final trips = [
        _entry(
          id: 'trip-ev',
          vehicleId: 'ev1',
          startedAt: DateTime(2026, 4, 22, 9),
          distanceKm: 10.0,
          avgLPer100Km: 18.5,
        ),
      ];
      await _pumpTab(
        tester,
        vehicleId: null,
        trips: trips,
        vehicles: [evVehicle],
        activeVehicle: evVehicle,
      );

      expect(find.text('18.5 kWh/100 km'), findsOneWidget);
      expect(find.textContaining('L/100 km'), findsNothing);
    });
  });
}
