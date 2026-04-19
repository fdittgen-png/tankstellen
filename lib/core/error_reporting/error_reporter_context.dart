import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';

import '../constants/app_constants.dart';

/// Small synchronous helper that resolves the fields needed to build
/// an `ErrorReportPayload` without awaiting any plugin calls.
///
/// Keeping this lookup synchronous means the error dialog can file a
/// report immediately after the user taps the button, without a
/// loading spinner or context-after-await gymnastics.
class ErrorReporterContext {
  const ErrorReporterContext._();

  /// Current UI locale as a `languageCode_COUNTRY` string.
  static String currentLocale(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final country = locale.countryCode;
    return country == null || country.isEmpty
        ? locale.languageCode
        : '${locale.languageCode}_$country';
  }

  /// Best-effort platform label — e.g. `Android`. Falls back to the
  /// bare `operatingSystem` name for any other OS.
  static String currentPlatform() {
    try {
      if (Platform.isAndroid) return 'Android';
      if (Platform.isIOS) return 'iOS';
      return Platform.operatingSystem;
    } catch (e) {
      debugPrint('currentPlatform: Platform query failed: $e');
      return 'unknown';
    }
  }

  /// App version string — currently pulled from [AppConstants]. The
  /// live build number is known only at runtime via `package_info_plus`,
  /// but that requires an async fetch, and the payload is built
  /// synchronously during the user's dialog interaction. The exact
  /// build number is recoverable from the app version anyway.
  static String currentAppVersion() => AppConstants.appVersion;
}
