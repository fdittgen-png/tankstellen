// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/obd2/data/obd2_breadcrumb_collector.dart';
import 'package:tankstellen/features/obd2/data/session/live_sample_snapshot.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_transport.dart';
import 'package:tankstellen/features/obd2/domain/pid_scheduler.dart';
import 'package:tankstellen/features/vehicle/domain/entities/reference_vehicle.dart';

/// #4315 — the fuel-rate chain assertions that used to run through the
/// uncalled pull reader (`Obd2Service.readFuelRateLPerHour`), retargeted
/// at [LiveSampleSnapshot.deriveFuelRateLPerHour], the only fuel-rate and
/// speed-density implementation a recorded trip ever used.
///
/// Ported from `fuel_rate_resolution_chain_test` (#1397),
/// `eta_v_resolution_chain_test` (#1422), `obd2_service_maf_fallback_test`
/// (#800 / #813 / #2456 / #2458), the fuel-rate groups of
/// `obd2_service_test` (#717 / #812 / #950 / #1395), the pull group of
/// `commanded_phi_convention_test` (#3426), the one uncovered case of
/// `obd2_service_precision_branch_test` (#3429) and the engine-size ratio of
/// `trip_recording_controller_test` (#812). Where the live chain differs
/// from the dead one — the catalog displacement is never consulted — the
/// test pins the live behaviour and says so.
///
/// Real parsers, real subscriptions; raw ELM327 frames are delivered by
/// hand through a capturing scheduler against a fixed clock.

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
    callbacks[command.trim()] = onResult;
  }
}

class _Service extends Obd2Service {
  _Service(Set<int> supported) : super(_StubTransport()) {
    debugSetSupportedPids(supported);
  }
}

/// Every PID the snapshot subscribes, resolved — so the strict precision
/// families subscribe too. What a case does not deliver stays unlatched.
const _everything = <int>{
  0x0C, 0x0D, 0x11, 0x04, 0x0F, 0x05, 0x06, 0x07, 0x2F, 0x10, 0x0B, 0x5E,
  0x44, 0x33, 0x49, 0x4A, 0x4B, 0x43, 0x08, 0x09, 0x5C, 0x46, 0x0E, //
  0x24, 0x34, 0x66, 0x9D, 0xA2, 0x52,
};

/// A snapshot for [vehicle] / [reference] with every frame in [frames]
/// (trimmed request → raw response) delivered at one fixed instant.
LiveSampleSnapshot _snapshot(
  Map<String, String> frames, {
  VehicleProfile? vehicle,
  ReferenceVehicle? reference,
  Obd2BreadcrumbRecorder? collector,
}) {
  final scheduler = _Capture();
  final at = DateTime.utc(2026, 9, 16, 12);
  final snapshot = LiveSampleSnapshot(
    service: _Service(_everything),
    vehicle: vehicle,
    referenceVehicle: reference,
    breadcrumbCollector: collector,
    onHighPriorityParse: (_) {},
    onSpeedSample: (_) {},
    clock: () => at,
  );
  snapshot.subscribeAllTiers(scheduler);
  for (final f in frames.entries) {
    final deliver = scheduler.callbacks[f.key];
    expect(deliver, isNotNull, reason: '${f.key} is not subscribed');
    deliver!(f.value);
  }
  return snapshot;
}

double? _rate(
  Map<String, String> frames, {
  VehicleProfile? vehicle,
  ReferenceVehicle? reference,
}) =>
    _snapshot(frames, vehicle: vehicle, reference: reference)
        .deriveFuelRateLPerHour();

// Raw fixtures (real ELM327 Mode 01 wire format).
const _maf10 = {'0110': '41 10 04 00'}; // 10.24 g/s
const _sd2500 = {
  '010B': '41 0B 41', // MAP 65 kPa
  '010F': '41 0F 46', // IAT 30 °C
  '010C': '41 0C 27 10', // 2500 rpm
};
const _sdIdle = {
  '010B': '41 0B 28', // MAP 40 kPa
  '010F': '41 0F 41', // IAT 25 °C
  '010C': '41 0C 0C 80', // 800 rpm
};

/// The petrol MAF figure every #800 case compares against: ≈ 3.389 L/h.
const _petrolMaf = 10.24 * 3600.0 / (kPetrolAfr * kPetrolDensityGPerL);

