// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:typed_data';

import 'package:tankstellen/core/domain/gps_calibration_matrix.dart';
import 'package:tankstellen/core/domain/pump_gain_entry.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/obd2/data/session/live_sample_snapshot.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_fuel_rate_reader.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_transport.dart';
import 'package:tankstellen/features/obd2/domain/pid_scheduler.dart';
import 'package:tankstellen/features/obd2/domain/services/obd2_gps_estimate_fallback.dart';
import 'package:tankstellen/features/trips/data/trip_summary_codec.dart';
import 'package:tankstellen/features/trips/domain/services/gps_live_estimate_folder.dart';
import 'package:tankstellen/features/trips/domain/services/gps_live_fuel_estimator.dart';
import 'package:tankstellen/features/trips/domain/services/physics_scale_calibrator.dart';
import 'package:tankstellen/features/trips/domain/trip_recorder.dart';
import 'package:tankstellen/features/trips/providers/gps_trip_fuel_backfill.dart';

/// The consumption streams the #4233 identity goldens pin (Epic #4222).
///
/// Every figure a production producer emits today — the live OBD2
/// snapshot, the pull-mode reader, the GPS road-load estimator and every
/// consumer of it (live folder, no-fuel-PID fallback, physics-scale
/// replay, stop-time backfill) and the trip recorder's summary — driven
/// by fixed, clock-free inputs and flattened to `label → value`, doubles
/// as their float64 **bit pattern**. Wiring the fuzzy engine (neutral
/// rules, ADR 0023) must leave every entry bit-identical.
///
/// Summary JSON drops the `cmv` key (#4233's version stamp): the stamp is
/// new provenance, not a figure.
Future<Map<String, String>> collectConsumptionFigures() async {
  final out = <String, String>{};
  _collectLiveSnapshot(out);
  await _collectPullReader(out);
  _collectGpsEstimator(out);
  _collectGpsConsumers(out);
  _collectRecorder(out);
  return out;
}

/// A double's IEEE-754 bit pattern as 16 hex digits; `null` stays `null`.
String bitsOf(double? x) => x == null
    ? 'null'
    : (ByteData(8)..setFloat64(0, x))
        .getUint64(0)
        .toRadixString(16)
        .padLeft(16, '0');

String _bitsList(Iterable<double?> xs) => xs.map(bitsOf).join(',');

// ─── Vehicles ───────────────────────────────────────────────────────────

const _raw = VehicleProfile(
    id: 'v', name: 'Raw', engineCylinders: 4, curbWeightKg: 1200);
const _scalar = VehicleProfile(
  id: 'v',
  name: 'Scalar',
  engineCylinders: 4,
  curbWeightKg: 1200,
  pumpGain: 0.8,
  pumpGainSamples: 3,
);
const _flex = VehicleProfile(
  id: 'v',
  name: 'Flex',
  engineCylinders: 4,
  multiFuelCapable: true,
  tankFuelKey: 'e10',
  pumpGainByFuel: {
    'e10': PumpGainEntry(gain: 1.1, samples: 2),
    'e85': PumpGainEntry(gain: 0.7, samples: 2),
  },
);
const _diesel = VehicleProfile(
  id: 'v',
  name: 'Diesel',
  engineCylinders: 4,
  preferredFuelType: 'diesel',
  curbWeightKg: 1650,
  pumpGain: 1.2,
  pumpGainSamples: 4,
);
const _vehicles = {
  'raw': _raw,
  'scalar': _scalar,
  'flex': _flex,
  'diesel': _diesel,
};

// ─── OBD2 matrix (raw ELM327 Mode 01 frames) ────────────────────────────

class _Case {
  const _Case(this.supported, this.frames,
      {this.values = const {}, this.sessionFuelKey, this.iatAgeSeconds = 0});

  final Set<int> supported;

  /// Live path: request (trimmed) → response frame.
  final Map<String, String> frames;

  /// Pull path: the reader's read name → decoded value.
  final Map<String, double?> values;
  final String? sessionFuelKey;
  final int iatAgeSeconds;
}

const _rpm = {'010C': '41 0C 27 10'}; // 2500 rpm
const _ctx = {
  '010D': '41 0D 3C', // 60 km/h
  '0104': '41 04 80', // load 50 %
  '0111': '41 11 40', // throttle 25 %
  '0105': '41 05 5A', // coolant 50 °C
  '015C': '41 5C 64', // oil 60 °C
};
const _trims = {'0106': '41 06 8D', '0107': '41 07 70'}; // +10.2 %, −12.5 %
const _sd = {'010B': '41 0B 64', '010F': '41 0F 3C'}; // 100 kPa, 20 °C
const _trimValues = {'stft': 10.15625, 'ltft': -12.5};
const _sdValues = {'map': 100.0, 'iat': 20.0, 'rpm': 2500.0};

