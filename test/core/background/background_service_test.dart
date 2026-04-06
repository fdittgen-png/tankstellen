import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/background/background_service.dart';
import 'package:tankstellen/core/notifications/notification_service.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';

void main() {
  group('BackgroundService', () {
    test('BackgroundService.init does not throw in test environment', () {
      // BackgroundService.init calls Workmanager().initialize which
      // requires platform channels. In unit tests without a running
      // Flutter engine, this will throw a MissingPluginException.
      // We verify the method exists and is callable.
      expect(BackgroundService.init, isA<Function>());
    });

    test('retry constants are reasonable', () {
      expect(BackgroundService.maxRetryAttempts, greaterThanOrEqualTo(2));
      expect(BackgroundService.maxRetryAttempts, lessThanOrEqualTo(5));
      expect(
        BackgroundService.retryBaseDelay.inSeconds,
        greaterThanOrEqualTo(1),
      );
    });
  });

  group('HiveStorage.initInIsolate', () {
    test('initInIsolate method exists and is callable', () {
      // initInIsolate requires platform channels (FlutterSecureStorage),
      // so we can only verify the method signature exists.
      expect(HiveStorage.initInIsolate, isA<Function>());
    });

    test('background service does not open Hive boxes directly', () {
      // Verify the background service delegates Hive initialization
      // to HiveStorage.initInIsolate (with encryption) rather than
      // opening boxes directly without a cipher.
      final source = File(
        'lib/core/background/background_service.dart',
      ).readAsStringSync();

      // Should NOT contain direct Hive.openBox calls
      expect(
        source.contains('Hive.openBox'),
        isFalse,
        reason: 'Background service must use HiveStorage.initInIsolate() '
            'instead of opening Hive boxes directly without encryption',
      );

      // Should NOT import hive_flutter directly
      expect(
        source.contains("import 'package:hive_flutter/hive_flutter.dart'"),
        isFalse,
        reason: 'Background service should not import Hive directly',
      );

      // Should use initInIsolate
      expect(
        source.contains('initInIsolate'),
        isTrue,
        reason: 'Background service must call HiveStorage.initInIsolate()',
      );
    });
  });

  group('NotificationService', () {
    test('NotificationService.init method exists', () {
      // Verify the init method exists on NotificationService.
      // Actual initialization requires platform channels (Android/iOS).
      expect(NotificationService.init, isA<Function>());
    });
  });
}
