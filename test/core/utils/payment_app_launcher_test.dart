import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/payment_app_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  group('paymentAppForBrand', () {
    test('returns null for unknown brand', () {
      expect(paymentAppForBrand('Unknown Station'), isNull);
    });

    test('returns null for empty or whitespace brand', () {
      expect(paymentAppForBrand(''), isNull);
      expect(paymentAppForBrand('   '), isNull);
    });

    test('returns Shell App for Shell brand', () {
      final app = paymentAppForBrand('Shell');
      expect(app, isNotNull);
      expect(app!.displayName, 'Shell App');
      expect(app.androidPackageId, contains('shell'));
    });

    test('matches brand variations case-insensitively', () {
      expect(paymentAppForBrand('SHELL')?.displayName, 'Shell App');
      expect(paymentAppForBrand('Shell Express')?.displayName, 'Shell App');
      expect(paymentAppForBrand('shell')?.displayName, 'Shell App');
    });

    test('maps TotalEnergies and Total to the same app', () {
      expect(paymentAppForBrand('Total')?.displayName, 'TotalEnergies');
      expect(paymentAppForBrand('TotalEnergies')?.displayName,
          'TotalEnergies');
      expect(paymentAppForBrand('TotalEnergies Access')?.displayName,
          'TotalEnergies');
    });

    test('maps Repsol to Waylet', () {
      expect(paymentAppForBrand('Repsol')?.displayName, 'Waylet');
    });

    test('returns defined apps for all supported brands', () {
      const brands = ['Shell', 'BP', 'Aral', 'Total', 'Esso', 'OMV',
          'Eni', 'Repsol'];
      for (final brand in brands) {
        final app = paymentAppForBrand(brand);
        expect(app, isNotNull, reason: '$brand should map to an app');
        expect(app!.androidPackageId, isNotEmpty,
            reason: '$brand app needs a package ID');
      }
    });
  });

  group('PaymentAppLauncher.playStoreWebUrl', () {
    test('uses Play Store web format with the package ID', () {
      const app = PaymentApp(
        displayName: 'Test App',
        androidPackageId: 'com.example.app',
      );
      final url = PaymentAppLauncher.playStoreWebUrl(app);
      expect(url.toString(),
          'https://play.google.com/store/apps/details?id=com.example.app');
    });
  });

  group('PaymentAppLauncher.open', () {
    tearDown(() => PaymentAppLauncher.resetForTesting());

    test('opens app scheme when probe returns true', () async {
      final calls = <Uri>[];
      PaymentAppLauncher.probe = (uri) async => true;
      PaymentAppLauncher.launcher = (uri, {LaunchMode? mode}) async {
        calls.add(uri);
        return true;
      };

      const app = PaymentApp(
        displayName: 'Test',
        androidPackageId: 'com.example.test',
        appScheme: 'testapp://pay',
      );

      final result = await PaymentAppLauncher.open(app);

      expect(result, isTrue);
      expect(calls, hasLength(1));
      expect(calls.single.scheme, 'testapp');
    });

    test('falls back to market URI when scheme probe returns false',
        () async {
      final calls = <Uri>[];
      PaymentAppLauncher.probe = (uri) async => false;
      PaymentAppLauncher.launcher = (uri, {LaunchMode? mode}) async {
        calls.add(uri);
        return true;
      };

      const app = PaymentApp(
        displayName: 'Test',
        androidPackageId: 'com.example.test',
        appScheme: 'testapp://pay',
      );

      final result = await PaymentAppLauncher.open(app);

      expect(result, isTrue);
      expect(calls.single.scheme, 'market');
      expect(calls.single.toString(), contains('com.example.test'));
    });

    test('goes straight to market when no scheme is provided',
        () async {
      final calls = <Uri>[];
      PaymentAppLauncher.probe = (uri) async => true;
      PaymentAppLauncher.launcher = (uri, {LaunchMode? mode}) async {
        calls.add(uri);
        return true;
      };

      const app = PaymentApp(
        displayName: 'Test',
        androidPackageId: 'com.example.test',
      );

      final result = await PaymentAppLauncher.open(app);

      expect(result, isTrue);
      expect(calls.single.scheme, 'market');
    });

    test('falls through to web Play Store when market launch fails',
        () async {
      final calls = <Uri>[];
      PaymentAppLauncher.probe = (uri) async => false;
      PaymentAppLauncher.launcher = (uri, {LaunchMode? mode}) async {
        calls.add(uri);
        return uri.scheme == 'https';
      };

      const app = PaymentApp(
        displayName: 'Test',
        androidPackageId: 'com.example.test',
      );

      final result = await PaymentAppLauncher.open(app);

      expect(result, isTrue);
      expect(calls.map((u) => u.scheme).toList(), ['market', 'https']);
      expect(calls.last.host, 'play.google.com');
    });

    test('returns false when nothing can be launched', () async {
      PaymentAppLauncher.probe = (uri) async => false;
      PaymentAppLauncher.launcher = (uri, {LaunchMode? mode}) async {
        return false;
      };

      const app = PaymentApp(
        displayName: 'Test',
        androidPackageId: 'com.example.test',
      );

      final result = await PaymentAppLauncher.open(app);
      expect(result, isFalse);
    });
  });
}
