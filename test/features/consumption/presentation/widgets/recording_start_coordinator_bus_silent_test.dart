// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'obd2_connection_errors.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/'
    'recording_start_coordinator.dart';
import 'package:tankstellen/features/consumption/providers/'
    'trip_recording_provider.dart';
import '../../../../helpers/silence_error_logger.dart';

/// #2892 — the coordinator must NOT start a degraded GPS-only trip when the
/// service connected but the vehicle bus never answered (`busAnswered ==
/// false`). It must instead surface the existing localized "turn the ignition
/// on" condition ([Obd2AdapterUnresponsive]), roll the connecting phase back,
/// and tear down the dead link — never calling `notifier.start(service)`.
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
      'a silent-bus connect surfaces Obd2AdapterUnresponsive, disconnects, '
      'and never calls notifier.start (#2892)', (tester) async {
    final service = _FakeObd2Service(busAnswered: false);
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

    // The EXISTING localized "turn the ignition on" condition is surfaced.
    expect(errors, hasLength(1));
    expect(errors.single, isA<Obd2AdapterUnresponsive>(),
        reason: 'silent bus must surface the ignition-off condition');

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
    final service = _FakeObd2Service(busAnswered: true);
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

/// Fake [Obd2Service] whose `busAnswered` is fixed by the test and whose
/// `disconnect` is counted. Everything else is unreachable in these tests.
class _FakeObd2Service implements Obd2Service {
  _FakeObd2Service({required bool busAnswered})
      : busAnsweredValue = busAnswered;

  final bool busAnsweredValue;
  int disconnectCallCount = 0;

  @override
  bool get busAnswered => busAnsweredValue;

  @override
  Future<void> disconnect() async {
    disconnectCallCount++;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
