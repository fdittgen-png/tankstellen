// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'failure_kind.dart';

export 'failure_kind.dart';

/// Base class for all domain exceptions in the app.
///
/// Sealed so that `switch` on [AppException] is exhaustive and all
/// catch blocks using `on AppException` will match any app error.
///
/// ## `message` is a developer diagnostic — not user-facing (#1663)
///
/// Every [message] string here (and in the data-layer throw sites that
/// raise these — `ApiException('Invalid MITECO response')`, etc.) is an
/// English diagnostic for logs and [toString]. It is deliberately NOT
/// localized: the user-facing path is `ErrorLocalizer.localize`, which
/// maps each exception *type* (and HTTP status) to a translated ARB
/// string and never reads `message`. UI code must therefore route every
/// error through `ErrorLocalizer` rather than showing `e.message` /
/// `e.toString()` directly.
sealed class AppException implements Exception {
  const AppException();

  /// English developer diagnostic — see the class doc. Not for display.
  String get message;
}

class ApiException extends AppException {
  @override
  final String message;
  final int? statusCode;

  /// Typed classification of this failure (#2255). Lets callers branch on the
  /// *kind* (transient vs terminal, rate-limited, …) instead of sniffing the
  /// English [message] prefix. Defaults to [FailureKind.unknown] for the rare
  /// throw site that has no better information.
  final FailureKind kind;

  /// When [kind] is [FailureKind.rateLimited], the upstream-suggested backoff
  /// parsed from the `Retry-After` header (seconds or HTTP-date). Null when the
  /// header was absent or unparseable.
  final Duration? retryAfter;

  const ApiException({
    required this.message,
    this.statusCode,
    this.kind = FailureKind.unknown,
    this.retryAfter,
  });

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

class CacheException extends AppException {
  @override
  final String message;
  const CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

class LocationException extends AppException {
  @override
  final String message;
  const LocationException({required this.message});

  @override
  String toString() => 'LocationException: $message';
}

class NoApiKeyException extends AppException {
  const NoApiKeyException();

  @override
  String get message => 'No API key configured. Please set up your Tankerkoenig API key.';

  @override
  String toString() => message;
}

/// Thrown when the user tries to perform an EV charging-station lookup
/// without an OpenChargeMap key configured. Routed through ErrorLocalizer
/// so the UI message is translated.
class NoEvApiKeyException extends AppException {
  const NoEvApiKeyException();

  @override
  String get message =>
      'OpenChargeMap API key not configured. Set it up in Settings to search for EV charging stations.';

  @override
  String toString() => message;
}

/// Thrown when an upstream provider serves an invalid, expired, or otherwise
/// untrusted TLS certificate. We never bypass cert validation (MITM risk), so
/// the only remedy is to surface a clear, actionable message telling the user
/// that the data provider — not the app — is misconfigured, and (if known)
/// which host is affected so the user can contact the data source (#837).
class UpstreamCertificateException extends AppException {
  /// Upstream hostname whose certificate failed validation (e.g.
  /// `datos.energia.gob.ar`). Used in the localized message so the user
  /// knows which provider to contact.
  final String host;

  /// Country code (ISO-3166-1 alpha-2, lowercase) of the affected provider,
  /// e.g. `ar`. Lets the UI prefix the message with the country name.
  final String? countryCode;

  /// Underlying error detail (usually the Dio / X509 error text) for
  /// diagnostics — NOT shown to the user as-is.
  final String? detail;

  const UpstreamCertificateException({
    required this.host,
    this.countryCode,
    this.detail,
  });

  @override
  String get message =>
      'Upstream certificate invalid or expired for $host'
      '${detail == null ? '' : ' ($detail)'}.';

  @override
  String toString() => 'UpstreamCertificateException: $message';
}

/// Thrown when every service in a fallback chain has failed,
/// including the cache. Carries accumulated errors from each step
/// so the UI can report exactly what went wrong.
class ServiceChainExhaustedException extends AppException {
  final List<dynamic> errors;

  const ServiceChainExhaustedException({required this.errors});

  @override
  String get message {
    if (errors.isEmpty) return 'All services unavailable.';
    final details = errors.map((e) => e.toString()).join('\n');
    return 'All services failed:\n$details';
  }

  @override
  String toString() => message;
}
