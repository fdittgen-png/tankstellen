// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/auto_record_trace_log.dart';
import 'package:tankstellen/features/consumption/data/obd2/auto_trip_coordinator.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm327_protocol.dart';
import 'package:tankstellen/features/consumption/data/obd2/ios_background_adapter_listener.dart';
import 'package:tankstellen/features/consumption/data/obd2/ios_restoration_event.dart';
import 'package:tankstellen/features/consumption/data/obd2/ios_state_restoration_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_permissions.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/consumption/providers/auto_record_orchestrator.dart';
import 'package:tankstellen/features/consumption/providers/auto_record_orchestrator_factories.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/feature_management/domain/feature_manifest.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../helpers/silence_error_logger.dart';

/// #3167 — decision-table test for the iOS Core Bluetooth
/// state-restoration → [AutoTripCoordinator] wiring (hands-free
/// auto-record Phase 3, Epic #3165).
///
/// Drives the REAL [IosBackgroundAdapterListener] (injected through the
/// orchestrator's listener-factory seam, exactly the production wiring
/// shape) with a fake restoration service + controller-backed
/// connection-state streams, and asserts the coordinator's decisions:
///
/// | active vehicle? | auto-record? | already recording? | restored connect → |
/// |-----------------|--------------|--------------------|--------------------|
/// | paired uuid     | enabled      | no                 | session opens, trip starts on speed |
/// | paired uuid     | DISABLED     | —                  | nothing armed, nothing starts        |
/// | NO paired id    | enabled      | —                  | no coordinator at all                |
/// | paired uuid     | enabled      | YES                | no second session / second start     |
class _FakeVehicleProfileList extends VehicleProfileList {
  _FakeVehicleProfileList(this._initial);

  final List<VehicleProfile> _initial;

  @override
  List<VehicleProfile> build() => _initial;
}

class _FakeTripRecording extends TripRecording {
  int startCalls = 0;
  final List<bool> startAutomaticFlags = <bool>[];

  @override
  TripRecordingState build() => const TripRecordingState();

  @override
  Future<void> start(Obd2Service service, {bool automatic = false}) async {
    startCalls++;
    startAutomaticFlags.add(automatic);
  }

  @override
  Future<void> stopAndSaveAutomatic() async {}
}

class _CountingPermissions implements Obd2Permissions {
  @override
  Future<Obd2PermissionState> current() async => Obd2PermissionState.granted;

  @override
  Future<Obd2PermissionState> request() async => Obd2PermissionState.granted;

  @override
  Future<bool> requestNotifications() async => true;
}

class _TestFeatureFlags extends FeatureFlags {
  _TestFeatureFlags(this._initial);

  final Set<Feature> _initial;

  @override
  Set<Feature> build() => {..._initial};
}

class _FakeRestorationService implements IosStateRestorationService {
  final List<String> registeredUuids = <String>[];
  IosRestorationWillRestore? launchEvent;
  bool _tagConsumed = false;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> registerPersistedAdapter(String peripheralUuid) async {
    registeredUuids.add(peripheralUuid);
  }

  @override
  Stream<IosRestorationEvent> get events => const Stream.empty();

  @override
  IosRestorationWillRestore? get launchRestoration => launchEvent;

  @override
  bool consumeLaunchRestorationTag() {
    if (launchEvent == null || _tagConsumed) return false;
    _tagConsumed = true;
    return true;
  }

  @override
  Future<void> dispose() async {}
}

/// Canned `41 0D <hex>` speed transport (mirrors the helper in
/// `auto_record_orchestrator_test.dart`).
class _FakeTransport implements Obd2Transport {
  _FakeTransport(this.speedQueue);

