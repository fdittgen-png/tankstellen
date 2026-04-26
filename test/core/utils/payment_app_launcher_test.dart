import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:tankstellen/core/utils/payment_app_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

/// Offline tests for [paymentAppForBrand] and [PaymentAppLauncher]. The
/// brand catalog is empty today (#736 — every hard-coded Play Store id
/// 404'd), so no live probe runs.
///
/// When a brand is re-added, wrap [assertLivePlayStoreListing] (below) in
/// a `@Tags(['network'])` test so CI catches silent Play Store redirects
/// before users tap the chip. See `docs/guides/NETWORK_TESTS.md`.
void main() {
  group('paymentAppForBrand', () {
    test('returns null for unknown brand', () {
      expect(paymentAppForBrand('Unknown Station'), isNull);
    });

    test('returns null for empty or whitespace brand', () {
      expect(paymentAppForBrand(''), isNull);
      expect(paymentAppForBrand('   '), isNull);
    });

    test('(#736) returns null for every previously-supported brand — '
        'the catalog was emptied because all hardcoded IDs 404d on '
        'the Play Store', () {
      const formerlySupported = [
        'Shell',
        'BP',
        'Aral',
        'Total',
        'TotalEnergies',
        'Esso',
        'OMV',
        'Eni',
        'Repsol',
      ];
      for (final brand in formerlySupported) {
        expect(
          paymentAppForBrand(brand),
          isNull,
          reason:
              '$brand was removed pending a verified Play Store id. '
              'Re-adding requires passing the @Tags([network]) probe '
              'further down in this file.',
        );
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

  // ---------------------------------------------------------------------
  // #736 — the audit-grade probe. Why this exists:
  //
  // The "returns defined apps for all supported brands" test used to
  // assert only that the package id was a non-empty string. It passed
  // with hallucinated IDs like `com.totalenergies.servicesapp` that
  // don't correspond to any real Play Store listing. Users tapping
  // the Pay-with-X chip ended up on a 404 store page.
  //
  // This test actually fetches the Play Store web URL for every
  // registered brand and asserts:
  //   (a) the listing responds with 2xx;
  //   (b) the response HTML echoes the package id — if the Play Store
  //       redirects to its home page on an unknown id, the id won't
  //       be in the HTML, so this catches silent redirects.
  //
  // Tagged `network` so the offline unit suite stays fast. The CI
  // network-tests job (nightly) runs it; shipping a bad id fails CI
  // before it reaches users.
  // ---------------------------------------------------------------------
  // Live-probe helper — exposed as a top-level function so a future
  // PR that re-adds a brand can drop a single `test()` call into
  // this file calling `assertLivePlayStoreListing('<brandKey>')`.
  // The helper is invoked by zero production tests today because the
  // catalog is empty (#736). When a brand is re-added, wire a
  // @Tags(['network']) test that calls this.
}

/// Probe a brand's Play Store listing. Asserts the web page returns
/// 2xx/3xx AND echoes the package id in its HTML body — the latter
/// is what distinguishes a real listing from the Play Store's silent
/// "unknown id" redirect to its home page.
///
/// Exposed for the re-add workflow of #736: add the brand to
/// `_brandPaymentApps`, then wrap this in a `@Tags(['network'])` test.
@visibleForTesting
Future<void> assertLivePlayStoreListing(String brandKey) async {
  final app = paymentAppForBrand(brandKey);
  expect(app, isNotNull, reason: 'brand $brandKey not in catalog');
  final url = PaymentAppLauncher.playStoreWebUrl(app!);
  final res = await http.get(url, headers: const {
    'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36',
    'Accept-Language': 'en-US,en;q=0.9',
  });
  expect(res.statusCode, anyOf(200, 301, 302),
      reason:
          '$brandKey Play Store listing returned ${res.statusCode} — '
          'the id is either wrong or region-blocked for the probe.');
  expect(
    res.body,
    contains(app.androidPackageId),
    reason: '$brandKey Play Store page did not echo its own package '
        'id — the store almost certainly redirected to its home page '
        'because the id does not exist.',
  );
}
