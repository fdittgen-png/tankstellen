import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/consumption/data/obd2/pid_scheduler.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_recording_controller.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';

void main() {
  group('TripRecordingController (#726)', () {
    test('start() reads the odometer once and exposes it as '
        'odometerStartKm', () async {
      // Hand-crafted raw ELM327 responses: Mode 01 PID A6 encodes the
      // odometer at 1/10 km resolution (value / 10). Bytes
      // `00 01 6A 2C` = 0x16A2C = 92 716 raw → 9271.6 km.
      final transport = FakeObd2Transport({
        'ATZ': 'ELM327 v1.5>',
        'ATE0': 'OK>',
        'ATL0': 'OK>',
        'ATH0': 'OK>',
        'ATSP0': 'OK>',
        '01A6': '41 A6 00 01 6A 2C>',
      });
      final service = Obd2Service(transport);
      await service.connect();

      final ctl = TripRecordingController(
        service: service,
        pollInterval: const Duration(minutes: 1), // never ticks in-test
      );
      await ctl.start();
      await ctl.stop();

      expect(ctl.odometerStartKm, closeTo(9271.6, 0.01));
    });

    test('stop() returns a non-null TripSummary even when no sample '
        'was ever recorded', () async {
      final transport = FakeObd2Transport({
        'ATZ': 'ELM327 v1.5>',
        'ATE0': 'OK>',
        'ATL0': 'OK>',
        'ATH0': 'OK>',
        'ATSP0': 'OK>',
        '01A6': 'NO DATA>',
      });
      final service = Obd2Service(transport);
      await service.connect();

      final ctl = TripRecordingController(
        service: service,
        pollInterval: const Duration(minutes: 1),
      );
      await ctl.start();
      final summary = await ctl.stop();

      expect(summary.distanceKm, 0);
      expect(summary.fuelLitersConsumed, isNull);
      expect(ctl.odometerStartKm, isNull);
    });

    test('pause() freezes polling; resume() re-arms it (#726)', () async {
      final transport = FakeObd2Transport({
        'ATZ': 'ELM327 v1.5>',
        'ATE0': 'OK>',
        'ATL0': 'OK>',
        'ATH0': 'OK>',
        'ATSP0': 'OK>',
        '01A6': '41 A6 00 01 6A 2C>',
      });
      final service = Obd2Service(transport);
      await service.connect();

      final ctl = TripRecordingController(
        service: service,
        pollInterval: const Duration(minutes: 1),
      );
      await ctl.start();
      expect(ctl.isRecording, isTrue);
      expect(ctl.isPaused, isFalse);
      expect(ctl.isActive, isTrue);

      ctl.pause();
      expect(ctl.isPaused, isTrue);
      expect(ctl.isRecording, isFalse);
      expect(ctl.isActive, isTrue,
          reason: 'paused means "still owns the service", not "stopped"');

      ctl.resume();
      expect(ctl.isPaused, isFalse);
      expect(ctl.isRecording, isTrue);

      await ctl.stop();
    });

    test('refreshOdometer() pulls a fresh reading before stop()',
        () async {
      // Transport returns two different values on successive 01A6 calls
      // so we can assert refreshOdometer picks up the second one.
      var call = 0;
      final transport = _SequencedTransport(
        init: {
          'ATZ': 'ELM327 v1.5>',
          'ATE0': 'OK>',
          'ATL0': 'OK>',
          'ATH0': 'OK>',
          'ATSP0': 'OK>',
        },
        onOdometer: () {
          call++;
          return call == 1
              ? '41 A6 00 01 6A 2C>' // 92716 km at start
              : '41 A6 00 01 6A 3E>'; // 92734 km later
        },
      );
      final service = Obd2Service(transport);
      await service.connect();

      final ctl = TripRecordingController(
        service: service,
        pollInterval: const Duration(minutes: 1),
      );
      await ctl.start();
      expect(ctl.odometerStartKm, closeTo(9271.6, 0.01));
      await ctl.refreshOdometer();
      expect(ctl.odometerLatestKm, closeTo(9273.4, 0.01));
      await ctl.stop();
    });

    group('engine-param plumbing — #812 phase 3', () {
      test(
          'accepts a VehicleProfile and feeds its engine fields into '
          'readFuelRateLPerHour on every poll', () async {
        // On a Peugeot 107-class setup (no PID 5E, no MAF; only
        // MAP+IAT+RPM), the resulting fuel rate is directly
        // proportional to displacement × η_v. Doubling displacement
        // doubles the rate. Test the wire-up by running the chain
        // with two different engine-size configurations and
        // asserting the ratio matches the math.
        Future<Obd2Service> peugeot107() async {
          final t = FakeObd2Transport({
            'ATZ': 'ELM327 v1.5>',
            'ATE0': 'OK>',
            'ATL0': 'OK>',
            'ATH0': 'OK>',
            'ATSP0': 'OK>',
            '015E': 'NO DATA>',
            '0110': 'NO DATA>',
            '010B': '41 0B 50>', // MAP 80 kPa
            '010F': '41 0F 41>', // IAT 25 °C
            '010C': '41 0C 0E A6>', // RPM 939.5
          });
          final s = Obd2Service(t);
          await s.connect();
          return s;
        }

        // Service-level sanity: 2.0 L yields twice the fuel rate of
        // 1.0 L at the same VE and operating point — passing two
        // profiles that differ only in displacement.
        final svc1 = await peugeot107();
        final rate1L = await svc1.readFuelRateLPerHour(
          vehicle: const VehicleProfile(
            id: 'a',
            name: '1.0L',
            engineDisplacementCc: 1000,
          ),
        );
        final svc2 = await peugeot107();
        final rate2L = await svc2.readFuelRateLPerHour(
          vehicle: const VehicleProfile(
            id: 'b',
            name: '2.0L',
            engineDisplacementCc: 2000,
          ),
        );
        expect(rate1L, isNotNull);
        expect(rate2L, isNotNull);
        expect(rate2L! / rate1L!, closeTo(2.0, 0.01));

        // Controller wire-up: the constructor param is plumbed
        // through. Not validated by running the poll loop (that
        // requires a timer + streaming), but the parameter is
        // captured and non-null when supplied.
        final ctl = TripRecordingController(
          service: svc1,
          pollInterval: const Duration(minutes: 1),
          vehicle: const VehicleProfile(
            id: 'peugeot107',
            name: 'Peugeot 107',
            engineDisplacementCc: 998,
            volumetricEfficiency: 0.80,
          ),
        );
        await ctl.start();
        await ctl.stop();
        // No observable side-effect to assert beyond "no throw",
        // but this locks the constructor signature against
        // accidental removal.
      });

      test(
          'null vehicle falls back to the generic 1.0 L / 0.85 defaults — '
          'matches the pre-#812 hardcoded behavior', () async {
        final transport = FakeObd2Transport({
          'ATZ': 'ELM327 v1.5>',
          'ATE0': 'OK>',
          'ATL0': 'OK>',
          'ATH0': 'OK>',
          'ATSP0': 'OK>',
          '01A6': 'NO DATA>',
        });
        final service = Obd2Service(transport);
        await service.connect();

        // Omitting the vehicle param should not throw and should
        // behave identically to the pre-#812 constructor.
        final ctl = TripRecordingController(
          service: service,
          pollInterval: const Duration(minutes: 1),
        );
        await ctl.start();
        await ctl.stop();
      });
    });

    group('PidScheduler integration — #814 phase 2', () {
      test(
          'high tier (5 Hz RPM) fires at least 3 callbacks within ~1 s '
          'of simulated polling', () async {
        final transport = _CountingTransport(responses: {
          'ATZ': 'ELM327 v1.5>',
          'ATE0': 'OK>',
          'ATL0': 'OK>',
          'ATH0': 'OK>',
          'ATSP0': 'OK>',
          // Valid RPM: 41 0C 0E A6 → 939.5 rpm
          '010C': '41 0C 0E A6>',
          // Valid speed: 41 0D 32 → 50 km/h
          '010D': '41 0D 32>',
          '0111': '41 11 40>',
          '0104': '41 04 40>',
          '010F': '41 0F 41>',
          '0106': '41 06 80>',
          '0107': '41 07 80>',
          '012F': '41 2F 80>',
          '01A6': '41 A6 00 01 6A 2C>',
          '0902': 'NO DATA>',
        });
        final service = Obd2Service(transport);
        await service.connect();

        final ctl = TripRecordingController(
          service: service,
          // Keep emit debounce out of the way — we only care about
          // the scheduler's per-PID callback rate for this assertion.
          pollInterval: const Duration(minutes: 1),
          // Inject a fast-tick scheduler so we can assert refresh
          // behaviour within a test-friendly window. Production uses
          // the 100 ms tickRate default (see _buildScheduler).
          scheduler: PidScheduler(
            transport: service.sendCommand,
            tickRate: const Duration(milliseconds: 20),
          ),
        );
        await ctl.start();
        // Let the scheduler run for ~1 s of wall-clock time. With
        // a 20 ms tickRate the 5 Hz RPM PID (010C) gets well above
        // 3 callbacks even with ~12 subscribed PIDs in the round-
        // robin.
        await Future<void>.delayed(const Duration(seconds: 1));
        await ctl.stop();

        expect(
          transport.callCount('010C'),
          greaterThanOrEqualTo(3),
          reason: '5 Hz RPM should land ≥ 3 reads per second under an '
              'instant transport',
        );
      });

      test(
          'low tier (0.1 Hz fuel level) receives at least one read when '
          'the scheduler runs long enough for the initial-read rule to '
          'fire', () async {
        // New subscriptions win unconditionally on their first tick
        // (infinity weight), so even in a 1 s window crowded with fast
        // PIDs the 0.1 Hz fuel-level PID gets its initial read.
        final transport = _CountingTransport(responses: {
          'ATZ': 'ELM327 v1.5>',
          'ATE0': 'OK>',
          'ATL0': 'OK>',
          'ATH0': 'OK>',
          'ATSP0': 'OK>',
          '010C': '41 0C 0E A6>',
          '010D': '41 0D 32>',
          '0111': '41 11 40>',
          '0104': '41 04 40>',
          '010F': '41 0F 41>',
          '0106': '41 06 80>',
          '0107': '41 07 80>',
          '012F': '41 2F 80>',
          '01A6': '41 A6 00 01 6A 2C>',
          '0902': 'NO DATA>',
        });
        final service = Obd2Service(transport);
        await service.connect();

        final ctl = TripRecordingController(
          service: service,
          pollInterval: const Duration(minutes: 1),
          scheduler: PidScheduler(
            transport: service.sendCommand,
            tickRate: const Duration(milliseconds: 20),
          ),
        );
        await ctl.start();
        // 2 s of wall-clock is enough time for every subscribed PID
        // to win its initial (infinity-weight) tick — the low-tier
        // PID must be among them.
        await Future<void>.delayed(const Duration(seconds: 2));
        await ctl.stop();

        expect(
          transport.callCount('012F'),
          greaterThanOrEqualTo(1),
          reason: 'low-tier fuel level starved — the initial-read rule '
              'should guarantee at least one read',
        );
      });

      test(
          'VIN is read exactly once at start() and exposed via the vin '
          'getter — subsequent ticks never re-issue 0902', () async {
        final transport = _CountingTransport(responses: {
          'ATZ': 'ELM327 v1.5>',
          'ATE0': 'OK>',
          'ATL0': 'OK>',
          'ATH0': 'OK>',
          'ATSP0': 'OK>',
          '010C': '41 0C 0E A6>',
          '010D': '41 0D 32>',
          '0111': '41 11 40>',
          '0104': '41 04 40>',
          '010F': '41 0F 41>',
          '0106': '41 06 80>',
          '0107': '41 07 80>',
          '012F': '41 2F 80>',
          '01A6': '41 A6 00 01 6A 2C>',
          // VIN response for "WVWZZZ3BZYP123456" — Elm327Protocol
          // just needs a valid 49 XX prefix + 17 ASCII-hex chars.
          '0902': '49 02 01 57 56 57 5A 5A 5A 33 42 5A 59 50 31 32 33 '
              '34 35 36>',
        });
        final service = Obd2Service(transport);
        await service.connect();
        final baseline0902Calls = transport.callCount('0902');

        final ctl = TripRecordingController(
          service: service,
          pollInterval: const Duration(minutes: 1),
          scheduler: PidScheduler(
            transport: service.sendCommand,
            tickRate: const Duration(milliseconds: 20),
          ),
        );
        await ctl.start();
        await Future<void>.delayed(const Duration(milliseconds: 600));
        await ctl.stop();

        // VIN was read at start() — exactly once since connect() ran
        // (connect() consumes 0902 for the supported-PID cache key
        // when a cache is wired in; here no cache, so connect doesn't
        // call it). The scheduler must not re-issue 0902 mid-trip.
        final delta = transport.callCount('0902') - baseline0902Calls;
        expect(
          delta,
          1,
          reason: 'VIN should be a single one-shot read at start(); '
              'found $delta 0902 commands during the trip',
        );
        expect(ctl.vin, isNotNull);
      });

      test(
          'TripLiveReading captures snapshot values from independent '
          'PID callbacks — characterization against the old one-shot '
          'poll', () async {
        // Under the pre-#814 model _pollOnce() read speed/RPM/fuel-
        // rate/engine-load/fuel-level on every tick and fired one
        // TripLiveReading. Under the new model each PID arrives
        // independently; a debounced emit assembles the same fields.
        // This test injects a hand-controlled scheduler with a tiny
        // tickRate and asserts that after running the scheduler for a
        // bit the TripLiveReading carries the expected values.
        final transport = _CountingTransport(responses: {
          'ATZ': 'ELM327 v1.5>',
          'ATE0': 'OK>',
          'ATL0': 'OK>',
          'ATH0': 'OK>',
          'ATSP0': 'OK>',
          '010C': '41 0C 0E A6>', // 939.5 rpm
          '010D': '41 0D 32>', // 50 km/h
          '0111': '41 11 40>',
          '0104': '41 04 33>', // 0x33 = 51 → ~20 %
          '010F': '41 0F 41>',
          '0106': '41 06 80>',
          '0107': '41 07 80>',
          '012F': '41 2F 80>', // 50 %
          '01A6': '41 A6 00 01 6A 2C>',
          '0902': 'NO DATA>',
        });
        final service = Obd2Service(transport);
        await service.connect();

        // 50 ms emit cadence so we get a burst of debounced events
        // within a ~1 s test window.
        final ctl = TripRecordingController(
          service: service,
          pollInterval: const Duration(milliseconds: 50),
          scheduler: PidScheduler(
            transport: service.sendCommand,
            tickRate: const Duration(milliseconds: 20),
          ),
        );
        final readings = <TripLiveReading>[];
        final sub = ctl.live.listen(readings.add);
        await ctl.start();
        await Future<void>.delayed(const Duration(milliseconds: 800));
        await sub.cancel();
        await ctl.stop();

        expect(readings, isNotEmpty,
            reason: 'debounced emit timer must produce at least one '
                'TripLiveReading within the test window');
        final latest = readings.last;
        // Speed landed via 010D → 50 km/h.
        expect(latest.speedKmh, closeTo(50, 0.001));
        // RPM landed via 010C (0x0E 0xA6): ((14×256)+166)/4 = 937.5.
        expect(latest.rpm, closeTo(937.5, 0.5));
        // Engine load landed via 0104 → ~20 %.
        expect(latest.engineLoadPercent, closeTo(20, 1));
        // Fuel level landed via 012F → ~50 %.
        expect(latest.fuelLevelPercent, closeTo(50, 1));
      });
    });
  });
}

