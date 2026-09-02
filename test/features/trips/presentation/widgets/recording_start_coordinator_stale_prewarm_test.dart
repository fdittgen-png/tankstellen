// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/feature_management/api.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_connection_service.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_link_supervisor.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_link_drop_signal.dart';
import 'package:tankstellen/features/obd2/providers/obd2_reconnect_provider.dart';
import 'package:tankstellen/features/trips/presentation/widgets/recording_start_coordinator.dart';
import 'package:tankstellen/features/trips/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import '../../../../helpers/silence_error_logger.dart';

/// #3896 — the coordinator lives as long as the process (the shell's
/// IndexedStack never disposes the Trajets tab), while the #2274 pre-warm
/// snapshot was taken ONCE when the tab first opened. The second manual
/// recording of a session started on that snapshot — a closed corpse the
/// link owner had long recycled — and degraded to GPS-only until the app
/// was restarted. Reuse-live-first (#3527 rule 2): the supervisor's
/// CURRENT link wins, and the pre-warm is one-shot.
void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  const vehicle = VehicleProfile(
    id: 'v1',
    name: 'Peugeot 107',
    obd2AdapterMac: 'D4:E9:5E:A8:CD:7E',
    obd2AdapterName: 'vLinker FS',
  );

  /// Pump a bare [Consumer] wired like the Trajets FAB: the spy notifier,
  /// the injected supervisor, the OBD2-required feature flag, a pinned
  /// vehicle and a connection service whose direct dial answers [warm].
  Future<({WidgetRef ref, _SpyTripRecording notifier})> pump(
    WidgetTester tester, {
    required Obd2LinkSupervisor sup,
    required _FakeObd2Service warm,
  }) async {
    late WidgetRef captured;
    late _SpyTripRecording notifier;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tripRecordingProvider.overrideWith(_SpyTripRecording.new),
          obd2ReconnectProvider.overrideWith(() => _SupervisorStub(sup)),
          enabledFeaturesProvider.overrideWithValue({Feature.obd2Optional}),
          activeVehicleProfileProvider
              .overrideWith(() => _StubActiveVehicle(vehicle)),
          obd2ConnectionProvider.overrideWithValue(_FakeConnection(warm)),
        ],
        child: Consumer(
          builder: (_, ref, _) {
            captured = ref;
            notifier =
                ref.read(tripRecordingProvider.notifier) as _SpyTripRecording;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return (ref: captured, notifier: notifier);
  }

  testWidgets(
      '#3896 — a start after the owner RECYCLED the link starts on the '
      'supervisor\'s current service, never the stale pre-warm snapshot',
      (tester) async {
    final s1 = _FakeObd2Service(); // the pre-warm (trip 1's link)
    final s2 = _FakeObd2Service(); // the owner's redial between trips
    final sup = Obd2LinkSupervisor(
      dial: () async => s2,
      drops: const Stream<Obd2LinkDropEvent>.empty(),
    );
    addTearDown(sup.dispose);
    final coordinator = RecordingStartCoordinator();
    final h = await pump(tester, sup: sup, warm: s1);

    // Tab opens: the pre-warm dials through the supervisor and lands s1.
    coordinator.maybePrewarm(h.ref);
    await tester.pump();
    expect(identical(sup.service, s1), isTrue,
        reason: 'the pre-warm must route through the one supervisor');

    // Between trips the owner recycles the link (adapter slept → drop →
    // fresh dial): s1 is now a closed corpse, s2 is THE live link.
    await sup.disconnect();
    await sup.connect();
    expect(identical(sup.service, s2), isTrue);
    expect(s1.disconnectCallCount, 1, reason: 'the owner closed s1');

    final errors = <Object>[];
    h.notifier.enterConnecting();
    await coordinator.connectAndStart(
      h.ref,
      notifier: h.notifier,
      openPicker: () async => fail('a live supervised link needs no picker'),
      onConnectionError: errors.add,
      isMounted: () => true,
    );

    expect(errors, isEmpty);
    expect(h.notifier.startCallCount, 1);
    expect(identical(h.notifier.lastStartedService, s2), isTrue,
        reason: 'the trip must start on the CURRENT link, not the corpse');
    expect(s1.reprobeCallCount, 0,
        reason: 'the corpse is not even probed');
  });

  testWidgets(
      '#3896 — a start after the owner PARKED the link (no live service) '
      'discards the stale pre-warm and dials through the picker path',
      (tester) async {
    final s1 = _FakeObd2Service();
    final s3 = _FakeObd2Service(); // the picker's fresh dial
    final sup = Obd2LinkSupervisor(
      dial: () async => null,
      drops: const Stream<Obd2LinkDropEvent>.empty(),
    );
    addTearDown(sup.dispose);
    final coordinator = RecordingStartCoordinator();
    final h = await pump(tester, sup: sup, warm: s1);

    coordinator.maybePrewarm(h.ref);
    await tester.pump();
    expect(identical(sup.service, s1), isTrue);

    // The owner parks (user disconnect / engine-off convergence): the
    // pre-warm snapshot still points at s1, which is closed.
    await sup.disconnect();
    expect(sup.service, isNull);

    var pickerOpened = 0;
    final errors = <Object>[];
    h.notifier.enterConnecting();
    await coordinator.connectAndStart(
      h.ref,
      notifier: h.notifier,
      openPicker: () async {
        pickerOpened++;
        return s3;
      },
      onConnectionError: errors.add,
      isMounted: () => true,
    );

    expect(errors, isEmpty);
    expect(pickerOpened, 1, reason: 'no live link ⇒ the picker fast path');
    expect(identical(h.notifier.lastStartedService, s3), isTrue,
        reason: 'the trip must never start on the closed pre-warm');
  });

  testWidgets(
      '#3896 — the pre-warm is ONE-SHOT: a second start in the same '
      'process re-reads the supervisor instead of the consumed snapshot',
      (tester) async {
    final s1 = _FakeObd2Service();
    final s2 = _FakeObd2Service();
    final dials = <Obd2Service?>[s2];
    final sup = Obd2LinkSupervisor(
      dial: () async => dials.isEmpty ? null : dials.removeAt(0),
      drops: const Stream<Obd2LinkDropEvent>.empty(),
    );
    addTearDown(sup.dispose);
    final coordinator = RecordingStartCoordinator();
    final h = await pump(tester, sup: sup, warm: s1);

    coordinator.maybePrewarm(h.ref);
    await tester.pump();

    // Trip 1 — the pre-warm IS the live link: start on s1 (unchanged).
    h.notifier.enterConnecting();
    await coordinator.connectAndStart(
      h.ref,
      notifier: h.notifier,
      openPicker: () async => fail('trip 1 has a live pre-warm'),
      onConnectionError: (_) {},
      isMounted: () => true,
    );
    expect(identical(h.notifier.lastStartedService, s1), isTrue);

    // Trip 1 ends; the owner recycles the link before trip 2.
    h.notifier.state = const TripRecordingState();
    await sup.disconnect();
    await sup.connect();
    expect(identical(sup.service, s2), isTrue);

    // Trip 2 — must follow the owner, not the snapshot consumed by trip 1.
    h.notifier.enterConnecting();
    await coordinator.connectAndStart(
      h.ref,
      notifier: h.notifier,
      openPicker: () async => fail('a live supervised link needs no picker'),
      onConnectionError: (_) {},
      isMounted: () => true,
    );
    expect(h.notifier.startCallCount, 2);
    expect(identical(h.notifier.lastStartedService, s2), isTrue,
        reason: 'the second recording of the session was the field failure');
  });
}

