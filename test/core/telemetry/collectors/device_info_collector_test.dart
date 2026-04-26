import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/constants/app_constants.dart';
import 'package:tankstellen/core/telemetry/collectors/device_info_collector.dart';

void main() {
  group('DeviceInfoCollector.collect', () {
    test('populates os + osVersion + platform for the host OS', () {
      final info = DeviceInfoCollector.collect();

      if (kIsWeb) {
        expect(info.os, 'web');
        expect(info.platform, 'web');
      } else {
        expect(info.os, Platform.operatingSystem);
        expect(info.osVersion, Platform.operatingSystemVersion);
        final expected =
            (Platform.isAndroid || Platform.isIOS) ? 'mobile' : 'desktop';
        expect(info.platform, expected);
      }
    });

    test('includes a non-empty locale string', () {
      // The collector reads from PlatformDispatcher.locale, which the
      // test binding populates with the host locale. We just assert
      // that the field made it through rather than pinning a value.
      final info = DeviceInfoCollector.collect();
      expect(info.locale, isNotEmpty);
    });

    test('includes the app version from AppConstants', () {
      final info = DeviceInfoCollector.collect();
      expect(info.appVersion, AppConstants.appVersion);
      expect(info.appVersion, isNotEmpty);
    });

    test('screen dimensions are non-negative doubles', () {
      // Under `flutter test`, the test harness provides a default
      // view, so screen size can be > 0. If that ever changes the
      // catch-clause in the collector returns 0 — which is still
      // safe (no negative values).
      final info = DeviceInfoCollector.collect();
      expect(info.screenWidth, greaterThanOrEqualTo(0));
      expect(info.screenHeight, greaterThanOrEqualTo(0));
    });

    test('two consecutive collects produce equivalent snapshots', () {
      // The collector reads live values each call; on a stable host
      // two back-to-back calls should agree on os/platform/version
      // even if screen size could drift (it does not, in-process).
      final a = DeviceInfoCollector.collect();
      final b = DeviceInfoCollector.collect();
      expect(b.os, a.os);
      expect(b.osVersion, a.osVersion);
      expect(b.platform, a.platform);
      expect(b.appVersion, a.appVersion);
    });
  });
}
