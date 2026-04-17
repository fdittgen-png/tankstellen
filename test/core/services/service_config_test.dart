import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/constants/app_constants.dart';
import 'package:tankstellen/core/services/service_config.dart';

void main() {
  group('ServiceConfig (defaults)', () {
    test('applies 10-second default timeouts for connect and receive', () {
      const cfg = ServiceConfig(baseUrl: 'https://example.com');
      expect(cfg.connectTimeout, const Duration(seconds: 10));
      expect(cfg.receiveTimeout, const Duration(seconds: 10));
    });

    test('defaults to empty headers + null apiKeyParamName', () {
      const cfg = ServiceConfig(baseUrl: 'https://example.com');
      expect(cfg.headers, isEmpty);
      expect(cfg.apiKeyParamName, isNull);
    });

    test('accepts explicit headers + apiKeyParamName', () {
      const cfg = ServiceConfig(
        baseUrl: 'https://example.com',
        apiKeyParamName: 'apikey',
        headers: {'X-Test': '1'},
      );
      expect(cfg.apiKeyParamName, 'apikey');
      expect(cfg.headers['X-Test'], '1');
    });
  });

  group('ServiceConfigs.tankerkoenig', () {
    test('points at creativecommons.tankerkoenig.de', () {
      expect(ServiceConfigs.tankerkoenig.baseUrl,
          'https://creativecommons.tankerkoenig.de/json');
    });

    test('uses the "apikey" query parameter for key injection', () {
      expect(ServiceConfigs.tankerkoenig.apiKeyParamName, 'apikey');
    });

    test('sends the app User-Agent so upstream can identify us', () {
      expect(ServiceConfigs.tankerkoenig.headers['User-Agent'],
          AppConstants.userAgent);
    });
  });

  group('ServiceConfigs.nominatim', () {
    test('points at nominatim.openstreetmap.org', () {
      expect(ServiceConfigs.nominatim.baseUrl,
          'https://nominatim.openstreetmap.org');
    });

    test('has no API key parameter (keyless service)', () {
      expect(ServiceConfigs.nominatim.apiKeyParamName, isNull);
    });

    test('sends the User-Agent — required by OSM usage policy', () {
      // Nominatim will rate-limit or block requests with no UA;
      // pin the contract so a refactor can't accidentally drop it.
      expect(ServiceConfigs.nominatim.headers['User-Agent'],
          AppConstants.userAgent);
    });
  });

  group('ServiceConfigs.osrm', () {
    test('uses 30s receive timeout for routing', () {
      // Routing responses can be large for long cross-country
      // routes; the default 10s is too tight.
      expect(ServiceConfigs.osrm.receiveTimeout,
          const Duration(seconds: 30));
    });

    test('has no API key (public OSRM demo server)', () {
      expect(ServiceConfigs.osrm.apiKeyParamName, isNull);
    });
  });

  group('ServiceConfigs.openChargeMap', () {
    test('points at api.openchargemap.io/v3', () {
      expect(ServiceConfigs.openChargeMap.baseUrl,
          'https://api.openchargemap.io/v3');
    });

    test('uses the "key" query parameter for key injection', () {
      expect(ServiceConfigs.openChargeMap.apiKeyParamName, 'key');
    });
  });
}
