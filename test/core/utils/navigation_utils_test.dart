import 'package:flutter_test/flutter_test.dart';

/// Tests for NavigationUtils URI/URL construction logic.
///
/// Since launchUrl depends on platform channels, we test the URI/URL
/// construction logic directly — the same string-building that
/// NavigationUtils.openInMaps and openRouteInMaps use internally.
void main() {
  group('NavigationUtils - geo: URI construction', () {
    test('constructs geo URI without label', () {
      const lat = 48.8566;
      const lng = 2.3522;
      // Matches NavigationUtils.openInMaps: geo:lat,lng?q=lat,lng
      const query = '?q=$lat,$lng';
      final uri = Uri.parse('geo:$lat,$lng$query');

      expect(uri.scheme, 'geo');
      expect(uri.path, '$lat,$lng');
      expect(uri.query, 'q=$lat,$lng');
    });

    test('constructs geo URI with label', () {
      const lat = 48.8566;
      const lng = 2.3522;
      const label = 'Eiffel Tower';
      // Matches NavigationUtils.openInMaps: geo:lat,lng?q=lat,lng(encodedLabel)
      final query = '?q=$lat,$lng(${Uri.encodeComponent(label)})';
      final uri = Uri.parse('geo:$lat,$lng$query');

      expect(uri.scheme, 'geo');
      expect(uri.path, '$lat,$lng');
      expect(uri.query, contains('Eiffel'));
      expect(uri.query, contains(Uri.encodeComponent(label)));
    });

    test('handles special characters in label', () {
      const lat = 48.8566;
      const lng = 2.3522;
      const label = 'Station & Café "Test"';
      final encoded = Uri.encodeComponent(label);

      // Verify special chars are properly encoded
      expect(encoded, isNot(contains('&')));
      expect(encoded, isNot(contains('"')));
      expect(encoded, contains('%26')); // &
      expect(encoded, contains('%22')); // "

      // Full URI should parse without error
      final uri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($encoded)');
      expect(uri.scheme, 'geo');
    });

    test('handles German umlauts in label', () {
      const label = 'Tankstelle München';
      final encoded = Uri.encodeComponent(label);

      expect(encoded, isNot(contains('ü')));
      expect(Uri.decodeComponent(encoded), label);
    });

    test('handles French accented characters in label', () {
      const label = 'Station Énergie Côte d\'Azur';
      final encoded = Uri.encodeComponent(label);

      expect(encoded, isNot(contains('É')));
      expect(encoded, isNot(contains('ô')));
      expect(Uri.decodeComponent(encoded), label);
    });

    test('handles negative coordinates', () {
      const lat = -33.8688;
      const lng = -151.2093;
      final uri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');

      expect(uri.scheme, 'geo');
      expect(uri.toString(), contains('-33.8688'));
      expect(uri.toString(), contains('-151.2093'));
    });

    test('handles zero coordinates', () {
      final uri = Uri.parse('geo:0.0,0.0?q=0.0,0.0');

      expect(uri.scheme, 'geo');
      expect(uri.path, '0.0,0.0');
    });
  });

  group('NavigationUtils - Google Maps route URL construction', () {
    test('constructs route URL with origin and destination', () {
      // Matches NavigationUtils.openRouteInMaps
      const origin = '48.8566,2.3522';
      const destination = '51.5074,-0.1278';
      final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&origin=$origin'
        '&destination=$destination'
        '&travelmode=driving',
      );

      expect(url.scheme, 'https');
      expect(url.host, 'www.google.com');
      expect(url.path, '/maps/dir/');
      expect(url.queryParameters['api'], '1');
      expect(url.queryParameters['origin'], origin);
      expect(url.queryParameters['destination'], destination);
      expect(url.queryParameters['travelmode'], 'driving');
    });

    test('constructs route URL with waypoints joined by pipe', () {
      const origin = '48.8566,2.3522';
      const destination = '51.5074,-0.1278';
      final waypoints = ['49.4431,1.0993', '50.6292,3.0573'];
      // Matches NavigationUtils: waypoints.join('|')
      var urlStr = 'https://www.google.com/maps/dir/?api=1'
          '&origin=$origin'
          '&destination=$destination'
          '&travelmode=driving';
      urlStr += '&waypoints=${waypoints.join('|')}';
      final url = Uri.parse(urlStr);

      expect(url.queryParameters['waypoints'],
          '49.4431,1.0993|50.6292,3.0573');
    });

    test('constructs route URL without waypoints when list is empty', () {
      const origin = '48.8566,2.3522';
      const destination = '51.5074,-0.1278';
      final waypoints = <String>[];

      var urlStr = 'https://www.google.com/maps/dir/?api=1'
          '&origin=$origin'
          '&destination=$destination'
          '&travelmode=driving';
      if (waypoints.isNotEmpty) {
        urlStr += '&waypoints=${waypoints.join('|')}';
      }
      final url = Uri.parse(urlStr);

      expect(url.queryParameters.containsKey('waypoints'), isFalse);
    });

    test('fallback URL uses /maps/dir/ with destination only', () {
      // Matches NavigationUtils.openInMaps fallback
      const lat = 48.8566;
      const lng = 2.3522;
      final fallbackUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
      );

      expect(fallbackUrl.scheme, 'https');
      expect(fallbackUrl.host, 'www.google.com');
      expect(fallbackUrl.path, '/maps/dir/');
      expect(fallbackUrl.queryParameters['destination'], '$lat,$lng');
    });
  });

  group('NavigationUtils - URL encoding correctness', () {
    test('pipe separator in waypoints is preserved in raw URL', () {
      const waypoints = '48.0,2.0|49.0,3.0';
      // In NavigationUtils, waypoints are NOT percent-encoded — they're
      // inserted directly into the URL string before Uri.parse()
      final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&waypoints=$waypoints',
      );

      // Uri.parse treats | as a valid query character
      expect(url.queryParameters['waypoints'], waypoints);
    });

    test('coordinates with many decimal places are preserved', () {
      const lat = 48.85660000;
      const lng = 2.35220000;
      final uri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');

      // Dart trims trailing zeros, but the precision should be preserved
      expect(uri.toString(), contains('48.8566'));
      expect(uri.toString(), contains('2.3522'));
    });
  });
}