const _cases = <String, _Case>{
  'pid9D': _Case({0x9D, 0x0C}, {..._rpm, '019D': '41 9D 01 F4 00 00'},
      values: {'rate9d': 10.0}),
  'pidA2': _Case({0xA2, 0x0C}, {..._rpm, '01A2': '41 A2 02 80'},
      values: {'cylRate': 20.0, 'rpm': 2500.0}),
  'pid5E': _Case({0x5E, 0x0C}, {..._rpm, '015E': '41 5E 00 C8'},
      values: {'pid5e': 10.0}),
  'maf10': _Case({0x10, 0x0C}, {..._rpm, '0110': '41 10 04 00'},
      values: {'maf': 10.24}),
  'maf66': _Case({0x66, 0x10, 0x0C},
      {..._rpm, '0166': '41 66 01 05 40', '0110': '41 10 04 00'},
      values: {'maf66': 42.0, 'maf': 10.24}),
  'maf10Trims': _Case({0x10, 0x0C, 0x06, 0x07},
      {..._rpm, '0110': '41 10 04 00', ..._trims},
      values: {'maf': 10.24, ..._trimValues}),
  'maf10MeasuredPhi': _Case({0x10, 0x0C, 0x06, 0x07, 0x24},
      {..._rpm, '0110': '41 10 04 00', ..._trims, '0124': '41 24 66 66 32 DD'},
      values: {'maf': 10.24, ..._trimValues, 'measuredPhi': 0.8}),
  'maf10CommandedPhi': _Case({0x10, 0x0C, 0x44},
      {..._rpm, '0110': '41 10 04 00', '0144': '41 44 99 9A'},
      values: {'maf': 10.24, 'commandedPhi': 1.2}),
  'mafImplausible': _Case({0x10, 0x0C}, {..._rpm, '0110': '41 10 FF FF'},
      values: {'maf': 655.35}),
  'mafZero': _Case({0x10, 0x0C}, {..._rpm, '0110': '41 10 00 00'},
      values: {'maf': 0.0}),
  'speedDensity': _Case({0x0B, 0x0F, 0x0C}, {..._rpm, ..._sd},
      values: _sdValues),
  'speedDensityFull': _Case(
      {0x0B, 0x0F, 0x0C, 0x06, 0x07, 0x33, 0x44, 0x0D, 0x04, 0x11, 0x05, 0x5C},
      {..._rpm, ..._sd, ..._trims, ..._ctx, '0133': '41 33 62',
        '0144': '41 44 99 9A'},
      values: {..._sdValues, ..._trimValues, 'baro': 98.0,
        'commandedPhi': 1.2}),
  'speedDensityIat5s': _Case({0x0B, 0x0F, 0x0C}, {..._rpm, ..._sd},
      values: _sdValues, iatAgeSeconds: 5),
  'speedDensityIat20s': _Case({0x0B, 0x0F, 0x0C}, {..._rpm, ..._sd},
      values: _sdValues, iatAgeSeconds: 20),
  'ethanol85': _Case({0x52, 0x10, 0x0C, 0x06, 0x07},
      {..._rpm, '0152': '41 52 D9', '0110': '41 10 04 00', ..._trims},
      values: {'ethanol': 85.1, 'maf': 10.24, ..._trimValues}),
  'ethanol20': _Case({0x52, 0x10, 0x0C, 0x06, 0x07},
      {..._rpm, '0152': '41 52 33', '0110': '41 10 04 00', ..._trims},
      values: {'ethanol': 20.0, 'maf': 10.24, ..._trimValues}),
  'sessionDiesel': _Case({0x10, 0x0C, 0x06, 0x07, 0x44},
      {..._rpm, '0110': '41 10 04 00', ..._trims, '0144': '41 44 99 9A'},
      values: {'maf': 10.24, ..._trimValues, 'commandedPhi': 1.2},
      sessionFuelKey: 'diesel'),
  'sessionE85SpeedDensity': _Case({0x0B, 0x0F, 0x0C, 0x06, 0x07},
      {..._rpm, ..._sd, ..._trims},
      values: {..._sdValues, ..._trimValues}, sessionFuelKey: 'e85'),
};

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

