// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_breadcrumb_collector.dart';
import 'package:tankstellen/features/obd2/data/session/live_sample_snapshot.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_transport.dart';
import 'package:tankstellen/features/obd2/domain/fuel_mixture_model.dart';
import 'package:tankstellen/features/obd2/domain/pid_scheduler.dart';

/// #4159 — pins the [LiveSampleSnapshot] read facade before its latches
/// move into a per-signal store: which frame lands in which `latest*`
/// getter, which callbacks feed the silent-failure observer and the
/// odometer, that a NO DATA answer never clears a landed value, that the
/// ordinary latches hold forever while measured φ (10 s) and the
/// speed-density IAT (12 s) expire at an inclusive edge, and what
/// `deriveFuelRateLPerHour` returns with its provenance per branch.
///
/// Real parsers and real callbacks; delivery is driven by hand (a
/// capturing scheduler) so the clock is exact. Literal commands and
/// frames on purpose — the pin must not borrow the vocabulary it guards.

class _StubTransport implements Obd2Transport {
  @override
  bool get isConnected => true;
  @override
  Future<void> connect() async {}
  @override
  Future<void> disconnect() async {}
  @override
  Future<String> sendCommand(String command) async => 'NO DATA';
}

class _Capture extends PidScheduler {
  _Capture() : super(transport: (_) async => 'NO DATA');

  final Map<String, void Function(String)> callbacks = {};

  @override
  void subscribe(
    String command,
    ScheduledPid config,
    void Function(String response) onResult,
  ) {
    callbacks[command] = onResult;
  }

  void deliver(String command, String frame) => callbacks[command]!(frame);
}

class _Clock {
  _Clock(this.now);
  DateTime now;
  DateTime call() => now;
  void advance(Duration d) => now = now.add(d);
}

/// Every PID the snapshot knows, resolved — so the strict precision
/// families subscribe too.
const _everything = <int>{
  0x0C, 0x0D, 0x11, 0x04, 0x0F, 0x05, 0x06, 0x07, 0x2F, 0x10, 0x0B, 0x5E,
  0x44, 0x33, 0x49, 0x4A, 0x4B, 0x43, 0x08, 0x09, 0x5C, 0x46, 0x0E, //
  0x24, 0x34, 0x66, 0x9D, 0xA2, 0x52,
};

/// One valid frame per subscribed command, with distinct values so a
/// crossed wire shows.
const _frames = <String, String>{
  '010C\r': '41 0C 1A F8', // rpm 1726
  '010D\r': '41 0D 3C', // 60 km/h
  '0111\r': '41 11 80', // throttle 128/255
  '0149\r': '41 49 33', // pedal D 51/255
  '014A\r': '41 4A 4D', // pedal E 77/255
  '014B\r': '41 4B 1A', // pedal F 26/255
  '015E\r': '41 5E 00 64', // 5.0 L/h
  '0110\r': '41 10 04 00', // MAF 10.24 g/s
  '010B\r': '41 0B 64', // MAP 100 kPa
  '0144\r': '41 44 8C CD', // commanded φ 0x8CCD/32768
  '0104\r': '41 04 66', // load 102/255
  '0143\r': '41 43 01 00', // abs load 256/255
  '0106\r': '41 06 8D', // STFT +13/128
  '0107\r': '41 07 7A', // LTFT −6/128
  '0108\r': '41 08 84', // STFT2 +4/128
  '0109\r': '41 09 7C', // LTFT2 −4/128
  '010F\r': '41 0F 3C', // IAT 20 °C
  '010E\r': '41 0E 94', // timing 10°
  '0133\r': '41 33 5F', // baro 95 kPa
  '0105\r': '41 05 7B', // coolant 83 °C
  '012F\r': '41 2F B3', // tank 179/255
  '015C\r': '41 5C 82', // oil 90 °C
  '0146\r': '41 46 32', // ambient 10 °C
  '0124\r': '41 24 66 66 32 DD', // measured φ 0x6666/32768
  '0134\r': '41 34 C0 00 00 00', // measured φ 1.5
  '0166\r': '41 66 01 05 40', // MAF66 42 g/s
  '019D\r': '41 9D 01 F4 00 00', // 10 g/s
  '01A2\r': '41 A2 02 80', // 20 mg/stroke
  '0152\r': '41 52 D9', // ethanol 217/255
};

class _Harness {
  _Harness(Set<int> supported)
      : clock = _Clock(DateTime.utc(2026, 9, 16, 12)),
        scheduler = _Capture() {
    snapshot = LiveSampleSnapshot(
      service: _Service(supported),
      breadcrumbCollector: collector,
      onHighPriorityParse: highPriority.add,
      onSpeedSample: speeds.add,
      clock: clock.call,
    );
    snapshot.subscribeAllTiers(scheduler);
  }

  final _Clock clock;
  final _Capture scheduler;
  final collector = Obd2BreadcrumbCollector();
  final highPriority = <Object?>[];
  final speeds = <double>[];
  late final LiveSampleSnapshot snapshot;