double _sd2500Rate({
  required int cc,
  required double ve,
  double afr = kPetrolAfr,
  double density = kPetrolDensityGPerL,
}) =>
    estimateFuelRateLPerHourFromMap(
      mapKpa: 65,
      iatCelsius: 30,
      rpm: 2500,
      engineDisplacementCc: cc,
      volumetricEfficiency: ve,
      afr: afr,
      fuelDensityGPerL: density,
    )!;

void main() {
  group('branch chain (#717 / #800 / #813)', () {
    test('PID 5E is returned directly; trims present are never applied', () {
      expect(
        _rate({
          '015E': '41 5E 08 00', // 102.4 L/h
          '0106': '41 06 A0', // +25 % STFT — must NOT apply
          '0107': '41 07 A0', // +25 % LTFT — must NOT apply
        }),
        closeTo(102.4, 0.1),
      );
    });

    test('5E absent → MAF, petrol 14.7 × 740 (≈ 3.389 L/h)', () {
      expect(_rate(_maf10), closeTo(3.389, 0.01));
      expect(_rate(_maf10), closeTo(_petrolMaf, 1e-9));
    });

    test('nothing landed → null', () {
      expect(_rate(const {}), isNull);
    });

    test('speed-density at idle (MAP 40, IAT 25, 800 rpm) is plausible', () {
      final rate = _rate(_sdIdle);
      expect(rate, isNotNull);
      expect(rate, greaterThan(0.2));
      expect(rate, lessThan(3.0));
    });

    test('speed-density with IAT missing returns null and records a none '
        'crumb carrying the partial inputs', () {
      final collector = Obd2BreadcrumbCollector();
      final snap = _snapshot(
          {'010B': '41 0B 40', '010C': '41 0C 0C 80'},
          collector: collector);
      expect(snap.deriveFuelRateLPerHour(), isNull);
      expect(collector.entries.last.branch, Obd2BranchTag.none);
      expect(collector.entries.last.mapKpa, closeTo(64, 0.01));
      expect(collector.entries.last.iatCelsius, isNull);
    });

    test('MAF + both bank-1 trims: 3.389 × (1 + (10.16 + 4.69) / 100)', () {
      expect(
        _rate({..._maf10, '0106': '41 06 8D', '0107': '41 07 86'}),
        closeTo(3.893, 0.05),
      );
    });

    test('one bank-1 trim missing → the raw MAF rate, not half a trim', () {
      expect(_rate({..._maf10, '0107': '41 07 90'}), closeTo(3.389, 0.01));
    });

    test('symmetric bank-2 trims cancel bank 1 (#2458)', () {
      expect(
        _rate({
          ..._maf10,
          '0106': '41 06 88', // +6.25 %
          '0107': '41 07 88', // +6.25 %
          '0108': '41 08 78', // −6.25 %
          '0109': '41 09 78', // −6.25 %
        }),
        closeTo(3.389, 0.02),
      );
    });

    test('bank 2 absent → bank-1-only factor 1.125 (#2458)', () {
      expect(
        _rate({..._maf10, '0106': '41 06 88', '0107': '41 07 88'}),
        closeTo(3.813, 0.03),
      );
    });
  });

  group('fuel type on the MAF branch (#800)', () {
    VehicleProfile fuel(String key) =>
        VehicleProfile(id: key, name: key, preferredFuelType: key);

    test('e10 → petrol constants', () {
      expect(_rate(_maf10, vehicle: fuel('e10')), closeTo(3.389, 0.01));
    });

    test('diesel → 14.5 × 832 (≈ 3.056 L/h), below petrol', () {
      final diesel = _rate(_maf10, vehicle: fuel('diesel'))!;
      expect(diesel, closeTo(3.056, 0.01));
      expect(diesel, lessThan(_rate(_maf10, vehicle: fuel('e10'))!));
    });

    test('dieselPremium routes through the diesel constants', () {
      expect(_rate(_maf10, vehicle: fuel('dieselPremium')),
          closeTo(3.056, 0.01));
    });

    test('cng reuses the petrol-equivalent pair', () {
      expect(_rate(_maf10, vehicle: fuel('cng')), closeTo(3.389, 0.01));
    });

    test('manual AFR / density overrides beat a measured ethanol blend '
        '(#3429)', () {
      const pinned = VehicleProfile(
        id: 'p',
        name: 'pinned',
        preferredFuelType: 'e85',
        manualAfrOverride: 10.5,
        manualFuelDensityGPerLOverride: 800.0,
      );
      expect(
        _rate({..._maf10, '0152': '41 52 40'}, vehicle: pinned), // ≈ 25 %
        closeTo(10.24 * 3600.0 / (10.5 * 800.0), 0.01),
      );
    });
  });

  group('commanded φ 0x44 and baro 0x33 (#2456 / #3426)', () {
    double mafWith0x44(String frame) => _rate({..._maf10, '0144': frame})!;

    test('φ = 1.2 derives ~20 % more fuel than stoich (≈ 4.067 L/h)', () {
      expect(mafWith0x44('41 44 99 9A'), closeTo(4.067, 0.02));
    });

    test('φ = 0.9 derives less fuel (≈ 3.050 L/h)', () {
      expect(mafWith0x44('41 44 73 33'), closeTo(3.050, 0.02));
    });

    test('raw lean frame (41 44 66 66) yields ~20 % less fuel than stoich '
        '(41 44 80 00) — the SAE direction, end to end', () {
      final lean = mafWith0x44('41 44 66 66');
      final stoich = mafWith0x44('41 44 80 00');
      expect(lean, lessThan(stoich));
      expect(lean / stoich, closeTo(0.7999, 0.005));
      expect(stoich, closeTo(_petrolMaf, 1e-9));
    });

    test('raw rich frame (41 44 99 9A) yields ~20 % more than stoich', () {
      expect(mafWith0x44('41 44 99 9A') / mafWith0x44('41 44 80 00'),
          closeTo(1.2, 0.005));
    });

    test('speed-density at altitude (baro 84 kPa) scales by 84 / 101.325',
        () {
      final sea = _rate(_sdIdle)!;
      final altitude = _rate({..._sdIdle, '0133': '41 33 54'})!;
      expect(altitude, lessThan(sea));
      expect(altitude / sea, closeTo(84.0 / 101.325, 0.01));
    });
  });

  group('displacement / η_v / AFR precedence (#812 / #1397 / #1422)', () {
    // Renault 1.5 dCi — the motivating Duster case.
    const duster = ReferenceVehicle(
      make: 'Dacia',
      model: 'Duster',
      generation: 'II (2018-)',
      yearStart: 2018,
      displacementCc: 1461,
      fuelType: 'diesel',
      transmission: 'manual',
      volumetricEfficiency: 0.86,
      odometerPidStrategy: 'unknown',
    );
    const dusterDci = ReferenceVehicle(
      make: 'Dacia',
      model: 'Duster',
      generation: 'II dCi 115 (2017-2024)',
      yearStart: 2017,
      yearEnd: 2024,
      displacementCc: 1461,
      fuelType: 'diesel',
      transmission: 'manual',
      volumetricEfficiency: 0.85,
      odometerPidStrategy: 'stdA6',
      inductionType: InductionType.vnt,
      directInjection: true,
    );
    const peugeot208 = ReferenceVehicle(
      make: 'Peugeot',
      model: '208',
      generation: 'II (2019-)',
      yearStart: 2019,
      displacementCc: 1199,
      fuelType: 'petrol',
      transmission: 'manual',
      volumetricEfficiency: 0.85,
      odometerPidStrategy: 'psaUds',
      inductionType: InductionType.turbocharged,
      directInjection: true,
    );
    const yarisHybrid = ReferenceVehicle(
      make: 'Toyota',
      model: 'Yaris',
      generation: 'IV (2020-)',
      yearStart: 2020,
      displacementCc: 1490,
      fuelType: 'hybrid',
      transmission: 'automatic',
      volumetricEfficiency: 0.88,
      atkinsonCycle: true,
    );

    /// Rate and the η_v the snapshot stamped, for one speed-density tick.
    (double, double?) sd(VehicleProfile? vehicle, ReferenceVehicle? ref) {
      final snap = _snapshot(_sd2500, vehicle: vehicle, reference: ref);
      return (snap.deriveFuelRateLPerHour()!, snap.lastFuelRateVe);
    }

    test('manual overrides win over profile, catalog and defaults', () {
      const profile = VehicleProfile(
        id: 'v',
        name: 'Duster (overridden)',
        engineDisplacementCc: 1461,
        volumetricEfficiency: 0.86,
        preferredFuelType: 'diesel',
        manualEngineDisplacementCcOverride: 1700.0,
        manualVolumetricEfficiencyOverride: 0.92,
        manualAfrOverride: 14.0,
        manualFuelDensityGPerLOverride: 800.0,
      );
      final (rate, ve) = sd(profile, duster);
      expect(rate,
          closeTo(_sd2500Rate(cc: 1700, ve: 0.92, afr: 14.0, density: 800), 1e-9));
      expect(ve, 0.92);
      expect(
          (rate -
                  _sd2500Rate(
                      cc: 1461,
                      ve: 0.86,
                      afr: kDieselAfr,
                      density: kDieselDensityGPerL))
              .abs(),
          greaterThan(0.1));
    });

    test('no overrides → the profile fields', () {
      const profile = VehicleProfile(
        id: 'v',
        name: 'Duster (vehicle)',
        engineDisplacementCc: 1500,
        volumetricEfficiency: 0.90,
        preferredFuelType: 'diesel',
      );
      expect(
          sd(profile, duster).$1,
          closeTo(
              _sd2500Rate(
                  cc: 1500,
                  ve: 0.90,
                  afr: kDieselAfr,
                  density: kDieselDensityGPerL),
              1e-9));
    });

    test('only the AFR overridden: displacement, η_v and density keep their '
        'chain', () {
      const profile = VehicleProfile(
        id: 'v',
        name: 'Duster (partial)',
        engineDisplacementCc: 1461,
        volumetricEfficiency: 0.86,
        preferredFuelType: 'diesel',
        manualAfrOverride: 14.0,
      );
      expect(
          sd(profile, duster).$1,
          closeTo(
              _sd2500Rate(
                  cc: 1461, ve: 0.86, afr: 14.0, density: kDieselDensityGPerL),
              1e-9));
    });

    test('profile 1600 cc × 0.88 differs clearly from the 1000 cc × 0.85 '
        'default', () {
      const profile = VehicleProfile(
        id: 'v1',
        name: '1.6L override',
        engineDisplacementCc: 1600,
        volumetricEfficiency: 0.88,
      );
      final rate = sd(profile, null).$1;
      expect(rate, closeTo(_sd2500Rate(cc: 1600, ve: 0.88), 1e-9));
      expect((rate - sd(null, null).$1).abs(), greaterThan(1e-2));
      expect(sd(null, null).$1, closeTo(_sd2500Rate(cc: 1000, ve: 0.85), 1e-9));
    });

    test('profile displacement with the model-default η_v 0.85', () {
      const profile =
          VehicleProfile(id: 'v2', name: '1.6L', engineDisplacementCc: 1600);
      expect(sd(profile, null).$1,
          closeTo(_sd2500Rate(cc: 1600, ve: 0.85), 1e-9));
    });

    test('no profile displacement → 1000 cc; the profile η_v still wins', () {
      const profile =
          VehicleProfile(id: 'v3', name: 'no cc', volumetricEfficiency: 0.72);
      expect(sd(profile, null).$1,
          closeTo(_sd2500Rate(cc: 1000, ve: 0.72), 1e-9));
    });

    test('doubling the displacement doubles the rate', () {
      const frames = {
        '010B': '41 0B 50', // MAP 80 kPa
        '010F': '41 0F 41', // IAT 25 °C
        '010C': '41 0C 0E A6', // 939.5 rpm
      };
      final oneLitre = _rate(frames,
          vehicle: const VehicleProfile(
              id: 'a', name: '1.0L', engineDisplacementCc: 1000))!;
      final twoLitre = _rate(frames,
          vehicle: const VehicleProfile(
              id: 'b', name: '2.0L', engineDisplacementCc: 2000))!;
      expect(twoLitre / oneLitre, closeTo(2.0, 0.01));
    });

    test('the catalog displacement is NOT consulted: a profile without one '
        'uses 1000 cc (#4315 — the pull reader used the catalog row)', () {
      const profile = VehicleProfile(
          id: 'v', name: 'Duster (catalog)', preferredFuelType: 'diesel');
      final (rate, ve) = sd(profile, duster);
      expect(ve, 0.85);
      expect(
          rate,
          closeTo(
              _sd2500Rate(
                  cc: 1000,
                  ve: 0.85,
                  afr: kDieselAfr,
                  density: kDieselDensityGPerL),
              1e-9));
    });

    test('a profile displacement still beats the catalog, with the profile '
        'η_v', () {
      const profile = VehicleProfile(
        id: 'override',
        name: 'tuned',
        engineDisplacementCc: 1800,
        volumetricEfficiency: 0.92,
      );
      expect(sd(profile, peugeot208).$1,
          closeTo(_sd2500Rate(cc: 1800, ve: 0.92), 1e-9));
    });

    group('η_v engine-tech defaults (#1422 phase 1)', () {
      test('manual override beats the VNT helper', () {
        const profile = VehicleProfile(
          id: 'v',
          name: 'manual',
          engineDisplacementCc: 1461,
          preferredFuelType: 'diesel',
          manualVolumetricEfficiencyOverride: 0.78,
        );
        expect(sd(profile, dusterDci).$2, 0.78);
      });

      test('a stored non-default value (0.91) beats the turbo-DI helper', () {
        const profile = VehicleProfile(
          id: 'v',
          name: '208 stored',
          engineDisplacementCc: 1199,
          volumetricEfficiency: 0.91,
        );
        expect(sd(profile, peugeot208).$2, 0.91);
      });

      test('a learned 0.85 (samples > 0) is kept', () {
        const profile = VehicleProfile(
          id: 'v',
          name: 'learned',
          engineDisplacementCc: 1461,
          preferredFuelType: 'diesel',
          volumetricEfficiencySamples: 3,
        );
        expect(sd(profile, dusterDci).$2, 0.85);
      });

      test('cold-start profile + VNT diesel → 0.95, a higher rate than '
          '0.85', () {
        const profile = VehicleProfile(
          id: 'v',
          name: 'cold',
          engineDisplacementCc: 1461,
          preferredFuelType: 'diesel',
        );
        final (rate, ve) = sd(profile, dusterDci);
        expect(ve, 0.95);
        const diesel = (afr: kDieselAfr, density: kDieselDensityGPerL);
        expect(
            rate,
            closeTo(
                _sd2500Rate(
                    cc: 1461,
                    ve: 0.95,
                    afr: diesel.afr,
                    density: diesel.density),
                1e-9));
        expect(
            rate,
            greaterThan(_sd2500Rate(
                cc: 1461,
                ve: 0.85,
                afr: diesel.afr,
                density: diesel.density)));
      });

      test('cold-start profile + turbo-DI petrol → 0.93', () {
        const profile = VehicleProfile(
            id: 'v', name: '208 cold', engineDisplacementCc: 1199);
        expect(sd(profile, peugeot208).$2, 0.93);
      });

      test('cold-start profile + Atkinson → 0.70', () {
        const profile = VehicleProfile(
            id: 'v', name: 'Yaris cold', engineDisplacementCc: 1490);
        expect(sd(profile, yarisHybrid).$2, 0.70);
      });

      test('no catalog match → the 0.85 hard fallback', () {
        const profile = VehicleProfile(
            id: 'v', name: 'niche import', engineDisplacementCc: 1500);
        final (rate, ve) = sd(profile, null);
        expect(ve, 0.85);
        expect(rate, closeTo(_sd2500Rate(cc: 1500, ve: 0.85), 1e-9));
      });

      test('no profile + turbo-DI catalog row → 0.93 at the 1000 cc '
          'fallback', () {
        const vwGolf = ReferenceVehicle(
          make: 'Volkswagen',
          model: 'Golf',
          generation: 'VIII (2019-)',
          yearStart: 2019,
          displacementCc: 1498,
          fuelType: 'petrol',
          transmission: 'automatic',
          volumetricEfficiency: 0.87,
          odometerPidStrategy: 'vwUds',
          inductionType: InductionType.turbocharged,
          directInjection: true,
        );
        final (rate, ve) = sd(null, vwGolf);
        expect(ve, 0.93);
        expect(rate, closeTo(_sd2500Rate(cc: 1000, ve: 0.93), 1e-9));
      });
    });
  });

  group('breadcrumbs and sanity bounds (#1395)', () {
    test('a 5E tick records a 5E crumb with the rate and the constants', () {
      final collector = Obd2BreadcrumbCollector();
      final rate = _snapshot({'015E': '41 5E 00 50'}, collector: collector)
          .deriveFuelRateLPerHour();
      expect(rate, closeTo(4.0, 0.01));
      expect(collector.entries, hasLength(1));
      final crumb = collector.entries.single;
      expect(crumb.branch, Obd2BranchTag.pid5E);
      expect(crumb.fuelRateLPerHour, closeTo(4.0, 0.01));
      expect(crumb.pid5ELPerHour, closeTo(4.0, 0.01));
      expect(crumb.afr, closeTo(14.7, 0.01));
      expect(crumb.fuelDensityGPerL, closeTo(740, 0.5));
      expect(crumb.flag, isNull);
    });

    test('bound A: 5E < 0.3 L/h above 1500 rpm is flagged, not dropped', () {
      final collector = Obd2BreadcrumbCollector();
      final rate = _snapshot(
        {'015E': '41 5E 00 04', '010C': '41 0C 22 00'}, // 0.2 L/h, 2176 rpm
        collector: collector,
      ).deriveFuelRateLPerHour();
      expect(rate, closeTo(0.2, 0.01));
      expect(collector.entries.single.flag,
          Obd2BreadcrumbCollector.flagSuspiciousLow);
      expect(collector.entries.single.rpm, closeTo(2176, 0.5));
      expect(collector.suspiciousSampleCount, 1);
    });

    test('bound A: the same low rate at idle is not flagged', () {
      final collector = Obd2BreadcrumbCollector();
      _snapshot({'015E': '41 5E 00 04', '010C': '41 0C 0C 80'},
              collector: collector)
          .deriveFuelRateLPerHour();
      expect(collector.entries.single.flag, isNull);
      expect(collector.suspiciousSampleCount, 0);
    });

    test('bound B: 5E vs MAF divergence > 50 % is flagged', () {
      final collector = Obd2BreadcrumbCollector();
      _snapshot({
        '015E': '41 5E 01 40', // 16.0 L/h vs MAF-derived ≈ 3.39
        ..._maf10,
        '010C': '41 0C 0C 80',
      }, collector: collector)
          .deriveFuelRateLPerHour();
      expect(collector.entries, hasLength(1));
      expect(collector.entries.single.flag,
          Obd2BreadcrumbCollector.flag5eVsMafDivergent);
      expect(collector.suspiciousSampleCount, 1);
    });

    test('bound B: 5E within 50 % of MAF is not flagged', () {
      final collector = Obd2BreadcrumbCollector();
      _snapshot({
        '015E': '41 5E 00 44', // 3.4 L/h
        ..._maf10,
        '010C': '41 0C 0C 80',
      }, collector: collector)
          .deriveFuelRateLPerHour();
      expect(collector.entries.single.flag, isNull);
      expect(collector.suspiciousSampleCount, 0);
    });

    test('a MAF tick records a MAF crumb with the g/s', () {
      final collector = Obd2BreadcrumbCollector();
      _snapshot(_maf10, collector: collector).deriveFuelRateLPerHour();
      expect(collector.entries.single.branch, Obd2BranchTag.maf);
      expect(collector.entries.single.mafGramsPerSecond, closeTo(10.24, 0.01));
    });

    test('a speed-density tick records MAP, IAT and rpm', () {
      final collector = Obd2BreadcrumbCollector();
      _snapshot(_sd2500, collector: collector).deriveFuelRateLPerHour();
      final crumb = collector.entries.single;
      expect(crumb.branch, Obd2BranchTag.speedDensity);
      expect(crumb.mapKpa, closeTo(65, 0.01));
      expect(crumb.iatCelsius, closeTo(30, 0.01));
      expect(crumb.rpm, closeTo(2500, 0.01));
    });

    test('without a collector the rate is unchanged', () {
      expect(_rate({'015E': '41 5E 01 80'}), closeTo(19.2, 0.1));
    });
  });
}