class _SupportStubService extends Obd2Service {
  _SupportStubService(Set<int> supported) : super(_StubTransport()) {
    debugSetSupportedPids(supported);
  }
}

class _CapturingScheduler extends PidScheduler {
  _CapturingScheduler() : super(transport: (_) async => 'NO DATA');

  final Map<String, void Function(String)> callbacks = {};

  @override
  void subscribe(
    String command,
    ScheduledPid config,
    void Function(String response) onResult,
  ) {
    callbacks[command.trim()] = onResult;
  }
}

class _Clock {
  _Clock(this.now);
  DateTime now;
  DateTime call() => now;
}

void _collectLiveSnapshot(Map<String, String> out) {
  final t0 = DateTime.utc(2026, 9, 16, 12);
  for (final v in _vehicles.entries) {
    for (final c in _cases.entries) {
      final clock = _Clock(t0.subtract(Duration(seconds: c.value.iatAgeSeconds)));
      final scheduler = _CapturingScheduler();
      final snapshot = LiveSampleSnapshot(
        service: _SupportStubService(c.value.supported),
        vehicle: v.value,
        onHighPriorityParse: (_) {},
        onSpeedSample: (_) {},
        clock: clock.call,
      )..sessionFuelTypeKey = c.value.sessionFuelKey;
      snapshot.subscribeAllTiers(scheduler);
      // IAT lands first (possibly in the past), everything else "now".
      final iat = c.value.frames['010F'];
      if (iat != null) scheduler.callbacks['010F']?.call(iat);
      clock.now = t0;
      for (final f in c.value.frames.entries) {
        if (f.key == '010F') continue;
        scheduler.callbacks[f.key]?.call(f.value);
      }
      final key = 'live/${v.key}/${c.key}';
      out['$key/rate'] = bitsOf(snapshot.deriveFuelRateLPerHour());
      out['$key/source'] = '${snapshot.lastFuelRateSource?.name}';
      out['$key/gain'] = bitsOf(snapshot.lastPumpGainResolution?.gain);
      out['$key/ve'] = bitsOf(snapshot.lastFuelRateVe);
    }
  }
}

class _ValueReads implements Obd2FuelRateReads {
  _ValueReads(this.supported, this.values);

  final Set<int> supported;
  final Map<String, double?> values;

  @override
  bool isPidSupported(int pid) => supported.contains(pid);
  @override
  bool isPidKnownSupported(int pid) => supported.contains(pid);

  Future<double?> _read(String name) async => values[name];

  @override
  Future<double?> readEthanolPercent() => _read('ethanol');
  @override
  Future<double?> readEngineFuelRateGramsPerSecond() => _read('rate9d');
  @override
  Future<double?> readCylinderFuelRateMgPerStroke() => _read('cylRate');
  @override
  Future<double?> readRpm() => _read('rpm');
  @override
  Future<double?> readMafSensorGramsPerSecond() => _read('maf66');
  @override
  Future<double?> readMafGramsPerSecond() => _read('maf');
  @override
  Future<double?> readMeasuredPhi() => _read('measuredPhi');
  @override
  Future<double?> readCommandedEquivalenceRatio() => _read('commandedPhi');
  @override
  Future<double?> readManifoldPressureKpa() => _read('map');
  @override
  Future<double?> readIntakeAirTempCelsius() => _read('iat');
  @override
  Future<double?> readBaroPressureKpa() => _read('baro');
  @override
  Future<double?> readShortTermFuelTrimPercent() => _read('stft');
  @override
  Future<double?> readLongTermFuelTrimPercent() => _read('ltft');
  @override
  Future<double?> readShortTermFuelTrimBank2Percent() => _read('stft2');
  @override
  Future<double?> readLongTermFuelTrimBank2Percent() => _read('ltft2');
  @override
  Future<double?> readDirectFuelRatePid5E() => _read('pid5e');
}

Future<void> _collectPullReader(Map<String, String> out) async {
  for (final v in _vehicles.entries) {
    for (final c in _cases.entries) {
      final rate = await Obd2FuelRateReader(
              reads: _ValueReads(c.value.supported, c.value.values))
          .read(vehicle: v.value);
      out['pull/${v.key}/${c.key}/rate'] = bitsOf(rate);
    }
  }
}

// ─── GPS road-load ──────────────────────────────────────────────────────

/// A speed stream (km/h) at a fixed cadence, plus optional per-tick dt
/// overrides and a confident grade.
class _GpsStream {
  const _GpsStream(this.speedsKmh,
      {this.dtSeconds = const [], this.gradeFraction = 0,
        this.gradeConfident = false});

