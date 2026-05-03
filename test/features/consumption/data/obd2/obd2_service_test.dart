import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_breadcrumb_collector.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/vehicle/domain/entities/reference_vehicle.dart';
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

/// Minimal transport that records the order of [sendCommand] calls
/// into the supplied list. Used by the #1330 regression test that
/// pins the legacy init sequence.
class _RecordingTransport implements Obd2Transport {
  final Map<String, String> _responses;
  final List<String> _log;
  bool _connected = false;

  _RecordingTransport(this._responses, this._log);

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async => _connected = true;

  @override
  Future<String> sendCommand(String command) async {
    if (!_connected) throw StateError('Not connected');
    final cmd = command.trim();
    _log.add(cmd);
    return _responses[cmd] ?? 'NO DATA>';
  }

  @override
  Future<void> disconnect() async => _connected = false;
}

void main() {
  group('Obd2Service PID expansion (#717)', () {
    test('readEngineLoad parses PID 04', () async {
      final service = await _connected({'0104': '41 04 80>'});
      expect(await service.readEngineLoad(), closeTo(50.2, 0.1));
    });

    test('readThrottlePercent parses PID 11', () async {
      final service = await _connected({'0111': '41 11 40>'});
      expect(await service.readThrottlePercent(), closeTo(25.1, 0.1));
    });

    test('readFuelRateLPerHour returns PID 5E when supported', () async {
      final service = await _connected({'015E': '41 5E 08 00>'});
      expect(await service.readFuelRateLPerHour(), closeTo(102.4, 0.1));
    });

    test(
        'readFuelRateLPerHour falls back to MAF (PID 10) when 5E returns '
        'NO DATA', () async {
      final service = await _connected({
        '015E': 'NO DATA>',
        '0110': '41 10 04 00>', // MAF = 10.24 g/s
      });
      final rate = await service.readFuelRateLPerHour();
      // 10.24 × 3600 / (14.7 × 740) ≈ 3.389 L/h
      expect(rate, closeTo(3.389, 0.01));
    });

    test(
        'readFuelRateLPerHour returns null when neither PID 5E nor MAF '
        'are supported AND the speed-density PIDs also fail', () async {
      // All three fallback tiers unsupported → final null. No change
      // to this contract after #800 added step 3 — only the path to
      // null grew an extra branch.
      final service = await _connected({
        '015E': 'NO DATA>',
        '0110': 'NO DATA>',
        '010B': 'NO DATA>',
        '010F': 'NO DATA>',
        '010C': 'NO DATA>',
      });
      expect(await service.readFuelRateLPerHour(), isNull);
    });

    test(
        'readFuelRateLPerHour falls back to speed-density (MAP+IAT+RPM) '
        'when neither PID 5E nor MAF are supported — #800 Peugeot 107 path',
        () async {
      // Peugeot 107 1.0L 1KR-FE ground truth: no 5E, no MAF, but MAP
      // + IAT + RPM all present. At idle (RPM 800, MAP 40 kPa, IAT
      // 25 °C) the speed-density estimate should land in a plausible
      // range around 0.5–1.5 L/h — not null, not zero, not insane.
      final service = await _connected({
        '015E': 'NO DATA>',
        '0110': 'NO DATA>',
        '010B': '41 0B 28>', // MAP = 40 kPa (idle vacuum)
        '010F': '41 0F 41>', // IAT = 25 °C (raw 0x41 = 65, 65−40 = 25)
        '010C': '41 0C 0C 80>', // RPM = ((12×256)+128)/4 = 800
      });
      final rate = await service.readFuelRateLPerHour();
      expect(rate, isNotNull);
      expect(rate, greaterThan(0.2));
      expect(rate, lessThan(3.0));
    });

    test(
        'readFuelRateLPerHour speed-density step returns null when any '
        'of MAP/IAT/RPM is missing — all three required', () async {
      // MAP present but IAT missing → step 3 bails out rather than
      // making up a temperature. Callers see the honest null and the
      // trip summary shows "—".
      final service = await _connected({
        '015E': 'NO DATA>',
        '0110': 'NO DATA>',
        '010B': '41 0B 40>',
        '010F': 'NO DATA>',
        '010C': '41 0C 0C 80>',
      });
      expect(await service.readFuelRateLPerHour(), isNull);
    });

    test('readManifoldPressureKpa parses PID 0B', () async {
      final service = await _connected({'010B': '41 0B 64>'});
      expect(await service.readManifoldPressureKpa(), closeTo(100.0, 0.01));
    });

    test('readIntakeAirTempCelsius parses PID 0F', () async {
      final service = await _connected({'010F': '41 0F 3C>'});
      expect(
        await service.readIntakeAirTempCelsius(),
        closeTo(20.0, 0.01),
      );
    });

    test(
        'readFuelRateLPerHour applies fuel-trim correction on the MAF path '
        'when both STFT and LTFT are readable (#813)', () async {
      final service = await _connected({
        '015E': 'NO DATA>',
        '0110': '41 10 04 00>', // MAF = 10.24 g/s → raw rate ≈ 3.389 L/h
        '0106': '41 06 8D>', // STFT raw 0x8D = 141 → +10.16 %
        '0107': '41 07 86>', // LTFT raw 0x86 = 134 → +4.69 %
      });
      final rate = await service.readFuelRateLPerHour();
      expect(rate, isNotNull);
      // Correction factor 1 + (10.16 + 4.69)/100 ≈ 1.1485
      // 3.389 × 1.1485 ≈ 3.893 L/h
      expect(rate, closeTo(3.893, 0.05));
    });

    test(
        'readFuelRateLPerHour skips trim correction on direct PID 5E path '
        '— that value is already post-trim (#813)', () async {
      final service = await _connected({
        '015E': '41 5E 08 00>', // 102.4 L/h
        '0106': '41 06 A0>', // +25% STFT — MUST NOT be applied
        '0107': '41 07 A0>', // +25% LTFT — MUST NOT be applied
      });
      final rate = await service.readFuelRateLPerHour();
      expect(rate, closeTo(102.4, 0.1));
    });

    test(
        'readFuelRateLPerHour leaves the raw rate unchanged when only one '
        'of STFT/LTFT is available (#813)', () async {
      // MAF path + STFT missing: prefer the raw 3.389 over a
      // half-applied correction.
      final service = await _connected({
        '015E': 'NO DATA>',
        '0110': '41 10 04 00>',
        '0106': 'NO DATA>',
        '0107': '41 07 90>',
      });
      final rate = await service.readFuelRateLPerHour();
      expect(rate, closeTo(3.389, 0.01));
    });

    group('readFuelRateLPerHour + supported-PID cache — #811 phase 2', () {
      test(
          'after discoverSupportedPids, unsupported PIDs are skipped — '
          'Peugeot 107 case: only MAP+IAT+RPM, no 5E, no MAF', () async {
        // Peugeot 107 exposes speed/RPM/load/coolant/throttle
        // /MAP/IAT but neither PID 5E nor MAF. Bitmap: 0x08 on PID
        // 0B (MAP), 0x02 on 0C (RPM), 0x08 on 0F (IAT). Easier to
        // hand-craft: a bitmap that supports 0B, 0C, 0F exactly.
        // bits-from-left (groupBase 0x00):
        //   PID 0B → byte 1 bit 2 = 0x20
        //   PID 0C → byte 1 bit 3 = 0x10
        //   PID 0F → byte 1 bit 6 = 0x02
        // → byte 1 = 0x32. All other bytes zero + no continuation.
        final service = await _connected({
          '0100': '41 00 00 32 00 00>', // PIDs 0B, 0C, 0F supported
          // Speed-density step responses:
          '010B': '41 0B 28>', // MAP 40 kPa
          '010F': '41 0F 41>', // IAT 25 °C
          '010C': '41 0C 0C 80>', // RPM 800
          // 5E and 10 intentionally UNMOCKED — if the service tries
          // them the fake transport returns NO DATA and costs a
          // round-trip. That's exactly the wasted work the cache
          // should prevent.
        });
        await service.discoverSupportedPids();
        expect(service.isPidSupported(0x5E), isFalse);
        expect(service.isPidSupported(0x10), isFalse);
        expect(service.isPidSupported(0x0B), isTrue);

        final rate = await service.readFuelRateLPerHour();
        // Speed-density produced a non-null rate → the chain reached
        // step 3 even though steps 1 and 2 were never queried.
        expect(rate, isNotNull);
        expect(rate, greaterThan(0));
      });

      test(
          'when cache is not populated, legacy blind-query behavior — '
          'every step still attempted', () async {
        // discoverSupportedPids never called → cache stays null →
        // isPidSupported returns true for every PID → all three
        // steps query blindly, honouring NO DATA as before.
        final service = await _connected({
          '015E': 'NO DATA>',
          '0110': 'NO DATA>',
          '010B': 'NO DATA>',
          '010F': 'NO DATA>',
          '010C': 'NO DATA>',
        });
        expect(service.isPidSupported(0x5E), isTrue);
        expect(await service.readFuelRateLPerHour(), isNull);
      });

      test(
          'cache-clear on reconnect — supported-PIDs forgotten between '
          'sessions', () async {
        final service = await _connected({
          '0100': '41 00 80 00 00 00>', // only PID 01
        });
        await service.discoverSupportedPids();
        expect(service.isPidSupported(0x5E), isFalse);

        await service.disconnect();
        await service.connect(); // fresh session
        expect(service.isPidSupported(0x5E), isTrue,
            reason: 'cache should clear on connect so a new car / '
                'new adapter firmware gets discovered fresh');
      });

      test(
          'MAF supported but 5E not → step 2 wins, step 3 never runs',
          () async {
        // Supported-PIDs bitmap sets PID 10 (MAF) but not 5E.
        // byte 1 bit 0 (= PID 09) through byte 1 bit 7 (= PID 16) —
        // MAF is PID 0x10 = 16 → byte 1 bit 7 = 0x01.
        final service = await _connected({
          '0100': '41 00 00 01 00 00>',
          '0110': '41 10 04 00>', // MAF = 10.24 g/s
          '0106': 'NO DATA>',
          '0107': 'NO DATA>',
        });
        await service.discoverSupportedPids();
        expect(service.isPidSupported(0x5E), isFalse);
        expect(service.isPidSupported(0x10), isTrue);

        final rate = await service.readFuelRateLPerHour();
        // MAF path (10.24 × 3600 / (14.7 × 740)) ≈ 3.389 L/h,
        // no trim correction because trims are NO DATA.
        expect(rate, closeTo(3.389, 0.01));
      });
    });

    group('readFuelRateLPerHour + VehicleProfile plumbing — #812 phase 3',
        () {
      // Shared Peugeot 107-style speed-density fixture: no 5E, no
      // MAF; only MAP+IAT+RPM. Same operating point across all the
      // tests below so expected values are comparable.
      const mapKpa = 65.0;
      const iatCelsius = 30.0;
      const rpm = 2500.0;
      Future<Obd2Service> speedDensityOnly() async {
        return _connected({
          '015E': 'NO DATA>',
          '0110': 'NO DATA>',
          '010B': '41 0B 41>', // MAP raw 0x41 = 65 kPa
          '010F': '41 0F 46>', // IAT raw 0x46 = 70; 70 − 40 = 30 °C
          '010C': '41 0C 27 10>', // RPM ((0x27×256)+0x10)/4 = 2500
          '0106': 'NO DATA>', // no fuel-trim correction in these tests
          '0107': 'NO DATA>',
        });
      }

      test(
          'null vehicle falls back to the same 1000 cc / 0.85 VE output '
          'as pre-phase-3 — characterization test', () async {
        final service = await speedDensityOnly();
        final rate = await service.readFuelRateLPerHour();
        final expected = Obd2Service.estimateFuelRateLPerHourFromMap(
          mapKpa: mapKpa,
          iatCelsius: iatCelsius,
          rpm: rpm,
          engineDisplacementCc: 1000,
          volumetricEfficiency: 0.85,
        );
        expect(rate, isNotNull);
        expect(expected, isNotNull);
        expect(rate, closeTo(expected!, 1e-3));
      });

      test(
          'VehicleProfile overrides both displacement and VE in the '
          'speed-density branch', () async {
        final service = await speedDensityOnly();
        const profile = VehicleProfile(
          id: 'v1',
          name: '1.6L override',
          engineDisplacementCc: 1600,
          volumetricEfficiency: 0.88,
        );
        final rate =
            await service.readFuelRateLPerHour(vehicle: profile);
        final expected = Obd2Service.estimateFuelRateLPerHourFromMap(
          mapKpa: mapKpa,
          iatCelsius: iatCelsius,
          rpm: rpm,
          engineDisplacementCc: 1600,
          volumetricEfficiency: 0.88,
        );
        expect(rate, isNotNull);
        expect(expected, isNotNull);
        expect(rate, closeTo(expected!, 1e-3));

        // And the override must actually change the answer vs. the
        // defaults — otherwise the plumbing could be silently
        // dropping the profile and the test would still pass.
        final defaultRate = await (await speedDensityOnly())
            .readFuelRateLPerHour();
        expect(
          (rate! - defaultRate!).abs(),
          greaterThan(1e-2),
          reason: '1600 cc × 0.88 VE should yield a clearly different '
              'rate from 1000 cc × 0.85 VE',
        );
      });

      test(
          'partial profile (displacement known, VE left at model default) '
          'uses the profile displacement and the VehicleProfile default VE',
          () async {
        final service = await speedDensityOnly();
        // VehicleProfile's volumetricEfficiency field defaults to
        // 0.85 at the model level — NOT null — so "unknown" here
        // means "user hasn't overridden the VehicleProfile default".
        // The behaviour should match passing a profile with
        // displacement 1600 + VE 0.85 explicitly.
        const profile = VehicleProfile(
          id: 'v2',
          name: '1.6L, default VE',
          engineDisplacementCc: 1600,
        );
        final rate =
            await service.readFuelRateLPerHour(vehicle: profile);
        final expected = Obd2Service.estimateFuelRateLPerHourFromMap(
          mapKpa: mapKpa,
          iatCelsius: iatCelsius,
          rpm: rpm,
          engineDisplacementCc: 1600,
          volumetricEfficiency: 0.85,
        );
        expect(rate, isNotNull);
        expect(expected, isNotNull);
        expect(rate, closeTo(expected!, 1e-3));
      });

      test(
          'profile with null engineDisplacementCc falls back to the '
          '1000 cc default — VE from profile still wins', () async {
        final service = await speedDensityOnly();
        const profile = VehicleProfile(
          id: 'v3',
          name: 'no displacement, custom VE',
          volumetricEfficiency: 0.72,
        );
        final rate =
            await service.readFuelRateLPerHour(vehicle: profile);
        final expected = Obd2Service.estimateFuelRateLPerHourFromMap(
          mapKpa: mapKpa,
          iatCelsius: iatCelsius,
          rpm: rpm,
          engineDisplacementCc: 1000,
          volumetricEfficiency: 0.72,
        );
        expect(rate, isNotNull);
        expect(expected, isNotNull);
        expect(rate, closeTo(expected!, 1e-3));
      });

      test(
          'profile is not used on the direct PID 5E path — that value '
          'is already per-vehicle from the ECU', () async {
        final service = await _connected({'015E': '41 5E 08 00>'});
        const profile = VehicleProfile(
          id: 'v4',
          name: 'irrelevant',
          engineDisplacementCc: 9999,
          volumetricEfficiency: 0.50,
        );
        final rate =
            await service.readFuelRateLPerHour(vehicle: profile);
        // Same 102.4 L/h as the no-profile 5E test above — the
        // profile is just ignored when PID 5E wins.
        expect(rate, closeTo(102.4, 0.1));
      });
    });

    group('discoverSupportedPids — #811', () {
      test('returns an empty set when the transport is disconnected',
          () async {
        final service = await _connected({});
        await service.disconnect();
        expect(await service.discoverSupportedPids(), isEmpty);
      });

      test(
          'walks the PID chain and stops when the "next-range" bit is '
          'clear', () async {
        // First bitmap: PIDs 01, 03, 05, 08, and the group+32 bit
        // (= PID 32) is clear → walk stops after this bitmap.
        // 1010_1001 0000_0000 0000_0000 0000_0000 = 0xA9 0x00 0x00 0x00
        final service = await _connected({
          '0100': '41 00 A9 00 00 00>',
        });
        final pids = await service.discoverSupportedPids();
        // 1010_1001 at MSB-first:
        //   bit 0 → PID 1, bit 2 → PID 3, bit 4 → PID 5, bit 7 → PID 8.
        expect(pids, {1, 3, 5, 8});
      });

      test(
          'continues to the next range when the continuation bit is set',
          () async {
        // Range 0x00: continuation bit (PID 32) set → walk to 0x20.
        // Byte 4 = 0x01 sets the LSB only = PID 32 supported.
        // Range 0x20: one PID set, continuation clear.
        final service = await _connected({
          '0100': '41 00 80 00 00 01>', // PIDs 1 + 32
          '0120': '41 20 40 00 00 00>', // PID 34, no continuation
        });
        final pids = await service.discoverSupportedPids();
        expect(pids, containsAll([1, 32, 34]));
      });

      test('bails out on a NO DATA mid-walk', () async {
        final service = await _connected({
          '0100': '41 00 80 00 00 01>', // PIDs 1 + 32 + continuation
          '0120': 'NO DATA>', // adapter gives up
        });
        final pids = await service.discoverSupportedPids();
        expect(pids, {1, 32}); // only what the first range returned
      });
    });

    test('readShortTermFuelTrimPercent parses PID 06 (#813)', () async {
      final service = await _connected({'0106': '41 06 90>'});
      expect(
        await service.readShortTermFuelTrimPercent(),
        closeTo(12.5, 0.1),
      );
    });

    test('readLongTermFuelTrimPercent parses PID 07 (#813)', () async {
      final service = await _connected({'0107': '41 07 70>'});
      // raw 0x70 = 112, (112-128)*100/128 = -12.5 → lean-running engine
      expect(
        await service.readLongTermFuelTrimPercent(),
        closeTo(-12.5, 0.1),
      );
    });

    group('applyFuelTrimCorrection pure math — #813', () {
      test('positive trims enrich (raw × (1 + sum/100))', () {
        expect(
          Obd2Service.applyFuelTrimCorrection(10.0, stft: 6.0, ltft: 4.0),
          closeTo(11.0, 0.001),
        );
      });

      test('negative trims lean (factor < 1)', () {
        expect(
          Obd2Service.applyFuelTrimCorrection(10.0, stft: -5.0, ltft: -5.0),
          closeTo(9.0, 0.001),
        );
      });

      test('zero trims pass through unchanged', () {
        expect(
          Obd2Service.applyFuelTrimCorrection(10.0, stft: 0, ltft: 0),
          closeTo(10.0, 0.001),
        );
      });
    });

    group('estimateFuelRateLPerHourFromMap — #800 speed-density math', () {
      test('typical Peugeot 107 cruise: 2500 RPM, 65 kPa, 30 °C → '
          '~3–5 L/h (plausible cruise consumption)', () {
        final rate = Obd2Service.estimateFuelRateLPerHourFromMap(
          mapKpa: 65,
          iatCelsius: 30,
          rpm: 2500,
          engineDisplacementCc: 1000,
          volumetricEfficiency: 0.85,
        );
        expect(rate, isNotNull);
        expect(rate, greaterThan(2.5));
        expect(rate, lessThan(6.0));
      });

      test('returns null when any input is non-positive', () {
        expect(
          Obd2Service.estimateFuelRateLPerHourFromMap(
            mapKpa: 0, // can't have 0 kPa physically
            iatCelsius: 25,
            rpm: 800,
            engineDisplacementCc: 1000,
            volumetricEfficiency: 0.85,
          ),
          isNull,
        );
        expect(
          Obd2Service.estimateFuelRateLPerHourFromMap(
            mapKpa: 40,
            iatCelsius: -273.15, // 0 K — breaks ideal gas law
            rpm: 800,
            engineDisplacementCc: 1000,
            volumetricEfficiency: 0.85,
          ),
          isNull,
        );
        expect(
          Obd2Service.estimateFuelRateLPerHourFromMap(
            mapKpa: 40,
            iatCelsius: 25,
            rpm: 0, // engine off
            engineDisplacementCc: 1000,
            volumetricEfficiency: 0.85,
          ),
          isNull,
        );
      });

      test('scales linearly with displacement (2.0 L burns 2× the fuel '
          'of a 1.0 L at the same operating point)', () {
        final small = Obd2Service.estimateFuelRateLPerHourFromMap(
          mapKpa: 50,
          iatCelsius: 20,
          rpm: 2000,
          engineDisplacementCc: 1000,
          volumetricEfficiency: 0.85,
        )!;
        final big = Obd2Service.estimateFuelRateLPerHourFromMap(
          mapKpa: 50,
          iatCelsius: 20,
          rpm: 2000,
          engineDisplacementCc: 2000,
          volumetricEfficiency: 0.85,
        )!;
        expect(big / small, closeTo(2.0, 0.01));
      });

      test('matches the stoichiometric MAF path on the same underlying '
          'air-mass flow — formulas agree when given equivalent inputs', () {
        // Hand-compute the air mass flow for known inputs, then verify
        // both the speed-density method and the MAF-based formula
        // agree on the resulting fuel rate.
        const mapKpa = 100.0;
        const iatCelsius = 25.0;
        const rpm = 3000.0;
        const displacementCc = 1000;
        const ve = 0.85;
        const r = 287.0;
        const iatK = iatCelsius + 273.15;
        const displacementM3 = displacementCc / 1_000_000.0;
        const airKgPerS = (mapKpa * 1000 * displacementM3 * (rpm / 120) * ve) /
            (r * iatK);
        const airGPerS = airKgPerS * 1000;
        const expectedFromMaf = airGPerS * 3600 / (14.7 * 740);
        final fromMap = Obd2Service.estimateFuelRateLPerHourFromMap(
          mapKpa: mapKpa,
          iatCelsius: iatCelsius,
          rpm: rpm,
          engineDisplacementCc: displacementCc,
          volumetricEfficiency: ve,
        )!;
        expect(fromMap, closeTo(expectedFromMaf, 0.001));
      });
    });

    test('readMafGramsPerSecond parses PID 10', () async {
      final service = await _connected({'0110': '41 10 04 00>'});
      expect(await service.readMafGramsPerSecond(), closeTo(10.24, 0.01));
    });

    test('readFuelLevelPercent parses PID 2F', () async {
      final service = await _connected({'012F': '41 2F 80>'});
      expect(await service.readFuelLevelPercent(), closeTo(50.2, 0.1));
    });

    test('every new reader returns null when the transport is disconnected',
        () async {
      final service = await _connected({});
      await service.disconnect();
      expect(await service.readEngineLoad(), isNull);
      expect(await service.readThrottlePercent(), isNull);
      expect(await service.readFuelRateLPerHour(), isNull);
      expect(await service.readMafGramsPerSecond(), isNull);
      expect(await service.readFuelLevelPercent(), isNull);
    });
  });

  group('Obd2Service', () {
    test('connect initializes ELM327 adapter', () async {
      final transport = FakeObd2Transport({
        'ATZ': 'ELM327 v1.5>',
        'ATE0': 'OK>',
        'ATL0': 'OK>',
        'ATH0': 'OK>',
        'ATSP0': 'OK>',
      });
      final service = Obd2Service(transport);

      final connected = await service.connect();

      expect(connected, isTrue);
      expect(service.isConnected, isTrue);
    });

    test(
      'connect with default adapter sends legacy init sequence (#1330)',
      () async {
        // Phase 1 regression: the default profile MUST drive the
        // service's connect path with the legacy hardcoded init list.
        // If [GenericElm327Adapter.initSequence] or the connect loop
        // diverges, this test fails before any production user does.
        // #1401 phase 1 appended a follow-up `ATI` (firmware-version
        // probe) — included in the expected list but does not change
        // the init sequence itself.
        final sent = <String>[];
        final transport = _RecordingTransport(
          {
            'ATZ': 'ELM327 v1.5>',
            'ATE0': 'OK>',
            'ATL0': 'OK>',
            'ATH0': 'OK>',
            'ATSP0': 'OK>',
            'ATI': 'ELM327 v1.5>',
          },
          sent,
        );
        final service = Obd2Service(transport);
        await service.connect();
        expect(sent, ['ATZ', 'ATE0', 'ATL0', 'ATH0', 'ATSP0', 'ATI']);
      },
    );

    test('readOdometerKm returns odometer from PID A6', () async {
      final transport = FakeObd2Transport({
        'ATZ': 'ELM327 v1.5>',
        'ATE0': 'OK>',
        'ATL0': 'OK>',
        'ATH0': 'OK>',
        'ATSP0': 'OK>',
        '01A6': '41 A6 00 12 D6 87>',
      });
      final service = Obd2Service(transport);
      await service.connect();

      final km = await service.readOdometerKm();

      expect(km, closeTo(123456.7, 0.1));
    });

    test('readOdometerKm falls back to PID 31 when A6 not supported',
        () async {
      final transport = FakeObd2Transport({
        'ATZ': 'ELM327 v1.5>',
        'ATE0': 'OK>',
        'ATL0': 'OK>',
        'ATH0': 'OK>',
        'ATSP0': 'OK>',
        '01A6': 'NO DATA>',
        '0131': '41 31 4E 20>',
      });
      final service = Obd2Service(transport);
      await service.connect();

      final km = await service.readOdometerKm();

      expect(km, 20000.0);
    });

    test('readOdometerKm returns null when not connected', () async {
      final transport = FakeObd2Transport();
      final service = Obd2Service(transport);

      final km = await service.readOdometerKm();

      expect(km, isNull);
    });

    test('readSpeedKmh returns current speed', () async {
      final transport = FakeObd2Transport({
        'ATZ': 'ELM327 v1.5>',
        'ATE0': 'OK>',
        'ATL0': 'OK>',
        'ATH0': 'OK>',
        'ATSP0': 'OK>',
        '010D': '41 0D 50>',
      });
      final service = Obd2Service(transport);
      await service.connect();

      final speed = await service.readSpeedKmh();

      expect(speed, 80);
    });

    test('readRpm returns engine RPM', () async {
      final transport = FakeObd2Transport({
        'ATZ': 'ELM327 v1.5>',
        'ATE0': 'OK>',
        'ATL0': 'OK>',
        'ATH0': 'OK>',
        'ATSP0': 'OK>',
        '010C': '41 0C 0F A0>',
      });
      final service = Obd2Service(transport);
      await service.connect();

      final rpm = await service.readRpm();

      expect(rpm, closeTo(1000, 0.5));
    });

    test('disconnect works', () async {
      final transport = FakeObd2Transport({
        'ATZ': 'OK>',
        'ATE0': 'OK>',
        'ATL0': 'OK>',
        'ATH0': 'OK>',
        'ATSP0': 'OK>',
      });
      final service = Obd2Service(transport);
      await service.connect();
      expect(service.isConnected, isTrue);

      await service.disconnect();
      expect(service.isConnected, isFalse);
    });
  });

  group('Obd2Service ReferenceVehicle catalog consumer (#950 phase 2)', () {
    // PSA UDS-style fixture: PID A6 missing, PID 31 missing, but the
    // PSA mfg odometer command 22D101 returns a 2-byte km value. This
    // is the in-catalog Peugeot 208 path the user runs today.
    const peugeot208 = ReferenceVehicle(
      make: 'Peugeot',
      model: '208',
      generation: 'II (2019-)',
      yearStart: 2019,
      displacementCc: 1199,
      fuelType: 'petrol',
      transmission: 'manual',
      odometerPidStrategy: 'psaUds',
    );

    // VW Golf VIII — 1498 cc, vwUds. The VW odometer command is
    // 222203 returning a 3-byte km value.
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
    );

    // Fictional vehicle the catalog does not cover. Phase 2 callers
    // are expected to pass `null` when the lookup misses; the service
    // then falls back to the pre-#950 generic behaviour.
    const unknownStrategy = ReferenceVehicle(
      make: 'Acme',
      model: 'XYZ',
      generation: 'I',
      yearStart: 2020,
      displacementCc: 1500,
      fuelType: 'petrol',
      transmission: 'manual',
      odometerPidStrategy: 'unknown',
    );

    test(
        'readOdometerKm with Peugeot 208 ReferenceVehicle (psaUds) reads '
        'the PSA mfg odometer command — preserves pre-#950 behaviour',
        () async {
      // VIN-free fixture: only the PSA-specific 22D101 command answers,
      // proving the service dispatched on `odometerPidStrategy` rather
      // than walking the brand catalog blindly.
      final transport = FakeObd2Transport({
        ..._initResponses,
        '01A6': 'NO DATA>',
        '0131': 'NO DATA>',
        // 0xD1 0x01 prefix + 2 bytes (0x4E 0x20) → 20000 km.
        '22D101': '62 D1 01 4E 20>',
      });
      final service = Obd2Service(transport);
      await service.connect();

      final km = await service.readOdometerKm(referenceVehicle: peugeot208);
      expect(km, 20000.0);
    });

    test(
        'readFuelRateLPerHour without VehicleProfile uses ReferenceVehicle '
        'displacement + VE in the speed-density branch (Peugeot 208: 1199 cc, '
        '0.85 VE)', () async {
      // Speed-density-only fixture (no 5E, no MAF, no trims).
      final transport = FakeObd2Transport({
        ..._initResponses,
        '015E': 'NO DATA>',
        '0110': 'NO DATA>',
        '010B': '41 0B 41>', // MAP raw 0x41 = 65 kPa
        '010F': '41 0F 46>', // IAT raw 0x46 → 30 °C
        '010C': '41 0C 27 10>', // RPM 2500
        '0106': 'NO DATA>',
        '0107': 'NO DATA>',
      });
      final service = Obd2Service(transport);
      await service.connect();

      final rate = await service.readFuelRateLPerHour(
        referenceVehicle: peugeot208,
      );
      final expected = Obd2Service.estimateFuelRateLPerHourFromMap(
        mapKpa: 65,
        iatCelsius: 30,
        rpm: 2500,
        engineDisplacementCc: 1199,
        volumetricEfficiency: 0.85,
      );
      expect(rate, isNotNull);
      expect(expected, isNotNull);
      expect(rate, closeTo(expected!, 1e-3));
    });

    test(
        'readOdometerKm with VW Golf ReferenceVehicle (vwUds) reads the VW '
        'mfg odometer command (222203 → 3-byte km)', () async {
      final transport = FakeObd2Transport({
        ..._initResponses,
        '01A6': 'NO DATA>',
        '0131': 'NO DATA>',
        // 0x22 0x03 prefix + 3 bytes → 0x01 0xE2 0x40 = 123456 km.
        '222203': '62 22 03 01 E2 40>',
      });
      final service = Obd2Service(transport);
      await service.connect();

      final km = await service.readOdometerKm(referenceVehicle: vwGolf);
      expect(km, 123456.0);
    });

    test(
        'readFuelRateLPerHour with VW Golf ReferenceVehicle uses 1498 cc + '
        '0.87 VE (catalog values, not 1000 cc / 0.85 default)', () async {
      final transport = FakeObd2Transport({
        ..._initResponses,
        '015E': 'NO DATA>',
        '0110': 'NO DATA>',
        '010B': '41 0B 41>',
        '010F': '41 0F 46>',
        '010C': '41 0C 27 10>',
        '0106': 'NO DATA>',
        '0107': 'NO DATA>',
      });
      final service = Obd2Service(transport);
      await service.connect();

      final rate = await service.readFuelRateLPerHour(
        referenceVehicle: vwGolf,
      );
      final expected = Obd2Service.estimateFuelRateLPerHourFromMap(
        mapKpa: 65,
        iatCelsius: 30,
        rpm: 2500,
        engineDisplacementCc: 1498,
        volumetricEfficiency: 0.87,
      );
      expect(rate, isNotNull);
      expect(expected, isNotNull);
      expect(rate, closeTo(expected!, 1e-3));

      // Sanity: 1498 cc / 0.87 VE must produce a clearly different
      // rate from the 1000 cc / 0.85 generic default.
      final defaultRate = Obd2Service.estimateFuelRateLPerHourFromMap(
        mapKpa: 65,
        iatCelsius: 30,
        rpm: 2500,
        engineDisplacementCc: 1000,
        volumetricEfficiency: 0.85,
      )!;
      expect((rate! - defaultRate).abs(), greaterThan(1e-2));
    });

    test(
        'readOdometerKm with unknown-strategy ReferenceVehicle returns null '
        'gracefully when standard PIDs miss — no mfg fallback attempted',
        () async {
      // No PSA / VW / BMW / Renault commands are mocked. If the
      // service tried any of them, FakeObd2Transport throws. The
      // strategy switch must short-circuit to null after PID 31.
      final transport = FakeObd2Transport({
        ..._initResponses,
        '01A6': 'NO DATA>',
        '0131': 'NO DATA>',
      });
      final service = Obd2Service(transport);
      await service.connect();

      final km = await service.readOdometerKm(
        referenceVehicle: unknownStrategy,
      );
      expect(km, isNull);
    });

    test(
        'readFuelRateLPerHour with unknown-make ReferenceVehicle still uses '
        'its 1500 cc displacement (data-driven default beats the legacy '
        '1000 cc constant)', () async {
      final transport = FakeObd2Transport({
        ..._initResponses,
        '015E': 'NO DATA>',
        '0110': 'NO DATA>',
        '010B': '41 0B 41>',
        '010F': '41 0F 46>',
        '010C': '41 0C 27 10>',
        '0106': 'NO DATA>',
        '0107': 'NO DATA>',
      });
      final service = Obd2Service(transport);
      await service.connect();

      final rate = await service.readFuelRateLPerHour(
        referenceVehicle: unknownStrategy,
      );
      final expected = Obd2Service.estimateFuelRateLPerHourFromMap(
        mapKpa: 65,
        iatCelsius: 30,
        rpm: 2500,
        engineDisplacementCc: 1500,
        volumetricEfficiency: 0.85,
      );
      expect(rate, isNotNull);
      expect(expected, isNotNull);
      expect(rate, closeTo(expected!, 1e-3));
    });

    test(
        'VehicleProfile still wins over ReferenceVehicle when both supplied '
        '— the user can override catalog defaults', () async {
      final transport = FakeObd2Transport({
        ..._initResponses,
        '015E': 'NO DATA>',
        '0110': 'NO DATA>',
        '010B': '41 0B 41>',
        '010F': '41 0F 46>',
        '010C': '41 0C 27 10>',
        '0106': 'NO DATA>',
        '0107': 'NO DATA>',
      });
      final service = Obd2Service(transport);
      await service.connect();

      const profile = VehicleProfile(
        id: 'override',
        name: 'tuned',
        engineDisplacementCc: 1800,
        volumetricEfficiency: 0.92,
      );
      final rate = await service.readFuelRateLPerHour(
        vehicle: profile,
        referenceVehicle: vwGolf,
      );
      final expected = Obd2Service.estimateFuelRateLPerHourFromMap(
        mapKpa: 65,
        iatCelsius: 30,
        rpm: 2500,
        engineDisplacementCc: 1800,
        volumetricEfficiency: 0.92,
      );
      expect(rate, isNotNull);
      expect(expected, isNotNull);
      expect(rate, closeTo(expected!, 1e-3));
    });

    test(
        'readOdometerKm with no ReferenceVehicle still walks the VIN→brand '
        'fallback (pre-#950 behaviour preserved when callers do not opt in)',
        () async {
      // Same fixture as the existing "PID A6 returns odometer" test —
      // proves we did not break call sites that pass nothing.
      final transport = FakeObd2Transport({
        ..._initResponses,
        '01A6': '41 A6 00 12 D6 87>',
      });
      final service = Obd2Service(transport);
      await service.connect();

      final km = await service.readOdometerKm();
      expect(km, closeTo(123456.7, 0.1));
    });
  });

  group('readFuelRateLPerHour breadcrumb + sanity bounds (#1395)', () {
    test(
        'PID 5E read pushes a 5E branch breadcrumb with the directRate '
        'AND vehicle constants', () async {
      final collector = Obd2BreadcrumbCollector();
      final service = await _connected({
        // 0x00 0x50 = 80 → 80 × 0.05 = 4.0 L/h.
        '015E': '41 5E 00 50>',
      });
      service.breadcrumbCollector = collector;

      await service.readFuelRateLPerHour();

      expect(collector.entries, hasLength(1));
      final crumb = collector.entries.first;
      expect(crumb.branch, equals(Obd2BranchTag.pid5E));
      expect(crumb.fuelRateLPerHour, closeTo(4.0, 0.01));
      expect(crumb.pid5ELPerHour, closeTo(4.0, 0.01));
      expect(crumb.afr, closeTo(14.7, 0.01));
      expect(crumb.fuelDensityGPerL, closeTo(740, 0.5));
    });

    test(
        'sanity-bound A: PID 5E < 0.3 L/h at RPM > 1500 records '
        'suspicious-low flag — value is NOT dropped', () async {
      final collector = Obd2BreadcrumbCollector();
      final service = await _connected({
        // 0x00 0x04 = 4 × 0.05 = 0.2 L/h, which trips the < 0.3 guard.
        '015E': '41 5E 00 04>',
        // RPM = ((A*256)+B)/4. 0x22 0x00 → 8704/4 = 2176, well above
        // the 1500 threshold.
        '010C': '41 0C 22 00>',
      });
      service.breadcrumbCollector = collector;

      final rate = await service.readFuelRateLPerHour();

      // The 0.2 L/h value is still surfaced — the trip integrator
      // uses it; the suspect bit is a per-trip rollup, not a per-tick
      // rejection.
      expect(rate, closeTo(0.2, 0.01));
      expect(collector.entries, hasLength(1));
      expect(
        collector.entries.first.flag,
        equals(Obd2BreadcrumbCollector.flagSuspiciousLow),
      );
      expect(collector.suspiciousSampleCount, equals(1));
    });

    test(
        'sanity-bound A: PID 5E < 0.3 L/h at RPM <= 1500 does NOT '
        'flag — idle ECU is allowed to report 0', () async {
      final collector = Obd2BreadcrumbCollector();
      final service = await _connected({
        '015E': '41 5E 00 04>', // 0.2 L/h
        '010C': '41 0C 0C 80>', // RPM 800 (idle)
      });
      service.breadcrumbCollector = collector;

      await service.readFuelRateLPerHour();

      expect(collector.entries.first.flag, isNull);
      expect(collector.suspiciousSampleCount, equals(0));
    });

    test(
        'sanity-bound B: PID 5E vs MAF divergence > 50 % records '
        '5e-vs-maf-divergent flag', () async {
      final collector = Obd2BreadcrumbCollector();
      final service = await _connected({
        // PID 5E: 0x01 0x40 = 320 × 0.05 = 16.0 L/h.
        '015E': '41 5E 01 40>',
        // MAF 10.24 g/s → derived = 10.24 × 3600 / (14.7 × 745)
        // ≈ 3.367 L/h. |16-3.37|/3.37 ≈ 3.7 → divergent.
        '0110': '41 10 04 00>',
        // RPM 800 — keeps us above the suspicious-low threshold AND
        // doesn't trip the < 0.3 guard since 16 L/h is high.
        '010C': '41 0C 0C 80>',
      });
      service.breadcrumbCollector = collector;

      await service.readFuelRateLPerHour();

      // The breadcrumb's `flag` is set to 5e-vs-maf-divergent because
      // the cross-check ran AFTER the initial record.
      expect(collector.entries, hasLength(1));
      expect(
        collector.entries.first.flag,
        equals(Obd2BreadcrumbCollector.flag5eVsMafDivergent),
      );
      expect(collector.suspiciousSampleCount, equals(1));
    });

    test(
        'sanity-bound B: PID 5E vs MAF within 50 % does NOT flag — '
        'normal sensor agreement', () async {
      final collector = Obd2BreadcrumbCollector();
      final service = await _connected({
        // PID 5E: 0x00 0x44 = 68 × 0.05 = 3.4 L/h.
        '015E': '41 5E 00 44>',
        // MAF 10.24 g/s → derived ≈ 3.367 L/h. |3.4 - 3.367|/3.367
        // ≈ 0.01 — well inside the 50 % band.
        '0110': '41 10 04 00>',
        '010C': '41 0C 0C 80>',
      });
      service.breadcrumbCollector = collector;

      await service.readFuelRateLPerHour();

      expect(collector.entries, hasLength(1));
      expect(collector.entries.first.flag, isNull);
      expect(collector.suspiciousSampleCount, equals(0));
    });

    test(
        'MAF branch records a MAF breadcrumb when PID 5E is not '
        'available', () async {
      final collector = Obd2BreadcrumbCollector();
      final service = await _connected({
        '015E': 'NO DATA>',
        '0110': '41 10 04 00>', // MAF 10.24 g/s
      });
      service.breadcrumbCollector = collector;

      await service.readFuelRateLPerHour();

      expect(collector.entries, hasLength(1));
      expect(collector.entries.first.branch, equals(Obd2BranchTag.maf));
      expect(
        collector.entries.first.mafGramsPerSecond,
        closeTo(10.24, 0.01),
      );
    });

    test(
        'when no breadcrumb collector is wired, the service stays '
        'fully backwards-compatible', () async {
      // No collector — exercises the null-safe `?.` paths in
      // readFuelRateLPerHour. The trip recorder must integrate the
      // returned value as before.
      // 0x01 0x80 = 384 × 0.05 = 19.2 L/h.
      final service = await _connected({'015E': '41 5E 01 80>'});

      final rate = await service.readFuelRateLPerHour();
      expect(rate, closeTo(19.2, 0.1));
    });
  });
}
