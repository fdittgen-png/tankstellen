// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';

import '../../error/exceptions.dart';
import '../../services/service_result.dart';

/// Immutable snapshot of an error suitable for serialization into a
/// GitHub issue prefill.
///
/// Only carries non-sensitive fields — never any GPS coordinates, API
/// keys, full URLs (query params are stripped), user addresses, or
/// trace identifiers that could be cross-referenced with server logs.
class ErrorReportPayload {
  /// The runtime type of the original error (e.g. `ApiException`).
  final String errorType;

  /// Sanitized error message — at most a few hundred characters.
  final String errorMessage;

  /// HTTP status code if the error originated from an HTTP call.
  final int? statusCode;

  /// ISO country code of the active country (e.g. `GB`, `FR`) if known.
  final String? countryCode;

  /// Human-readable source label (e.g. `CMA Fuel Finder`). Pulled from
  /// [ServiceSource.displayName] when the error came from a service.
  final String? sourceLabel;

  /// Accumulated fallback-chain error lines, one per failed service.
  final List<String> fallbackChain;

  /// App version string (e.g. `4.3.0+4062`).
  final String appVersion;

  /// Device / OS label (e.g. `Android 15 · samsung SM-G998B`).
  final String platform;

  /// Active UI locale (e.g. `fr_FR`).
  final String locale;

  /// Wall clock at which the error was captured.
  final DateTime capturedAt;

  /// First few lines of the stack trace (sanitized, no file paths).
  final String? stackExcerpt;

  /// Network connectivity state at time of error (e.g. `wifi`, `mobile`, `none`).
  final String? networkState;

  /// What the user was doing (e.g. `GPS search`, `ZIP search 34120`).
  final String? searchContext;

  /// False when this error must NOT offer a "report a bug" CTA — it is
  /// either a designed-in stop-gap message tied to an already-tracked
  /// issue, or a transient connectivity failure. Filing either as a new
  /// GitHub issue just creates triage noise (#1606).
  final bool reportable;

  /// True when the error is a status-less network / connectivity
  /// failure — the UI shows a "check your connection" hint rather than
  /// a report CTA.
  final bool isTransientNetwork;

  const ErrorReportPayload({
    required this.errorType,
    required this.errorMessage,
    required this.appVersion,
    required this.platform,
    required this.locale,
    required this.capturedAt,
    this.statusCode,
    this.countryCode,
    this.sourceLabel,
    this.fallbackChain = const [],
    this.stackExcerpt,
    this.networkState,
    this.searchContext,
    this.reportable = true,
    this.isTransientNetwork = false,
  });

  /// Stable fingerprint for client-side dedup (#1606) — type + source +
  /// sanitized message. Two reports of the same underlying failure
  /// share a fingerprint, so the reporter can suppress a duplicate.
  String get fingerprint =>
      '$errorType|${sourceLabel ?? ''}|$errorMessage';

  /// Builds a payload from an error object, extracting structured fields
  /// from well-known exception types.
  factory ErrorReportPayload.fromError(
    Object error, {
    required String appVersion,
    required String platform,
    required String locale,
    String? countryCode,
    String? networkState,
    String? searchContext,
    StackTrace? stackTrace,
  }) {
    int? statusCode;
    String? sourceLabel;
    final fallbackChain = <String>[];
    var message = _sanitizeMessage(error.toString());

    if (error is ApiException) {
      statusCode = error.statusCode;
    }
    if (error is ServiceChainExhaustedException) {
      for (final inner in error.errors) {
        if (inner is ServiceError) {
          sourceLabel ??= inner.source.displayName;
          statusCode ??= inner.statusCode;
          fallbackChain.add(
            '${inner.source.displayName}: '
            '${_sanitizeMessage(inner.message)}'
            '${inner.statusCode != null ? " (status ${inner.statusCode})" : ""}',
          );
        } else {
          fallbackChain.add(_sanitizeMessage(inner.toString()));
        }
      }
      if (fallbackChain.isNotEmpty) {
        message = fallbackChain.first;
      }
    }

    final assessment = assessReportability(error);

    return ErrorReportPayload(
      errorType: error.runtimeType.toString(),
      errorMessage: message,
      statusCode: statusCode,
      countryCode: countryCode,
      sourceLabel: sourceLabel,
      fallbackChain: fallbackChain,
      appVersion: appVersion,
      platform: platform,
      locale: locale,
      capturedAt: DateTime.now(),
      stackExcerpt: _extractStackExcerpt(stackTrace),
      networkState: networkState,
      searchContext: searchContext,
      reportable: assessment.reportable,
      isTransientNetwork: assessment.transient,
    );
  }

