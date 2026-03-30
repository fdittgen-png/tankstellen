import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error_tracing/models/error_trace.dart';

void main() {
  group('ErrorCategory', () {
    test('has exactly 8 values', () {
      expect(ErrorCategory.values.length, 8);
    });

    test('all values have non-empty English display names', () {
      for (final category in ErrorCategory.values) {
        expect(category.displayName.isNotEmpty, true,
            reason: '${category.name} should have a non-empty displayName');
      }
    });

    test('display names are in English (no German characters)', () {
      // German-specific patterns: umlauts, sharp-s, common German words
      final germanPattern = RegExp(r'[äöüÄÖÜß]|Fehler|Unbekannt|Netzwerk');
      for (final category in ErrorCategory.values) {
        expect(germanPattern.hasMatch(category.displayName), false,
            reason:
                '${category.name} displayName "${category.displayName}" appears to contain German text');
      }
    });

    test('api category has correct display name', () {
      expect(ErrorCategory.api.displayName, 'API Error');
    });

    test('network category has correct display name', () {
      expect(ErrorCategory.network.displayName, 'Network Error');
    });

    test('cache category has correct display name', () {
      expect(ErrorCategory.cache.displayName, 'Cache Error');
    });

    test('ui category has correct display name', () {
      expect(ErrorCategory.ui.displayName, 'UI Error');
    });

    test('platform category has correct display name', () {
      expect(ErrorCategory.platform.displayName, 'Platform Error');
    });

    test('serviceChain category has correct display name', () {
      expect(ErrorCategory.serviceChain.displayName, 'Service Chain Error');
    });

    test('provider category has correct display name', () {
      expect(ErrorCategory.provider.displayName, 'Provider Error');
    });

    test('unknown category has correct display name', () {
      expect(ErrorCategory.unknown.displayName, 'Unknown');
    });
  });
}
