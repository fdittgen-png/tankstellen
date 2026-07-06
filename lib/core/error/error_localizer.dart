// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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
  static String localize(Object error, AppLocalizations l10n) {
    if (error is ApiException) {
      if (error.statusCode != null && error.statusCode! >= 500) {
        return l10n.errorServer;
      }
      if (error.statusCode == 403 || error.statusCode == 401) {
        return l10n.errorApiKey;
      }
      return l10n.errorNetwork;
    }

    if (error is LocationException) {
      return l10n.errorLocation;
    }

    if (error is NoApiKeyException) {
      return l10n.errorNoApiKey;
    }

    if (error is NoEvApiKeyException) {
      return l10n.errorNoEvApiKey;
    }

    if (error is UpstreamCertificateException) {
      // ARB message carries a `{host}` placeholder so the user knows who to
      // contact. Fallback mirrors the ARB wording in English (#837).
      return l10n.errorUpstreamCertExpired(error.host);
    }

    if (error is ServiceChainExhaustedException) {
      return l10n.errorAllServicesFailed;
    }

    if (error is CacheException) {
      return l10n.errorCache;
    }

    if (error is DioException) {
      return _localizeDioError(error, l10n);
    }

    // Fallback for unknown errors
    return l10n.errorUnknown;
  }

  static String _localizeDioError(DioException error, AppLocalizations l10n) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      // dio 5.10 — the transform phase timing out is a timeout like the rest.
      case DioExceptionType.transformTimeout:
        return l10n.errorTimeout;
      case DioExceptionType.connectionError:
        return l10n.errorNoConnection;
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode ?? 0;
        if (code >= 500) {
          return l10n.errorServer;
        }
        return l10n.errorNetwork;
      case DioExceptionType.cancel:
        return l10n.errorCancelled;
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return l10n.errorNetwork;
    }
  }
}