  void deliver(String command) =>
      scheduler.deliver(command, _frames[command]!);
}

class _Service extends Obd2Service {
  _Service(Set<int> supported) : super(_StubTransport()) {
    debugSetSupportedPids(supported);
  }
}

double _pct(int byte) => byte * 100.0 / 255.0;
double _trim(int byte) => (byte - 128) * 100.0 / 128.0;

void main() {
  test('before anything lands every getter is null and no branch resolves',
      () {
    final h = _Harness(_everything);
    final s = h.snapshot;
    expect(
      [
        s.latestSpeedKmh, s.latestRpm, s.latestThrottlePercent,
        s.latestEngineLoadPercent, s.latestCoolantTempC,
        s.latestFuelLevelPercent, s.latestCommandedPhi, s.latestBaroKpa,
        s.latestAbsLoadPercent, s.latestMeasuredPhi, s.latestEthanolPercent,
        s.latestPedalPercent, s.latestOilTempC, s.latestAmbientTempC,
        s.latestIatCelsius, s.latestTimingAdvanceDeg, s.latestMaf,
        s.latestMapKpa, s.latestStft, s.latestLtft,
      ],
      everyElement(isNull),
    );
    expect(s.lastFuelRateSource, isNull);
    expect(s.deriveFuelRateLPerHour(), isNull);
    expect(s.lastFuelRateSource, FuelRateSourceTag.none);
    expect(s.lastFuelRateBranch, Obd2BranchTag.none);
    expect(s.lastFuelRateVe, isNull);
  });

  test('every frame lands in its own getter; observer + odometer taps', () {
    final h = _Harness(_everything);
    expect(h.scheduler.callbacks.keys.toSet(), _frames.keys.toSet());
    for (final command in _frames.keys) {
      h.deliver(command);
    }
    final s = h.snapshot;
    expect(s.latestRpm, 1726.0);
    expect(s.latestSpeedKmh, 60.0);
    expect(s.latestThrottlePercent, _pct(0x80));
    expect(s.latestPedalPercent, _pct(0x4D), reason: 'max of D/E/F');
    expect(s.latestMaf, closeTo(10.24, 1e-9));
    expect(s.latestMapKpa, 100.0);
    expect(s.latestCommandedPhi, 0x8CCD / 32768.0);
    expect(s.latestEngineLoadPercent, _pct(0x66));
    expect(s.latestAbsLoadPercent, 256 * 100.0 / 255.0);
    expect(s.latestStft, _trim(0x8D));
    expect(s.latestLtft, _trim(0x7A));
    expect(s.latestIatCelsius, 20.0);
    expect(s.latestTimingAdvanceDeg, 10.0);
    expect(s.latestBaroKpa, 95.0);
    expect(s.latestCoolantTempC, 83.0);
    expect(s.latestFuelLevelPercent, _pct(0xB3));
    expect(s.latestOilTempC, 90.0);
    expect(s.latestAmbientTempC, 10.0);
    expect(s.latestMeasuredPhi, 0x6666 * 2.0 / 65536.0,
        reason: '0x24 over 0x34');
    expect(s.latestEthanolPercent, _pct(0xD9));

    // The silent-failure observer hears rpm, speed, throttle, 5E, MAF and
    // MAP — in subscription order — and nothing else.
    expect(h.highPriority, [1726.0, 60, _pct(0x80), 5.0, 10.24, 100.0]);
    expect(h.speeds, [60.0]);

    // 0x9D is the top branch; E85-range ethanol picks the blended density.
    final mixture =
        resolveMixtureConstants(null, measuredEthanolPercent: _pct(0xD9));
    expect(s.deriveFuelRateLPerHour(),
        closeTo(10.0 * 3600.0 / mixture.densityGPerL, 1e-9));
    expect(s.lastFuelRateSource, FuelRateSourceTag.pid9D);
    expect(s.lastFuelRateBranch, Obd2BranchTag.pid5E);
    expect(s.lastFuelRateVe, isNull);
  });

  test('a NO DATA answer never clears a landed value, and the observer '
      'hears the null', () {
    final h = _Harness(_everything);
    h.deliver('010C\r');
    h.deliver('0105\r');
    h.scheduler.deliver('010C\r', 'NO DATA');
    h.scheduler.deliver('0105\r', 'NO DATA');
    expect(h.snapshot.latestRpm, 1726.0);
    expect(h.snapshot.latestCoolantTempC, 83.0);
    expect(h.highPriority, [1726.0, null]);
  });

  test('pedal is the max of the channels that landed, not a running max',
      () {
    final h = _Harness(_everything);
    h.scheduler.deliver('0149\r', '41 49 66'); // D 102/255
    expect(h.snapshot.latestPedalPercent, _pct(0x66));
    h.scheduler.deliver('014B\r', '41 4B 1A'); // F 26/255
    expect(h.snapshot.latestPedalPercent, _pct(0x66));
    h.scheduler.deliver('0149\r', '41 49 0D'); // D drops to 13/255
    expect(h.snapshot.latestPedalPercent, _pct(0x1A));
  });

  test('ordinary latches hold forever; measured φ expires after 10 s', () {
    final h = _Harness(_everything);
    h.deliver('010C\r');
    h.deliver('0144\r');
    h.deliver('0124\r');
    h.clock.advance(const Duration(seconds: 10));
    expect(h.snapshot.latestMeasuredPhi, isNotNull);
    h.clock.advance(const Duration(milliseconds: 1));
    expect(h.snapshot.latestMeasuredPhi, isNull);
    h.clock.advance(const Duration(hours: 1));
    expect(h.snapshot.latestRpm, 1726.0);
    expect(h.snapshot.latestCommandedPhi, 0x8CCD / 32768.0);
  });

  group('branches and provenance', () {
    test('0xA2 needs a cylinder count, so without a profile 0x5E wins', () {
      final h = _Harness(_everything);
      h.deliver('01A2\r');
      h.deliver('010C\r');
      h.deliver('015E\r');
      expect(h.snapshot.deriveFuelRateLPerHour(), 5.0);
      expect(h.snapshot.lastFuelRateSource, FuelRateSourceTag.pid5E);
      expect(h.snapshot.lastFuelRateBranch, Obd2BranchTag.pid5E);
    });

    test('MAF 0x66 over 0x10, measured φ over commanded, trims on both '
        'banks', () {
      final h = _Harness(_everything);
      for (final c in [
        '0166\r', '0110\r', '0124\r', '0144\r', //
        '0106\r', '0107\r', '0108\r', '0109\r',
      ]) {
        h.deliver(c);
      }
      final afr = effectiveAfrForMixture(kPetrolAfr,
          measuredPhi: 0x6666 * 2.0 / 65536.0,
          commandedPhi: 0x8CCD / 32768.0,
          isDiesel: false);
      final raw = 42.0 * 3600.0 / (afr * kPetrolDensityGPerL);
      expect(
        h.snapshot.deriveFuelRateLPerHour(),
        closeTo(
          applyFuelTrimCorrection(raw,
              stft: _trim(0x8D),
              ltft: _trim(0x7A),
              stftBank2: _trim(0x84),
              ltftBank2: _trim(0x7C)),
          1e-9,
        ),
      );
      expect(h.snapshot.lastFuelRateSource, FuelRateSourceTag.maf66);
      expect(h.snapshot.lastFuelRateBranch, Obd2BranchTag.maf);
      expect(h.snapshot.lastFuelRateVe, isNull);
    });

    test('MAF 0x10 alone is tagged maf', () {
      final h = _Harness(_everything);
      h.deliver('0110\r');
      expect(h.snapshot.deriveFuelRateLPerHour(),
          closeTo(10.24 * 3600.0 / (kPetrolAfr * kPetrolDensityGPerL), 1e-9));
      expect(h.snapshot.lastFuelRateSource, FuelRateSourceTag.maf);
    });

    test('speed-density with baro and commanded φ, η_v stamped', () {
      final h = _Harness(_everything);
      for (final c in ['010B\r', '010F\r', '010C\r', '0133\r', '0144\r']) {
        h.deliver(c);
      }
      final expected = estimateFuelRateLPerHourFromMap(
        mapKpa: 100.0,
        iatCelsius: 20.0,
        rpm: 1726.0,
        engineDisplacementCc: 1000,
        volumetricEfficiency: 0.85,
        afr: effectiveAfrForMixture(kPetrolAfr,
            commandedPhi: 0x8CCD / 32768.0, isDiesel: false),
        fuelDensityGPerL: kPetrolDensityGPerL,
        baroKpa: 95.0,
      );
      expect(h.snapshot.deriveFuelRateLPerHour(), closeTo(expected!, 1e-9));
      expect(h.snapshot.lastFuelRateSource, FuelRateSourceTag.speedDensity);
      expect(h.snapshot.lastFuelRateBranch, Obd2BranchTag.speedDensity);
      expect(h.snapshot.lastFuelRateVe, 0.85);
      expect(h.collector.entries.last.branch, Obd2BranchTag.speedDensity);
    });

    test('the speed-density IAT is reusable for exactly 12 s', () {
      final h = _Harness(_everything);
      h.deliver('010F\r');
      h.clock.advance(const Duration(seconds: 12));
      h.deliver('010B\r');
      h.deliver('010C\r');
      expect(h.snapshot.deriveFuelRateLPerHour(), isNotNull);
      h.clock.advance(const Duration(milliseconds: 1));
      expect(h.snapshot.deriveFuelRateLPerHour(), isNull);
      expect(h.snapshot.lastFuelRateSource, FuelRateSourceTag.none);
      expect(h.snapshot.lastFuelRateVe, isNull);
      // The getter itself is not staleness-gated.
      expect(h.snapshot.latestIatCelsius, 20.0);
    });
  });
}
