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
      } on Exception catch (e, st) {
        debugPrint('PaymentAppLauncher scheme failed: $e\n$st');
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
    } on Exception catch (e, st) {
      debugPrint('PaymentAppLauncher market failed: $e\n$st');
    }

    final webUri = playStoreWebUrl(app);
    try {
      return await launcher(webUri, mode: LaunchMode.externalApplication);
    } on Exception catch (e, st) {
      debugPrint('PaymentAppLauncher web fallback failed: $e\n$st');
      return false;
    }
  }

  /// Public web Play Store URL for a payment app. Safe to share in
  /// other surfaces (email, copy-to-clipboard).
  static Uri playStoreWebUrl(PaymentApp app) => Uri.parse(
      'https://play.google.com/store/apps/details?id=${app.androidPackageId}');
}

/// Registered branded payment apps. Only entries whose Android
/// package ID has been verified to resolve to a live Play Store
/// listing belong here — everything else is a dead link on the
/// user's device (#736). When an entry is suspicious, remove it
/// rather than leave it: a missing "Pay with X" chip is far better
/// UX than a chip that launches the Play Store on a 404 page.
///
/// Adding a new brand? Before committing:
/// 1. Open `https://play.google.com/store/apps/details?id=<id>`
///    in an incognito browser. Confirm the listing loads.
/// 2. Add the entry here.
/// 3. Run `flutter test --tags=network test/core/utils/payment_app_launcher_test.dart`
///    — the network-tagged probe asserts the Play Store page is live.
///
/// The removed entries from before #736 (Aral, TotalEnergies/Total,
/// Esso, OMV, Eni, Repsol/Waylet) had guessed package IDs that the
/// user confirmed resolve to 404 Play Store pages. Re-add only with
/// verified IDs.
/// Empty pending verified Play Store IDs (#736). Shell's
/// `com.shell.sitibv.shellgoplus` and BP's `com.bp.bpme` were also
/// confirmed 404 by the live-probe test along with the other brands.
/// The whole branded-app catalog was guesswork.
///
/// Re-adding a brand requires running:
/// `flutter test --tags=network test/core/utils/payment_app_launcher_test.dart`
/// against the candidate ID and getting a green probe. The probe
/// fetches the Play Store page and asserts the page body echoes the
/// package id — catching silent redirects to the store home.
const _brandPaymentApps = <String, PaymentApp>{};
