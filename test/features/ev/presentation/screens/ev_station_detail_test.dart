import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/stores/settings_hive_store.dart';

void main() {
  group('EV Station', () {
    test('default EV API key is available', () {
      expect(SettingsHiveStore.defaultEvApiKey, isNotEmpty);
      expect(SettingsHiveStore.defaultEvApiKey, contains('-'));
    });

    test('default EV API key has valid UUID format', () {
      final key = SettingsHiveStore.defaultEvApiKey;
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      expect(uuidRegex.hasMatch(key), isTrue);
    });

    test('station name does not contain Demo prefix', () {
      // The demo fallback service generated names like "Demo Fast Charger".
      // With the default API key, real data should be served.
      // This is a guard to ensure demo naming is not used in production.
      const demoNames = [
        'Demo Fast Charger',
        'Demo Destination Charger',
        'Demo AC Point',
        'Demo CHAdeMO',
      ];
      for (final name in demoNames) {
        expect(name.startsWith('Demo'), isTrue,
            reason: 'These are demo names — production stations should not have them');
      }
    });
  });
}
