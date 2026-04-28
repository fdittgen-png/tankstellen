import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/core/widgets/empty_state.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_registry.dart';
import 'package:tankstellen/features/consumption/data/obd2/bluetooth_facade.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm_byte_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connection_errors.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connection_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_permissions.dart';
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

/// Fake whose `startTrip()` resolves on a [Completer] the test
/// controls. Lets a test pump while the start flow is mid-flight so
/// it can assert that the inline [TripStartProgress] card replaces
/// the disabled button (#1230) instead of the screen looking frozen.
class _PendingTripRecording extends TripRecording {
  final Completer<StartTripOutcome> gate = Completer<StartTripOutcome>();

  @override
  TripRecordingState build() => const TripRecordingState();

  @override
  Future<StartTripOutcome> startTrip({
    String? vehicleId,
    String? adapterMac,
    Obd2Service? service,
  }) {
    return gate.future;
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

/// Fake that returns [StartTripOutcome.needsPicker] — drives the
/// picker code path in `_onStartRecording` (#1188).
class _NeedsPickerTripRecording extends TripRecording {
  int startTripCallCount = 0;
  int startServiceCallCount = 0;

  @override
  TripRecordingState build() => const TripRecordingState();

  @override
  Future<StartTripOutcome> startTrip({
    String? vehicleId,
    String? adapterMac,
    Obd2Service? service,
  }) async {
    startTripCallCount++;
    return StartTripOutcome.needsPicker;
  }

  @override
  Future<void> start(Obd2Service service, {bool automatic = false}) async {
    startServiceCallCount++;
  }
}

/// Fake [Obd2ConnectionService] that records `connectByMac` calls and
/// returns a synthetic [Obd2Service] (or null to force the sheet
/// fallback) so the trajets_tab pinned-MAC tests don't spin up any
/// Bluetooth stack. The constructor uses the existing fake permissions
/// + bluetooth facades so the underlying scan path also stays inert.
class _RecordingFakeConnection extends Obd2ConnectionService {
  _RecordingFakeConnection({this.connectByMacResult})
      : super(
          registry: Obd2AdapterRegistry.defaults(),
          permissions: _AlwaysGrantedPermissions(),
          bluetooth: _EmptyBluetoothFacade(),
        );

  final Obd2Service? connectByMacResult;
  final List<String> connectByMacCalls = [];

  @override
  Future<Obd2Service?> connectByMac(
    String mac, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    connectByMacCalls.add(mac);
    return connectByMacResult;
  }

  @override
  Stream<List<ResolvedObd2Candidate>> scan({
    Duration timeout = const Duration(seconds: 8),
  }) async* {
    // Empty stream — the picker sheet (when shown) sits in scanning.
  }
}

class _AlwaysGrantedPermissions implements Obd2Permissions {
  @override
  Future<Obd2PermissionState> current() async => Obd2PermissionState.granted;

  @override
  Future<Obd2PermissionState> request() async => Obd2PermissionState.granted;
}

class _EmptyBluetoothFacade implements BluetoothFacade {
  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout = const Duration(seconds: 8),
  }) async* {}

  @override
  Future<void> stopScan() async {}

  @override
  ElmByteChannel channelFor(String deviceId, Obd2AdapterProfile profile) {
    throw UnimplementedError('not used in trajets_tab tests');
  }
}

class _NoopObd2Service implements Obd2Service {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
  bool coldStartSurcharge = false,
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
      coldStartSurcharge: coldStartSurcharge,
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
  Obd2ConnectionService? obd2Connection,
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
      if (obd2Connection != null)
        obd2ConnectionProvider.overrideWith((_) => obd2Connection),
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

