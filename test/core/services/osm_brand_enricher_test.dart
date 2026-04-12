import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/services/osm_brand_enricher.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    when(() => mockDio.options).thenReturn(BaseOptions());
  });

  group('OsmBrandEnricher', () {
    test('returns brand from Overpass response', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => Response(
                data: {
                  'elements': [
                    {
                      'type': 'node',
                      'id': 123,
                      'tags': {'amenity': 'fuel', 'brand': 'Eni'},
                    },
                  ],
                },
                statusCode: 200,
                requestOptions: RequestOptions(),
              ));

      final enricher = OsmBrandEnricher(dio: mockDio);
      final brand = await enricher.getBrand(43.428, 3.606);

      expect(brand, 'Eni');
    });

    test('returns null when no fuel station found', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => Response(
                data: {'elements': []},
                statusCode: 200,
                requestOptions: RequestOptions(),
              ));

      final enricher = OsmBrandEnricher(dio: mockDio);
      final brand = await enricher.getBrand(43.428, 3.606);

      expect(brand, isNull);
    });

    test('returns null when station has no brand tag', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => Response(
                data: {
                  'elements': [
                    {
                      'type': 'node',
                      'id': 123,
                      'tags': {'amenity': 'fuel', 'name': 'Some Station'},
                    },
                  ],
                },
                statusCode: 200,
                requestOptions: RequestOptions(),
              ));

      final enricher = OsmBrandEnricher(dio: mockDio);
      final brand = await enricher.getBrand(43.428, 3.606);

      expect(brand, isNull);
    });

    test('returns null on network error', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenThrow(DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.connectionTimeout,
          ));

      final enricher = OsmBrandEnricher(dio: mockDio);
      final brand = await enricher.getBrand(43.428, 3.606);

      expect(brand, isNull);
    });

    test('returns null on non-200 response', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => Response(
                data: 'error',
                statusCode: 429,
                requestOptions: RequestOptions(),
              ));

      final enricher = OsmBrandEnricher(dio: mockDio);
      final brand = await enricher.getBrand(43.428, 3.606);

      expect(brand, isNull);
    });

    test('picks first element with brand tag', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => Response(
                data: {
                  'elements': [
                    {
                      'type': 'node',
                      'id': 1,
                      'tags': {'amenity': 'fuel'},
                    },
                    {
                      'type': 'node',
                      'id': 2,
                      'tags': {'amenity': 'fuel', 'brand': 'Shell'},
                    },
                  ],
                },
                statusCode: 200,
                requestOptions: RequestOptions(),
              ));

      final enricher = OsmBrandEnricher(dio: mockDio);
      final brand = await enricher.getBrand(48.0, 2.0);

      expect(brand, 'Shell');
    });
  });
}
