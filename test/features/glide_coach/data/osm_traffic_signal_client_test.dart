import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/glide_coach/data/osm_traffic_signal_client.dart';

class _MockDio extends Mock implements Dio {}

class _FakeOptions extends Fake implements Options {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeOptions());
  });

  group('OsmTrafficSignalClient.fetchInBoundingBox (#1125 phase 1)', () {
    late _MockDio dio;
    late OsmTrafficSignalClient client;

    setUp(() {
      dio = _MockDio();
      client = OsmTrafficSignalClient(dio: dio);
    });

    Response<dynamic> okResponse(Map<String, dynamic> body) => Response<dynamic>(
          requestOptions: RequestOptions(path: OsmTrafficSignalClient.endpoint),
          statusCode: 200,
          data: body,
        );

    test('POSTs the Overpass interpreter URL with the bbox-scoped query',
        () async {
      when(() => dio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => okResponse({'elements': []}));

      await client.fetchInBoundingBox(
        south: 43.4,
        west: 3.4,
        north: 43.5,
        east: 3.5,
      );

      final captured = verify(() => dio.post<dynamic>(
            captureAny(),
            data: captureAny(named: 'data'),
            options: any(named: 'options'),
          )).captured;

      expect(captured[0], OsmTrafficSignalClient.endpoint);
      final body = captured[1] as String;
      expect(body, contains('[out:json][timeout:25];'));
      expect(
        body,
        contains('node["highway"="traffic_signals"](43.4,3.4,43.5,3.5);'),
      );
      expect(body, contains('out;'));
    });

    test('parses elements into TrafficSignal entities', () async {
      when(() => dio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => okResponse({
                'elements': [
                  {
                    'type': 'node',
                    'id': 1234567890,
                    'lat': 43.4501,
                    'lon': 3.4502,
                    'tags': {
                      'highway': 'traffic_signals',
                      'crossing': 'marked',
                    },
                  },
                  {
                    'type': 'node',
                    'id': 9876543210,
                    'lat': 43.4602,
                    'lon': 3.4503,
                    // No tags map at all — must still parse with nulls.
                  },
                ],
              }));

      final signals = await client.fetchInBoundingBox(
        south: 43.4,
        west: 3.4,
        north: 43.5,
        east: 3.5,
      );

      expect(signals, hasLength(2));
      expect(signals[0].id, '1234567890');
      expect(signals[0].lat, 43.4501);
      expect(signals[0].lng, 3.4502);
      expect(signals[0].highway, 'traffic_signals');
      expect(signals[0].crossing, 'marked');

      expect(signals[1].id, '9876543210');
      expect(signals[1].crossing, isNull);
      expect(signals[1].highway, isNull);
    });

    test('skips elements missing lat/lon without throwing', () async {
      when(() => dio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => okResponse({
                'elements': [
                  // Bad row: missing lat.
                  {
                    'id': 1,
                    'lon': 3.4,
                    'tags': {'highway': 'traffic_signals'},
                  },
                  // Good row.
                  {
                    'id': 2,
                    'lat': 43.5,
                    'lon': 3.5,
                  },
                ],
              }));

      final signals = await client.fetchInBoundingBox(
        south: 43.4,
        west: 3.4,
        north: 43.5,
        east: 3.5,
      );

      expect(signals, hasLength(1));
      expect(signals.single.id, '2');
    });

    test('throws OsmTrafficSignalException on DioException', () async {
      when(() => dio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: OsmTrafficSignalClient.endpoint),
        type: DioExceptionType.connectionTimeout,
        message: 'connect timeout',
      ));

      expect(
        () => client.fetchInBoundingBox(
          south: 0,
          west: 0,
          north: 1,
          east: 1,
        ),
        throwsA(isA<OsmTrafficSignalException>()),
      );
    });

    test('throws OsmTrafficSignalException on non-2xx status', () async {
      when(() => dio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response<dynamic>(
                requestOptions:
                    RequestOptions(path: OsmTrafficSignalClient.endpoint),
                statusCode: 504,
                data: 'gateway timeout',
              ));

      expect(
        () => client.fetchInBoundingBox(
          south: 0,
          west: 0,
          north: 1,
          east: 1,
        ),
        throwsA(isA<OsmTrafficSignalException>()),
      );
    });

    test('throws OsmTrafficSignalException when payload is not a JSON object',
        () async {
      when(() => dio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response<dynamic>(
                requestOptions:
                    RequestOptions(path: OsmTrafficSignalClient.endpoint),
                statusCode: 200,
                data: 'not json',
              ));

      expect(
        () => client.fetchInBoundingBox(
          south: 0,
          west: 0,
          north: 1,
          east: 1,
        ),
        throwsA(isA<OsmTrafficSignalException>()),
      );
    });

    test('throws OsmTrafficSignalException when "elements" is missing',
        () async {
      when(() => dio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => okResponse({'version': 0.6}));

      expect(
        () => client.fetchInBoundingBox(
          south: 0,
          west: 0,
          north: 1,
          east: 1,
        ),
        throwsA(isA<OsmTrafficSignalException>()),
      );
    });
  });
}
