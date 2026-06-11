// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/auto_record_trace_log.dart';
import 'package:tankstellen/features/consumption/data/obd2/auto_trip_coordinator.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm327_protocol.dart';
import 'package:tankstellen/features/consumption/data/obd2/fake_background_adapter_listener.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_permissions.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/consumption/providers/auto_record_orchestrator.dart';
import 'package:tankstellen/features/consumption/providers/auto_record_orchestrator_factories.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/feature_management/domain/feature_manifest.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import '../../../helpers/silence_error_logger.dart';

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
    obd2AdapterMac: mac,
    movementStartThresholdKmh: thresholdKmh,
    disconnectSaveDelaySec: delaySec,
  );
}

void main() {
  silenceErrorLoggerSpool();
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
  // #2282 concern 2 — counts how many times the orchestrator asked for
  // POST_NOTIFICATIONS before arming.
  late _CountingPermissions permissions;
  // #2282 concern 1 — MACs the foreground (direct-connect) opener was
  // called for, in call order.
  late List<String> foregroundOpenedMacs;

  setUp(() {
    AutoRecordTraceLog.clear();
    harness = _ListenerHarness();
    fakeTripRecording = _FakeTripRecording();
    speedByMac = <String, Queue<int?>>{};
    servicesByMac = <String, Obd2Service>{};
    permissions = _CountingPermissions();
    foregroundOpenedMacs = <String>[];
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

  // #2282 concern 1 — a direct-connect opener that records every MAC it
  // is asked to wake. Reuses the same speed-queue so a foreground arm
  // can drive the same threshold logic as the background path.
  Obd2ForegroundSessionOpener fakeForegroundOpener() {
    return (String mac) async {
      foregroundOpenedMacs.add(mac);
      final queue = speedByMac.putIfAbsent(mac, () => Queue<int?>());
      final service = Obd2Service(_FakeTransport(queue));
      servicesByMac[mac] = service;
      return service;
    };
  }

  ProviderContainer makeContainer({
    required _FakeVehicleProfileList vehicleList,
    Set<Feature>? initialFeatureFlags,
  }) {
    // Default: include Feature.autoRecord (manifest default-true) AND
    // Feature.obd2TripRecording (its prerequisite) so existing tests
    // that don't pin the central gate observe the orchestrator as
    // "effectively enabled" under #1447 cascading-disable. Tests that
    // exercise the central gate or the parent edge pass a custom set.
    final flags = initialFeatureFlags ??
        {
          ...FeatureManifest.defaultManifest.defaultEnabledSet(),
          Feature.obd2TripRecording,
        };
    return ProviderContainer(
      overrides: [
        vehicleProfileListProvider.overrideWith(() => vehicleList),
        tripRecordingProvider.overrideWith(() => fakeTripRecording),
        autoRecordListenerFactoryProvider.overrideWithValue(harness.factory()),
        autoRecordSessionOpenerFactoryProvider.overrideWithValue(fakeOpener()),
        autoRecordForegroundSessionOpenerFactoryProvider
            .overrideWithValue(fakeForegroundOpener()),
        obd2PermissionsProvider.overrideWithValue(permissions),
        featureFlagsProvider.overrideWith(() => _TestFeatureFlags(flags)),
      ],
    );
  }

  test(
      'new vehicle with autoRecord=true and obd2AdapterMac creates and starts coordinator',
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

  // -------------------------------------------------------------------------
  // #2282 concern 2 — POST_NOTIFICATIONS requested before arming.
  // -------------------------------------------------------------------------

  group('POST_NOTIFICATIONS runtime request (#2282 concern 2)', () {
    test('requests notifications before arming an eligible vehicle',
        () async {
      final list = _FakeVehicleProfileList([_profile(id: 'v1')]);
      final container = makeContainer(vehicleList: list);
      addTearDown(container.dispose);

      container.read(autoRecordOrchestratorProvider);
      await Future<void>.delayed(Duration.zero);

      expect(permissions.notificationRequests, 1,
          reason: 'arming a coordinator must request POST_NOTIFICATIONS once');
      // The arm still happens — the notification grant is best-effort.
      expect(harness.listenerArmedFor('AA:BB:CC:DD:EE:FF'), isNotNull);
    });

    test('still arms when the notification permission is denied (graceful)',
        () async {
      permissions = _CountingPermissions(granted: false);
      final list = _FakeVehicleProfileList([_profile(id: 'v1')]);
      final container = makeContainer(vehicleList: list);
      addTearDown(container.dispose);

      container.read(autoRecordOrchestratorProvider);
      await Future<void>.delayed(Duration.zero);

      expect(permissions.notificationRequests, 1);
      final orchestrator =
          container.read(autoRecordOrchestratorProvider.notifier);
      expect(orchestrator.activeVehicleIdsForTest, {'v1'},
          reason: 'a denied notification grant must NOT block arming');
      expect(harness.listenerArmedFor('AA:BB:CC:DD:EE:FF')!.startCalls, 1);
    });

    test('does not request notifications when no vehicle is eligible',
        () async {
      final list =
          _FakeVehicleProfileList([_profile(id: 'v1', autoRecord: false)]);
      final container = makeContainer(vehicleList: list);
      addTearDown(container.dispose);

      container.read(autoRecordOrchestratorProvider);
      await Future<void>.delayed(Duration.zero);

      expect(permissions.notificationRequests, 0,
          reason: 'no arm → no notification prompt');
    });
  });

  // -------------------------------------------------------------------------
  // #2282 concern 1 — foreground-active arming via app resume.
  // -------------------------------------------------------------------------

  group('foreground-active arming (#2282 concern 1)', () {
    test('resume drives a DIRECT connect for each armed vehicle', () async {
      final list = _FakeVehicleProfileList([_profile(id: 'v1')]);
      final container = makeContainer(vehicleList: list);
      addTearDown(container.dispose);

      container.read(autoRecordOrchestratorProvider);
      await Future<void>.delayed(Duration.zero);

      // Simulate an app resume by invoking the orchestrator's
      // foreground-arm path directly (the production trigger is an
      // AppLifecycleListener.onResume, which a unit test can't fire).
      await container
          .read(autoRecordOrchestratorProvider.notifier)
          .debugArmForegroundActive();
      await Future<void>.delayed(Duration.zero);

      expect(foregroundOpenedMacs, ['AA:BB:CC:DD:EE:FF'],
          reason: 'a resume must open a direct connect to the paired '
              'adapter from the live engine');
    });
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

  test('vehicle without obd2AdapterMac is ignored', () async {
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

  test('changing obd2AdapterMac stops old coordinator and starts a new one',
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

  // -------------------------------------------------------------------------
  // Central master-gate behaviour (#1373 phase 3d).
  //
  // The per-vehicle [VehicleProfile.autoRecord] bool stays unchanged —
  // each vehicle keeps its own opt-in. The central [Feature.autoRecord]
  // is a master gate consulted FIRST: when off, no vehicle auto-records
  // regardless of its bool; when on, the per-vehicle bool decides.
  // -------------------------------------------------------------------------

  group('central master gate (Feature.autoRecord)', () {
    test(
      'central feature disabled + per-vehicle bool true → no coordinator',
      () async {
        final list = _FakeVehicleProfileList(
          [_profile(id: 'v1', autoRecord: true)],
        );
        final container = makeContainer(
          vehicleList: list,
          initialFeatureFlags: <Feature>{
            // Manifest defaults MINUS autoRecord (master gate off).
            // obd2TripRecording stays absent — autoRecord requires it
            // but the test doesn't toggle it through the central API,
            // and the fake skips dependency checks anyway.
            Feature.gamification,
            Feature.priceAlerts,
            Feature.priceHistory,
            Feature.routePlanning,
            Feature.evCharging,
          },
        );
        addTearDown(container.dispose);

        container.read(autoRecordOrchestratorProvider);
        await Future<void>.delayed(Duration.zero);

        final orchestrator =
            container.read(autoRecordOrchestratorProvider.notifier);
        expect(
          orchestrator.activeVehicleIdsForTest,
          isEmpty,
          reason:
              'When the central master gate is off, NO vehicle is armed '
              'regardless of its per-vehicle bool. This is the whole point '
              'of the wrap — a single central toggle disables auto-record '
              'across the whole app without touching per-vehicle state.',
        );
        expect(
          harness.created,
          isEmpty,
          reason:
              'No coordinator means no listener factory call — the gate '
              'short-circuits before the orchestrator constructs anything.',
        );
      },
    );

    test(
      'central feature enabled + per-vehicle bool false → no coordinator',
      () async {
        // Independent gate verification — the per-vehicle bool still
        // matters even when the central feature is on. This pins the
        // wrap semantics (BOTH must be true) rather than a replace
        // (central wins).
        final list = _FakeVehicleProfileList(
          [_profile(id: 'v1', autoRecord: false)],
        );
        final container = makeContainer(vehicleList: list);
        addTearDown(container.dispose);

        container.read(autoRecordOrchestratorProvider);
        await Future<void>.delayed(Duration.zero);

        final orchestrator =
            container.read(autoRecordOrchestratorProvider.notifier);
        expect(
          orchestrator.activeVehicleIdsForTest,
          isEmpty,
          reason:
              'Per-vehicle bool false must STILL prevent auto-record when '
              'the central feature is on — this confirms the central gate '
              'wraps (AND logic) rather than overrides the per-vehicle bool.',
        );
      },
    );

    test(
      'central feature enabled + per-vehicle bool true → coordinator armed',
      () async {
        final list = _FakeVehicleProfileList(
          [_profile(id: 'v1', autoRecord: true)],
        );
        final container = makeContainer(vehicleList: list);
        addTearDown(container.dispose);

        container.read(autoRecordOrchestratorProvider);
        await Future<void>.delayed(Duration.zero);

        final orchestrator =
            container.read(autoRecordOrchestratorProvider.notifier);
        expect(
          orchestrator.activeVehicleIdsForTest,
          {'v1'},
          reason:
              'Both gates open → coordinator armed exactly as before. '
              'Pre-3d behaviour preserved when nothing is touched.',
        );
        expect(
          harness.listenerArmedFor('AA:BB:CC:DD:EE:FF'),
          isNotNull,
        );
      },
    );

    test(
      'flipping the central feature off after arming tears the coordinator '
      'down',
      () async {
        final list = _FakeVehicleProfileList(
          [_profile(id: 'v1', autoRecord: true)],
        );
        final container = makeContainer(vehicleList: list);
        addTearDown(container.dispose);

        container.read(autoRecordOrchestratorProvider);
        await Future<void>.delayed(Duration.zero);

        final listener = harness.listenerArmedFor('AA:BB:CC:DD:EE:FF')!;
        expect(listener.startCalls, 1);

        // Disable the central feature externally — the orchestrator's
        // build() watches featureFlagsProvider so a flip rebuilds the
        // provider and re-runs the diff against the unchanged vehicle
        // list, dropping every active coordinator.
        await container
            .read(featureFlagsProvider.notifier)
            .disable(Feature.autoRecord);
        await Future<void>.delayed(Duration.zero);

        final orchestrator =
            container.read(autoRecordOrchestratorProvider.notifier);
        expect(
          orchestrator.activeVehicleIdsForTest,
          isEmpty,
          reason:
              'Disabling the central master gate at runtime must tear '
              'down every active coordinator. The orchestrator watches '
              'the feature-flag set so it rebuilds + re-diffs on every '
              'flip.',
        );
        expect(
          listener.stopCalls,
          1,
          reason:
              'The torn-down coordinator must call stop() on its listener '
              'so the native foreground service un-arms.',
        );
      },
    );
  });
}

/// Counts POST_NOTIFICATIONS requests (#2282 concern 2) and reports a
/// fixed grant decision. The Bluetooth scan/connect permissions report
/// `granted` so they never interfere with arming.
class _CountingPermissions implements Obd2Permissions {
  _CountingPermissions({this.granted = true});

  final bool granted;
  int notificationRequests = 0;

  @override
  Future<Obd2PermissionState> current() async => Obd2PermissionState.granted;

  @override
  Future<Obd2PermissionState> request() async => Obd2PermissionState.granted;

  @override
  Future<bool> requestNotifications() async {
    notificationRequests++;
    return granted;
  }
}

/// Synthetic in-memory [FeatureFlags] notifier used to drive the
/// orchestrator's master-gate behaviour without going through the
/// Hive-backed repository AND without enforcing the manifest
/// dependency graph (so a test can put the system in a state the
/// graph would normally reject — e.g. autoRecord disabled while
/// obd2TripRecording is also absent).
///
/// Mirrors the equivalent test double in
/// `test/features/sync/providers/baseline_sync_enabled_provider_test.dart`.
class _TestFeatureFlags extends FeatureFlags {
  _TestFeatureFlags([Set<Feature>? initial])
      : _initial = initial ?? <Feature>{};

  final Set<Feature> _initial;

  @override
  Set<Feature> build() => {..._initial};

  @override
  Future<void> enable(Feature feature) async {
    final current = state.value ?? const <Feature>{}; if (current.contains(feature)) return;
    state = AsyncData({...current, feature});
  }

  @override
  Future<void> disable(Feature feature) async {
    final current = state.value ?? const <Feature>{}; if (!current.contains(feature)) return;
    state = AsyncData({...current}..remove(feature));
  }
}
