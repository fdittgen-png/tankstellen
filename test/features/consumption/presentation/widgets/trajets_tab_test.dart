// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/core/widgets/empty_state.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_registry.dart';
import 'package:tankstellen/features/consumption/data/obd2/bluetooth_facade.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm_byte_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connection_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_permissions.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trajets_record_fab.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trajets_tab.dart';
import 'package:tankstellen/features/consumption/providers/trip_history_provider.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import '../../../../helpers/silence_error_logger.dart';

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
    bool automatic = false,
  }) async {
    return StartTripOutcome.alreadyActive;
  }
}

/// #2274 concern 2 fake — records the start-now-connect-later sequence
/// (`enterConnecting` → `start`) without the real provider's heavy
/// connect/prime work. The base-class `enterConnecting` / `cancelConnecting`
/// / `setConnectStage` mutate `state` for real (cheap copyWith), so the
/// connecting phase is observable; only `start` is stubbed to a counter
/// that flips the phase to recording.
class _ConnectLaterTripRecording extends TripRecording {
  int startServiceCallCount = 0;
  Obd2Service? lastStartedService;

  @override
  TripRecordingState build() => const TripRecordingState();

  @override
  Future<void> start(Obd2Service service, {bool automatic = false}) async {
    startServiceCallCount++;
    lastStartedService = service;
    state = state.copyWith(
      phase: TripRecordingPhase.recording,
      clearConnectStage: true,
    );
  }
}

/// Fake [Obd2ConnectionService] that records `connectByMac` calls and
/// returns a synthetic [Obd2Service] (or null to force the sheet
/// fallback) so the trajets_tab pinned-MAC tests don't spin up any
/// Bluetooth stack. The constructor uses the existing fake permissions
/// + bluetooth facades so the underlying scan path also stays inert.
class _RecordingFakeConnection extends Obd2ConnectionService {
  _RecordingFakeConnection({
    this.connectByMacDirectResult,
  }) : super(
          registry: Obd2AdapterRegistry.defaults(),
          permissions: _AlwaysGrantedPermissions(),
          bluetooth: _EmptyBluetoothFacade(),
        );

  /// #2274 concern 3 — what the pre-warm direct-connect resolves to.
  /// Null ⇒ pre-warm misses and the start flow falls back to the picker.
  final Obd2Service? connectByMacDirectResult;
  final List<String> connectByMacCalls = [];
  final List<String> connectByMacDirectCalls = [];

  /// #3025 — records the transport-aware pre-warm / pinned connect entry the
  /// firstConnect orchestrators now route through (instead of the BLE-only
  /// `connectByMacDirect`). The fake returns [connectByMacDirectResult] so the
  /// existing pre-warm-hit assertions still hold, while the recorded list lets a
  /// test assert the adapter NAME drove the routing.
  final List<String> connectByMacTransportAwareCalls = [];

  @override
  Future<Obd2Service?> connectByMac(
    String mac, {
    Duration timeout = const Duration(seconds: 5),
    String? adapterName,
  }) async {
    connectByMacCalls.add(mac);
    return null;
  }

  @override
  Future<Obd2Service?> connectByMacDirect(
    String mac, {
    Duration timeout = const Duration(seconds: 4),
    bool fallbackToScan = true,
    String? adapterName,
  }) async {
    connectByMacDirectCalls.add(mac);
    return connectByMacDirectResult;
  }

  @override
  Future<Obd2Service?> connectByMacTransportAware(
    String mac, {
    String? adapterName,
    bool fallbackToScan = true,
  }) async {
    connectByMacTransportAwareCalls.add(mac);
    return connectByMacDirectResult;
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

  @override
  Future<bool> requestNotifications() async => true;
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

  @override
  ElmByteChannel channelForDirect(
    String mac, {
    Duration connectTimeout = const Duration(seconds: 4),
    bool autoConnect = false,
  }) {
    throw UnimplementedError('not used in trajets_tab tests');
  }
}

class _NoopObd2Service implements Obd2Service {
  // #2892 — the recording coordinator gates on `busAnswered` before starting:
  // a connected service whose vehicle bus never answered surfaces the
  // "turn the ignition on" condition instead of starting a degraded trip.
  // These tests exercise the healthy start/pre-warm flow, so the fake reports
  // a live bus (the silent-bus gate has its own dedicated coverage in
  // recording_start_coordinator_bus_silent_test.dart).
  @override
  bool get busAnswered => true;

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
        // #2494 — the record FAB now floats in the Scaffold FAB slot (as it
        // does in production via PageScaffold) rather than inside the tab
        // body. Hosting it here keeps the existing CTA assertions valid
        // while exercising the unified FAB-over-list path.
        builder: (_, _) => Scaffold(
          body: TrajetsTab(vehicleId: vehicleId),
          floatingActionButton: const TrajetsRecordFab(),
        ),
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
  silenceErrorLoggerSpool();
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

