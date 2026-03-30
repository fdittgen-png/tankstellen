import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/providers/app_state_provider.dart';
import 'package:tankstellen/features/profile/presentation/widgets/config_verification_widget.dart';

void main() {
  group('ConfigVerificationWidget', () {
    test('widget exists and can be instantiated', () {
      const widget = ConfigVerificationWidget();
      expect(widget, isNotNull);
      expect(widget, isA<ConfigVerificationWidget>());
    });
  });

  group('StorageStats', () {
    test('has correct default values', () {
      const stats = StorageStats();
      expect(stats.favoriteCount, 0);
      expect(stats.alertCount, 0);
      expect(stats.ignoredCount, 0);
      expect(stats.ratingsCount, 0);
      expect(stats.cacheEntryCount, 0);
      expect(stats.priceHistoryCount, 0);
      expect(stats.profileCount, 0);
      expect(stats.hasGpsPosition, false);
      expect(stats.hasApiKey, false);
      expect(stats.hasCustomEvKey, false);
    });

    test('accepts custom values', () {
      const stats = StorageStats(
        favoriteCount: 5,
        alertCount: 3,
        ignoredCount: 2,
        ratingsCount: 10,
        cacheEntryCount: 42,
        priceHistoryCount: 7,
        profileCount: 2,
        hasGpsPosition: true,
        hasApiKey: true,
        hasCustomEvKey: true,
      );
      expect(stats.favoriteCount, 5);
      expect(stats.alertCount, 3);
      expect(stats.ignoredCount, 2);
      expect(stats.ratingsCount, 10);
      expect(stats.cacheEntryCount, 42);
      expect(stats.priceHistoryCount, 7);
      expect(stats.profileCount, 2);
      expect(stats.hasGpsPosition, isTrue);
      expect(stats.hasApiKey, isTrue);
      expect(stats.hasCustomEvKey, isTrue);
    });
  });
}
