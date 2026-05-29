// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_registry.dart';
import 'package:tankstellen/features/consumption/data/obd2/bluetooth_facade.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/consumption/data/obd2/broken_map_belief.dart';
import 'package:tankstellen/features/consumption/data/obd2/broken_map_detector.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm_byte_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connection_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_permissions.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd_adapter_blocklist.dart';
import 'package:tankstellen/features/consumption/data/obd2/oem_pid_table.dart';
import 'package:tankstellen/features/vehicle/data/vin_adapter_pair_auto_populator.dart';
import 'package:tankstellen/features/vehicle/data/vin_decoder.dart';
import 'package:tankstellen/features/vehicle/domain/entities/reference_vehicle.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';

/// Integration tests for [VinAdapterPairAutoPopulator] (#1399).
///
/// Cases:
///   1. Happy path with vPIC + PID 0x51 — fills empty fields, PID wins.
///   2. Offline-only path (vinOnlineDecode=false) — make/year only.
///   3. ECU returns NO DATA for VIN — aborted outcome, no profile change.
///   4. Connect fails — aborted outcome, no profile change.
///   5. PID 0x51 unsupported — fuel type comes from offline/vPIC fallback.
///   6. Existing user-entered field is preserved; conflictSummary is set.
class _MockDio extends Mock implements Dio {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    errorLogger.resetForTest();
    errorLogger.testRecorderOverride = _NoOpRecorder();
  });

  tearDown(() {
    errorLogger.resetForTest();
  });

  // Build a connected Obd2Service against a deterministic transport.
  Obd2Service buildConnectedService(Map<String, String> responses) {
    final initResponses = {
      'ATZ': 'ELM327 v1.5>',
      'ATE0': 'OK>',
      'ATL0': 'OK>',
      'ATH0': 'OK>',
      'ATSP0': 'OK>',
      'ATI': 'ELM327 v1.5>',
    };
    final transport = FakeObd2Transport({...initResponses, ...responses});
    final service = Obd2Service(transport);
    return service;
  }

  // Build a vPIC-mocked decoder. Returns a "PEUGEOT 107 2008 1.0L" body
  // when allowOnlineLookup is true; ignored otherwise.
  VinDecoder buildDecoder({required bool online}) {
    final dio = _MockDio();
    when(() => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: const {
            'Results': [
              {'Variable': 'Make', 'Value': 'PEUGEOT'},
              {'Variable': 'Model', 'Value': '107'},
              {'Variable': 'Model Year', 'Value': '2008'},
              {'Variable': 'Displacement (L)', 'Value': '1.0'},
              {'Variable': 'Fuel Type - Primary', 'Value': 'Gasoline'},
            ],
          },
        ));
    return VinDecoder(dio: dio, allowOnlineLookup: online);
  }

  VehicleProfile baseProfile() {
    return const VehicleProfile(id: 'v1', name: 'Test Car');
  }

  // VIN response captured from the parser-test fixture: 5-frame Mode 09
  // PID 02 with header `49 02 NN` per frame, 17-byte VIN body.
  String buildValidVinResponse(String vin) {
    final body = vin.codeUnits
        .map((c) => c.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
    return '49 02 01 $body 49 02 02 49 02 03 49 02 04 49 02 05>';
  }

  group('happy path with vPIC + PID 0x51', () {
    test('fills empty fields; PID 0x51 overrides decoded fuel type',
        () async {
      const vin = 'VF36B8HZL8R123456';
      final service = buildConnectedService({
        '0902': buildValidVinResponse(vin),
        // PID 0x51 returns 0x04 (diesel) — should win over vPIC Gasoline.
        '0151': '41 51 04>',
      });
      final connection = _FakeConnection(connectByMacResult: service);
      final populator = VinAdapterPairAutoPopulator(
        connection: connection,
        decoder: buildDecoder(online: true),
      );

      final outcome = await populator.run(
        pairedAdapterMac: 'AA:BB',
        profile: baseProfile(),
      );

      expect(outcome.profile, isNotNull);
      expect(outcome.readVin, isTrue);
      expect(outcome.didDecodeOnline, isTrue);
      expect(outcome.appliedAny, isTrue);
      expect(outcome.profile!.detectedMake, 'PEUGEOT');
      expect(outcome.profile!.detectedYear, 2008);
      expect(outcome.profile!.detectedFuelType, 'diesel'); // PID wins
      expect(outcome.profile!.preferredFuelType, 'diesel');
      expect(outcome.profile!.lastReadVin, vin);
      expect(outcome.conflictSummary, isNull);
    });
  });

  group('offline-only path (vinOnlineDecode=false)', () {
    test('skips vPIC, fills make + year from WMI + position 10', () async {
      const vin = 'VF36B8HZL8R123456';
      final service = buildConnectedService({
        '0902': buildValidVinResponse(vin),
      });
      final connection = _FakeConnection(connectByMacResult: service);
      final populator = VinAdapterPairAutoPopulator(
        connection: connection,
        decoder: buildDecoder(online: false),
      );

      final outcome = await populator.run(
        pairedAdapterMac: 'AA:BB',
        profile: baseProfile(),
      );

      expect(outcome.profile, isNotNull);
      expect(outcome.readVin, isTrue);
      expect(outcome.didDecodeOnline, isFalse);
      expect(outcome.profile!.detectedMake, 'Peugeot');
      // Position 10 of VF36B8HZL8R123456 is '8' → 2008.
      expect(outcome.profile!.detectedYear, 2008);
      // No model / displacement on the offline path.
      expect(outcome.profile!.detectedModel, isNull);
      expect(outcome.profile!.detectedEngineDisplacementCc, isNull);
    });
  });

  group('aborted paths', () {
    test('ECU returns NO DATA for VIN → aborted outcome', () async {
      final service = buildConnectedService({'0902': 'NO DATA>'});
      final connection = _FakeConnection(connectByMacResult: service);
      final populator = VinAdapterPairAutoPopulator(
        connection: connection,
        decoder: buildDecoder(online: false),
      );

      final outcome = await populator.run(
        pairedAdapterMac: 'AA:BB',
        profile: baseProfile(),
      );

      expect(outcome.profile, isNull);
      expect(outcome.readVin, isFalse);
      expect(outcome.appliedAny, isFalse);
    });

    test('connectByMac returns null → aborted outcome', () async {
      final connection = _FakeConnection(connectByMacResult: null);
      final populator = VinAdapterPairAutoPopulator(
        connection: connection,
        decoder: buildDecoder(online: false),
      );

      final outcome = await populator.run(
        pairedAdapterMac: 'AA:BB',
        profile: baseProfile(),
      );

      expect(outcome.profile, isNull);
      expect(outcome.readVin, isFalse);
    });
  });

  group('PID 0x51 unsupported', () {
    test('falls back to decoded fuel type when 0x51 returns NO DATA',
        () async {
      const vin = 'VF36B8HZL8R123456';
      final service = buildConnectedService({
        '0902': buildValidVinResponse(vin),
        '0151': 'NO DATA>',
      });
      final connection = _FakeConnection(connectByMacResult: service);
      final populator = VinAdapterPairAutoPopulator(
        connection: connection,
        decoder: buildDecoder(online: true),
      );

      final outcome = await populator.run(
        pairedAdapterMac: 'AA:BB',
        profile: baseProfile(),
      );

      expect(outcome.profile, isNotNull);
      // vPIC returned Gasoline → normalised to "petrol".
      expect(outcome.profile!.detectedFuelType, 'petrol');
    });
  });

  group('user fields are not silently overwritten', () {
    test('user-entered "Renault" make survives a "PEUGEOT" decode',
        () async {
      const vin = 'VF36B8HZL8R123456';
      final service = buildConnectedService({
        '0902': buildValidVinResponse(vin),
      });
      final connection = _FakeConnection(connectByMacResult: service);
      final populator = VinAdapterPairAutoPopulator(
        connection: connection,
        decoder: buildDecoder(online: true),
      );

      final existing = baseProfile().copyWith(make: 'Renault');
      final outcome = await populator.run(
        pairedAdapterMac: 'AA:BB',
        profile: existing,
      );

      expect(outcome.profile, isNotNull);
      // User value preserved, detected mirror still tracks decoded.
      expect(outcome.profile!.make, 'Renault');
      expect(outcome.profile!.detectedMake, 'PEUGEOT');
      expect(outcome.conflictSummary, isNotNull);
    });
  });

  group('broken-MAP detector wiring (#1423 phase 2)', () {
    test(
        'when a detector is provided, the outcome carries the resulting '
        'belief and a broken-MAP fixture pushes the posterior past the '
        'verifying band',
        () async {
      const vin = 'VF36B8HZL8R123456';
      // Petrol PID 0x51 wins, so the detector picks the petrol branch
      // (vacuum check). Idle MAP at 99 kPa with baro 101 kPa → score
      // clamps to 1.0 → posterior after one Bayesian fold from the
      // default Beta(1, 9) prior: α=8.5, β=4.5, mean ≈ 0.654.
      // Throttle 0x03 → ~1.18 % — clearly closed.
      final service = buildConnectedService({
        '0902': buildValidVinResponse(vin),
        '0151': '41 51 01>', // gasoline → petrol branch
        '0111': '41 11 03>', // tps ≈ 1.18 %
        '010B': '41 0B 63>', // mapIdle = 0x63 = 99 kPa
        '0133': '41 33 65>', // baro = 0x65 = 101 kPa
      });
      final connection = _FakeConnection(connectByMacResult: service);
      final populator = VinAdapterPairAutoPopulator(
        connection: connection,
        decoder: buildDecoder(online: false),
        brokenMapDetector: const BrokenMapDetector(),
      );

      final outcome = await populator.run(
        pairedAdapterMac: 'AA:BB',
        profile: baseProfile(),
      );

      expect(outcome.brokenMapBelief, isNotNull);
      expect(outcome.brokenMapBelief!.observationCount, 1);
      expect(outcome.brokenMapBelief!.alpha, closeTo(8.5, 1e-9));
      expect(outcome.brokenMapBelief!.beta, closeTo(4.5, 1e-9));
      expect(
        outcome.brokenMapBelief!.pointEstimate,
        closeTo(8.5 / 13.0, 1e-9),
      );
      expect(
        outcome.brokenMapBelief!.lastTrigger,
        BrokenMapReason.idleVacuumMissing,
      );
    });

    test(
        'when no detector is provided the outcome.brokenMapBelief is null '
        '(legacy call sites stay green)', () async {
      const vin = 'VF36B8HZL8R123456';
      final service = buildConnectedService({
        '0902': buildValidVinResponse(vin),
      });
      final connection = _FakeConnection(connectByMacResult: service);
      final populator = VinAdapterPairAutoPopulator(
        connection: connection,
        decoder: buildDecoder(online: false),
        // brokenMapDetector intentionally omitted.
      );

      final outcome = await populator.run(
        pairedAdapterMac: 'AA:BB',
        profile: baseProfile(),
      );

      expect(outcome.brokenMapBelief, isNull);
    });
  });

  group('persistent blocklist wiring (#1423 phase 4)', () {
    test(
        'a blocklist hit (recall confidence > 0.7) short-circuits the probe '
        'and surfaces a priorObservation belief', () async {
      const vin = 'VF36B8HZL8R123456';
      final initResponses = {
        'ATZ': 'ELM327 v1.5>',
        'ATE0': 'OK>',
        'ATL0': 'OK>',
        'ATH0': 'OK>',
        'ATSP0': 'OK>',
        'ATI': 'ELM327 v1.5>',
      };
      final transport = FakeObd2Transport({
        ...initResponses,
        '0902': buildValidVinResponse(vin),
      });
      final service = Obd2Service(transport);
      final connection = _FakeConnection(connectByMacResult: service);

      final storage = _FakeSettingsStorage()
        ..data['obdAdapterBroken:ELM327 v1.5'] = 0.85;
      final blocklist = ObdAdapterBlocklist(storage);

      final populator = VinAdapterPairAutoPopulator(
        connection: connection,
        decoder: buildDecoder(online: false),
        brokenMapDetector: const BrokenMapDetector(),
        blocklist: blocklist,
      );

      final outcome = await populator.run(
        pairedAdapterMac: 'AA:BB',
        profile: baseProfile(),
      );

      expect(outcome.brokenMapBelief, isNotNull);
      // Recalled scalar 0.85 → reconstructed Beta(α, β) with
      // pseudoCount = 10: α = 8.5, β = 1.5, mean = 0.85.
      expect(outcome.brokenMapBelief!.pointEstimate, closeTo(0.85, 1e-9));
      expect(outcome.brokenMapBelief!.alpha, closeTo(8.5, 1e-9));
      expect(outcome.brokenMapBelief!.beta, closeTo(1.5, 1e-9));
      expect(outcome.brokenMapBelief!.observationCount, 0,
          reason:
              'observationCount=0 signals "hydrated from a prior session" '
              '— never bumped because no fresh probe ran.');
      expect(outcome.brokenMapBelief!.lastTrigger,
          BrokenMapReason.priorObservation);

      // The probe issues 0111 (TPS), 010B (MAP), 0133 (baro). NONE of
      // these may have been sent — the blocklist hit short-circuited
      // the detector entirely.
      final sent = transport.sentCommands;
      expect(sent.any((c) => c.startsWith('0111')), isFalse,
          reason: 'TPS probe must not run on blocklist hit');
      expect(sent.any((c) => c.startsWith('010B')), isFalse,
          reason: 'MAP probe must not run on blocklist hit');
      expect(sent.any((c) => c.startsWith('0133')), isFalse,
          reason: 'baro probe must not run on blocklist hit');
    });

    test(
        'a blocklist value at-or-below 0.7 does NOT short-circuit — fresh '
        'probe runs and overwrites the prior belief', () async {
      const vin = 'VF36B8HZL8R123456';
      // Healthy MAP fixture from the existing detector tests — vacuum
      // delta 71 → score 0 → confidence stays at 0 after one fold.
      final service = buildConnectedService({
        '0902': buildValidVinResponse(vin),
        '0151': '41 51 01>',
        '0111': '41 11 03>',
        '010B': '41 0B 1E>', // 0x1E = 30 kPa
        '0133': '41 33 65>', // 0x65 = 101 kPa
      });
      final connection = _FakeConnection(connectByMacResult: service);
      final storage = _FakeSettingsStorage()
        ..data['obdAdapterBroken:ELM327 v1.5'] = 0.4;
      final blocklist = ObdAdapterBlocklist(storage);

      final populator = VinAdapterPairAutoPopulator(
        connection: connection,
        decoder: buildDecoder(online: false),
        brokenMapDetector: const BrokenMapDetector(),
        blocklist: blocklist,
      );

      final outcome = await populator.run(
        pairedAdapterMac: 'AA:BB',
        profile: baseProfile(),
      );

      expect(outcome.brokenMapBelief, isNotNull);
      // Probe ran from a fresh prior — score 0 → α=0.5, β=5.5,
      // posterior mean ≈ 0.083 (silent band, no blocklist write).
      expect(outcome.brokenMapBelief!.alpha, closeTo(0.5, 1e-9));
      expect(outcome.brokenMapBelief!.beta, closeTo(5.5, 1e-9));
      expect(outcome.brokenMapBelief!.pointEstimate, lessThan(0.4));
      expect(outcome.brokenMapBelief!.observationCount, 1);
      // Below-threshold probe result must NOT touch the blocklist.
      expect(storage.data['obdAdapterBroken:ELM327 v1.5'], 0.4,
          reason: 'sub-threshold probe result must not overwrite blocklist');
    });

    test(
        'a probe that yields confidence > 0.7 is persisted into the '
        'blocklist for the connected adapter', () async {
      const vin = 'VF36B8HZL8R123456';
      // Broken MAP fixture — vacuum delta 2 kPa → score 1.0 → after
      // one EMA fold from prior 0.85 → confidence ~0.91 (> threshold).
      final storage = _FakeSettingsStorage();
      // Pre-seed a non-blocking entry so the recall doesn't short-
      // circuit, and verify persistence overwrites cleanly.
      final blocklist = ObdAdapterBlocklist(storage);
      // Use an artificially-elevated prior via the detector's own
      // `prior` parameter wouldn't help here — the populator always
      // probes from `const BrokenMapBelief()`. To exercise the
      // > 0.7 persistence branch with a single observation, drive the
      // probe with an extreme broken-MAP fixture that pushes one-shot
      // confidence to α (= 0.4)? That's below 0.7. So instead seed
      // the blocklist below threshold and run the populator twice
      // — but the populator is single-shot. Easiest path: use the
      // detector directly with a strong prior to assert the
      // populator's persistence call site, via a custom detector.
      //
      // Workaround: stub the detector to return a high-confidence
      // belief unconditionally so the populator exercises the
      // persistence branch. The integration of "real probe → strong
      // confidence" is covered by the broken_map_detector tests; we
      // just need to prove the populator wires recordBelief
      // correctly.
      final service = buildConnectedService({
        '0902': buildValidVinResponse(vin),
        '0151': '41 51 01>',
      });
      final connection = _FakeConnection(connectByMacResult: service);

      final populator = VinAdapterPairAutoPopulator(
        connection: connection,
        decoder: buildDecoder(online: false),
        brokenMapDetector: const _StubHighConfidenceDetector(0.92),
        blocklist: blocklist,
      );

      final outcome = await populator.run(
        pairedAdapterMac: 'AA:BB',
        profile: baseProfile(),
      );

      expect(outcome.brokenMapBelief, isNotNull);
      expect(outcome.brokenMapBelief!.pointEstimate, closeTo(0.92, 1e-9));
      // Persisted into the blocklist under the connected adapter's id.
      // The blocklist stores the posterior mean, not the raw α/β.
      expect(storage.data['obdAdapterBroken:ELM327 v1.5'], closeTo(0.92, 1e-9));
    });

    test(
        'no blocklist + no detector → outcome.brokenMapBelief is null '
        '(legacy behaviour preserved)', () async {
      const vin = 'VF36B8HZL8R123456';
      final service = buildConnectedService({
        '0902': buildValidVinResponse(vin),
      });
      final connection = _FakeConnection(connectByMacResult: service);
      final populator = VinAdapterPairAutoPopulator(
        connection: connection,
        decoder: buildDecoder(online: false),
        // Both omitted.
      );

      final outcome = await populator.run(
        pairedAdapterMac: 'AA:BB',
        profile: baseProfile(),
      );

      expect(outcome.brokenMapBelief, isNull);
    });

    test(
        'a blocklist with no entry for this adapter falls through to a '
        'fresh probe', () async {
      const vin = 'VF36B8HZL8R123456';
      final service = buildConnectedService({
        '0902': buildValidVinResponse(vin),
        '0151': '41 51 01>',
        '0111': '41 11 03>',
        '010B': '41 0B 1E>',
        '0133': '41 33 65>',
      });
      final connection = _FakeConnection(connectByMacResult: service);
      final storage = _FakeSettingsStorage();
      final blocklist = ObdAdapterBlocklist(storage);

      final populator = VinAdapterPairAutoPopulator(
        connection: connection,
        decoder: buildDecoder(online: false),
        brokenMapDetector: const BrokenMapDetector(),
        blocklist: blocklist,
      );

      final outcome = await populator.run(
        pairedAdapterMac: 'AA:BB',
        profile: baseProfile(),
      );

      expect(outcome.brokenMapBelief, isNotNull);
      expect(outcome.brokenMapBelief!.observationCount, 1,
          reason: 'fresh probe ran — observationCount bumped from 0 to 1');
      // Healthy MAP → no blocklist write.
      expect(storage.data, isEmpty);
    });
  });
}

