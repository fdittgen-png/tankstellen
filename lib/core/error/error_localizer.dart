import 'package:dio/dio.dart';
import '../../l10n/app_localizations.dart';
import 'exceptions.dart';

/// Maps exception types to user-friendly localized messages.
///
/// Use instead of `e.toString()` or `e.message` in the UI to avoid
/// showing raw DioException/StackTrace text to end users.
class ErrorLocalizer {
  ErrorLocalizer._();

  /// Convert any error to a user-friendly message using localized strings.
  /// Falls back to English when l10n is unavailable.
  static String localize(Object error, AppLocalizations? l10n) {
    if (error is ApiException) {
      if (error.statusCode != null && error.statusCode! >= 500) {
        return l10n?.errorServer ?? 'Server error. Please try again later.';
      }
      if (error.statusCode == 403 || error.statusCode == 401) {
        return l10n?.errorApiKey ?? 'Invalid API key. Check your settings.';
      }
      return l10n?.errorNetwork ?? 'Network error. Check your connection.';
    }

    if (error is LocationException) {
      return l10n?.errorLocation ?? 'Could not determine your location.';
    }

    if (error is NoApiKeyException) {
      return l10n?.errorNoApiKey ?? 'No API key configured. Go to Settings to add one.';
    }

    if (error is NoEvApiKeyException) {
      return l10n?.errorNoEvApiKey ??
          'OpenChargeMap API key not configured. Add one in Settings to search EV charging stations.';
    }

    if (error is ServiceChainExhaustedException) {
      return l10n?.errorAllServicesFailed ?? 'Could not load data. Check your connection and try again.';
    }

    if (error is CacheException) {
      return l10n?.errorCache ?? 'Local data error. Try clearing the cache.';
    }

    if (error is DioException) {
      return _localizeDioError(error, l10n);
    }

    // Fallback for unknown errors
    return l10n?.errorUnknown ?? 'An unexpected error occurred.';
  }

  static String _localizeDioError(DioException error, AppLocalizations? l10n) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return l10n?.errorTimeout ?? 'Connection timed out. Please try again.';
      case DioExceptionType.connectionError:
        return l10n?.errorNoConnection ?? 'No internet connection.';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode ?? 0;
        if (code >= 500) {
          return l10n?.errorServer ?? 'Server error. Please try again later.';
        }
        return l10n?.errorNetwork ?? 'Network error. Check your connection.';
      case DioExceptionType.cancel:
        return l10n?.errorCancelled ?? 'Request was cancelled.';
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return l10n?.errorNetwork ?? 'Network error. Check your connection.';
    }
  }
}
