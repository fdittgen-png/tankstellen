// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/obd2/data/obd2_breadcrumb_collector.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_fuel_rate_reader.dart';
import 'package:tankstellen/features/obd2/domain/fuel_mixture_model.dart';
import 'package:tankstellen/features/obd2/domain/fuel_rate_estimator.dart';

/// #4159 — pins [Obd2FuelRateReader]'s exact sequence of support-gate
/// questions (strict vs optimistic, per PID) and reads, per branch, before
/// its PID literals are replaced by signal names. Short-circuit order is
/// part of the contract: `strict(0xA2)` is asked BEFORE the cylinder count
/// is consulted, and `strict(0x66)` is asked twice on the MAF branch.
///
/// The fake answers from fixed sets and a value table, so the logged
/// sequence is the reader's own decision and nothing else.

String _hex(int pid) =>
    '0x${pid.toRadixString(16).toUpperCase().padLeft(2, '0')}';

class _LogReads implements Obd2FuelRateReads {
  _LogReads({
    this.strict = const {},
    this.optimistic = const {},
    this.values = const {},
  });

  final Set<int> strict;
  final Set<int> optimistic;
  final Map<String, double?> values;
  final List<String> log = <String>[];

  @override
  bool isPidSupported(int pid) {
    final v = optimistic.contains(pid);
    log.add('opt(${_hex(pid)})=$v');
    return v;
  }

  @override
  bool isPidKnownSupported(int pid) {
    final v = strict.contains(pid);
    log.add('strict(${_hex(pid)})=$v');
    return v;
  }