/// Detector double for the populator persistence test. The real
/// detector's probe path is exercised in broken_map_detector_test;
/// here we just need to assert the populator's wiring of
/// [ObdAdapterBlocklist.recordBelief]. Returning a fixed high
/// posterior keeps the test deterministic without recreating the
/// full broken-MAP fixture in this file.
class _StubHighConfidenceDetector extends BrokenMapDetector {
  final double pointEstimate;
  const _StubHighConfidenceDetector(this.pointEstimate);

  @override
  Future<BrokenMapBelief> probe(
    Obd2RawCommandPort port, {
    required bool isDiesel,
    required BrokenMapBelief prior,
    required DateTime now,
    ReferenceVehicle? vehicle,
    Future<bool> Function()? awaitUserRev,
  }) async {
    // Reconstruct a Beta posterior with pseudoCount=10 around the
    // requested mean — same shape the production recall path uses.
    const pseudoCount = 10.0;
    return BrokenMapBelief(
      alpha: pointEstimate * pseudoCount,
      beta: (1.0 - pointEstimate) * pseudoCount,
      observationCount: 1,
      lastUpdate: now,
      lastTrigger: BrokenMapReason.idleVacuumMissing,
    );
  }
}

class _FakeSettingsStorage implements SettingsStorage {
  final Map<String, dynamic> data = {};

