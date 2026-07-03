// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/obd2/data/fuel_mixture_model.dart';
import 'package:tankstellen/features/obd2/data/live_sample_snapshot.dart';
import 'package:tankstellen/features/obd2/data/obd2_breadcrumb_collector.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_transport.dart';
import 'package:tankstellen/features/obd2/data/pid_scheduler.dart';

/// Epic #3416 — the LIVE derivation path ([deriveFuelRateLPerHour]) with
/// the precision branches: 0x9D/0xA2 on top (#3428), 0x66-over-0x10 MAF,
/// measured-φ-over-commanded (#3427), diesel gating (#3430) and the
/// ethanol blend (#3429). Latches are filled by driving the REAL
/// scheduler + parsers with raw ELM327 frames — no echo fakes.
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
  /// Seeds the REAL resolver (#3416 seam) instead of overriding
  /// [isPidSupported]: the precision families are gated on the strict
  /// `isPidKnownSupported` (resolved ∧ contains), so the stubbed set must
  /// be a genuinely RESOLVED set for the production gate to pass.
  _SupportStubService(Set<int> supported) : super(_StubTransport()) {
    debugSetSupportedPids(supported);
  }
}

/// Subscribe a snapshot for [supported], run the scheduler over a
/// transport answering from [responses] (raw `41 …>` frames; anything
/// unmapped is NO DATA), then hand the snapshot back for derivation.
Future<LiveSampleSnapshot> _filledSnapshot({
  required Set<int> supported,
  required Map<String, String> responses,
  VehicleProfile? vehicle,
  Obd2BreadcrumbRecorder? collector,
  String? sessionFuelTypeKey,
}) async {
  final scheduler = PidScheduler(
    transport: (cmd) async => responses[cmd.trim()] ?? 'NO DATA>',
    tickRate: const Duration(milliseconds: 2),
  );
  final snapshot = LiveSampleSnapshot(
    service: _SupportStubService(supported),
    vehicle: vehicle,
    breadcrumbCollector: collector,
    onHighPriorityParse: (_) {},
    onSpeedSample: (_) {},
  )..sessionFuelTypeKey = sessionFuelTypeKey;
  snapshot.subscribeAllTiers(scheduler);
  scheduler.start();
  await Future<void>.delayed(const Duration(milliseconds: 400));
  scheduler.stop();
  await Future<void>.delayed(const Duration(milliseconds: 20));
  return snapshot;
}

