import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';

// Shared AT-init boilerplate for the FakeObd2Transport.
const _initResponses = {
  'ATZ': 'ELM327 v1.5>',
  'ATE0': 'OK>',
  'ATL0': 'OK>',
  'ATH0': 'OK>',
  'ATSP0': 'OK>',
};

Future<Obd2Service> _connected(Map<String, String> extra) async {
  final transport = FakeObd2Transport({..._initResponses, ...extra});
  final service = Obd2Service(transport);
  await service.connect();
  return service;
}

void main() {
  group('Obd2Service.readFuelRateLPerHour — MAF fuel-type branch (#800)', () {
    // MAF input used across the diesel / petrol comparison below.
    // `41 10 04 00` decodes as (0x0400 / 100) = 10.24 g/s.
    const mafLine = '41 10 04 00>';

    test(
        'PID 5E supported: returns 5E value directly; MAF + trim never '
        'consulted — preserves pre-#800 contract', () async {
      // PID 5E present. MAF intentionally NOT mocked — if the chain
      // reached it the fake transport would return NO DATA and the
      // final rate would match the MAF branch instead. Asserting the
      // 5E value proves the earlier tier won.
      final service = await _connected({
        '015E': '41 5E 08 00>', // raw 2048 / 20 = 102.4 L/h
        '0106': '41 06 A0>', // +25% STFT (must NOT be applied)
        '0107': '41 07 A0>', // +25% LTFT (must NOT be applied)
      });
      final rate = await service.readFuelRateLPerHour();
      expect(rate, closeTo(102.4, 0.1));
    });

    test(
        'PID 5E not supported, PID 10 supported, petrol profile: MAF '
        'formula uses AFR 14.7 × density 740 g/L', () async {
      final service = await _connected({
        '015E': 'NO DATA>',
        '0110': mafLine,
        '0106': 'NO DATA>', // no trim correction
        '0107': 'NO DATA>',
      });
      const profile = VehicleProfile(
        id: 'v1',
        name: 'Peugeot 107 petrol',
        preferredFuelType: 'e10',
      );
      final rate = await service.readFuelRateLPerHour(vehicle: profile);
      // MAF = 10.24 g/s.
      // L/h = 10.24 × 3600 / (14.7 × 740) ≈ 3.389.
      expect(rate, closeTo(3.389, 0.01));
    });

    test(
        'PID 5E not supported, PID 10 supported, diesel profile: MAF '
        'formula uses AFR 14.5 × density 832 g/L (#800)', () async {
      final service = await _connected({
        '015E': 'NO DATA>',
        '0110': mafLine,
        '0106': 'NO DATA>',
        '0107': 'NO DATA>',
      });
      const profile = VehicleProfile(
        id: 'v2',
        name: 'Peugeot 107 diesel',
        preferredFuelType: 'diesel',
      );
      final rate = await service.readFuelRateLPerHour(vehicle: profile);
      // L/h = 10.24 × 3600 / (14.5 × 832) ≈ 3.056.
      expect(rate, closeTo(3.056, 0.01));
    });

    test(
        'dieselPremium string also routes through the diesel branch '
        '— key matches `contains("diesel")`', () async {
      final service = await _connected({
        '015E': 'NO DATA>',
        '0110': mafLine,
        '0106': 'NO DATA>',
        '0107': 'NO DATA>',
      });
      const profile = VehicleProfile(
        id: 'v3',
        name: 'dieselPremium car',
        preferredFuelType: 'dieselPremium',
      );
      final rate = await service.readFuelRateLPerHour(vehicle: profile);
      // Same math as the straight `diesel` case → ~3.056 L/h.
      expect(rate, closeTo(3.056, 0.01));
    });

    test(
        'diesel MAF rate < petrol MAF rate at identical MAF — the '
        'constants order correctly', () async {
      final petrol = await _connected({
        '015E': 'NO DATA>',
        '0110': mafLine,
        '0106': 'NO DATA>',
        '0107': 'NO DATA>',
      });
      final dieselSvc = await _connected({
        '015E': 'NO DATA>',
        '0110': mafLine,
        '0106': 'NO DATA>',
        '0107': 'NO DATA>',
      });
      const petrolProfile = VehicleProfile(
        id: 'p',
        name: 'petrol',
        preferredFuelType: 'e10',
      );
      const dieselProfile = VehicleProfile(
        id: 'd',
        name: 'diesel',
        preferredFuelType: 'diesel',
      );
      final petrolRate =
          await petrol.readFuelRateLPerHour(vehicle: petrolProfile);
      final dieselRate =
          await dieselSvc.readFuelRateLPerHour(vehicle: dieselProfile);
      expect(petrolRate, isNotNull);
      expect(dieselRate, isNotNull);
      // Diesel denominator (14.5 × 832) is bigger than petrol
      // (14.7 × 740) so L/h is smaller — matches real-world diesel
      // efficiency at identical mass-flow input.
      expect(dieselRate!, lessThan(petrolRate!));
    });

    test(
        'neither 5E nor 10: speed-density fallback still runs (MAP + '
        'IAT + RPM) — preserves pre-#800 Peugeot path', () async {
      final service = await _connected({
        '015E': 'NO DATA>',
        '0110': 'NO DATA>',
        '010B': '41 0B 28>', // MAP = 40 kPa (idle vacuum)
        '010F': '41 0F 41>', // IAT = 25 °C
        '010C': '41 0C 0C 80>', // RPM 800
        '0106': 'NO DATA>',
        '0107': 'NO DATA>',
      });
      final rate = await service.readFuelRateLPerHour();
      expect(rate, isNotNull);
      // Same plausibility envelope the #810 test asserts.
      expect(rate, greaterThan(0.2));
      expect(rate, lessThan(3.0));
    });

    test(
        'MAF path applies fuel-trim correction when STFT + LTFT are '
        'readable (#800, #813)', () async {
      final service = await _connected({
        '015E': 'NO DATA>',
        '0110': mafLine, // MAF 10.24 g/s → petrol raw ≈ 3.389 L/h
        '0106': '41 06 8D>', // STFT raw 0x8D ≈ +10.16 %
        '0107': '41 07 86>', // LTFT raw 0x86 ≈ +4.69 %
      });
      const profile = VehicleProfile(
        id: 'v5',
        name: 'petrol + trims',
        preferredFuelType: 'e10',
      );
      final rate = await service.readFuelRateLPerHour(vehicle: profile);
      // Correction factor 1 + (10.16 + 4.69)/100 ≈ 1.1485.
      // 3.389 × 1.1485 ≈ 3.893 L/h.
      expect(rate, closeTo(3.893, 0.05));
    });

    test(
        'MAF path skips trim correction when STFT is missing — better '
        'raw MAF than half-applied trim (#813)', () async {
      final service = await _connected({
        '015E': 'NO DATA>',
        '0110': mafLine,
        '0106': 'NO DATA>', // STFT unavailable
        '0107': '41 07 86>',
      });
      final rate = await service.readFuelRateLPerHour();
      expect(rate, closeTo(3.389, 0.01));
    });

    test(
        'nothing supported (5E / 10 / MAP / IAT / RPM all NO DATA) '
        'returns null — pre-#800 contract', () async {
      final service = await _connected({
        '015E': 'NO DATA>',
        '0110': 'NO DATA>',
        '010B': 'NO DATA>',
        '010F': 'NO DATA>',
        '010C': 'NO DATA>',
      });
      expect(await service.readFuelRateLPerHour(), isNull);
    });

    test('null vehicle defaults to petrol on MAF path (#800)', () async {
      final service = await _connected({
        '015E': 'NO DATA>',
        '0110': mafLine,
        '0106': 'NO DATA>',
        '0107': 'NO DATA>',
      });
      final rate = await service.readFuelRateLPerHour();
      // Null vehicle should match the petrol profile rate: ~3.389 L/h.
      expect(rate, closeTo(3.389, 0.01));
    });

    test(
        'unknown preferredFuelType ("cng") defaults to petrol — safer '
        'to under-count than over-count', () async {
      final service = await _connected({
        '015E': 'NO DATA>',
        '0110': mafLine,
        '0106': 'NO DATA>',
        '0107': 'NO DATA>',
      });
      const profile = VehicleProfile(
        id: 'v6',
        name: 'CNG car',
        preferredFuelType: 'cng',
      );
      final rate = await service.readFuelRateLPerHour(vehicle: profile);
      // cng ≠ diesel → petrol constants → ~3.389 L/h.
      expect(rate, closeTo(3.389, 0.01));
    });
  });
}
