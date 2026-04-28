import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/auto_record_trace_log.dart';
import 'package:tankstellen/features/consumption/data/obd2/auto_trip_coordinator.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm327_protocol.dart';
import 'package:tankstellen/features/consumption/data/obd2/fake_background_adapter_listener.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/consumption/providers/auto_record_orchestrator.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

/// Tests for the auto-record orchestrator (#1004 phase 2b-3).
///
/// Drives the orchestrator with:
///  - a fake [VehicleProfileList] notifier so the test can imperatively
///    push vehicle-list snapshots and observe the diff behaviour;
///  - a per-test factory that hands out fresh [FakeBackgroundAdapterListener]
///    instances so each coordinator gets its own listener (the orchestrator
///    constructs one listener per coordinator on purpose — see the
///    "MAC change" test);
///  - a controllable session-opener factory so threshold logic stays
///    deterministic without touching real Bluetooth;
///  - a fake [TripRecording] notifier counting `start` / `stopAndSaveAutomatic`
///    calls.
///
/// Each test owns its own [ProviderContainer] and disposes it in the
/// teardown so the keepAlive providers don't leak across tests.

class _FakeVehicleProfileList extends VehicleProfileList {
  _FakeVehicleProfileList(this._initial);

  List<VehicleProfile> _initial;

  @override
  List<VehicleProfile> build() => _initial;

  void setProfiles(List<VehicleProfile> next) {
    _initial = next;
    state = next;
  }
}

/// Fake [TripRecording] that records start/stop calls. We override the
/// notifier (not its state) because the orchestrator calls into the
/// notifier via `ref.read(...notifier)` — a state override would not
/// intercept those method calls.
class _FakeTripRecording extends TripRecording {
  int startCalls = 0;
  int stopAndSaveCalls = 0;
  final List<bool> startAutomaticFlags = <bool>[];
  final List<Obd2Service> startServices = <Obd2Service>[];

  @override
  TripRecordingState build() => const TripRecordingState();

  @override
  Future<void> start(Obd2Service service, {bool automatic = false}) async {
    startCalls++;
    startAutomaticFlags.add(automatic);
    startServices.add(service);
  }

  @override
  Future<void> stopAndSaveAutomatic() async {
    stopAndSaveCalls++;
  }
}

/// Bookkeeping bundle that pairs each fake listener with the MAC it was
/// armed against. Lets the test recover the listener for a vehicle id
/// (via the orchestrator's `armedMacForTest`) and emit synthetic events
/// at the right time.
class _ListenerHarness {
  final List<FakeBackgroundAdapterListener> created =
      <FakeBackgroundAdapterListener>[];

  /// Returns a factory closure compatible with
  /// [BackgroundAdapterListenerFactory]. Each call mints a fresh fake
  /// listener — the orchestrator constructs one listener per
  /// coordinator, so we want fresh instances on every diff add.
  BackgroundAdapterListenerFactory factory() {
    return () {
      final listener = FakeBackgroundAdapterListener();
      created.add(listener);
      return listener;
    };
  }

  /// Last listener whose first arm matches [mac]. The orchestrator
  /// calls `start(mac: ...)` exactly once per coordinator so the first
  /// armed MAC unambiguously identifies which fake belongs to which
  /// vehicle.
  FakeBackgroundAdapterListener? listenerArmedFor(String mac) {
    for (final l in created.reversed) {
      if (l.startedMacs.isNotEmpty && l.startedMacs.first == mac) {
        return l;
      }
    }
    return null;
  }

  Future<void> disposeAll() async {
    for (final l in created) {
      await l.dispose();
    }
  }
}

/// Test-only [Obd2Transport] that returns canned `41 0D <hex>` speed
/// responses. Mirrors the helper in `auto_trip_coordinator_test` so
/// the orchestrator-level test can exercise the full provider override
/// chain without depending on that file.
class _FakeTransport implements Obd2Transport {
  final Queue<int?> speedQueue;
  bool _connected = true;

  _FakeTransport(this.speedQueue);

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async {
    _connected = true;
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
  }

