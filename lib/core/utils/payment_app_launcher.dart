import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Describes a branded payment/loyalty app for a fuel station brand.
///
/// The app is opened by tapping a "Pay with X" button on the station
/// detail screen. If the app is not installed, the Play Store page is
/// opened instead so the user can install it.
@immutable
class PaymentApp {
  /// User-facing product name (e.g. "Shell App", "BPme", "Aral Pay").
  final String displayName;

  /// Android package ID used to build the Play Store URL
  /// (e.g. `com.shell.sitibv.shellgoplus`).
  final String androidPackageId;

  /// Optional direct URL scheme that deep-links into the app when
  /// it is installed. `null` means we always fall back to the Play
  /// Store and let Android route to the app if it is present.
  final String? appScheme;

  const PaymentApp({
    required this.displayName,
    required this.androidPackageId,
    this.appScheme,
  });
}

/// Maps a station brand to its branded payment app, or `null` if the
/// brand has no known paying app.
///
/// Match is case-insensitive and matches any substring so that brand
/// variations like "Shell Express" or "TotalEnergies Access" still
/// resolve to the parent app.
PaymentApp? paymentAppForBrand(String brand) {
  final normalized = brand.trim().toLowerCase();
  if (normalized.isEmpty) return null;
  for (final entry in _brandPaymentApps.entries) {
    if (normalized.contains(entry.key)) return entry.value;
  }
  return null;
}

/// Launches a payment app, preferring a deep-link into the app when
/// its scheme is known and installed; otherwise falls back to the
/// Play Store so the user can install it.
///
/// Returns `true` if something was launched, `false` if all attempts
/// failed (e.g. no browser or market app on the device).
class PaymentAppLauncher {
  PaymentAppLauncher._();

  /// The injection points below let tests override the launch/probe
  /// functions without having to plumb through a plugin mock. They
  /// reset to the real `url_launcher` functions after each test via
  /// [resetForTesting].
  @visibleForTesting
  static Future<bool> Function(Uri uri, {LaunchMode mode}) launcher =
      _defaultLauncher;
  @visibleForTesting
  static Future<bool> Function(Uri uri) probe = _defaultProbe;

  @visibleForTesting
  static void resetForTesting() {
    launcher = _defaultLauncher;
    probe = _defaultProbe;
  }

  static Future<bool> _defaultLauncher(Uri uri, {LaunchMode? mode}) =>
      launchUrl(uri, mode: mode ?? LaunchMode.externalApplication);

  static Future<bool> _defaultProbe(Uri uri) => canLaunchUrl(uri);

  /// Attempts to open [app]. Strategy:
  /// 1. If [app.appScheme] is set and the device reports it can
  ///    launch, deep-link directly into the app.
  /// 2. Otherwise, launch the `market:` URI so the Play Store opens
  ///    the app when installed, or the app's install page otherwise.
  /// 3. Fall back to the web Play Store URL so the flow still works
  ///    on devices without the Play Store (desktop tests, emulators
  ///    without Google services).
  static Future<bool> open(PaymentApp app) async {
    final scheme = app.appScheme;
    if (scheme != null && scheme.isNotEmpty) {
      final schemeUri = Uri.parse(scheme);
      try {
        if (await probe(schemeUri)) {
          final launched = await launcher(
            schemeUri,
            mode: LaunchMode.externalApplication,
          );
          if (launched) return true;
        }
      } on Exception catch (e) {
        debugPrint('PaymentAppLauncher scheme failed: $e');
      }
    }

    final marketUri =
        Uri.parse('market://details?id=${app.androidPackageId}');
    try {
      final launched = await launcher(
        marketUri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return true;
    } on Exception catch (e) {
      debugPrint('PaymentAppLauncher market failed: $e');
    }

    final webUri = playStoreWebUrl(app);
    try {
      return await launcher(webUri, mode: LaunchMode.externalApplication);
    } on Exception catch (e) {
      debugPrint('PaymentAppLauncher web fallback failed: $e');
      return false;
    }
  }

  /// Public web Play Store URL for a payment app. Safe to share in
  /// other surfaces (email, copy-to-clipboard).
  static Uri playStoreWebUrl(PaymentApp app) => Uri.parse(
      'https://play.google.com/store/apps/details?id=${app.androidPackageId}');
}

const _brandPaymentApps = {
  'shell': PaymentApp(
    displayName: 'Shell App',
    androidPackageId: 'com.shell.sitibv.shellgoplus',
  ),
  'bp': PaymentApp(
    displayName: 'BPme',
    androidPackageId: 'com.bp.bpme',
  ),
  'aral': PaymentApp(
    displayName: 'Aral Pay',
    androidPackageId: 'de.aral.arelion',
  ),
  'totalenergies': PaymentApp(
    displayName: 'TotalEnergies',
    androidPackageId: 'com.totalenergies.servicesapp',
  ),
  'total': PaymentApp(
    displayName: 'TotalEnergies',
    androidPackageId: 'com.totalenergies.servicesapp',
  ),
  'esso': PaymentApp(
    displayName: 'Esso Extras',
    androidPackageId: 'com.exxonmobil.xsell',
  ),
  'omv': PaymentApp(
    displayName: 'OMV Drive',
    androidPackageId: 'at.omv.business.drive',
  ),
  'eni': PaymentApp(
    displayName: 'Eni Station+',
    androidPackageId: 'it.eni.stationplus',
  ),
  'repsol': PaymentApp(
    displayName: 'Waylet',
    androidPackageId: 'com.waylet',
  ),
};