  final List<double> speedsKmh;

  /// Per-tick dt; ticks beyond the list use 1 s.
  final List<double> dtSeconds;
  final double gradeFraction;
  final bool gradeConfident;

  double dtAt(int i) => i < dtSeconds.length ? dtSeconds[i] : 1.0;
}

const _gpsStreams = <String, _GpsStream>{
  'cityStopGo': _GpsStream([0, 8, 19, 31, 42, 38, 27, 12, 0, 0, 0, 14, 29,
    45, 51, 49, 33, 18, 6, 0]),
  'highway': _GpsStream([112, 114.5, 117, 118.2, 121, 124.7, 126, 125.1,
    123.4, 120, 119.3, 122.8, 127.5, 130, 128.6]),
  'climbConfident': _GpsStream([55, 57, 60, 61, 62, 62.5, 63, 62, 61, 60],
      gradeFraction: 0.06, gradeConfident: true),
  'descentConfident': _GpsStream([70, 72, 74, 76, 78, 80, 81, 82],
      gradeFraction: -0.08, gradeConfident: true),
  'gradeNotConfident': _GpsStream([60, 61, 62, 63, 64],
      gradeFraction: 0.1),
  'speedSpike': _GpsStream([50, 51, 200, 52, 50, 49, 250, 48, 47]),
  'standstill': _GpsStream([0, 0, 0, 0, 0, 0]),
  'dtNonPositive': _GpsStream([30, 32, 34, 36, 38, 40, 42],
      dtSeconds: [1, 0, -1, 1, 0.25, 2.5, 1]),
};

final _gpsVehicles = <String, (VehicleProfile?, GpsCalibrationMatrix?)>{
  'default': (null, null),
  'dieselScaled': (
    _diesel,
    GpsCalibrationMatrix.coldStart().copyWith(physicsScale: 1.15),
  ),
  'e85Light': (
    const VehicleProfile(
        id: 'e', name: 'E85', preferredFuelType: 'e85', curbWeightKg: 980),
    GpsCalibrationMatrix.coldStart().copyWith(physicsScale: 0.9),
  ),
};

void _collectGpsEstimator(Map<String, String> out) {
  for (final v in _gpsVehicles.entries) {
    for (final s in _gpsStreams.entries) {
      final est = GpsLiveFuelEstimator.forVehicle(v.value.$1, v.value.$2);
      final instant = <double?>[];
      final avg = <double?>[];
      final litres = <double?>[];
      final speeds = s.value.speedsKmh;
      for (var i = 1; i < speeds.length; i++) {
        instant.add(est.onSample(
          speedMps: speeds[i] / 3.6,
          prevSpeedMps: speeds[i - 1] / 3.6,
          dtSeconds: s.value.dtAt(i),
          gradeFraction: s.value.gradeFraction,
          gradeConfident: s.value.gradeConfident,
        ));
        avg.add(est.runningAvgLPer100Km);
        litres.add(est.litersSoFar);
      }
      final key = 'gps/${v.key}/${s.key}';
      out['$key/instant'] = _bitsList(instant);
      out['$key/avg'] = _bitsList(avg);
      out['$key/litres'] = _bitsList(litres);
    }
  }
}

/// Samples at 1 Hz from [t0] over [speedsKmh], with an optional altitude
/// ramp (metres per sample) so the folder's grade calculator can become
/// confident.
List<TripSample> _samples(List<double> speedsKmh,
    {double? altitudeStepM, double? fuelRate}) {
  final t0 = DateTime.utc(2026, 9, 16, 8);
  return [
    for (var i = 0; i < speedsKmh.length; i++)
      TripSample(
        timestamp: t0.add(Duration(seconds: i)),
        speedKmh: speedsKmh[i],
        rpm: fuelRate == null ? null : 1800,
        fuelRateLPerHour: fuelRate,
        altitudeM: altitudeStepM == null ? null : 200 + altitudeStepM * i,
      ),
  ];
}

Map<String, String> _flattenJson(Object? json, String prefix) {
  final out = <String, String>{};
  void walk(Object? node, String path) {
    if (node is Map) {
      for (final e in node.entries) {
        walk(e.value, '$path.${e.key}');
      }
    } else if (node is List) {
      for (var i = 0; i < node.length; i++) {
        walk(node[i], '$path[$i]');
      }
    } else if (node is double) {
      out[path] = bitsOf(node);
    } else {
      out[path] = '$node';
    }
  }

  walk(json, prefix);
  return out;
}

