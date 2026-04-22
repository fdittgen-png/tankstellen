import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/vehicle/data/vin_decoder.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vin_data.dart';

class _MockDio extends Mock implements Dio {}

/// Tests for [VinDecoder] (#812 phase 1).
///
/// vPIC calls are stubbed via mocktail so the suite is fully offline.
/// Covers:
///   - input validation (length, illegal letters)
///   - the vPIC happy path with a recorded Peugeot 107 response
///   - WMI offline fallback on DioException
///   - WMI offline fallback on empty / unrecognised vPIC body
///   - unknown WMI → wmiOffline with null fields (not invalid — the
///     VIN itself validated, the decoder just has nothing to say)
void main() {
  setUpAll(() {
    registerFallbackValue(Uri());
  });

  group('VinDecoder VIN validation', () {
    test('rejects a VIN shorter than 17 characters (no network call)',
        () async {
      final dio = _MockDio();
      final dec = VinDecoder(dio: dio);
      final result = await dec.decode('VF3ABC');

      expect(result, isNotNull);
      expect(result!.source, VinDataSource.invalid);
      expect(result.make, isNull);
      expect(result.model, isNull);
      // Crucially, no network call happened on the invalid path.
      verifyNever(() => dio.get<Map<String, dynamic>>(any(),
          queryParameters: any(named: 'queryParameters')));
    });

    test('rejects a VIN containing forbidden I / O / Q letters', () async {
      final dio = _MockDio();
      final dec = VinDecoder(dio: dio);
      // 'I' is never used in VINs (too close to '1').
      final result = await dec.decode('VF3IIIIIIIIIIIIII');

      expect(result, isNotNull);
      expect(result!.source, VinDataSource.invalid);
      verifyNever(() => dio.get<Map<String, dynamic>>(any(),
          queryParameters: any(named: 'queryParameters')));
    });

    test('uppercases lowercase input before validation', () async {
      final dio = _MockDio();
      when(() => dio.get<Map<String, dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionError,
      ));
      final dec = VinDecoder(dio: dio);
      final result = await dec.decode('vf36b8hzl8r123456');
      // Should fall back to WMI (VF3 → Peugeot), which also proves
      // the cleaner normalised to uppercase and the 17-char check
      // passed.
      expect(result, isNotNull);
      expect(result!.source, VinDataSource.wmiOffline);
      expect(result.make, 'Peugeot');
    });
  });

  group('VinDecoder WMI offline fallback (network unavailable)', () {
    // Every test in this group mocks vPIC as unreachable so the
    // decoder is forced onto the WMI-only branch.
    late _MockDio dio;
    late VinDecoder decoder;

    setUp(() {
      dio = _MockDio();
      when(() => dio.get<Map<String, dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionError,
      ));
      decoder = VinDecoder(dio: dio);
    });

    test('known WMI → partial VinData with make + country', () async {
      final r = await decoder.decode('VF38HKFVZ6R123456');
      expect(r, isNotNull);
      expect(r!.source, VinDataSource.wmiOffline);
      expect(r.make, 'Peugeot');
      expect(r.country, 'France');
      expect(r.displacementL, isNull, reason: 'WMI carries no engine data');
      expect(r.cylinderCount, isNull);
    });

    test('unknown WMI → VinData(source: wmiOffline) with nulls everywhere',
        () async {
      // ZZZ is not in the table — decoder still reports wmiOffline
      // (the VIN validated, we just couldn't identify the maker).
      final r = await decoder.decode('ZZZ1234567890ZZZZ');
      expect(r, isNotNull);
      expect(r!.source, VinDataSource.wmiOffline);
      expect(r.make, isNull);
      expect(r.country, isNull);
    });
  });

  group('VinDecoder NHTSA vPIC happy path (mocked Dio)', () {
    test('parses a full vPIC response into every field', () async {
      final dio = _MockDio();
      when(() => dio.get<Map<String, dynamic>>(
            '/api/vehicles/decodevin/VF36B8HZL8R123456',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: _peugeot107VpicResponse,
          ));

      final dec = VinDecoder(dio: dio);
      final r = await dec.decode('VF36B8HZL8R123456');

      expect(r, isNotNull);
      expect(r!.source, VinDataSource.vpic);
      expect(r.make, 'PEUGEOT');
      expect(r.model, '107');
      expect(r.modelYear, 2008);
      expect(r.displacementL, closeTo(1.0, 0.01));
      expect(r.cylinderCount, 3);
      expect(r.fuelTypePrimary, 'Gasoline');
      expect(r.vin, 'VF36B8HZL8R123456');
      expect(r.isComplete, isTrue);
    });

    test('falls back to WMI when vPIC returns empty Results', () async {
      final dio = _MockDio();
      when(() => dio.get<Map<String, dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: const {'Results': []},
          ));

      final dec = VinDecoder(dio: dio);
      final r = await dec.decode('VF36B8HZL8R123456');

      expect(r, isNotNull);
      expect(r!.source, VinDataSource.wmiOffline);
      expect(r.make, 'Peugeot'); // from WMI fallback, not vPIC
    });

    test('falls back to WMI when vPIC raises DioException (5xx)', () async {
      final dio = _MockDio();
      when(() => dio.get<Map<String, dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
      ));

      final dec = VinDecoder(dio: dio);
      final r = await dec.decode('VF36B8HZL8R123456');

      expect(r, isNotNull);
      expect(r!.source, VinDataSource.wmiOffline);
    });

    test('falls back to WMI when vPIC returns no Results key', () async {
      // vPIC occasionally returns a 200 with no Results key when it
      // doesn't recognise the VIN at all. Make sure we don't NPE.
      final dio = _MockDio();
      when(() => dio.get<Map<String, dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: const {'Message': 'VIN not recognised'},
          ));

      final dec = VinDecoder(dio: dio);
      final r = await dec.decode('VF36B8HZL8R123456');
      expect(r, isNotNull);
      expect(r!.source, VinDataSource.wmiOffline);
    });
  });

  group('VinData', () {
    test('isComplete is true only when make + model + displacement are set',
        () {
      const complete = VinData(
        vin: 'VF36B8HZL8R123456',
        make: 'Peugeot',
        model: '107',
        displacementL: 1.0,
        source: VinDataSource.vpic,
      );
      expect(complete.isComplete, isTrue);

      const makeOnly = VinData(
        vin: 'VF38HKFVZ6R123456',
        make: 'Peugeot',
        source: VinDataSource.wmiOffline,
      );
      expect(makeOnly.isComplete, isFalse);

      const empty = VinData(
        vin: 'short',
        source: VinDataSource.invalid,
      );
      expect(empty.isComplete, isFalse);
    });

    test('round-trips through JSON (Hive serialization)', () {
      const data = VinData(
        vin: 'VF36B8HZL8R123456',
        make: 'PEUGEOT',
        model: '107',
        modelYear: 2008,
        displacementL: 1.0,
        cylinderCount: 3,
        fuelTypePrimary: 'Gasoline',
        source: VinDataSource.vpic,
      );
      final roundTripped = VinData.fromJson(data.toJson());
      expect(roundTripped, equals(data));
    });
  });
}

/// Condensed vPIC response. Real vPIC returns 130+ variables; we only
/// parse the fields we care about. The extras + 'Not Applicable'
/// values are included to verify the parser filters them without
/// throwing.
const _peugeot107VpicResponse = {
  'Results': [
    {'Variable': 'Make', 'Value': 'PEUGEOT'},
    {'Variable': 'Model', 'Value': '107'},
    {'Variable': 'Model Year', 'Value': '2008'},
    {'Variable': 'Displacement (L)', 'Value': '1.0'},
    {'Variable': 'Engine Number of Cylinders', 'Value': '3'},
    {'Variable': 'Fuel Type - Primary', 'Value': 'Gasoline'},
    {'Variable': 'Body Class', 'Value': 'Hatchback/Liftback/Notchback'},
    {'Variable': 'Plant City', 'Value': 'Not Applicable'},
    {'Variable': 'Plant Country', 'Value': ''},
  ],
};