class _SupervisorStub extends Obd2Reconnect {
  _SupervisorStub(this._sup);
  final Obd2LinkSupervisor _sup;

  @override
  Obd2LinkSupervisor get supervisor => _sup;

  @override
  Obd2LinkState build() => Obd2LinkState.idle;
}

class _StubActiveVehicle extends ActiveVehicleProfile {
  _StubActiveVehicle(this._value);
  final VehicleProfile? _value;

  @override
  VehicleProfile? build() => _value;
}

/// Connection service whose direct (pre-warm) dial answers [warm].
class _FakeConnection implements Obd2ConnectionService {
  _FakeConnection(this.warm);
  final Obd2Service warm;

  @override
  Future<Obd2Service?> connectByMacTransportAware(
    String mac, {
    String? adapterName,
    bool fallbackToScan = true,
  }) async =>
      warm;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SpyTripRecording extends TripRecording {
  int startCallCount = 0;
  Obd2Service? lastStartedService;

  @override
  TripRecordingState build() => const TripRecordingState();

  @override
  Future<void> start(Obd2Service service, {bool automatic = false}) async {
    startCallCount++;
    lastStartedService = service;
    state = state.copyWith(
      phase: TripRecordingPhase.recording,
      clearConnectStage: true,
    );
  }
}

/// Healthy-bus fake: `busProbe == answered` so no start-gate rung fires;
/// only `disconnect` / `discoverSupportedPids` are counted.
class _FakeObd2Service implements Obd2Service {
  int disconnectCallCount = 0;
  int reprobeCallCount = 0;
  bool _connected = true;

  @override
  bool get busAnswered => true;

  @override
  Obd2BusProbeResult get busProbe => Obd2BusProbeResult.answered;

  @override
  bool get isConnected => _connected;

  @override
  int get sessionSuccessfulObdSends => 0;

  @override
  Future<Set<int>> discoverSupportedPids() async {
    reprobeCallCount++;
    return const <int>{};
  }

  @override
  Future<void> disconnect() async {
    disconnectCallCount++;
    _connected = false;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