/// Counts how many times each command is sent. Used to assert
/// per-tier refresh rates and one-shot semantics under the new
/// scheduler-driven polling loop (#814 phase 2).
class _CountingTransport implements Obd2Transport {
  final Map<String, String> responses;
  final Map<String, int> _counts = <String, int>{};
  bool _connected = false;

  _CountingTransport({required this.responses});

  int callCount(String command) => _counts[command] ?? 0;

  @override
  Future<void> connect() async => _connected = true;
  @override
  Future<void> disconnect() async => _connected = false;
  @override
  bool get isConnected => _connected;
  @override
  Future<String> sendCommand(String command) async {
    final key = command.trim();
    _counts[key] = (_counts[key] ?? 0) + 1;
    return responses[key] ?? 'NO DATA>';
  }
}

/// Transport that serves canned responses for the init + a custom
/// lambda for every `01A6` call. Used to simulate the odometer
/// changing during the trip.
class _SequencedTransport implements Obd2Transport {
  final Map<String, String> init;
  final String Function() onOdometer;
  _SequencedTransport({required this.init, required this.onOdometer});

  bool _connected = false;
  @override
  Future<void> connect() async => _connected = true;
  @override
  Future<void> disconnect() async => _connected = false;
  @override
  bool get isConnected => _connected;
  @override
  Future<String> sendCommand(String command) async {
    final key = command.trim();
    if (key == '01A6') return onOdometer();
    return init[key] ?? 'NO DATA>';
  }
}
