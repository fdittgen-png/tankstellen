import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/data/services/ev_charging_service.dart';

/// #697 — Spain EV search returned zero results.
///
/// Root cause: OCM's `countrycode` filter dropped legitimate stations
/// in border regions and occasionally mis-tagged country metadata.
/// Dropping the filter keeps geographic constraint (lat/lng + radius)
/// without the false zero.
///
/// This test uses a capturing Dio adapter to assert the outbound
/// query parameters actually sent to OCM — regardless of what the
/// service's public API accepts.
void main() {
  group('EVChargingService (#697)', () {
    test(
        'does NOT forward countrycode to the OCM API, even when the '
        'call site passes one', () async {
      final capture = _CapturingAdapter();
      final service = EVChargingService(
        apiKey: 'test-key',
        dio: Dio()..httpClientAdapter = capture,
      );

      await service.searchStations(
        lat: 40.4168,
        lng: -3.7038,
        radiusKm: 10,
        countryCode: 'ES',
      );

      expect(capture.capturedQueryParams, isNotNull);
      expect(
        capture.capturedQueryParams!.containsKey('countrycode'),
        isFalse,
        reason:
            'OCM countrycode filter was dropping legitimate ES results '
            '(#697). Service must omit the param entirely.',
      );
      // The geographic filters ARE still there.
      expect(capture.capturedQueryParams!['latitude'], '40.4168');
      expect(capture.capturedQueryParams!['longitude'], '-3.7038');
      expect(capture.capturedQueryParams!['distance'], '10.0');
      expect(capture.capturedQueryParams!['key'], 'test-key');
    });
  });
}

class _CapturingAdapter implements HttpClientAdapter {
  Map<String, String>? capturedQueryParams;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    capturedQueryParams = options.uri.queryParameters;
    // Return an empty JSON list so the service parses a valid (empty)
    // response without blowing up on this synthetic test.
    return ResponseBody.fromString(
      jsonEncode(<dynamic>[]),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