  Future<double?> _read(String name) async {
    log.add('read:$name');
    return values[name];
  }

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

Future<(double?, List<String>)> _run(
  _LogReads reads, {
  VehicleProfile? vehicle,
  Obd2BreadcrumbRecorder? collector,
}) async {
  final rate = await Obd2FuelRateReader(reads: reads, collector: collector)
      .read(vehicle: vehicle);
  return (rate, reads.log);
}

/// The questions every call asks before the mass branches, when nothing
/// strict is supported.
const _preamble = ['strict(0x52)=false', 'strict(0x9D)=false'];

void main() {
  const fourCyl = VehicleProfile(id: 'c4', name: 'c4', engineCylinders: 4);
  const diesel =
      VehicleProfile(id: 'd', name: 'd', preferredFuelType: 'diesel');

  test('ethanol is asked strictly and read first when supported', () async {
    final (_, log) = await _run(_LogReads(
      strict: {0x52},
      values: {'ethanol': 10.0},
    ));
    expect(log.take(3), ['strict(0x52)=true', 'read:ethanol',
        'strict(0x9D)=false']);
  });

  test('0x9D hit: density only, nothing else asked', () async {
    final (rate, log) = await _run(_LogReads(
      strict: {0x9D},
      values: {'rate9d': 10.0},
    ));
    expect(rate, closeTo(10.0 * 3600.0 / kPetrolDensityGPerL, 1e-9));
    expect(log, ['strict(0x52)=false', 'strict(0x9D)=true', 'read:rate9d']);
  });

  test('0x9D hit with a collector cross-checks 0x5E optimistically',
      () async {
    final (_, log) = await _run(
      _LogReads(
        strict: {0x9D},
        optimistic: {0x5E},
        values: {'rate9d': 10.0, 'pid5e': 5.0},
      ),
      collector: Obd2BreadcrumbCollector(),
    );
    expect(log, [
      'strict(0x52)=false', 'strict(0x9D)=true', 'read:rate9d',
      'opt(0x5E)=true', 'read:pid5e',
    ]);
  });

  test('0x9D null → 0xA2 with a cylinder count', () async {
    final (rate, log) = await _run(
      _LogReads(
        strict: {0x9D, 0xA2},
        values: {'rate9d': null, 'cylRate': 20.0, 'rpm': 2500.0},
      ),
      vehicle: fourCyl,
    );
    const gps = 20.0 * (2500.0 / 60.0) / 2.0 * 4.0 / 1000.0;
    expect(rate, closeTo(gps * 3600.0 / kPetrolDensityGPerL, 1e-9));
    expect(log, [
      'strict(0x52)=false', 'strict(0x9D)=true', 'read:rate9d',
      'strict(0xA2)=true', 'read:cylRate', 'read:rpm',
    ]);
  });

  test('0xA2 without a cylinder count is still ASKED, then 0x5E wins',
      () async {
    final (rate, log) = await _run(_LogReads(
      strict: {0xA2},
      optimistic: {0x5E},
      values: {'pid5e': 5.0},
    ));
    expect(rate, 5.0);
    expect(log, [
      ..._preamble, 'strict(0xA2)=true', 'opt(0x5E)=true', 'read:pid5e',
    ]);
  });

  test('0x5E null → 0x66 null → 0x10, petrol trims read, 0x44 asked',
      () async {
    final (rate, log) = await _run(_LogReads(
      strict: {0x66},
      optimistic: {0x5E, 0x10},
      values: {'maf': 10.24},
    ));
    expect(rate, closeTo(10.24 * 3600.0 / (kPetrolAfr * kPetrolDensityGPerL),
        1e-9));
    expect(log, [
      ..._preamble, 'strict(0xA2)=false',
      'opt(0x5E)=true', 'read:pid5e',
      'strict(0x66)=true', 'strict(0x66)=true', 'read:maf66',
      'opt(0x10)=true', 'read:maf',
      'read:measuredPhi', 'opt(0x44)=false',
      'read:stft', 'read:ltft',
    ]);
  });

  test('diesel on the MAF branch never asks 0x44 and reads no trims',
      () async {
    final (rate, log) = await _run(
      _LogReads(optimistic: {0x10, 0x44}, values: {'maf': 10.24}),
      vehicle: diesel,
    );
    expect(rate, closeTo(10.24 * 3600.0 / (kDieselAfr * kDieselDensityGPerL),
        1e-9));
    expect(log, [
      ..._preamble, 'strict(0xA2)=false', 'opt(0x5E)=false',
      'strict(0x66)=false', 'opt(0x10)=true',
      'strict(0x66)=false', 'opt(0x10)=true', 'read:maf',
      'read:measuredPhi',
    ]);
  });

  test('bank-2 trims are asked optimistically after both bank-1 reads',
      () async {
    final (rate, log) = await _run(_LogReads(
      optimistic: {0x10, 0x08, 0x09},
      values: {
        'maf': 10.24, 'stft': 10.0, 'ltft': 0.0, 'stft2': 5.0, 'ltft2': -5.0,
      },
    ));
    const raw = 10.24 * 3600.0 / (kPetrolAfr * kPetrolDensityGPerL);
    expect(
      rate,
      closeTo(
        applyFuelTrimCorrection(raw,
            stft: 10.0, ltft: 0.0, stftBank2: 5.0, ltftBank2: -5.0),
        1e-9,
      ),
    );
    expect(log.skip(log.indexOf('read:measuredPhi')), [
      'read:measuredPhi', 'opt(0x44)=false',
      'read:stft', 'read:ltft',
      'opt(0x08)=true', 'read:stft2', 'opt(0x09)=true', 'read:ltft2',
    ]);
  });

  group('speed-density', () {
    const sdGates = [
      'strict(0xA2)=false', 'opt(0x5E)=false', 'strict(0x66)=false',
      'opt(0x10)=false',
    ];

    test('with baro 0x33 and commanded 0x44', () async {
      final (rate, log) = await _run(_LogReads(
        optimistic: {0x0B, 0x0F, 0x0C, 0x33, 0x44},
        values: {
          'map': 50.0, 'iat': 20.0, 'rpm': 2000.0, 'baro': 90.0,
          'commandedPhi': 1.1, 'stft': 0.0, 'ltft': 0.0,
        },
      ));
      final expected = estimateFuelRateLPerHourFromMap(
        mapKpa: 50.0,
        iatCelsius: 20.0,
        rpm: 2000.0,
        engineDisplacementCc: kDefaultEngineDisplacementCc,
        volumetricEfficiency: kDefaultVolumetricEfficiency,
        afr: effectiveAfrForMixture(kPetrolAfr,
            measuredPhi: null, commandedPhi: 1.1, isDiesel: false),
        fuelDensityGPerL: kPetrolDensityGPerL,
        baroKpa: 90.0,
      );
      expect(rate, closeTo(expected!, 1e-9));
      expect(log, [
        ..._preamble, ...sdGates,
        'opt(0x0B)=true', 'opt(0x0F)=true', 'opt(0x0C)=true',
        'read:map', 'read:iat', 'read:rpm',
        'opt(0x33)=true', 'read:baro',
        'read:measuredPhi', 'opt(0x44)=true', 'read:commandedPhi',
        'read:stft', 'read:ltft', 'opt(0x08)=false', 'opt(0x09)=false',
      ]);
    });

    test('without baro: sea-level assumption, 0x33 still asked', () async {
      final (rate, log) = await _run(_LogReads(
        optimistic: {0x0B, 0x0F, 0x0C},
        values: {'map': 50.0, 'iat': 20.0, 'rpm': 2000.0},
      ));
      final expected = estimateFuelRateLPerHourFromMap(
        mapKpa: 50.0,
        iatCelsius: 20.0,
        rpm: 2000.0,
        engineDisplacementCc: kDefaultEngineDisplacementCc,
        volumetricEfficiency: kDefaultVolumetricEfficiency,
        afr: kPetrolAfr,
        fuelDensityGPerL: kPetrolDensityGPerL,
      );
      expect(rate, closeTo(expected!, 1e-9));
      expect(log, [
        ..._preamble, ...sdGates,
        'opt(0x0B)=true', 'opt(0x0F)=true', 'opt(0x0C)=true',
        'read:map', 'read:iat', 'read:rpm',
        'opt(0x33)=false', 'read:measuredPhi', 'opt(0x44)=false',
        'read:stft', 'read:ltft',
      ]);
    });

    test('one input value missing: all three still read, null', () async {
      final (rate, log) = await _run(_LogReads(
        optimistic: {0x0B, 0x0F, 0x0C},
        values: {'map': 50.0, 'iat': null, 'rpm': 2000.0},
      ));
      expect(rate, isNull);
      expect(log, [
        ..._preamble, ...sdGates,
        'opt(0x0B)=true', 'opt(0x0F)=true', 'opt(0x0C)=true',
        'read:map', 'read:iat', 'read:rpm',
      ]);
    });

    test('one input gate closed: the gates short-circuit, no reads',
        () async {
      final (rate, log) = await _run(_LogReads(optimistic: {0x0B, 0x0C}));
      expect(rate, isNull);
      expect(log, [
        ..._preamble, ...sdGates, 'opt(0x0B)=true', 'opt(0x0F)=false',
      ]);
    });
  });
}
