// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:dio/dio.dart';

/// Whether [error] is a connection-LAYER transient — an offline / no-network
/// / connection-reset failure rather than a real server error (#2703).
///
/// Lifted out of `PrixCarburantsStationService._isOffline` (#2524) so the
/// trace de-noise gate ([TraceRecorder]) and the FR service share ONE
/// classification that cannot drift. A "Failed host lookup" SocketException
/// surfaces from Dio either as [DioExceptionType.connectionError] or, on some
/// platforms, as a [DioExceptionType.unknown] wrapping the raw SocketException;
/// a slow/refused connection arrives as one of the *timeout types; a low-level
/// `HttpException` ("Connection closed"/"Software caused connection abort")
/// is the raw socket layer giving up. All mean "the device has no working
/// connection right now", which is expected and already handled by returning
/// empty / skipping — so it must NOT pollute the error spool.
///
/// Deliberately NARROW: a [DioExceptionType.badResponse] (a 4xx/5xx the server
/// actually answered) is a REAL error and returns `false` here, so it still
/// persists as a trace. This does NOT route through `failureKindFromDio`
/// (which maps 5xx → network) precisely so a server error is never suppressed.
bool isOfflineDioException(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return true;
      case DioExceptionType.unknown:
        // i18n-ignore: matching a platform exception class name, not UI text.
        return error.error?.runtimeType.toString().contains('SocketException') ??
            false;
      case DioExceptionType.badResponse:
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
        return false;
    }
  }
  // A bare low-level connection abort/close from the socket layer.
  if (error is HttpException) return true;
  return false;
}

/// Whether [error] is an OFFLINE / no-network / host-lookup transient — a
/// SUPERSET of [isOfflineDioException] that also recognises the offline
/// shapes which arrive WITHOUT a Dio wrapper (#2745):
///
///  - a [SocketException] (or a Dio one) whose message reports a failed
///    host lookup / unreachable network — the device simply has no DNS;
///  - the supabase_flutter `AuthRetryableFetchException`, which wraps a
///    `SocketException` ("Failed host lookup" / "No address associated with
///    hostname") when the device is offline (#2745 traces #2–4);
///  - a `PlatformException(IO_ERROR / UNAVAILABLE)` from the on-device
///    geocoder, which the OS raises when the geocoding backend can't be
///    reached offline (#2745 trace #7).
///
/// Used by the [TraceRecorder] de-noise gate and the offline-tolerant
/// fallback sites (Nominatim / native geocoder) so a genuinely offline
/// device does not spool an ERROR for a call it was always going to lose.
///
/// Deliberately NARROW by shape + message, NOT by exception family: a
/// `PlatformException` that is NOT an offline IO error, an
/// `AuthRetryableFetchException` whose cause is a real 5xx (no offline
/// substring), and any non-offline failure return `false` so a GENUINE
/// failure still ERROR-logs. The match is the broadest offline signal that
/// stays free of false positives — it never inspects HTTP status codes.
bool isOfflineError(Object error) {
  if (isOfflineDioException(error)) return true;
  // A `DioException[unknown]` can wrap a raw [HttpException] connection-abort
  // (the FR feed field trace #1) — `isOfflineDioException` only inspects a
  // wrapped SocketException for the `unknown` type, so unwrap + re-classify
  // the inner error here (#2745).
  if (error is DioException) {
    final inner = error.error;
    if (inner != null && inner != error && isOfflineError(inner)) return true;
  }
  if (error is SocketException) return _looksOffline(error.toString());
  final typeName = error.runtimeType.toString();
  // The supabase_flutter retryable-fetch wrapper carries the underlying
  // socket message in its `toString()` (#2745). Match by type name + the
  // offline substring so a retryable fetch caused by a real server blip
  // (no offline substring) still persists.
  // i18n-ignore: matching a platform/library exception class name, not UI.
  if (typeName.contains('AuthRetryableFetchException')) {
    return _looksOffline(error.toString());
  }
  // On-device geocoder offline: `PlatformException(IO_ERROR, …UNAVAILABLE…)`
  // / a no-network platform-channel IO error (#2745 trace #7).
  // i18n-ignore: matching a platform exception class name, not UI text.
  if (typeName.contains('PlatformException')) {
    final msg = error.toString().toUpperCase();
    return msg.contains('UNAVAILABLE') ||
        (msg.contains('IO_ERROR') && msg.contains('NETWORK'));
  }
  return false;
}

/// True when [message] carries one of the offline / no-network / failed
/// host-lookup substrings. Matched case-insensitively. Kept in sync with
/// `friendlyAuthError`'s network-family substrings (#2745).
bool _looksOffline(String message) {
  final m = message.toUpperCase();
  return m.contains('FAILED HOST LOOKUP') ||
      m.contains('NO ADDRESS ASSOCIATED WITH HOSTNAME') ||
      m.contains('NETWORK IS UNREACHABLE') ||
      m.contains('SOFTWARE CAUSED CONNECTION ABORT') ||
      m.contains('CONNECTION CLOSED') ||
      m.contains('CONNECTION RESET') ||
      m.contains('ERRNO = 7');
}
