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
  });

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
    );
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