  @override
  dynamic getSetting(String key) => data[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    data[key] = value;
  }

  @override
  bool get isSetupComplete => false;
  @override
  bool get isSetupSkipped => false;
  @override
  Future<void> skipSetup() async {}
  @override
  Future<void> resetSetupSkip() async {}
}

class _FakeConnection extends Obd2ConnectionService {
  _FakeConnection({this.connectByMacResult})
      : super(
          registry: Obd2AdapterRegistry.defaults(),
          permissions: _AlwaysGrantedPermissions(),
          bluetooth: _UnusedBluetoothFacade(),
        );

  final Obd2Service? connectByMacResult;

  @override
  Future<Obd2Service?> connectByMac(
    String mac, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final s = connectByMacResult;
    if (s == null) return null;
    // The populator expects a connected service so it can issue PID
    // commands. Wire connect through here.
    await s.connect();
    return s;
  }
}

class _AlwaysGrantedPermissions implements Obd2Permissions {
  @override
  Future<Obd2PermissionState> current() async => Obd2PermissionState.granted;

  @override
  Future<Obd2PermissionState> request() async => Obd2PermissionState.granted;
}

class _UnusedBluetoothFacade implements BluetoothFacade {
  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout = const Duration(seconds: 8),
  }) async* {}

  @override
  Future<void> stopScan() async {}

  @override
  ElmByteChannel channelFor(String deviceId, Obd2AdapterProfile profile) {
    throw UnimplementedError();
  }

  @override
  ElmByteChannel channelForDirect(
    String mac, {
    Duration connectTimeout = const Duration(seconds: 4),
  }) {
    throw UnimplementedError();
  }
}

class _NoOpRecorder implements TraceRecorder {
  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