    testWidgets(
        '#2274 concern 2 — tapping the CTA enters the connecting phase and '
        'consumes a pre-warmed service via start()', (tester) async {
      final fakeService = _NoopObd2Service();
      final connection = _RecordingFakeConnection(
        connectByMacDirectResult: fakeService,
      );
      final notifier = _ConnectLaterTripRecording();
      await _pumpTab(
        tester,
        vehicleId: null,
        // A pinned MAC so the pre-warm fires the direct connect on open.
        activeVehicle: const VehicleProfile(
          id: 'v1',
          name: 'Daily Driver',
          type: VehicleType.combustion,
          obd2AdapterMac: 'AA:BB:CC:DD:EE:FF',
          obd2AdapterName: 'vLinker FS',
        ),
        trips: const [],
        recordingFactory: () => notifier,
        obd2Connection: connection,
      );
      // Let the post-frame pre-warm fire + resolve.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      // #3025 — pre-warm (concern 3) fires the TRANSPORT-AWARE connect on open.
      expect(connection.connectByMacTransportAwareCalls, ['AA:BB:CC:DD:EE:FF'],
          reason: 'pre-warm (concern 3) fires the transport-aware connect');

      await tester.tap(
        find.byKey(const Key('trajets_start_recording_button')),
      );
      // Don't pumpAndSettle — the recording-screen push would build the
      // full screen. A bounded pump lets the connect future chain.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // The pre-warmed service was consumed via start() — no second
      // connect, no picker sheet.
      expect(notifier.startServiceCallCount, 1);
      expect(notifier.lastStartedService, same(fakeService));
      expect(find.text('Pick an OBD2 adapter'), findsNothing);
    });

