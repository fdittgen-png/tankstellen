// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_connection_errors.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/'
    'recording_start_coordinator.dart';
import 'package:tankstellen/features/consumption/providers/'
    'trip_recording_provider.dart';
import '../../../../helpers/silence_error_logger.dart';

/// #2892 — the coordinator must NOT start a degraded GPS-only trip when the
/// service connected but the vehicle bus never answered (`busAnswered ==
/// false`). It must instead surface the engine-off condition — #3009 reclassed
/// this from the adapter-blaming [Obd2AdapterUnresponsive] to the accurate
/// "start the engine" [Obd2EngineOff] (the adapter DID answer every AT; only
/// the engine is off) — roll the connecting phase back, and tear down the dead
/// link — never calling `notifier.start(service)`.
void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Pump a bare [Consumer] inside a [ProviderScope] (overriding the trip
  /// recording notifier with [recordingFactory]) and hand the captured
  /// [WidgetRef] plus the MOUNTED spy notifier to [body]. Reading
  /// `.notifier` here mounts the spy so its base-class `state` access works.
  /// `connectAndStart` does not dereference `ref`, but it is a required typed
  /// parameter, so a real ref keeps the call honest.
  Future<void> withRef(
    WidgetTester tester,
    _SpyTripRecording Function() recordingFactory,
    Future<void> Function(WidgetRef ref, _SpyTripRecording notifier) body,
  ) async {
    late WidgetRef captured;
    late _SpyTripRecording notifier;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tripRecordingProvider.overrideWith(recordingFactory)],
        child: Consumer(
          builder: (_, ref, _) {
            captured = ref;
            notifier = ref.read(tripRecordingProvider.notifier)
                as _SpyTripRecording;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await body(captured, notifier);
  }

  testWidgets(
      'a CONFIRMED engine-off connect (probedSilent) surfaces Obd2EngineOff, '
      'disconnects, and never calls notifier.start (#2892, #3009, #3101)',
      (tester) async {
    // #3101 — only a `probedSilent` probe (ECU silent through every retry) is
    // a genuine engine-off. `busAnswered` is false here too, but the gate now
    // keys off the finer tri-state, not the coarse boolean.
    final service = _FakeObd2Service(
      busAnswered: false,
      busProbe: Obd2BusProbeResult.probedSilent,
    );
    final coordinator = RecordingStartCoordinator();
    final errors = <Object>[];
    late _SpyTripRecording recording;

    await withRef(tester, _SpyTripRecording.new, (ref, notifier) async {
      recording = notifier;
      // Mirror the live path: the screen is already in its connecting phase.
      notifier.enterConnecting();
      await coordinator.connectAndStart(
        ref,
        notifier: notifier,
        openPicker: () async => service,
        onConnectionError: errors.add,
        isMounted: () => true,
      );
    });

    // #3009 — the engine-off condition is surfaced with the accurate
    // "start the engine" exception, NOT the adapter-blaming one.
    expect(errors, hasLength(1));
    expect(errors.single, isA<Obd2EngineOff>(),
        reason: 'silent bus must surface the engine-off condition');

    // A degraded GPS-only trip is NOT started.
    expect(recording.startCallCount, 0,
        reason: 'notifier.start must NOT run when the bus did not answer');

    // The dead link is torn down + the connecting phase rolled back.
    expect(service.disconnectCallCount, 1,
        reason: 'the unusable link must be disconnected');
    expect(recording.cancelConnectingCallCount, greaterThanOrEqualTo(1),
        reason: 'the connecting phase must roll back to idle');
  });

  testWidgets(
      'a connect whose bus answered starts the trip as normal (#2892)',
      (tester) async {
    final service = _FakeObd2Service(
      busAnswered: true,
      busProbe: Obd2BusProbeResult.answered,
    );
    final coordinator = RecordingStartCoordinator();
    final errors = <Object>[];
    late _SpyTripRecording recording;

    await withRef(tester, _SpyTripRecording.new, (ref, notifier) async {
      recording = notifier;
      notifier.enterConnecting();
      await coordinator.connectAndStart(
        ref,
        notifier: notifier,
        openPicker: () async => service,
        onConnectionError: errors.add,
        isMounted: () => true,
      );
    });

    // The healthy path is untouched: no error, the trip starts, the link is
    // handed to the recording (NOT disconnected by the coordinator).
    expect(errors, isEmpty);
    expect(recording.startCallCount, 1,
        reason: 'a live bus must start the trip');
    expect(recording.lastStartedService, same(service));
    expect(service.disconnectCallCount, 0,
        reason: 'the live recording now owns the link');
  });

  testWidgets(
      '#3101 — a TRANSIENT probe (live-but-slow car, 0100 timed out: '
      'busAnswered=false but NOT engine-off) STARTS the trip, not bails',
      (tester) async {
    // The regression: a cache-miss first connect to a LIVE car whose `0100`
    // merely timed out during the protocol search. `busAnswered` is false
    // (no protocol digit, no PIDs yet) but `busProbe` is `transient`, NOT
    // `probedSilent`. The old gate bailed with Obd2EngineOff → "recording
    // won't start at all". The trip must start and the recording must own the
    // link so the scheduler picks up PIDs once the search converges.
    final service = _FakeObd2Service(
      busAnswered: false,
      busProbe: Obd2BusProbeResult.transient,
    );
    final coordinator = RecordingStartCoordinator();
    final errors = <Object>[];
    late _SpyTripRecording recording;

    await withRef(tester, _SpyTripRecording.new, (ref, notifier) async {
      recording = notifier;
      notifier.enterConnecting();
      await coordinator.connectAndStart(
        ref,
        notifier: notifier,
        openPicker: () async => service,
        onConnectionError: errors.add,
        isMounted: () => true,
      );
    });

    expect(errors, isEmpty,
        reason: 'a transient probe is NOT engine-off — no error');
    expect(recording.startCallCount, 1,
        reason: 'a live-but-slow car must start the trip (#3101)');
    expect(recording.lastStartedService, same(service));
    expect(service.disconnectCallCount, 0,
        reason: 'the live recording now owns the link — do not tear it down');
  });

  testWidgets(
      '#3101 — a warm cache-hit (notProbed, busAnswered=true) starts normally',
      (tester) async {
    // A pinned/paired adapter cache-hit skips discovery: `busProbe` is
    // `notProbed` and `busAnswered` trips on the cached protocol/PID set.
    final service = _FakeObd2Service(
      busAnswered: true,
      busProbe: Obd2BusProbeResult.notProbed,
    );
    final coordinator = RecordingStartCoordinator();
    final errors = <Object>[];
    late _SpyTripRecording recording;

    await withRef(tester, _SpyTripRecording.new, (ref, notifier) async {
      recording = notifier;
      notifier.enterConnecting();
      await coordinator.connectAndStart(
        ref,
        notifier: notifier,
        openPicker: () async => service,
        onConnectionError: errors.add,
        isMounted: () => true,
      );
    });

    expect(errors, isEmpty);
    expect(recording.startCallCount, 1);
  });
}

/// Spy [TripRecording] that records the calls the coordinator makes. The
/// base-class `enterConnecting` / `cancelConnecting` mutate `state` for real
/// (cheap copyWith) so the connecting phase is observable; `start` is stubbed
/// to a counter so the heavy connect/prime pipeline never runs.
class _SpyTripRecording extends TripRecording {
  int startCallCount = 0;
  int cancelConnectingCallCount = 0;
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

  @override
  void cancelConnecting() {
    cancelConnectingCallCount++;
    super.cancelConnecting();
  }
}

/// Fake [Obd2Service] whose `busAnswered` + `busProbe` are fixed by the test
/// and whose `disconnect` is counted. Everything else is unreachable here.
class _FakeObd2Service implements Obd2Service {
  _FakeObd2Service({
    required bool busAnswered,
    required Obd2BusProbeResult busProbe,
  })  : busAnsweredValue = busAnswered,
        busProbeValue = busProbe;

  final bool busAnsweredValue;
  final Obd2BusProbeResult busProbeValue;
  int disconnectCallCount = 0;

  @override
  bool get busAnswered => busAnsweredValue;

  @override
  Obd2BusProbeResult get busProbe => busProbeValue;

  @override
  Future<void> disconnect() async {
    disconnectCallCount++;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