Map<String, String> _summaryFigures(TripSummary s, String prefix) =>
    _flattenJson(tripSummaryToJson(s)..remove('cmv'), prefix);

void _collectGpsConsumers(Map<String, String> out) {
  final climb = _samples(
      [0, 20, 40, 55, 62, 65, 66, 64, 63, 65, 67, 70, 72, 71, 69, 70, 72,
        74, 75, 73, 70, 60, 45, 30, 10, 0],
      altitudeStepM: 1.2);
  final city = _samples([0, 8, 19, 31, 42, 38, 27, 12, 0, 0, 0, 14, 29, 45,
    51, 49, 33, 18, 6, 0]);
  final spike = _samples([50, 51, 200, 52, 50, 49, 250, 48, 47, 46, 45]);
  final streams = {'climb': climb, 'city': city, 'spike': spike};

  for (final v in _gpsVehicles.entries) {
    for (final s in streams.entries) {
      final key = '${v.key}/${s.key}';
      // Live folder.
      final folder = GpsLiveEstimateFolder.forVehicle(v.value.$1, v.value.$2);
      final instant = <double?>[];
      final avg = <double?>[];
      final litres = <double?>[];
      for (final sample in s.value) {
        final e = folder.fold(sample);
        instant.add(e.instantLPer100Km);
        avg.add(e.avgLPer100Km);
        litres.add(e.fuelLitersSoFar);
      }
      out['folder/$key/instant'] = _bitsList(instant);
      out['folder/$key/avg'] = _bitsList(avg);
      out['folder/$key/litres'] = _bitsList(litres);
      out['folder/$key/final'] =
          _bitsList([folder.finalAvgLPer100Km, folder.finalFuelLiters]);

      // Stop-time backfill: batch for gpsOnly, live folder otherwise.
      final base = TripSummary(
        distanceKm: 1.9,
        maxRpm: 0,
        highRpmSeconds: 0,
        idleSeconds: 3,
        harshBrakes: 0,
        harshAccelerations: 0,
        startedAt: s.value.first.timestamp,
        endedAt: s.value.last.timestamp,
      );
      for (final kind in TripKind.values) {
        final filled = backfillGpsTripFuel(
          base.copyWith(kind: kind),
          samples: s.value,
          vehicleCalibration: v.value.$2,
          liveFolder: folder,
        );
        out.addAll(_summaryFigures(filled, 'backfill/$key/${kind.name}'));
      }

      // No-fuel-PID OBD2 fallback (vehicle carries its own matrix).
      final vehicle = v.value.$1?.copyWith(gpsCalibration: v.value.$2);
      final est =
          Obd2GpsEstimateFallback.estimate(samples: s.value, vehicle: vehicle);
      out['fallback/$key/avg'] = bitsOf(est?.avgLPer100Km);
      out['fallback/$key/litres'] = bitsOf(est?.fuelLitersConsumed);
      out['fallback/$key/samples'] = _bitsList(
          (est?.samples ?? const <TripSample>[])
              .map((e) => e.estimatedFuelRateLPerHour));
      final fill = Obd2GpsEstimateFallback.fillWhenNoFuelPid(
          summary: base, samples: s.value, vehicle: vehicle);
      out.addAll(_summaryFigures(fill.summary, 'fallbackFill/$key'));

      // Physics-scale replay against an OBD2 ground truth.
      final calibrated = PhysicsScaleCalibrator.calibrate(
        vehicle: vehicle,
        matrix: v.value.$2,
        summary: base.copyWith(avgLPer100Km: 6.4, distanceKm: 2.5).copyWith(
            endedAt: s.value.first.timestamp.add(const Duration(minutes: 3))),
        samples: s.value,
      );
      out['calibrator/$key/scale'] = bitsOf(calibrated.physicsScale);
    }
  }
}

void _collectRecorder(Map<String, String> out) {
  final recorder = TripRecorder();
  final samples = _samples([0, 12, 30, 48, 55, 57, 40, 22, 5, 0],
      fuelRate: 3.7);
  var i = 0;
  for (final s in samples) {
    recorder.onSample(TripSample(
      timestamp: s.timestamp,
      speedKmh: s.speedKmh,
      rpm: 900.0 + 180 * i,
      fuelRateLPerHour: 0.9 + 0.83 * i,
    ));
    i++;
  }
  out.addAll(_summaryFigures(recorder.buildSummary(), 'recorder'));
}
