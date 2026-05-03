import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_registry.dart';
import 'package:tankstellen/features/consumption/data/obd2/bluetooth_facade.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm_byte_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connection_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_permissions.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/vehicle/data/vin_adapter_pair_auto_populator.dart';
import 'package:tankstellen/features/vehicle/data/vin_decoder.dart';
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
