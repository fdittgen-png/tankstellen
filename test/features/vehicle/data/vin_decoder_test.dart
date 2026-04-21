import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/vehicle/data/vin_decoder.dart';

class _MockDio extends Mock implements Dio {}

/// Tests for [VinDecoder] (#812). Uses `mocktail` MockDio (house
/// pattern) so no real network calls are made.
void main() {
  setUpAll(() {
    registerFallbackValue(Uri());
  });

  group('VinDecoder VIN validation', () {
    test('rejects a VIN shorter than 17 characters', () async {
      final dec = VinDecoder(dio: _MockDio());
      final result = await dec.decode('VF3ABC');
      expect(result.source, VinDecodeSource.invalid);
      expect(result.make, isNull);
    });

    test('rejects a VIN containing the forbidden I/O/Q letters', () async {
      final dec = VinDecoder(dio: _MockDio());
      // "I" is never used in VINs (looks like "1").
      final result = await dec.decode('VF3IIIIIIIIIIIIII');
      expect(result.source, VinDecodeSource.invalid);
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
      // Should fall back to WMI (VF3 → Peugeot), proving the cleaner
      // normalised to uppercase and the 17-char check passed.
      expect(result.source, VinDecodeSource.wmiFallback);
      expect(result.make, 'Peugeot');
    });
  });

  group('VinDecoder WMI table (offline fallback)', () {
    // Force a network failure on every test so we exercise the
    // WMI-only branch. The thenThrow arm mimics a DNS failure.
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

    test('VF3 → Peugeot FR', () async {
      final r = await decoder.decode('VF38HKFVZ6R123456');
      expect(r.make, 'Peugeot');
      expect(r.country, 'FR');
      expect(r.displacementLitres, isNull); // WMI doesn't carry engine data
    });

    test('WVW → Volkswagen DE', () async {
      final r = await decoder.decode('WVWZZZ1KZAM123456');
      expect(r.make, 'Volkswagen');
      expect(r.country, 'DE');
    });

    test('WBA → BMW DE', () async {
      final r = await decoder.decode('WBA3B1C50DF123456');
      expect(r.make, 'BMW');
    });

    test('5YJ → Tesla US', () async {
      final r = await decoder.decode('5YJ3E1EA7KF123456');
      expect(r.make, 'Tesla');
    });

    test('TMB → Škoda (Peugeot 107 was sometimes built on the same '
        'Kolín plant line — WMI disambiguates on country only)', () async {
      final r = await decoder.decode('TMBEG7NE5H0123456');
      expect(r.make, 'Škoda');
      expect(r.country, 'CZ');
    });

    test('unknown WMI → invalid source (falls through to manual entry)',
        () async {
      final r = await decoder.decode('ZZZ1234567890ZZZZ');
      expect(r.source, VinDecodeSource.invalid);
    });
  });

  group('VinDecoder NHTSA happy path (mocked Dio)', () {
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

      expect(r.source, VinDecodeSource.nhtsa);
      expect(r.make, 'PEUGEOT');
      expect(r.model, '107');
      expect(r.modelYear, 2008);
      expect(r.displacementLitres, closeTo(1.0, 0.01));
      expect(r.cylinders, 3);
      expect(r.fuelType, 'Gasoline');
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

      expect(r.source, VinDecodeSource.wmiFallback);
      expect(r.make, 'Peugeot'); // from WMI fallback, not vPIC
    });

    test('falls back to WMI when vPIC raises DioException (5xx)',
        () async {
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

      expect(r.source, VinDecodeSource.wmiFallback);
    });

    test('falls back to WMI when vPIC returns null Results key',
        () async {
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
      expect(r.source, VinDecodeSource.wmiFallback);
    });
  });

  group('VinDecodeResult', () {
    test('isComplete is true only when make + model + displacement are all '
        'set', () {
      const complete = VinDecodeResult(
        make: 'Peugeot',
        model: '107',
        displacementLitres: 1.0,
        source: VinDecodeSource.nhtsa,
      );
      expect(complete.isComplete, isTrue);

      const makeOnly = VinDecodeResult(
        make: 'Peugeot',
        source: VinDecodeSource.wmiFallback,
      );
      expect(makeOnly.isComplete, isFalse);

      const empty = VinDecodeResult(source: VinDecodeSource.invalid);
      expect(empty.isComplete, isFalse);
    });
  });
}

/// Condensed vPIC response. Real vPIC returns 130+ variables; we only
/// parse six. The extras + "Not Applicable" values are included to
/// verify the parser filters them without throwing.
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