void main() {
  // Raw fixtures (real ELM327 Mode 01 wire format).
  const rpm2500 = '41 0C 27 10>'; // 2500 RPM
  const maf10 = '41 10 04 00>'; // PID 0x10: 10.24 g/s
  const maf66A = '41 66 01 05 40>'; // PID 0x66 sensor A: 42 g/s
  const rate9d = '41 9D 01 F4 00 00>'; // 10.0 g/s engine fuel
  const cylRate = '41 A2 02 80>'; // 20 mg/stroke
  const phiLean = '41 24 66 66 32 DD>'; // measured φ ≈ 0.7999
  const phiRich44 = '41 44 99 9A>'; // commanded φ ≈ 1.2
  const ethanol85 = '41 52 D9>'; // 0xD9=217 → ≈ 85.1 %
  const stftPlus10 = '41 06 8D>'; // +10.16 %
  const ltftZero = '41 07 80>'; // 0 %

  group('branch order (#3428) — live path', () {
    test('0x9D wins over a present 0x5E; provenance = pid9D; '
        '9d-vs-5e divergence is flagged', () async {
      final collector = Obd2BreadcrumbCollector();
      final snap = await _filledSnapshot(
        supported: {0x9D, 0x5E, 0x0C},
        responses: {
          '019D': rate9d,
          '015E': '41 5E 00 64>', // 5.0 L/h — diverges from 9D's ~48.6
          '010C': rpm2500,
        },
        collector: collector,
      );
      final rate = snap.deriveFuelRateLPerHour();
      // 10 g/s × 3600 / 740 g/L ≈ 48.65 L/h (density only, petrol).
      expect(rate, closeTo(10.0 * 3600.0 / kPetrolDensityGPerL, 0.01));
      expect(snap.lastFuelRateSource, FuelRateSourceTag.pid9D);
      expect(
        collector.entries.last.flag,
        Obd2BreadcrumbCollector.flag9dVs5eDivergent,
      );
    });

    test('0xA2 converts via RPM + cylinder count when 9D is absent', () async {
      const fourCyl = VehicleProfile(
        id: 'c4',
        name: 'four cylinder',
        engineCylinders: 4,
      );
      final snap = await _filledSnapshot(
        supported: {0xA2, 0x0C},
        responses: {'01A2': cylRate, '010C': rpm2500},
        vehicle: fourCyl,
      );
      final rate = snap.deriveFuelRateLPerHour();
      // 20 mg × (2500/60)/2 × 4 = 1.6667 g/s → × 3600 / 740 ≈ 8.108 L/h.
      const gps = 20.0 * (2500.0 / 60.0) / 2.0 * 4.0 / 1000.0;
      expect(rate, closeTo(gps * 3600.0 / kPetrolDensityGPerL, 0.01));
      expect(snap.lastFuelRateSource, FuelRateSourceTag.pidA2);
    });

    test('0xA2 is skipped without a cylinder count → falls to 5E', () async {
      final snap = await _filledSnapshot(
        supported: {0xA2, 0x5E, 0x0C},
        responses: {
          '01A2': cylRate,
          '015E': '41 5E 00 64>', // 5.0 L/h
          '010C': rpm2500,
        },
      );
      expect(snap.deriveFuelRateLPerHour(), closeTo(5.0, 0.01));
      expect(snap.lastFuelRateSource, FuelRateSourceTag.pid5E);
    });

    test('MAF branch prefers the 0x66 total over 0x10', () async {
      final snap = await _filledSnapshot(
        supported: {0x66, 0x10},
        responses: {'0166': maf66A, '0110': maf10},
      );
      final rate = snap.deriveFuelRateLPerHour();
      // 42 g/s (0x66), NOT 10.24 g/s (0x10).
      expect(
        rate,
        closeTo(42.0 * 3600.0 / (kPetrolAfr * kPetrolDensityGPerL), 0.01),
      );
      expect(snap.lastFuelRateSource, FuelRateSourceTag.maf66);
    });
  });

  group('measured φ over commanded (#3427) — live path', () {
    test('fresh wideband φ (0x24) beats commanded 0x44 in the MAF branch',
        () async {
      final snap = await _filledSnapshot(
        supported: {0x10, 0x24, 0x44},
        responses: {'0110': maf10, '0124': phiLean, '0144': phiRich44},
      );
      final rate = snap.deriveFuelRateLPerHour();
      // effAFR = 14.7 / 0.7999 (measured LEAN), not 14.7 / 1.2.
      const effAfr = kPetrolAfr / (0x6666 * 2.0 / 65536.0);
      expect(
        rate,
        closeTo(10.24 * 3600.0 / (effAfr * kPetrolDensityGPerL), 0.02),
      );
    });

    test('commanded 0x44 remains the fallback without a wideband sensor',
        () async {
      final snap = await _filledSnapshot(
        supported: {0x10, 0x44},
        responses: {'0110': maf10, '0144': phiRich44},
      );
      final rate = snap.deriveFuelRateLPerHour();
      const effAfr = kPetrolAfr / (0x999A * 2.0 / 65536.0);
      expect(
        rate,
        closeTo(10.24 * 3600.0 / (effAfr * kPetrolDensityGPerL), 0.02),
      );
    });
  });

  group('diesel gating (#3430) — live path', () {
    const diesel = VehicleProfile(
      id: 'd',
      name: 'diesel',
      preferredFuelType: 'diesel',
    );

    test('diesel skips STFT/LTFT trim AND the commanded-φ adjustment', () async {
      final snap = await _filledSnapshot(
        supported: {0x10, 0x44, 0x06, 0x07},
        responses: {
          '0110': maf10,
          '0144': phiRich44, // must NOT be applied on diesel
          '0106': stftPlus10, // must NOT be applied on diesel
          '0107': ltftZero,
        },
        vehicle: diesel,
      );
      final rate = snap.deriveFuelRateLPerHour();
      // Pure stoich diesel math — no trim factor, no φ.
      expect(
        rate,
        closeTo(10.24 * 3600.0 / (kDieselAfr * kDieselDensityGPerL), 0.01),
      );
    });

    test('diesel USES a measured wideband φ (deep-lean allowed)', () async {
      final snap = await _filledSnapshot(
        supported: {0x10, 0x24},
        responses: {'0110': maf10, '0124': phiLean},
        vehicle: diesel,
      );
      final rate = snap.deriveFuelRateLPerHour();
      const effAfr = kDieselAfr / (0x6666 * 2.0 / 65536.0);
      expect(
        rate,
        closeTo(10.24 * 3600.0 / (effAfr * kDieselDensityGPerL), 0.02),
      );
    });

    test('petrol regression: trims + commanded φ still apply exactly as '
        'before', () async {
      final snap = await _filledSnapshot(
        supported: {0x10, 0x44, 0x06, 0x07},
        responses: {
          '0110': maf10,
          '0144': phiRich44,
          '0106': stftPlus10,
          '0107': ltftZero,
        },
      );
      final rate = snap.deriveFuelRateLPerHour();
      const effAfr = kPetrolAfr / (0x999A * 2.0 / 65536.0);
      const raw = 10.24 * 3600.0 / (effAfr * kPetrolDensityGPerL);
      const stft = (0x8D - 128) * 100.0 / 128.0;
      expect(rate, closeTo(raw * (1.0 + stft / 100.0), 0.02));
    });
  });

  group('ethanol blend + session fuel type (#3429) — live path', () {
    test('measured 0x52 ≈ 85 % swaps the petrol constants for the blend',
        () async {
      final snap = await _filledSnapshot(
        supported: {0x10, 0x52},
        responses: {'0110': maf10, '0152': ethanol85},
      );
      final rate = snap.deriveFuelRateLPerHour();
      final blend = blendedAfrDensityForEthanol(217 * 100.0 / 255.0);
      expect(
        rate,
        closeTo(10.24 * 3600.0 / (blend.afr * blend.densityGPerL), 0.03),
      );
      expect(snap.latestEthanolPercent, closeTo(85.1, 0.1));
    });

    test('session 0x51 key (diesel) beats a petrol profile key', () async {
      const petrolProfile = VehicleProfile(
        id: 'p',
        name: 'says petrol',
        preferredFuelType: 'petrol',
      );
      final snap = await _filledSnapshot(
        supported: {0x10},
        responses: {'0110': maf10},
        vehicle: petrolProfile,
        sessionFuelTypeKey: 'diesel',
      );
      final rate = snap.deriveFuelRateLPerHour();
      expect(
        rate,
        closeTo(10.24 * 3600.0 / (kDieselAfr * kDieselDensityGPerL), 0.01),
      );
    });
  });
}
