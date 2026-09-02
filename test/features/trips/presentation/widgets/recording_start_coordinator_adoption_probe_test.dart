// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_link_supervisor.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_link_drop_signal.dart';
import 'package:tankstellen/features/obd2/providers/obd2_reconnect_provider.dart';
import 'package:tankstellen/features/trips/presentation/widgets/recording_start_coordinator.dart';
import 'package:tankstellen/features/trips/providers/trip_recording_provider.dart';
import '../../../../helpers/silence_error_logger.dart';

/// #3915 (Epic #3914) — a REUSED supervised link is adopted by the start
/// flow only after a real round-trip. The 2026-09-01 field trip started
/// on an owner-held instance whose transport flag said connected while
/// every command threw instantly, and recorded 43 minutes with zero
/// engine data. A mute link gets ONE fresh dial through the owner's
/// single flight (the #3571 rung's shape); a link that answers starts
/// untouched.
void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<({WidgetRef ref, _SpyTripRecording notifier})> pump(
    WidgetTester tester, {
    required Obd2LinkSupervisor sup,
  }) async {
    late WidgetRef captured;
    late _SpyTripRecording notifier;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tripRecordingProvider.overrideWith(_SpyTripRecording.new),
          obd2ReconnectProvider.overrideWith(() => _SupervisorStub(sup)),
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
      '#3915 — a reused supervised link that fails the liveness probe '
      'gets ONE fresh dial through the owner before start', (tester) async {
    final mute = _FakeObd2Service(answersProbe: false);
    final fresh = _FakeObd2Service(answersProbe: true);
    final dials = <Obd2Service?>[mute, fresh];
    var dialCount = 0;
    final sup = Obd2LinkSupervisor(
      dial: () async {
        dialCount++;
        return dials.isEmpty ? null : dials.removeAt(0);
      },
      drops: const Stream<Obd2LinkDropEvent>.empty(),
    );
    addTearDown(sup.dispose);
    await sup.connect();
    expect(identical(sup.service, mute), isTrue,
        reason: 'the owner holds the connected-flag corpse');

    final coordinator = RecordingStartCoordinator();
    final h = await pump(tester, sup: sup);
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
    expect(mute.probeCallCount, 1, reason: 'adoption is proven, not assumed');
    expect(dialCount, 2, reason: 'exactly one fresh dial, via the owner');
    expect(mute.disconnectCallCount, 1,
        reason: 'the owner recycled the mute instance (fresh-socket rule)');
    expect(identical(sup.service, fresh), isTrue);
    expect(h.notifier.startCallCount, 1);
    expect(identical(h.notifier.lastStartedService, fresh), isTrue,
        reason: 'the trip starts on the link that answered');
  });

  testWidgets(
      '#3915 — a reused supervised link that answers the probe starts '
      'as-is, with no extra dial', (tester) async {
    final live = _FakeObd2Service(answersProbe: true);
    var dialCount = 0;
    final sup = Obd2LinkSupervisor(
      dial: () async {
        dialCount++;
        return live;
      },
      drops: const Stream<Obd2LinkDropEvent>.empty(),
    );
    addTearDown(sup.dispose);
    await sup.connect();

    final coordinator = RecordingStartCoordinator();
    final h = await pump(tester, sup: sup);
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
    expect(live.probeCallCount, 1);
    expect(dialCount, 1, reason: 'no redial for a link that answers');
    expect(live.disconnectCallCount, 0);
    expect(identical(h.notifier.lastStartedService, live), isTrue);
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

/// Healthy-bus fake whose transport flag ALWAYS says connected; only the
/// liveness round-trip tells the mute corpse from a live link.
class _FakeObd2Service implements Obd2Service {
  _FakeObd2Service({required this.answersProbe});

  final bool answersProbe;
  int probeCallCount = 0;
  int disconnectCallCount = 0;
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
  Future<bool> probeLiveness(
      {Duration timeout = kObd2LivenessProbeTimeout}) async {
    probeCallCount++;
    return answersProbe && _connected;
  }

  @override
  Future<Set<int>> discoverSupportedPids() async => const <int>{};

  @override
  Future<void> disconnect() async {
    disconnectCallCount++;
    _connected = false;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
