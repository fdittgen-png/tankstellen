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
