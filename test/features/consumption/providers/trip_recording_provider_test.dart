import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';

void main() {
  group('tripRecordingProvider (#726)', () {
    test('defaults to idle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(tripRecordingProvider);
      expect(state.phase, TripRecordingPhase.idle);
      expect(state.isActive, isFalse);
    });

    test('start + stop round trip leaves the state in finished '
        'with a valid summary', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = Obd2Service(FakeObd2Transport(_elmOk()));
      await service.connect();

      final notifier = container.read(tripRecordingProvider.notifier);
      await notifier.start(service);
      expect(
        container.read(tripRecordingProvider).phase,
        TripRecordingPhase.recording,
      );
      expect(container.read(tripRecordingProvider).isActive, isTrue);

      final result = await notifier.stop();
      expect(
        container.read(tripRecordingProvider).phase,
        TripRecordingPhase.finished,
      );
      expect(container.read(tripRecordingProvider).isActive, isFalse);
      expect(result.endOdometerKm, closeTo(9271.6, 0.01));
    });

    test('pause flips state to paused without disconnecting the service',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = Obd2Service(FakeObd2Transport(_elmOk()));
      await service.connect();

      final notifier = container.read(tripRecordingProvider.notifier);
      await notifier.start(service);
      notifier.pause();

      final state = container.read(tripRecordingProvider);
      expect(state.phase, TripRecordingPhase.paused);
      expect(state.isActive, isTrue,
          reason: 'paused trips still own the service');

      notifier.resume();
      expect(
        container.read(tripRecordingProvider).phase,
        TripRecordingPhase.recording,
      );

      await notifier.stop();
    });

    test('reset() returns to idle — used after the save/discard step',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = Obd2Service(FakeObd2Transport(_elmOk()));
      await service.connect();

      final notifier = container.read(tripRecordingProvider.notifier);
      await notifier.start(service);
      await notifier.stop();
      notifier.reset();

      expect(
        container.read(tripRecordingProvider).phase,
        TripRecordingPhase.idle,
      );
    });

    test('calling start() twice is a no-op for the second call', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final a = Obd2Service(FakeObd2Transport(_elmOk()));
      final b = Obd2Service(FakeObd2Transport(_elmOk()));
      await a.connect();
      await b.connect();

      final notifier = container.read(tripRecordingProvider.notifier);
      await notifier.start(a);
      // Second start while recording should not replace the service
      // underneath — the provider has to finish first.
      await notifier.start(b);

      expect(
        container.read(tripRecordingProvider).phase,
        TripRecordingPhase.recording,
      );

      await notifier.stop();
      // b was never wired in; clean it up manually.
      await b.disconnect();
    });
  });
}

Map<String, String> _elmOk() => const {
      'ATZ': 'ELM327 v1.5>',
      'ATE0': 'OK>',
      'ATL0': 'OK>',
      'ATH0': 'OK>',
      'ATSP0': 'OK>',
      '01A6': '41 A6 00 01 6A 2C>',
    };
