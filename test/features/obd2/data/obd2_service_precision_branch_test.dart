// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/obd2/data/fuel_mixture_model.dart';
import 'package:tankstellen/features/obd2/data/obd2_breadcrumb_collector.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_transport.dart';

/// Epic #3416 — the PULL mirror ([Obd2Service.readFuelRateLPerHour]) with
/// the precision branches, driven through [FakeObd2Transport] raw
/// transcripts (real `41 …>` frames; mapped-but-NO-DATA commands mean
/// "supported but silent", so the chain tries them and falls through).
///
/// The precision families (wideband φ, 0x66, 0x9D/0xA2, 0x52) are gated
/// STRICTLY on a RESOLVED support set (`isPidKnownSupported`, never
/// blind-subscribed), so every harness seeds the resolver via
/// [Obd2Service.debugSetSupportedPids] with the full set this file
/// exercises — branch selection is then driven purely by the transcript.
const _initResponses = {
  'ATZ': 'ELM327 v1.5>',
  'ATE0': 'OK>',
  'ATL0': 'OK>',
  'ATH0': 'OK>',
  'ATSP0': 'OK>',
};

/// Every PID this file's scenarios rely on — legacy chain PIDs included,
/// because a RESOLVED set is authoritative (membership, no blind-allow).
const _kResolvedPids = <int>{
  0x04, 0x06, 0x07, 0x0B, 0x0C, 0x0D, 0x0F, 0x10, 0x11, // legacy chain
  0x24, 0x33, 0x44, 0x52, 0x5E, 0x66, 0x9D, 0xA2, // precision + mixture
};

Future<Obd2Service> _connected(Map<String, String> extra,
    {Obd2BreadcrumbCollector? collector}) async {
  final transport = FakeObd2Transport({..._initResponses, ...extra});
  final service = Obd2Service(transport);
  service.breadcrumbCollector = collector;
  await service.connect();
  service.debugSetSupportedPids(_kResolvedPids);
  return service;
}