  final Queue<int?> speedQueue;
  bool _connected = true;

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

const String _uuid = '0A1B2C3D-0000-1111-2222-333344445555';

VehicleProfile _profile({
  bool autoRecord = true,
  String? adapterId = _uuid,
}) {
  return VehicleProfile(
    id: 'v1',
    name: 'Restored car',
    type: VehicleType.combustion,
    autoRecord: autoRecord,
    obd2AdapterMac: adapterId,
    movementStartThresholdKmh: 5.0,
    disconnectSaveDelaySec: 60,
  );
}

void main() {
  silenceErrorLoggerSpool();

  late _FakeTripRecording fakeTripRecording;
  late _FakeRestorationService restoration;
  late Map<String, StreamController<bool>> stateControllers;
  late List<String> openedMacs;
  late Map<String, Queue<int?>> speedById;

  setUp(() {
    AutoRecordTraceLog.clear();
    fakeTripRecording = _FakeTripRecording();
    restoration = _FakeRestorationService()
      // Every test here models the Core Bluetooth background relaunch.
      ..launchEvent = const IosRestorationWillRestore(<String>[]);
    stateControllers = <String, StreamController<bool>>{};
    openedMacs = <String>[];
    speedById = <String, Queue<int?>>{};
  });

  tearDown(() async {
    for (final c in stateControllers.values) {
      await c.close();
    }
  });

  Stream<bool> statesFor(String deviceId) {
    return stateControllers
        .putIfAbsent(deviceId, StreamController<bool>.broadcast)
        .stream;
  }

  Obd2SessionOpener fakeOpener() {
    return (String mac) async {
      openedMacs.add(mac);
      final queue = speedById.putIfAbsent(mac, () => Queue<int?>());
      return Obd2Service(_FakeTransport(queue));
    };
  }

  ProviderContainer makeContainer(List<VehicleProfile> profiles) {
    return ProviderContainer(
      overrides: [
        vehicleProfileListProvider
            .overrideWith(() => _FakeVehicleProfileList(profiles)),
        tripRecordingProvider.overrideWith(() => fakeTripRecording),
        // Production wiring shape: a REAL IosBackgroundAdapterListener per
        // coordinator, fed by the fake restoration service + fake streams.
        autoRecordListenerFactoryProvider.overrideWithValue(
          () => IosBackgroundAdapterListener(
            restoration: restoration,
            connectionStates: statesFor,
          ),
        ),
        autoRecordSessionOpenerFactoryProvider.overrideWithValue(fakeOpener()),
        autoRecordForegroundSessionOpenerFactoryProvider
            .overrideWithValue((String mac) async => null),
        obd2PermissionsProvider.overrideWithValue(_CountingPermissions()),
        featureFlagsProvider.overrideWith(
          () => _TestFeatureFlags({
            ...FeatureManifest.defaultManifest.defaultEnabledSet(),
            Feature.obd2TripRecording,
          }),
        ),
      ],
    );
  }

  test(
      'restored connect on an eligible vehicle opens a session and '
      'starts the trip on sustained speed', () async {
    // 3 supra-threshold samples at the 1 Hz production poll.
    speedById[_uuid] = Queue<int?>.of(<int?>[30, 32, 35, 40]);
    final container = makeContainer([_profile()]);
    addTearDown(container.dispose);

    container.read(autoRecordOrchestratorProvider);
    await Future<void>.delayed(Duration.zero);

    expect(restoration.registeredUuids, [_uuid],
        reason: 'arming must queue the long-lived pending connect for '
            'the paired peripheral');

    // The restoration relaunch left the peripheral already connected —
    // FBP replays that state to the fresh subscription.
    stateControllers[_uuid]!.add(true);
    await Future<void>.delayed(Duration.zero);

    expect(openedMacs, [_uuid],
        reason: 'the restored connect must open an OBD2 session through '
            'the (supervisor-admitted) session opener');

    // Production 1 Hz speed poll: 3 consecutive supra-threshold samples.
    await Future<void>.delayed(const Duration(milliseconds: 3500));
    expect(fakeTripRecording.startCalls, 1,
        reason: 'sustained movement after the restored connect must '
            'start exactly one automatic trip');
    expect(fakeTripRecording.startAutomaticFlags, [true]);
  });

  test('auto-record disabled on the vehicle → nothing armed, nothing starts',
      () async {
    final container = makeContainer([_profile(autoRecord: false)]);
    addTearDown(container.dispose);

    container.read(autoRecordOrchestratorProvider);
    await Future<void>.delayed(Duration.zero);

    expect(restoration.registeredUuids, isEmpty,
        reason: 'no coordinator → no pending-connect registration');
    expect(stateControllers, isEmpty,
        reason: 'no connection-state watch is opened either');
    expect(fakeTripRecording.startCalls, 0);
  });

  test('no paired adapter id → no coordinator at all', () async {
    final container = makeContainer([_profile(adapterId: null)]);
    addTearDown(container.dispose);

    container.read(autoRecordOrchestratorProvider);
    await Future<void>.delayed(Duration.zero);

    expect(
      container
          .read(autoRecordOrchestratorProvider.notifier)
          .activeVehicleIdsForTest,
      isEmpty,
    );
    expect(restoration.registeredUuids, isEmpty);
  });

  test(
      'already recording: a reconnect within the drive opens no second '
      'session and starts no second trip', () async {
    speedById[_uuid] = Queue<int?>.of(<int?>[30, 32, 35]);
    final container = makeContainer([_profile()]);
    addTearDown(container.dispose);

    container.read(autoRecordOrchestratorProvider);
    await Future<void>.delayed(Duration.zero);

    stateControllers[_uuid]!.add(true);
    await Future<void>.delayed(const Duration(milliseconds: 3500));
    expect(fakeTripRecording.startCalls, 1);

    // Tunnel bounce: disconnect then reconnect while the trip is live.
    stateControllers[_uuid]!.add(false);
    await Future<void>.delayed(Duration.zero);
    stateControllers[_uuid]!.add(true);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(openedMacs, [_uuid],
        reason: 'while the recorder owns the live session the '
            'coordinator must not open a competing one');
    expect(fakeTripRecording.startCalls, 1,
        reason: 'the in-flight trip continues — no double start');
  });
}
