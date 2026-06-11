// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_transport.dart';
import 'package:tankstellen/features/obd2/data/trip_recording_controller.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import '../../../helpers/silence_error_logger.dart';

/// #2458 / #2459 — end-to-end: the new PIDs flow scheduler → snapshot →
/// `_emit` → captured TripSample. The six consumed-but-unstored signals
/// are ALWAYS stamped (like throttle); the four raw mixture inputs are
/// stamped only when the per-trip diagnostic-capture flag is on.

const _init = {
  'ATZ': 'ELM327 v1.5>',
  'ATE0': 'OK>',
  'ATL0': 'OK>',
  'ATH0': 'OK>',
  'ATSP0': 'OK>',
  '01A6': 'NO DATA>',
};

/// A car that exposes the new PIDs. Speed-density path (no 5E / MAF) so
/// the fuel branch still resolves and the raw MAP/IAT/RPM land too.
const _richPidResponses = {
  '010C': '41 0C 1A F8>', // RPM 1726
  '010D': '41 0D 32>', // speed 50 km/h
  '0111': '41 11 40>', // throttle ~25 %
  '0110': '41 10 04 00>', // MAF 10.24 g/s (diagnostic raw input)
  '010B': '41 0B 41>', // MAP 65 kPa (diagnostic raw input)
  '010F': '41 0F 46>', // IAT 30 °C
  '0106': '41 06 88>', // STFT +6.25 % (diagnostic raw input)
  '0107': '41 07 84>', // LTFT +3.125 % (diagnostic raw input)
  '0144': '41 44 80 00>', // λ 1.0
  '0133': '41 33 5F>', // baro 95 kPa
  '0143': '41 43 01 00>', // absolute load ~100.4 % (boosted proxy)
  '0149': '41 49 99>', // pedal D ~60 %
  '015C': '41 5C 6E>', // oil temp 70 °C
  '0146': '41 46 32>', // ambient 10 °C
};

Future<Obd2Service> _service() async {
  final svc = Obd2Service(FakeObd2Transport({..._init, ..._richPidResponses}));
  await svc.connect();
  return svc;
}

/// Run the controller's scheduler long enough for the new PIDs to land,
/// then capture one emit and return the captured sample.
Future<TripSample> _captureOneSample({required bool diagnosticCapture}) async {
  final svc = await _service();
  final ctl = TripRecordingController(
    service: svc,
    pollInterval: const Duration(minutes: 1), // no auto-tick
    schedulerTickRate: const Duration(milliseconds: 2),
    diagnosticCapture: diagnosticCapture,
  );
  await ctl.start();
  // Let the weighted round-robin read each newly-subscribed PID at least
  // once (all start with lastReadAt == null → infinite weight).
  await Future<void>.delayed(const Duration(milliseconds: 400));
  ctl.debugEmitNow();
  final samples = ctl.capturedSamples;
  expect(samples, isNotEmpty, reason: 'an emit with speed/rpm must capture');
  final sample = samples.last;
  await ctl.stop();
  return sample;
}

void main() {
  silenceErrorLoggerSpool();

  group('#2459 _emit stamps the consumed-but-unstored signals', () {
    test('λ / baro / absLoad / pedal / oil / ambient are stamped '
        '(capture flag OFF — they are always persisted)', () async {
      final s = await _captureOneSample(diagnosticCapture: false);
      expect(s.lambda, closeTo(1.0, 0.001));
      expect(s.baroKpa, 95.0);
      expect(s.absLoadPercent, greaterThan(100.0)); // boosted proxy
      expect(s.pedalPercent, closeTo(60.0, 1.0));
      expect(s.oilTempC, 70.0);
      expect(s.ambientTempC, 10.0);
    });

    test('with capture OFF the raw mixture inputs stay null '
        '(zero storage growth)', () async {
      final s = await _captureOneSample(diagnosticCapture: false);
      expect(s.mafGramsPerSecond, isNull);
      expect(s.mapKpa, isNull);
      expect(s.stft, isNull);
      expect(s.ltft, isNull);
    });

    test('with capture ON the raw mixture inputs are stamped', () async {
      final s = await _captureOneSample(diagnosticCapture: true);
      expect(s.mafGramsPerSecond, closeTo(10.24, 0.1));
      expect(s.mapKpa, 65.0);
      expect(s.stft, closeTo(6.25, 0.1));
      expect(s.ltft, closeTo(3.125, 0.1));
      // The consumed-but-unstored signals are still present too.
      expect(s.lambda, closeTo(1.0, 0.001));
      expect(s.pedalPercent, closeTo(60.0, 1.0));
    });
  });

  group('a car WITHOUT the new PIDs stores nothing extra (#2458/#2459)', () {
    test('all new signals + raw inputs null even with capture ON', () async {
      // Minimal car: only RPM + speed answer; everything else NO DATA.
      final svc = Obd2Service(FakeObd2Transport({
        ..._init,
        '010C': '41 0C 1A F8>',
        '010D': '41 0D 32>',
      }));
      await svc.connect();
      final ctl = TripRecordingController(
        service: svc,
        pollInterval: const Duration(minutes: 1),
        schedulerTickRate: const Duration(milliseconds: 2),
        diagnosticCapture: true, // even with capture ON
      );
      await ctl.start();
      await Future<void>.delayed(const Duration(milliseconds: 400));
      ctl.debugEmitNow();
      final s = ctl.capturedSamples.last;
      await ctl.stop();
      expect(s.lambda, isNull);
      expect(s.baroKpa, isNull);
      expect(s.absLoadPercent, isNull);
      expect(s.pedalPercent, isNull);
      expect(s.oilTempC, isNull);
      expect(s.ambientTempC, isNull);
      expect(s.mafGramsPerSecond, isNull);
      expect(s.mapKpa, isNull);
      expect(s.stft, isNull);
      expect(s.ltft, isNull);
    });
  });
}