  // #1262 phase 3 — cold-start chip on the trip-history row. The chip
  // is rendered alongside distance / duration / avg-consumption when
  // the trip's `summary.coldStartSurcharge` is true (the recorder
  // flagged the coolant trace as never-warm / late-warm in phase 2).
  // Trips that warmed up normally — and trips on cars without PID
  // 0x05 — keep the flag false and the chip stays hidden.
  group('TrajetsTab — cold-start chip (#1262 phase 3)', () {
    testWidgets(
        'renders the chip with localized label and tooltip when the flag is true',
        (tester) async {
      final trips = [
        _entry(
          id: 'trip-cold',
          vehicleId: 'v1',
          startedAt: DateTime(2026, 4, 22, 9),
          endedAt: DateTime(2026, 4, 22, 9, 5),
          distanceKm: 1.8,
          coldStartSurcharge: true,
        ),
      ];

      await _pumpTab(
        tester,
        vehicleId: null,
        trips: trips,
        vehicles: [combustionVehicle],
        activeVehicle: combustionVehicle,
      );

      // Chip label is the localized "Cold start" string.
      expect(find.text('Cold start'), findsOneWidget);
      // Tooltip widget wraps the chip with the localized explanation
      // (find.byTooltip matches the message string against the
      // surrounding Tooltip / RawTooltip — this asserts the tooltip
      // is wired up regardless of which concrete class Flutter
      // instantiates internally).
      expect(
        find.byTooltip(
          "Engine didn't reach operating temperature during this trip — "
          'fuel consumption was higher than usual.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        "does NOT render the chip when the trip's flag is false",
        (tester) async {
      final trips = [
        _entry(
          id: 'trip-warm',
          vehicleId: 'v1',
          startedAt: DateTime(2026, 4, 22, 9),
          endedAt: DateTime(2026, 4, 22, 9, 30),
          distanceKm: 25.0,
          // coldStartSurcharge: false (default) — the chip must stay
          // hidden for trips that warmed up normally and for trips
          // recorded on cars without PID 0x05 (recorder leaves the
          // flag false in both cases — see #1262 phase 2 comments).
        ),
      ];

      await _pumpTab(
        tester,
        vehicleId: null,
        trips: trips,
        vehicles: [combustionVehicle],
        activeVehicle: combustionVehicle,
      );

      expect(find.text('Cold start'), findsNothing);
      // Distance chip is still rendered — sanity check that the row
      // built correctly.
      expect(find.text('25.0 km'), findsOneWidget);
    });
  });

  // #1188 — pinned-MAC fast path. When the active vehicle has an
  // adapter paired (`obd2AdapterMac` non-null), tapping Start
  // recording must NOT show the picker sheet. The picker calls
  // `connectByMac` silently and pushes straight into the recording
  // screen.
  group('TrajetsTab — pinned-MAC fast path (#1188)', () {
    const pairedVehicle = VehicleProfile(
      id: 'v1',
      name: 'Daily Driver',
      type: VehicleType.combustion,
      obd2AdapterMac: 'AA:BB:CC:DD:EE:FF',
      obd2AdapterName: 'vLinker FS',
    );
    const unpairedVehicle = VehicleProfile(
      id: 'v2',
      name: 'Daily Driver',
      type: VehicleType.combustion,
    );

    testWidgets(
        'paired vehicle skips the picker sheet on Start recording',
        (tester) async {
      final fakeService = _NoopObd2Service();
      final connection = _RecordingFakeConnection(
        connectByMacResult: fakeService,
      );
      final notifier = _NeedsPickerTripRecording();

      await _pumpTab(
        tester,
        vehicleId: null,
        trips: const [],
        activeVehicle: pairedVehicle,
        recordingFactory: () => notifier,
        obd2Connection: connection,
      );

      await tester.tap(
        find.byKey(const Key('trajets_start_recording_button')),
      );
      // Need to pump enough for the futures to chain through. Don't
      // pumpAndSettle — the recording screen push would attempt to
      // build the full TripRecordingScreen.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // startTrip fired and returned needsPicker.
      expect(notifier.startTripCallCount, 1);
      // Picker called connectByMac with the pinned MAC.
      expect(connection.connectByMacCalls, ['AA:BB:CC:DD:EE:FF']);
      // Sheet title NEVER appears — the picker short-circuited.
      expect(find.text('Pick an OBD2 adapter'), findsNothing);
      // The notifier received the connected service from the silent
      // pinned-MAC fast path.
      expect(notifier.startServiceCallCount, 1);
    });

    testWidgets(
        'unpaired vehicle still opens the picker sheet on Start recording',
        (tester) async {
      final connection = _RecordingFakeConnection();
      final notifier = _NeedsPickerTripRecording();

      await _pumpTab(
        tester,
        vehicleId: null,
        trips: const [],
        activeVehicle: unpairedVehicle,
        recordingFactory: () => notifier,
        obd2Connection: connection,
      );

      await tester.tap(
        find.byKey(const Key('trajets_start_recording_button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(notifier.startTripCallCount, 1);
      // No pinned MAC → picker did not attempt the silent connect.
      expect(connection.connectByMacCalls, isEmpty);
      // Sheet IS shown — the title text on the modal is rendered.
      expect(find.text('Pick an OBD2 adapter'), findsOneWidget);
    });
  });

  group('TrajetsTab — active recording CTA discoverability (#1237)', () {
    testWidgets(
      'idle state shows "Start recording" with the record-dot icon',
      (tester) async {
        await _pumpTab(tester, vehicleId: null, trips: const []);

        expect(find.text('Start recording'), findsOneWidget);
        expect(find.text('Resume recording'), findsNothing);
        // FilledButton.icon renders the dot when no trip is active.
        final button = tester.widget<FilledButton>(
          find.byKey(const Key('trajets_start_recording_button')),
        );
        expect(button.onPressed, isNotNull);
      },
    );

    testWidgets(
      'active recording switches CTA to "Resume recording" + visibility icon',
      (tester) async {
        await _pumpTab(
          tester,
          vehicleId: null,
          trips: const [],
          recordingFactory: () => _ActiveRecordingTrip(),
        );

        expect(find.text('Resume recording'), findsOneWidget);
        expect(find.text('Start recording'), findsNothing);
        expect(
          find.descendant(
            of: find.byKey(const Key('trajets_start_recording_button')),
            matching: find.byIcon(Icons.visibility),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('trajets_start_recording_button')),
            matching: find.byIcon(Icons.fiber_manual_record),
          ),
          findsNothing,
        );
      },
    );
  });

  // Inline progress feedback during the start flow (#1232). Without
  // this the user taps Start recording and the screen looks frozen for
  // several seconds while the BLE connect + odometer/VIN reads happen
  // — the disabled button gives no visual signal at all.
  group('TrajetsTab — start-flow progress feedback', () {
    testWidgets(
        'tapping Start recording swaps the button for the progress card',
        (tester) async {
      final notifier = _PendingTripRecording();
      await _pumpTab(
        tester,
        vehicleId: null,
        trips: const [],
        recordingFactory: () => notifier,
      );

      // Baseline: button visible, progress card not.
      expect(
        find.byKey(const Key('trajets_start_recording_button')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('trajets_start_progress')), findsNothing);

      await tester.tap(
        find.byKey(const Key('trajets_start_recording_button')),
      );
      // Pump twice so the `setState` lands and the AnimatedSwitcher
      // commits the new child without waiting for the swap animation.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Progress card replaces the button while startTrip() is pending.
      expect(find.byKey(const Key('trajets_start_progress')), findsOneWidget);
      expect(
        find.text('Connecting to OBD2 adapter…'),
        findsOneWidget,
      );

      // Resolve the gate so the start flow can finish — keeps the
      // widget tree clean for tearDown.
      notifier.gate.complete(StartTripOutcome.alreadyActive);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
    });
  });
}

/// Returns an [TripRecordingState] whose [TripRecordingState.isActive] is
/// `true` so the Trajets CTA flips to its "Resume recording" shape
/// without having to spin up the OBD2 service stack.
class _ActiveRecordingTrip extends TripRecording {
  @override
  TripRecordingState build() => const TripRecordingState(
        phase: TripRecordingPhase.recording,
      );

  @override
  Future<StartTripOutcome> startTrip({
    String? vehicleId,
    String? adapterMac,
    Obd2Service? service,
  }) async =>
      StartTripOutcome.alreadyActive;
}
