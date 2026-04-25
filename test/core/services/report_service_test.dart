import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/report_service.dart';

void main() {
  group('ReportService', () {
    group('submitComplaint', () {
      test('succeeds with valid API response', () async {
        final dio = Dio();
        dio.httpClientAdapter = _MockAdapter([
          const _MockResponse(200, {'ok': true, 'message': 'Report accepted'}),
        ]);

        final service = ReportService.withDio(dio);
        final result = await service.submitComplaint(
          stationId: 'abc-123',
          reportType: 'wrongDiesel',
          apiKey: 'test-key',
          correction: 1.459,
        );

        expect(result.success, isTrue);
        expect(result.message, 'Report accepted');
      });

      test('succeeds without correction for status reports', () async {
        final dio = Dio();
        dio.httpClientAdapter = _MockAdapter([
          const _MockResponse(200, {'ok': true}),
        ]);

        final service = ReportService.withDio(dio);
        final result = await service.submitComplaint(
          stationId: 'abc-123',
          reportType: 'wrongStatusOpen',
          apiKey: 'test-key',
        );

        expect(result.success, isTrue);
      });

      test('throws ApiException when API key is null', () async {
        final service = ReportService.withDio(Dio());

        expect(
          () => service.submitComplaint(
            stationId: 'abc-123',
            reportType: 'wrongDiesel',
            apiKey: null,
          ),
          throwsA(isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('API key'),
          )),
        );
      });

      test('throws ApiException when API key is empty', () async {
        final service = ReportService.withDio(Dio());

        expect(
          () => service.submitComplaint(
            stationId: 'abc-123',
            reportType: 'wrongDiesel',
            apiKey: '',
          ),
          throwsA(isA<ApiException>()),
        );
      });

      test('throws ApiException on network error', () async {
        final dio = Dio();
        dio.httpClientAdapter = _MockAdapter([
          const _MockResponse(500, 'Internal Server Error'),
        ]);

        final service = ReportService.withDio(dio);

        expect(
          () => service.submitComplaint(
            stationId: 'abc-123',
            reportType: 'wrongDiesel',
            apiKey: 'test-key',
            correction: 1.459,
          ),
          throwsA(isA<ApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            500,
          )),
        );
      });

      test('throws ApiException on connection timeout', () async {
        final dio = Dio(BaseOptions(
          connectTimeout: const Duration(milliseconds: 1),
        ));
        // Use an unreachable address to trigger timeout
        dio.options.baseUrl = 'http://192.0.2.1'; // RFC 5737 TEST-NET

        final service = ReportService.withDio(dio);

        expect(
          () => service.submitComplaint(
            stationId: 'abc-123',
            reportType: 'wrongDiesel',
            apiKey: 'test-key',
          ),
          throwsA(isA<ApiException>()),
        );
      });

      test('handles non-map response body gracefully', () async {
        final dio = Dio();
        dio.httpClientAdapter = _MockAdapter([
          const _MockResponse(200, 'OK'),
        ]);

        final service = ReportService.withDio(dio);
        final result = await service.submitComplaint(
          stationId: 'abc-123',
          reportType: 'wrongE5',
          apiKey: 'test-key',
          correction: 1.5,
        );

        expect(result.success, isTrue);
        expect(result.message, isNull);
      });
    });

    group('ReportResult', () {
      test('stores success and message', () {
        const result = ReportResult(success: true, message: 'Done');
        expect(result.success, isTrue);
        expect(result.message, 'Done');
      });

      test('message is optional', () {
        const result = ReportResult(success: true);
        expect(result.message, isNull);
      });
    });

    group('source-level regression', () {
      // #563 — submit-flow extracted to sibling report_submit_handler.dart so
      // report_screen.dart stays under the 300-LOC budget. The screen file
      // and the handler file together must keep the original invariants
      // (no direct Dio, ReportService.submitComplaint is the entry point).
      const reportScreenPath =
          'lib/features/report/presentation/screens/report_screen.dart';
      const submitHandlerPath =
          'lib/features/report/presentation/screens/report_submit_handler.dart';

      test('report_screen does not instantiate Dio directly', () {
        final screenSource = File(reportScreenPath).readAsStringSync();
        final handlerSource = File(submitHandlerPath).readAsStringSync();

        for (final entry in {
          reportScreenPath: screenSource,
          submitHandlerPath: handlerSource,
        }.entries) {
          expect(
            entry.value.contains('Dio('),
            isFalse,
            reason:
                '${entry.key} should use ReportService, not create Dio directly',
          );
          expect(
            entry.value.contains("import 'package:dio/dio.dart'"),
            isFalse,
            reason: '${entry.key} should not import Dio',
          );
        }
      });

      test('report_screen uses ReportService', () {
        final handlerSource = File(submitHandlerPath).readAsStringSync();

        expect(handlerSource, contains('ReportService'));
        expect(handlerSource, contains('submitComplaint'));
      });
    });
  });
}

class _MockResponse {
  final int statusCode;
  final Object body;

  const _MockResponse(this.statusCode, this.body);
}

class _MockAdapter implements HttpClientAdapter {
  final List<_MockResponse> _responses;
  int _index = 0;

  _MockAdapter(this._responses);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (_index >= _responses.length) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.unknown,
        error: 'No more mock responses',
      );
    }

    final mock = _responses[_index++];

    if (mock.statusCode >= 400) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: options,
          statusCode: mock.statusCode,
          data: mock.body,
        ),
      );
    }

    final encoded = jsonEncode(mock.body);
    return ResponseBody.fromString(
      encoded,
      mock.statusCode,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
