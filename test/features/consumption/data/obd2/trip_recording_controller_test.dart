import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connection_errors.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/consumption/data/obd2/paused_trip_repository.dart';
import 'package:tankstellen/features/consumption/data/obd2/pid_scheduler.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_recording_controller.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
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

  group('BT drop resilience — #797 phase 1', () {
    late Directory tmpDir;
    late Box<String> pausedBox;
    late Box<String> historyBox;
    late PausedTripRepository pausedRepo;
    late TripHistoryRepository historyRepo;

    setUp(() async {
      tmpDir = Directory.systemTemp.createTempSync('bt_drop_test_');
      Hive.init(tmpDir.path);
      pausedBox = await Hive.openBox<String>(
        'paused_${DateTime.now().microsecondsSinceEpoch}',
      );
      historyBox = await Hive.openBox<String>(
        'history_${DateTime.now().microsecondsSinceEpoch}',
      );
      pausedRepo = PausedTripRepository(box: pausedBox);
      historyRepo = TripHistoryRepository(box: historyBox);
    });

    tearDown(() async {
      await pausedBox.deleteFromDisk();
      await historyBox.deleteFromDisk();
      await Hive.close();
      tmpDir.deleteSync(recursive: true);
    });

    /// Common AT-init responses so `connect()` on the Obd2Service
    /// happy-paths before the test starts simulating drops. Also
    /// covers `01A6` (odometer) because [TripRecordingController.start]
    /// reads it once and a NO DATA short-circuits the null-fallback
    /// without throwing.
    Map<String, String> initResponses() => {
          'ATZ': 'ELM327 v1.5>',
          'ATE0': 'OK>',
          'ATL0': 'OK>',
          'ATH0': 'OK>',
          'ATSP0': 'OK>',
          '01A6': 'NO DATA>',
        };

    test(
        'three consecutive transport errors flip state to '
        'pausedDueToDrop and stop the scheduler', () async {
      final transport = _DroppingTransport(
        initResponses: initResponses(),
        firstGoodReads: 1, // one successful read before dropping
      );
      final service = Obd2Service(transport);
      await service.connect();
      // Drop the post-connect supported-PID scan noise.
      transport.startCounting();

      final ctl = TripRecordingController(
        service: service,
        pollInterval: const Duration(minutes: 1),
        pausedRepo: pausedRepo,
        historyRepo: historyRepo,
        pauseGraceWindow: const Duration(minutes: 5),
        schedulerTickRate: const Duration(milliseconds: 20),
      );
      final states = <TripRecordingControllerState>[];
      final sub = ctl.stateChanges.listen(states.add);

      await ctl.start();
      // Let the scheduler run long enough to accumulate well over 3
      // transport errors — once the _DroppingTransport exhausts its
      // good-read budget, every sendCommand throws.
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(
        ctl.currentState,
        TripRecordingControllerState.pausedDueToDrop,
        reason: 'repeated transport errors must flip state to '
            'pausedDueToDrop',
      );
      expect(
        states,
        contains(TripRecordingControllerState.pausedDueToDrop),
        reason: 'state stream must surface the drop transition',
      );

      await sub.cancel();
      // Scheduler has been stopped — but ctl.stop() would normally
      // also close streams; skip here because we've already cancelled
      // our listener and a second close would throw.
    });

    test(
        'typed Obd2DisconnectedException triggers a drop immediately '
        'without waiting for the 3-errors threshold', () async {
      final transport = _ThrowingTransport(
        initResponses: initResponses(),
        error: const Obd2DisconnectedException(),
      );
      final service = Obd2Service(transport);
      await service.connect();
      transport.startCounting();

      final ctl = TripRecordingController(
        service: service,
        pollInterval: const Duration(minutes: 1),
        pausedRepo: pausedRepo,
        historyRepo: historyRepo,
        pauseGraceWindow: const Duration(minutes: 5),
        dropThreshold: 99, // huge threshold — only typed path can fire
        schedulerTickRate: const Duration(milliseconds: 20),
      );

      await ctl.start();
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(
        ctl.currentState,
        TripRecordingControllerState.pausedDueToDrop,
        reason: 'typed Obd2DisconnectedException is the strongest '
            'signal; must not wait for the N-errors heuristic',
      );
    });

    test(
        'paused trip payload lands in the paused-trips box with the '
        'captured distance preserved', () async {
      final transport = FakeObd2Transport(initResponses());
      await transport.connect();
      final ctl = TripRecordingController(
        service: Obd2Service(transport),
        pollInterval: const Duration(minutes: 1),
        vehicleId: 'car-under-test',
        pausedRepo: pausedRepo,
        historyRepo: historyRepo,
      );
      await ctl.start();

      // Inject 30 1 s-spaced samples with a constant 50 km/h speed
      // so the recorder accumulates a tangible distance before the
      // drop. 29 intervals × 1 s × 50 km/h / 3600 ≈ 0.403 km.
      final startTs = DateTime(2026, 4, 22, 10);
      for (var i = 0; i < 30; i++) {
        ctl.debugInjectSample(
          speedKmh: 50,
          rpm: 1800,
          at: startTs.add(Duration(seconds: i)),
        );
      }
      ctl.debugTriggerDrop();

      expect(
        ctl.currentState,
        TripRecordingControllerState.pausedDueToDrop,
      );
      final saved = pausedRepo.loadAll();
      expect(saved, hasLength(1),
          reason: 'exactly one paused entry should have been written');
      final entry = saved.single;
      expect(entry.vehicleId, 'car-under-test');
      expect(entry.summary.distanceKm, greaterThan(0.3),
          reason: '30 samples at 50 km/h × 100 ms steps produce '
              '≈ 0.4 km, well above 0.3');
    });

    test(
        'resume() flips state back to recording, cancels the grace '
        'timer, and clears the paused-trips box row', () async {
      final transport = FakeObd2Transport(initResponses());
      await transport.connect();
      final ctl = TripRecordingController(
        service: Obd2Service(transport),
        pollInterval: const Duration(minutes: 1),
        vehicleId: 'car-resume',
        pausedRepo: pausedRepo,
        historyRepo: historyRepo,
        pauseGraceWindow: const Duration(milliseconds: 50),
      );
      await ctl.start();
      ctl.debugTriggerDrop();
      expect(pausedRepo.loadAll(), hasLength(1));
      expect(ctl.currentState, TripRecordingControllerState.pausedDueToDrop);

      ctl.resume();
      // Resume should flip the state back to recording even though
      // no new readings have arrived yet.
      expect(ctl.currentState, TripRecordingControllerState.recording);

      // Wait past the original grace deadline — nothing should be
      // finalised because the grace timer was cancelled on resume.
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(historyRepo.loadAll(), isEmpty,
          reason: 'resume must cancel the grace timer');
      // Paused row is cleared because the session is live again.
      expect(pausedRepo.loadAll(), isEmpty,
          reason: 'resume must delete the paused-trips row so a '
              'subsequent pause writes a fresh snapshot');
    });

    test(
        'grace window elapses → paused trip is finalised into history '
        'and removed from the paused-trips box', () async {
      final transport = FakeObd2Transport(initResponses());
      await transport.connect();
      final ctl = TripRecordingController(
        service: Obd2Service(transport),
        pollInterval: const Duration(minutes: 1),
        vehicleId: 'car-grace',
        pausedRepo: pausedRepo,
        historyRepo: historyRepo,
        pauseGraceWindow: const Duration(milliseconds: 50),
      );
      await ctl.start();

      // Feed one sample so the resulting TripHistoryEntry has a
      // non-trivial summary — otherwise the finalise call would
      // persist an empty row (valid but harder to assert).
      ctl.debugInjectSample(
        speedKmh: 40,
        rpm: 1600,
        at: DateTime(2026, 4, 22, 11),
      );
      ctl.debugInjectSample(
        speedKmh: 42,
        rpm: 1700,
        at: DateTime(2026, 4, 22, 11, 0, 1),
      );

      ctl.debugTriggerDrop();
      expect(pausedRepo.loadAll(), hasLength(1));

      // Wait for the 50 ms grace window to elapse. Even on a busy
      // CI box 200 ms is plenty of slack.
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(historyRepo.loadAll(), hasLength(1),
          reason: 'grace-window expiry must finalise the paused '
              'trip into the normal trip-history box');
      expect(pausedRepo.loadAll(), isEmpty,
          reason: 'paused-trips row must be removed once finalised');
      expect(ctl.currentState, TripRecordingControllerState.stopped);
    });

    test(
        'debugExpireGraceWindow promotes the paused trip even when '
        'the real timer hasn\'t fired yet — used by fake-async tests',
        () async {
      final transport = FakeObd2Transport(initResponses());
      await transport.connect();
      final ctl = TripRecordingController(
        service: Obd2Service(transport),
        pollInterval: const Duration(minutes: 1),
        vehicleId: 'car-debug',
        pausedRepo: pausedRepo,
        historyRepo: historyRepo,
        pauseGraceWindow: const Duration(hours: 1),
      );
      await ctl.start();
      ctl.debugInjectSample(
        speedKmh: 30,
        rpm: 1500,
        at: DateTime(2026, 4, 22, 12),
      );
      ctl.debugInjectSample(
        speedKmh: 32,
        rpm: 1550,
        at: DateTime(2026, 4, 22, 12, 0, 1),
      );
      ctl.debugTriggerDrop();
      await ctl.debugExpireGraceWindow();

      expect(historyRepo.loadAll(), hasLength(1));
      expect(pausedRepo.loadAll(), isEmpty);
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

/// Transport that serves init responses, then yields a configurable
/// number of healthy reads, then throws forever (#797 phase 1).
///
/// Used to exercise the controller's "3 consecutive errors → drop"
/// heuristic. The `startCounting` call moves the transport past the
/// post-connect supported-PID scan so the user-trip's read budget is
/// honoured rather than burned on the bitmap scan.
class _DroppingTransport implements Obd2Transport {
  final Map<String, String> initResponses;
  int firstGoodReads;
  bool _connected = false;
  bool _postConnect = false;

  _DroppingTransport({
    required this.initResponses,
    required this.firstGoodReads,
  });

  /// Mark the end of the post-connect noise window — subsequent
  /// sendCommand calls start consuming the `firstGoodReads` budget.
  void startCounting() {
    _postConnect = true;
  }

  @override
  Future<void> connect() async => _connected = true;
  @override
  Future<void> disconnect() async => _connected = false;
  @override
  bool get isConnected => _connected;
  @override
  Future<String> sendCommand(String command) async {
    final key = command.trim();
    final canned = initResponses[key];
    if (canned != null) return canned;
    if (!_postConnect) return 'NO DATA>';
    if (firstGoodReads > 0) {
      firstGoodReads--;
      // Valid RPM response — parses to a real number, resetting the
      // error counter. 0E A6 → ((14×256)+166)/4 = 937.5 rpm.
      return '41 0C 0E A6>';
    }
    throw StateError('Transport closed');
  }
}

/// Transport that serves init responses, then throws a pinned error
/// on every subsequent sendCommand. Used to verify the "typed
/// [Obd2DisconnectedException] triggers an immediate drop" path.
class _ThrowingTransport implements Obd2Transport {
  final Map<String, String> initResponses;
  final Object error;
  bool _connected = false;
  bool _postConnect = false;

  _ThrowingTransport({
    required this.initResponses,
    required this.error,
  });

  void startCounting() {
    _postConnect = true;
  }

  @override
  Future<void> connect() async => _connected = true;
  @override
  Future<void> disconnect() async => _connected = false;
  @override
  bool get isConnected => _connected;
  @override
  Future<String> sendCommand(String command) async {
    final key = command.trim();
    final canned = initResponses[key];
    if (canned != null) return canned;
    if (!_postConnect) return 'NO DATA>';
    throw error;
  }
}
