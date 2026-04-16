import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/constants/app_constants.dart';

void main() {
  group('AppConstants.appVersion', () {
    test('returns build-time fallback before runtime initialization', () {
      // Before setRuntimeVersion is called, should return _buildVersion
      expect(AppConstants.appVersion, isNotEmpty);
      expect(AppConstants.appVersion, isNot('4.0.0'),
          reason: 'Stale 4.0.0 must never appear (#570)');
    });

    test('returns runtime version after setRuntimeVersion', () {
      AppConstants.setRuntimeVersion('5.0.0+5012');
      expect(AppConstants.appVersion, '5.0.0+5012');
    });

    test('runtime version overrides build-time constant', () {
      AppConstants.setRuntimeVersion('99.0.0+9999');
      expect(AppConstants.appVersion, '99.0.0+9999');
    });
  });
}
