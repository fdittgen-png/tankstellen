// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';

/// Typed classification of a data-layer failure.
///
/// Replaces the fragile string-prefix sniffing the fallback chain used to do
/// on `ApiException.message` (#2255). Every HTTP/data error funnelled through
/// [ApiException]/`ServiceError` carries one of these so callers can branch on
/// the *kind* of failure (transient vs terminal, rate-limited, …) without
/// parsing English diagnostic text.
enum FailureKind {
  /// Connection-class failure — DNS, socket reset, no route to host. A retry
  /// or a fallback to cache may recover.
  network,

  /// Connect / send / receive timeout. Transient; a single retry often works.
  timeout,

  /// HTTP 429, or any response carrying a `Retry-After`. Callers must back off
  /// (honouring [ApiException.retryAfter] when present) rather than hammer.
  rateLimited,

  /// Response body could not be parsed / was malformed. Not transient — a
  /// retry returns the same broken payload.
  parse,

  /// HTTP 401 / 403, or a missing API key. Not transient.
  auth,

  /// HTTP 404. Not transient.
  notFound,

  /// The provider does not support this endpoint (e.g. single-station detail
  /// where only bulk listing exists). Not transient.
  unsupported,

  /// Anything not otherwise classified (incl. 4xx other than the above,
  /// cancellation, certificate errors). Treated as terminal by the chain.
  unknown;
}

/// Maps a [DioException] to a [FailureKind].
///
/// Mapping (per #2255):
/// - connectionTimeout / sendTimeout / receiveTimeout → [FailureKind.timeout]
/// - connectionError → [FailureKind.network]
/// - badResponse 429 → [FailureKind.rateLimited]
/// - badResponse 401/403 → [FailureKind.auth]
/// - badResponse 404 → [FailureKind.notFound]
/// - badResponse 5xx → [FailureKind.network] (server-side blip the chain's
///   one-shot transient retry should absorb, matching the prior 5xx behaviour)
/// - everything else (cancel, badCertificate, unknown, other 4xx) →
///   [FailureKind.unknown]
FailureKind failureKindFromDio(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    // dio 5.10 — the transform phase timing out is a timeout like the rest.
    case DioExceptionType.transformTimeout:
      return FailureKind.timeout;
    case DioExceptionType.connectionError:
      return FailureKind.network;
    case DioExceptionType.badResponse:
      return failureKindFromStatus(e.response?.statusCode);
    case DioExceptionType.cancel:
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      return FailureKind.unknown;
  }
}

/// Maps an HTTP status code to a [FailureKind].
///
/// 5xx → [FailureKind.network] so the chain's transient retry still fires for
/// the same status codes it did before (#2255 regression guard); 429 →
/// [FailureKind.rateLimited]; 401/403 → [FailureKind.auth]; 404 →
/// [FailureKind.notFound]; anything else → [FailureKind.unknown].
FailureKind failureKindFromStatus(int? statusCode) {
  if (statusCode == null) return FailureKind.unknown;
  if (statusCode == 429) return FailureKind.rateLimited;
  if (statusCode == 401 || statusCode == 403) return FailureKind.auth;
  if (statusCode == 404) return FailureKind.notFound;
  if (statusCode >= 500 && statusCode < 600) return FailureKind.network;
  return FailureKind.unknown;
}
