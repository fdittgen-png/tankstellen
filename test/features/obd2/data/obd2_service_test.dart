// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/protocol/adapter_capability.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_transport.dart';
import 'package:tankstellen/features/vehicle/domain/entities/reference_vehicle.dart';

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

    group('supported-PID bitmap + runtime probation — #811 phase 2 / #3532',
        () {
      // #4315 — these drove probation through the deleted pull reader's
      // 5E / MAF reads. The typed MAF read feeds the same
      // `noteMode01Reply` funnel, so the probation contract is pinned on it.
      test(
          'Peugeot 107 case (#3532 optimistic): the bitmap no longer '
          'rejects MAF — it answers NO DATA, and probation parks it after '
          '3 misses', () async {
        final service = await _connected({
          '0100': '41 00 00 32 00 00>', // PIDs 0B, 0C, 0F supported
          '0110': 'NO DATA>',
        });
        await service.discoverSupportedPids();
        expect(service.isPidSupported(0x10), isTrue,
            reason: '#3532 — the bitmap must not reject up-front');
        expect(service.isPidSupported(0x0B), isTrue);

        for (var i = 0; i < 3; i++) {
          expect(await service.readMafGramsPerSecond(), isNull);
        }
        expect(service.isPidSupported(0x10), isFalse,
            reason: '3× real NO DATA → probation parks MAF (#3532)');
        expect(service.isPidSupported(0x0B), isTrue,
            reason: 'probation parks only the PID that missed');
      });

      test(
          'when the cache is not populated, legacy blind-query behaviour — '
          'every PID is allowed', () async {
        final service = await _connected({'0110': 'NO DATA>'});
        expect(service.isPidSupported(0x5E), isTrue);
        expect(service.isPidSupported(0x10), isTrue);
        expect(await service.readMafGramsPerSecond(), isNull);
      });

      test(
          'probation-clear on reconnect — a PID parked by 3× NO DATA is '
          'retried in the next session (#3532)', () async {
        final service = await _connected({
          '0100': '41 00 80 00 00 00>', // only PID 01
          '0110': 'NO DATA>',
        });
        await service.discoverSupportedPids();
        for (var i = 0; i < 3; i++) {
          await service.readMafGramsPerSecond();
        }
        expect(service.isPidSupported(0x10), isFalse,
            reason: 'sanity: probation parked MAF this session');

        await service.disconnect();
        await service.connect(); // fresh session
        expect(service.isPidSupported(0x10), isTrue,
            reason: 'probation should clear on connect so a new car / '
                'new adapter firmware gets a fresh chance');
      });

      test(
          'a bitmap-absent PID that answers is read and stays supported '
          '(#3532)', () async {
        final service = await _connected({
          '0100': '41 00 80 00 00 00>', // only PID 01 — MAF not claimed
          '0110': '41 10 04 00>', // MAF = 10.24 g/s
        });
        await service.discoverSupportedPids();
        expect(service.isPidSupported(0x10), isTrue,
            reason: '#3532 — optimistic until 3× real NO DATA');
        expect(await service.readMafGramsPerSecond(), closeTo(10.24, 0.01));
        expect(service.isPidSupported(0x10), isTrue);
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
      expect(await service.readMafGramsPerSecond(), isNull);
      expect(await service.readFuelLevelPercent(), isNull);
      expect(await service.readVin(), isNull);
      expect(await service.readFuelType(), isNull);
    });
  });

  group('Obd2Service.readVin (#1399)', () {
    test('parses Mode 09 PID 02 multi-frame response into 17-char VIN',
        () async {
      // Build a realistic Mode 09 PID 02 multi-frame response. Same
      // shape exercised by [Elm327Parsers.parseVin] tests — frame
      // headers `49 02 NN` are stripped + 17 ASCII bytes remain.
      const vin = 'WVWZZZ1KZ8W123456';
      final body = vin.codeUnits
          .map((c) => c.toRadixString(16).padLeft(2, '0').toUpperCase())
          .join(' ');
      final response =
          '49 02 01 $body 49 02 02 49 02 03 49 02 04 49 02 05>';
      final service = await _connected({'0902': response});
      expect(await service.readVin(), vin);
    });

    test('NO DATA returns null', () async {
      final service = await _connected({'0902': 'NO DATA>'});
      expect(await service.readVin(), isNull);
    });
  });

  group('Obd2Service.readFuelType (#1399 PID 0x51)', () {
    test('petrol code 0x01 maps to "petrol"', () async {
      final service = await _connected({'0151': '41 51 01>'});
      expect(await service.readFuelType(), 'petrol');
    });

    test('diesel code 0x04 maps to "diesel"', () async {
      final service = await _connected({'0151': '41 51 04>'});
      expect(await service.readFuelType(), 'diesel');
    });

    test('unsupported (NO DATA) returns null', () async {
      final service = await _connected({'0151': 'NO DATA>'});
      expect(await service.readFuelType(), isNull);
    });

    test('reserved code returns null', () async {
      final service = await _connected({'0151': '41 51 FF>'});
      expect(await service.readFuelType(), isNull);
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
            'ATAT1': 'OK>',
            'ATI': 'ELM327 v1.5>',
          },
          sent,
        );
        final service = Obd2Service(transport);
        await service.connect();
        expect(sent, ['ATZ', 'ATE0', 'ATL0', 'ATH0', 'ATSP0', 'ATAT1', 'ATI']);
      },
    );

    // #1614 — runtime feature-probe that downgrades clones whose ATI
    // firmware string lies about their tier. #2261 concern 6 — the probe
    // is now DEFERRED off the connect critical path: connect() leaves the
    // claimed tier in place and ensureCapabilityReconciled() (run lazily
    // after the first samples) does the downgrade.
    group('runtime capability probe (#1614 / deferred #2261 concern 6)', () {
      test(
          'connect() does NOT send 0902 — the probe is off the critical '
          'path (#2261 concern 6)', () async {
        final sent = <String>[];
        final transport = _RecordingTransport(
          {
            'ATZ': 'ELM327 v2.2>',
            'ATE0': 'OK>',
            'ATL0': 'OK>',
            'ATH0': 'OK>',
            'ATSP0': 'OK>',
            'ATI': 'ELM327 v2.2>',
            '0902': 'CAN ERROR>',
          },
          sent,
        );
        final service = Obd2Service(transport);
        await service.connect();

        expect(sent, isNot(contains('0902')),
            reason: 'the multi-frame probe must not delay connect');
        expect(service.capability, Obd2AdapterCapability.oemPidsCapable,
            reason: 'connect leaves the firmware-claimed tier until the '
                'deferred probe reconciles it');
        expect(service.capabilityNeedsReconcile, isTrue);
      });

      test(
          'a lying clone — ATI reports v2.2 but the deferred multi-frame '
          'probe fails — is downgraded below oemPidsCapable', () async {
        final transport = FakeObd2Transport({
          'ATZ': 'ELM327 v2.2>',
          'ATE0': 'OK>',
          'ATL0': 'OK>',
          'ATH0': 'OK>',
          'ATSP0': 'OK>',
          'ATI': 'ELM327 v2.2>',
          // The clone cannot route a multi-frame ISO 15765 request.
          '0902': 'CAN ERROR>',
        });
        final service = Obd2Service(transport);
        await service.connect();
        await service.ensureCapabilityReconciled();

        expect(service.capability, Obd2AdapterCapability.standardOnly);
        expect(
          service.capability.index <
              Obd2AdapterCapability.oemPidsCapable.index,
          isTrue,
        );
        expect(service.capabilityNeedsReconcile, isFalse);
      });

      test(
          'a genuine v2.2 adapter — ATI reports v2.2 and the deferred probe '
          'returns a valid multi-frame VIN reply — keeps oemPidsCapable',
          () async {
        final transport = FakeObd2Transport({
          'ATZ': 'ELM327 v2.2>',
          'ATE0': 'OK>',
          'ATL0': 'OK>',
          'ATH0': 'OK>',
          'ATSP0': 'OK>',
          'ATI': 'ELM327 v2.2>',
          '0902': '014\n0: 49 02 01 57 50 30\n1: 5A 5A 5A 39 38 5A>',
        });
        final service = Obd2Service(transport);
        await service.connect();
        await service.ensureCapabilityReconciled();

        expect(service.capability, Obd2AdapterCapability.oemPidsCapable);
      });

      test(
          'ensureCapabilityReconciled is a one-shot — a second call sends '
          'no further 0902', () async {
        final sent = <String>[];
        final transport = _RecordingTransport(
          {
            'ATZ': 'ELM327 v2.2>',
            'ATE0': 'OK>',
            'ATL0': 'OK>',
            'ATH0': 'OK>',
            'ATSP0': 'OK>',
            'ATI': 'ELM327 v2.2>',
            '0902': 'CAN ERROR>',
          },
          sent,
        );
        final service = Obd2Service(transport);
        await service.connect();
        await service.ensureCapabilityReconciled();
        await service.ensureCapabilityReconciled();

        expect(sent.where((c) => c == '0902').length, 1,
            reason: 'the deferred probe runs at most once per connect');
      });

      test(
          'a standardOnly adapter (ATI v1.5) never probes — no 0902 even '
          'after ensureCapabilityReconciled', () async {
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
        expect(service.capabilityNeedsReconcile, isFalse,
            reason: 'standardOnly has nothing to downgrade — no deferred '
                'probe is armed');
        await service.ensureCapabilityReconciled();

        expect(service.capability, Obd2AdapterCapability.standardOnly);
        expect(sent, isNot(contains('0902')));
      });
    });

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
    // 222203 returning a 3-byte km value. 1.5 TSI turbo DI engine —
    // #1422 phase 1 helper derives 0.93 for this combo.
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
}