  /// Assess whether [error] should offer a report CTA (#1606).
  ///
  /// - `reportable` is false for a designed-in stop-gap message tied to
  ///   a tracked issue, or a transient network failure.
  /// - `transient` is true for a status-less connectivity failure.
  ///
  /// Exposed so a UI surface can decide whether to render the "report"
  /// button without building a full payload.
  static ({bool reportable, bool transient}) assessReportability(
      Object error) {
    final msg = _primaryMessage(error);
    final transient = _looksTransientNetwork(error, msg);
    final known = isKnownTrackedIssue(msg);
    return (reportable: !transient && !known, transient: transient);
  }

  /// True when [message] is a deliberate, already-tracked stop-gap
  /// message (e.g. "NSW FuelCheck retired … Tracked in #504") rather
  /// than an unexpected bug. Matches the `Tracked in #NNN` convention.
  static bool isKnownTrackedIssue(String message) =>
      RegExp(r'tracked in #\d+', caseSensitive: false).hasMatch(message);

  /// True when [error] is a status-less network / connectivity failure
  /// (a Dio connection/timeout error, or a message that names a network
  /// failure with no HTTP status) — non-actionable as a bug report.
  static bool _looksTransientNetwork(Object error, String message) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout;
    }
    final lower = message.toLowerCase();
    final mentionsNetwork = lower.contains('network error') ||
        lower.contains('connection failed') ||
        lower.contains('connection error') ||
        lower.contains('failed host lookup') ||
        lower.contains('no internet');
    final hasHttpStatus = RegExp(r'status:?\s*[1-5]\d\d').hasMatch(lower);
    return mentionsNetwork && !hasHttpStatus;
  }

  /// The primary, sanitized message for an error — the first inner
  /// service error for a [ServiceChainExhaustedException], else the
  /// error's own string form.
  static String _primaryMessage(Object error) {
    if (error is ServiceChainExhaustedException) {
      for (final inner in error.errors) {
        if (inner is ServiceError) return _sanitizeMessage(inner.message);
      }
      if (error.errors.isNotEmpty) {
        return _sanitizeMessage(error.errors.first.toString());
      }
    }
    return _sanitizeMessage(error.toString());
  }

  /// Extracts a short, privacy-safe stack trace excerpt.
  ///
  /// Keeps only `package:tankstellen/` frames (no system or third-party
  /// frames) and limits to 8 lines to fit in a GitHub URL.
  static String? _extractStackExcerpt(StackTrace? trace) {
    if (trace == null) return null;
    final lines = trace.toString().split('\n')
        .where((l) => l.contains('package:tankstellen/'))
        .take(8)
        .map((l) => l.trim())
        .toList();
    if (lines.isEmpty) return null;
    return lines.join('\n');
  }

  /// Strips control characters and collapses whitespace so the message
  /// fits into a GitHub issue body without breaking markdown parsing.
  static String _sanitizeMessage(String raw) {
    final collapsed = raw
        .replaceAll(RegExp(r'[\r\n\t]+'), ' ')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
    const maxLen = 400;
    if (collapsed.length <= maxLen) return collapsed;
    return '${collapsed.substring(0, maxLen)}…';
  }
}