  @override
  Future<String> sendCommand(String command) async {
    if (command == Elm327Protocol.vehicleSpeedCommand) {
      if (speedQueue.isEmpty) return 'NO DATA';
      final value = speedQueue.removeFirst();
      if (value == null) return 'NO DATA';
      return '41 0D ${value.toRadixString(16).padLeft(2, '0').toUpperCase()}';
    }
    return '';
  }
}

VehicleProfile _profile({
  required String id,
  bool autoRecord = true,
  String? mac = 'AA:BB:CC:DD:EE:FF',
  double thresholdKmh = 5.0,
  int delaySec = 60,
}) {
  return VehicleProfile(
    id: id,
    name: 'Test $id',
    type: VehicleType.combustion,
    autoRecord: autoRecord,
    pairedAdapterMac: mac,
    movementStartThresholdKmh: thresholdKmh,
    disconnectSaveDelaySec: delaySec,
  );
}

void main() {
  late _ListenerHarness harness;
  late _FakeTripRecording fakeTripRecording;
  // Speed-queue per opened MAC. Tests that exercise threshold-cross
  // pre-populate this with samples; the default empty queue means
  // `readSpeedKmh` returns null forever (no movement detected).
  late Map<String, Queue<int?>> speedByMac;
  // Services the harness handed out, keyed by MAC. Lets tests assert
  // identity between the opened service and the one passed to
  // [TripRecording.start].
  late Map<String, Obd2Service> servicesByMac;

  setUp(() {
    AutoRecordTraceLog.clear();
    harness = _ListenerHarness();
    fakeTripRecording = _FakeTripRecording();
    speedByMac = <String, Queue<int?>>{};
    servicesByMac = <String, Obd2Service>{};
  });

  tearDown(() async {
    await harness.disposeAll();
  });

  Obd2SessionOpener fakeOpener() {
    return (String mac) async {
      final queue = speedByMac.putIfAbsent(mac, () => Queue<int?>());
      final service = Obd2Service(_FakeTransport(queue));
      servicesByMac[mac] = service;
      return service;
    };
  }

  ProviderContainer makeContainer({
    required _FakeVehicleProfileList vehicleList,
  }) {
    return ProviderContainer(
      overrides: [
        vehicleProfileListProvider.overrideWith(() => vehicleList),
        tripRecordingProvider.overrideWith(() => fakeTripRecording),
        autoRecordListenerFactoryProvider.overrideWithValue(harness.factory()),
        autoRecordSessionOpenerFactoryProvider.overrideWithValue(fakeOpener()),
      ],
    );
  }

  test(
      'new vehicle with autoRecord=true and pairedAdapterMac creates and starts coordinator',
      () async {
    final list = _FakeVehicleProfileList(
      [_profile(id: 'v1')],
    );
    final container = makeContainer(vehicleList: list);
    addTearDown(container.dispose);

    container.read(autoRecordOrchestratorProvider);
    // The orchestrator schedules `coordinator.start()` via
    // `unawaited(...)`; let the microtask queue flush so the listener
    // observes the arming call before we assert.
    await Future<void>.delayed(Duration.zero);

    final orchestrator =
        container.read(autoRecordOrchestratorProvider.notifier);
    expect(orchestrator.activeVehicleIdsForTest, {'v1'});
    expect(orchestrator.armedMacForTest('v1'), 'AA:BB:CC:DD:EE:FF');

    final listener = harness.listenerArmedFor('AA:BB:CC:DD:EE:FF');
    expect(listener, isNotNull,
        reason: 'A listener must be armed for the wanted MAC');
    expect(listener!.startCalls, 1);
    expect(listener.startedMacs, ['AA:BB:CC:DD:EE:FF']);
  });

  test('vehicle with autoRecord=false is ignored', () async {
    final list = _FakeVehicleProfileList(
      [_profile(id: 'v1', autoRecord: false)],
    );
    final container = makeContainer(vehicleList: list);
    addTearDown(container.dispose);

    container.read(autoRecordOrchestratorProvider);
    await Future<void>.delayed(Duration.zero);

    final orchestrator =
        container.read(autoRecordOrchestratorProvider.notifier);
    expect(orchestrator.activeVehicleIdsForTest, isEmpty);
    expect(harness.created, isEmpty);
  });

  test('vehicle without pairedAdapterMac is ignored', () async {
    final list = _FakeVehicleProfileList(
      [_profile(id: 'v1', mac: null)],
    );
    final container = makeContainer(vehicleList: list);
    addTearDown(container.dispose);

    container.read(autoRecordOrchestratorProvider);
    await Future<void>.delayed(Duration.zero);

    final orchestrator =
        container.read(autoRecordOrchestratorProvider.notifier);
    expect(orchestrator.activeVehicleIdsForTest, isEmpty);
  });

  test(
      'flipping autoRecord to false stops and removes the coordinator',
      () async {
    final list = _FakeVehicleProfileList(
      [_profile(id: 'v1')],
    );
    final container = makeContainer(vehicleList: list);
    addTearDown(container.dispose);

    container.read(autoRecordOrchestratorProvider);
    await Future<void>.delayed(Duration.zero);

    final listener = harness.listenerArmedFor('AA:BB:CC:DD:EE:FF')!;
    expect(listener.startCalls, 1);

    list.setProfiles([_profile(id: 'v1', autoRecord: false)]);
    await Future<void>.delayed(Duration.zero);

    final orchestrator =
        container.read(autoRecordOrchestratorProvider.notifier);
    expect(orchestrator.activeVehicleIdsForTest, isEmpty);
    expect(listener.stopCalls, 1,
        reason: 'Disabling autoRecord must call stop() on the listener');
  });

  test('changing pairedAdapterMac stops old coordinator and starts a new one',
      () async {
    final list = _FakeVehicleProfileList(
      [_profile(id: 'v1', mac: 'AA:AA:AA:AA:AA:AA')],
    );
    final container = makeContainer(vehicleList: list);
    addTearDown(container.dispose);

    container.read(autoRecordOrchestratorProvider);
    await Future<void>.delayed(Duration.zero);

    final firstListener = harness.listenerArmedFor('AA:AA:AA:AA:AA:AA');
    expect(firstListener, isNotNull);
    expect(firstListener!.startCalls, 1);

    list.setProfiles([_profile(id: 'v1', mac: 'BB:BB:BB:BB:BB:BB')]);
    await Future<void>.delayed(Duration.zero);

    final orchestrator =
        container.read(autoRecordOrchestratorProvider.notifier);
    expect(orchestrator.activeVehicleIdsForTest, {'v1'});
    expect(orchestrator.armedMacForTest('v1'), 'BB:BB:BB:BB:BB:BB');
    expect(firstListener.stopCalls, 1,
        reason: 'Old listener must be stopped on MAC change');

    final secondListener = harness.listenerArmedFor('BB:BB:BB:BB:BB:BB');
    expect(secondListener, isNotNull);
    expect(secondListener!.startCalls, 1);
    expect(identical(firstListener, secondListener), isFalse,
        reason:
            'A MAC change must spin up a fresh listener, not re-arm the old one');
  });

  test('removing a vehicle from the list stops its coordinator', () async {
    final list = _FakeVehicleProfileList(
      [_profile(id: 'v1')],
    );
    final container = makeContainer(vehicleList: list);
    addTearDown(container.dispose);

    container.read(autoRecordOrchestratorProvider);
    await Future<void>.delayed(Duration.zero);

    final listener = harness.listenerArmedFor('AA:BB:CC:DD:EE:FF')!;
    expect(listener.startCalls, 1);

    list.setProfiles(const []);
    await Future<void>.delayed(Duration.zero);

    final orchestrator =
        container.read(autoRecordOrchestratorProvider.notifier);
    expect(orchestrator.activeVehicleIdsForTest, isEmpty);
    expect(listener.stopCalls, 1);
  });

  test(
      'two vehicles with autoRecord=true result in two independent coordinators',
      () async {
    final list = _FakeVehicleProfileList([
      _profile(id: 'v1', mac: 'AA:AA:AA:AA:AA:AA'),
      _profile(id: 'v2', mac: 'BB:BB:BB:BB:BB:BB'),
    ]);
    final container = makeContainer(vehicleList: list);
    addTearDown(container.dispose);

    container.read(autoRecordOrchestratorProvider);
    await Future<void>.delayed(Duration.zero);

    final orchestrator =
        container.read(autoRecordOrchestratorProvider.notifier);
    expect(orchestrator.activeVehicleIdsForTest, {'v1', 'v2'});
    expect(orchestrator.armedMacForTest('v1'), 'AA:AA:AA:AA:AA:AA');
    expect(orchestrator.armedMacForTest('v2'), 'BB:BB:BB:BB:BB:BB');

    final listenerA = harness.listenerArmedFor('AA:AA:AA:AA:AA:AA');
    final listenerB = harness.listenerArmedFor('BB:BB:BB:BB:BB:BB');
    expect(listenerA, isNotNull);
    expect(listenerB, isNotNull);
    expect(identical(listenerA, listenerB), isFalse,
        reason: 'Each vehicle must own a distinct listener instance');
  });

  test('disposing the orchestrator stops every active coordinator', () async {
    final list = _FakeVehicleProfileList([
      _profile(id: 'v1', mac: 'AA:AA:AA:AA:AA:AA'),
      _profile(id: 'v2', mac: 'BB:BB:BB:BB:BB:BB'),
    ]);
    final container = makeContainer(vehicleList: list);
    container.read(autoRecordOrchestratorProvider);
    await Future<void>.delayed(Duration.zero);

    final listenerA = harness.listenerArmedFor('AA:AA:AA:AA:AA:AA')!;
    final listenerB = harness.listenerArmedFor('BB:BB:BB:BB:BB:BB')!;
    expect(listenerA.startCalls, 1);
    expect(listenerB.startCalls, 1);

    container.dispose();
    // Disposal kicks `unawaited(stop)` calls; flush the microtask queue
    // so the listener bookkeeping reflects the requested stops.
    await Future<void>.delayed(Duration.zero);

    expect(listenerA.stopCalls, 1);
    expect(listenerB.stopCalls, 1);
  });

  test(
      'connect + supra-threshold OBD2 speed → start(service, automatic: true)',
      () async {
    const targetMac = 'AA:BB:CC:DD:EE:FF';
    speedByMac[targetMac] = Queue<int?>.of(<int?>[20, 25, 30, 40, 50, 60]);

    final list = _FakeVehicleProfileList(
      [
        _profile(
          id: 'v1',
          mac: targetMac,
          thresholdKmh: 5.0,
        ),
      ],
    );
    final container = makeContainer(vehicleList: list);
    addTearDown(container.dispose);

    container.read(autoRecordOrchestratorProvider);
    await Future<void>.delayed(Duration.zero);

    final listener = harness.listenerArmedFor(targetMac)!;
    listener.emitConnected(targetMac);
    // The opener resolves async; speed stream polls at 1 s by default
    // in production, but the orchestrator-level test uses the
    // production cadence — so this test waits a generous interval to
    // allow at least three reads. Trade-off: keeps the orchestrator
    // wiring honest at the cost of ~3 s wall-clock per assertion. The
    // poll period is the only knob we don't override, so this is the
    // shortest deterministic wait that still exercises the real code
    // path.
    await Future<void>.delayed(const Duration(milliseconds: 3500));

    expect(fakeTripRecording.startCalls, 1,
        reason: '3 supra-threshold OBD2 reads must trigger one start()');
    expect(fakeTripRecording.startAutomaticFlags, [true],
        reason: 'auto-record start must tag the trip as automatic');
    expect(fakeTripRecording.startServices, hasLength(1));
    expect(
      identical(fakeTripRecording.startServices.first, servicesByMac[targetMac]),
      isTrue,
      reason: 'the orchestrator must hand the SAME service the opener '
          'returned — ownership transfer, not copy',
    );
  }, timeout: const Timeout(Duration(seconds: 15)));
}