    testWidgets(
        '#2274 concern 2 — an unpaired vehicle (pre-warm miss) still opens '
        'the picker sheet from the connecting flow', (tester) async {
      final notifier = _ConnectLaterTripRecording();
      // No pinned MAC ⇒ pre-warm misses ⇒ the start flow falls back to
      // the picker, which opens its modal sheet.
      await _pumpTab(
        tester,
        vehicleId: null,
        activeVehicle: const VehicleProfile(
          id: 'v2',
          name: 'Daily Driver',
          type: VehicleType.combustion,
        ),
        trips: const [],
        recordingFactory: () => notifier,
        obd2Connection: _RecordingFakeConnection(),
      );
      await tester.pump();

      await tester.tap(
        find.byKey(const Key('trajets_start_recording_button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // No pre-warm hit (no pinned MAC) → the picker sheet opens and no
      // service reached start().
      expect(find.text('Pick an OBD2 adapter'), findsOneWidget);
      expect(notifier.startServiceCallCount, 0);
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

  // #2274 concern 3 — pre-warm connect on the trajets/start screen open. For a
  // pinned/bonded adapter the tab kicks the TRANSPORT-AWARE direct connect
  // (#3025 — `connectByMacTransportAware`, not the BLE-only `connectByMacDirect`
  // which 4 s-timed-out + poisoned the RFCOMM socket for a Classic adapter) the
  // moment it opens, and the start flow consumes that warm link (skipping the
  // picker). An unpaired vehicle warms nothing and falls back to the picker.
  group('TrajetsTab — pre-warm connect (#2274 concern 3 / #3025)', () {
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
        'paired vehicle pre-warms via the transport-aware connect on open and '
        'starts with the warm service (no picker) — #3025', (tester) async {
      final fakeService = _NoopObd2Service();
      final connection = _RecordingFakeConnection(
        connectByMacDirectResult: fakeService,
      );
      final notifier = _ConnectLaterTripRecording();

      await _pumpTab(
        tester,
        vehicleId: null,
        trips: const [],
        activeVehicle: pairedVehicle,
        recordingFactory: () => notifier,
        obd2Connection: connection,
      );
      // Post-frame pre-warm fires + resolves before any tap.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      // #3025 — the pre-warm goes through the TRANSPORT-AWARE entry (which routes
      // 'vLinker FS' — a Classic adapter — to RFCOMM), NOT the BLE-only
      // connectByMacDirect that 4 s-timed-out + poisoned the socket.
      expect(connection.connectByMacTransportAwareCalls, ['AA:BB:CC:DD:EE:FF']);
      expect(connection.connectByMacDirectCalls, isEmpty,
          reason: 'a Classic adapter must NEVER pre-warm over the BLE path');

      await tester.tap(
        find.byKey(const Key('trajets_start_recording_button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Warm link consumed via start(); picker never opens.
      expect(notifier.startServiceCallCount, 1);
      expect(notifier.lastStartedService, same(fakeService));
      expect(find.text('Pick an OBD2 adapter'), findsNothing);
    });

    testWidgets(
        'unpaired vehicle warms nothing on open and opens the picker on Start',
        (tester) async {
      final connection = _RecordingFakeConnection();
      final notifier = _ConnectLaterTripRecording();

      await _pumpTab(
        tester,
        vehicleId: null,
        trips: const [],
        activeVehicle: unpairedVehicle,
        recordingFactory: () => notifier,
        obd2Connection: connection,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      // No pinned MAC → nothing pre-warmed (neither path is touched).
      expect(connection.connectByMacDirectCalls, isEmpty);
      expect(connection.connectByMacTransportAwareCalls, isEmpty);

      await tester.tap(
        find.byKey(const Key('trajets_start_recording_button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Falls back to the picker sheet; no service reached start().
      expect(find.text('Pick an OBD2 adapter'), findsOneWidget);
      expect(notifier.startServiceCallCount, 0);
    });
  });

  group('TrajetsTab — active recording CTA discoverability (#1237)', () {
    testWidgets(
      'idle state shows "Start recording" with the record-dot icon',
      (tester) async {
        await _pumpTab(tester, vehicleId: null, trips: const []);

        expect(find.text('Start recording'), findsOneWidget);
        expect(find.text('Resume recording'), findsNothing);
        // #1889 — the CTA is an extended FAB (matching the fuel tab's
        // "add" button) and is enabled when no trip is active.
        final button = tester.widget<FloatingActionButton>(
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

  // #2274 concern 2 — start-now-connect-later moved the visible
  // progress onto the recording screen (pushed immediately in a
  // connecting state). The tab CTA reflects the connecting phase by
  // disabling + relabelling so a glance at the tab matches.
  group('TrajetsTab — connecting-phase CTA (#2274 concern 2)', () {
    testWidgets(
        'a connecting trip disables the CTA and shows the connecting label',
        (tester) async {
      await _pumpTab(
        tester,
        vehicleId: null,
        trips: const [],
        recordingFactory: () => _ConnectingTrip(),
      );
      await tester.pump();

      // The inline progress card no longer exists on the tab.
      expect(find.byKey(const Key('trajets_start_progress')), findsNothing);
      // CTA relabelled + disabled while connecting.
      expect(find.text('Connecting to OBD2 adapter…'), findsOneWidget);
      final button = tester.widget<FloatingActionButton>(
        find.byKey(const Key('trajets_start_recording_button')),
      );
      expect(button.onPressed, isNull,
          reason: 'CTA is disabled while a start is connecting');
    });
  });

  // #2530 — the wide-screen split now goes through the shared
  // ResponsiveMasterDetail scaffold. Structural pane-count assertions.
  group('TrajetsTab — #2530 responsive panes', () {
    final trips = [
      _entry(
        id: 'trip-r',
        vehicleId: 'v1',
        startedAt: DateTime(2026, 4, 22, 9),
        distanceKm: 12.0,
      ),
    ];

    testWidgets('compact width renders a single pane (no VerticalDivider)',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
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

      expect(find.byType(VerticalDivider), findsNothing);
      expect(find.byKey(const Key('trajets_list')), findsOneWidget);
    });

    testWidgets('expanded width renders two panes with the 2:3 ratio',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
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

      expect(find.byType(VerticalDivider), findsOneWidget);
      // Master flex 2 (insights), detail flex 3 (trajets list).
      final flexes = tester
          .widgetList<Expanded>(find.byType(Expanded))
          .map((e) => e.flex)
          .toList();
      expect(flexes, containsAllInOrder(<int>[2, 3]));
    });
  });
}

/// A trip stuck in the transient connecting phase (#2274 concern 2) so
/// the CTA renders its connecting shape without driving a real connect.
class _ConnectingTrip extends TripRecording {
  @override
  TripRecordingState build() => const TripRecordingState(
        phase: TripRecordingPhase.connecting,
        connectStage: TripStartStage.connectingAdapter,
      );
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
    bool automatic = false,
  }) async =>
      StartTripOutcome.alreadyActive;
}