void main() {
  const maf10 = '41 10 04 00>'; // 10.24 g/s
  const kPetrolAfr = 14.7;
  const kDieselAfr = 14.5;
  const kPetrolDensity = 740.0;
  const kDieselDensity = 832.0;

  group('branch order (#3428) — pull mirror', () {
    test('0x9D wins over a present 0x5E and needs only the density', () async {
      final service = await _connected({
        '019D': '41 9D 01 F4 00 00>', // 10.0 g/s
        '015E': '41 5E 08 00>', // 102.4 L/h — must NOT be returned
      });
      final rate = await service.readFuelRateLPerHour();
      expect(rate, closeTo(10.0 * 3600.0 / kPetrolDensity, 0.01));
    });

    test('9d-vs-5e divergence stamps the breadcrumb flag', () async {
      final collector = Obd2BreadcrumbCollector();
      final service = await _connected({
        '019D': '41 9D 01 F4 00 00>', // ≈ 48.65 L/h
        '015E': '41 5E 00 64>', // 5.0 L/h → > 50 % divergence
      }, collector: collector);
      await service.readFuelRateLPerHour();
      expect(
        collector.entries.last.flag,
        Obd2BreadcrumbCollector.flag9dVs5eDivergent,
      );
    });

    test('0xA2 converts via RPM + cylinders when 9D is silent', () async {
      const fourCyl = VehicleProfile(
        id: 'c4',
        name: 'four cylinder',
        engineCylinders: 4,
      );
      final service = await _connected({
        '019D': 'NO DATA>',
        '01A2': '41 A2 02 80>', // 20 mg/stroke
        '010C': '41 0C 27 10>', // 2500 RPM
        '015E': 'NO DATA>',
        '0110': 'NO DATA>',
      });
      final rate = await service.readFuelRateLPerHour(vehicle: fourCyl);
      const gps = 20.0 * (2500.0 / 60.0) / 2.0 * 4.0 / 1000.0;
      expect(rate, closeTo(gps * 3600.0 / kPetrolDensity, 0.01));
    });

    test('0xA2 is skipped without a cylinder count → chain falls to 5E',
        () async {
      final service = await _connected({
        '019D': 'NO DATA>',
        '01A2': '41 A2 02 80>',
        '015E': '41 5E 00 64>', // 5.0 L/h — the chain must land here
      });
      final rate = await service.readFuelRateLPerHour();
      expect(rate, closeTo(5.0, 0.01));
    });

    test('MAF branch prefers the 0x66 total over 0x10', () async {
      final service = await _connected({
        '019D': 'NO DATA>',
        '015E': 'NO DATA>',
        '0166': '41 66 03 05 40 02 A0>', // 42 + 21 = 63 g/s
        '0110': maf10, // 10.24 g/s — must NOT be used
        '0124': 'NO DATA>',
        '0144': 'NO DATA>',
        '0106': 'NO DATA>',
        '0107': 'NO DATA>',
      });
      final rate = await service.readFuelRateLPerHour();
      expect(
        rate,
        closeTo(63.0 * 3600.0 / (kPetrolAfr * kPetrolDensity), 0.02),
      );
    });
  });

  group('measured φ over commanded (#3427) — pull mirror', () {
    test('wideband 0x24 beats commanded 0x44 in the MAF branch', () async {
      final service = await _connected({
        '019D': 'NO DATA>',
        '015E': 'NO DATA>',
        '0166': 'NO DATA>',
        '0110': maf10,
        '0124': '41 24 66 66 32 DD>', // measured φ ≈ 0.7999 (lean)
        '0144': '41 44 99 9A>', // commanded 1.2 — must NOT be used
        '0106': 'NO DATA>',
        '0107': 'NO DATA>',
      });
      final rate = await service.readFuelRateLPerHour();
      const effAfr = kPetrolAfr / (0x6666 * 2.0 / 65536.0);
      expect(
        rate,
        closeTo(10.24 * 3600.0 / (effAfr * kPetrolDensity), 0.02),
      );
    });
  });

  group('diesel gating (#3430) — pull mirror', () {
    const diesel = VehicleProfile(
      id: 'd',
      name: 'diesel',
      preferredFuelType: 'diesel',
    );

    test('diesel skips trim + commanded φ (rich frame + big trims present '
        'change nothing)', () async {
      final service = await _connected({
        '019D': 'NO DATA>',
        '015E': 'NO DATA>',
        '0166': 'NO DATA>',
        '0110': maf10,
        '0124': 'NO DATA>',
        '0144': '41 44 99 9A>', // must NOT be applied
        '0106': '41 06 A0>', // +25 % STFT — must NOT be applied
        '0107': '41 07 A0>', // +25 % LTFT — must NOT be applied
      });
      final rate = await service.readFuelRateLPerHour(vehicle: diesel);
      expect(
        rate,
        closeTo(10.24 * 3600.0 / (kDieselAfr * kDieselDensity), 0.01),
      );
    });

    test('diesel USES a measured wideband φ', () async {
      final service = await _connected({
        '019D': 'NO DATA>',
        '015E': 'NO DATA>',
        '0166': 'NO DATA>',
        '0110': maf10,
        '0124': '41 24 66 66 32 DD>', // measured φ ≈ 0.7999
        '0106': 'NO DATA>',
        '0107': 'NO DATA>',
      });
      final rate = await service.readFuelRateLPerHour(vehicle: diesel);
      const effAfr = kDieselAfr / (0x6666 * 2.0 / 65536.0);
      expect(
        rate,
        closeTo(10.24 * 3600.0 / (effAfr * kDieselDensity), 0.02),
      );
    });

    test('petrol regression: commanded φ + trims still apply', () async {
      final service = await _connected({
        '019D': 'NO DATA>',
        '015E': 'NO DATA>',
        '0166': 'NO DATA>',
        '0110': maf10,
        '0124': 'NO DATA>',
        '0144': '41 44 99 9A>', // 1.2 rich
        '0106': '41 06 8D>', // +10.16 %
        '0107': '41 07 80>', // 0 %
      });
      final rate = await service.readFuelRateLPerHour();
      const effAfr = kPetrolAfr / (0x999A * 2.0 / 65536.0);
      const raw = 10.24 * 3600.0 / (effAfr * kPetrolDensity);
      const stft = (0x8D - 128) * 100.0 / 128.0;
      expect(rate, closeTo(raw * (1.0 + stft / 100.0), 0.02));
    });
  });

  group('ethanol blend (#3429) — pull mirror', () {
    test('measured 0x52 blends the constants in the MAF branch', () async {
      final service = await _connected({
        '019D': 'NO DATA>',
        '015E': 'NO DATA>',
        '0166': 'NO DATA>',
        '0110': maf10,
        '0152': '41 52 D9>', // ≈ 85.1 %
        '0124': 'NO DATA>',
        '0144': 'NO DATA>',
        '0106': 'NO DATA>',
        '0107': 'NO DATA>',
      });
      final rate = await service.readFuelRateLPerHour();
      final blend = blendedAfrDensityForEthanol(217 * 100.0 / 255.0);
      expect(
        rate,
        closeTo(10.24 * 3600.0 / (blend.afr * blend.densityGPerL), 0.03),
      );
    });

    test('manual AFR/density overrides beat the measured blend', () async {
      const pinned = VehicleProfile(
        id: 'p',
        name: 'pinned',
        preferredFuelType: 'e85',
        manualAfrOverride: 10.5,
        manualFuelDensityGPerLOverride: 800.0,
      );
      final service = await _connected({
        '019D': 'NO DATA>',
        '015E': 'NO DATA>',
        '0166': 'NO DATA>',
        '0110': maf10,
        '0152': '41 52 40>', // ≈ 25 % — must NOT displace the override
        '0124': 'NO DATA>',
        '0144': 'NO DATA>',
        '0106': 'NO DATA>',
        '0107': 'NO DATA>',
      });
      final rate = await service.readFuelRateLPerHour(vehicle: pinned);
      expect(rate, closeTo(10.24 * 3600.0 / (10.5 * 800.0), 0.01));
    });
  });
}
