// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:sentry_flutter/sentry_flutter.dart';

import 'bounded_diagnostic_map.dart';
import 'diagnostic_field_policy.dart';
import 'models/error_trace.dart' as et;

/// Canonical diagnostic redaction for storage, exports and Sentry (#4478).
/// Pure input transformations: no IO, consent changes or user-backup handling.
/// Sensitive assignments with ambiguous legacy formatting are omitted whole;
/// this is not a guarantee against arbitrary personal prose.
class PiiScrubber {
  PiiScrubber._();

  /// Replacement marker for any redacted email address.
  static const String emailMarker = '[REDACTED_EMAIL]';

  /// Replacement marker for any redacted lat/lng coordinate pair.
  static const String coordMarker = '[REDACTED_COORD]';

  /// Replacement marker for any redacted token-like opaque string.
  static const String tokenMarker = '[REDACTED_TOKEN]';

  /// Replacement marker for breadcrumb messages truncated for length.
  static const String truncatedMarker = '[REDACTED_LONG]';

  /// Maximum allowed length of a breadcrumb message before truncation.
  /// Above this, the entire body is replaced with [truncatedMarker]
  /// — better to lose context than to ship a paragraph of route args.
  static const int maxBreadcrumbMessageLength = 500;

  static const int maxTextLength = 16384;
  static const int maxValueCount = 16384;
  static const int maxDepth = 16;
  static const int maxTotalTextLength = 512 * 1024;
  static const String omittedMarker = '[REDACTED_CONTEXT]';
  static const String macMarker = '[REDACTED_MAC]';

  static final _macRegex = RegExp(
    r'\b(?:[0-9a-f]{2}(?::|-|%3a|%2d|\\u003a|\\u002d)){5}[0-9a-f]{2}\b|'
    r'\b[0-9a-f]{4}(?:\.[0-9a-f]{4}){2}\b|\b[0-9a-f]{12}\b',
    caseSensitive: false,
  );
  static final _vinRegex = RegExp(r'\b[A-HJ-NPR-Z0-9]{17}\b');
  static final _urlRegex = RegExp(r'''https?://[^\s<>"'\\]+''');
  static final _bearerRegex = RegExp(
    r'\b(?:Bearer|Basic)\s+[A-Za-z0-9._~+/-]+=*',
    caseSensitive: false,
  );
  static final _credentialAssignment = RegExp(
    r'\b(?:api[_-]?key|access[_-]?token|refresh[_-]?token|authorization|auth|token|'
    r'credentials?|session[_-]?id|'
    r'password|secret|vin(?:[_ -]?tail)?|(?:active[_ -]?)?profile[_ -]?(?:id|name)|'
    r'user(?:[_ -]?(?:id|name|data))?|profile|receipt(?:[_ -]?(?:id|number|text))?|'
    r'ocr[_ -]?(?:text|results?)|'
    r'(?:adapter|device)[_ -]?(?:name|address))\b["\\\s]*[:=]',
    caseSensitive: false,
  );
  static final _safeClass = RegExp(
    r'^[A-Za-z_$][A-Za-z0-9_$]*(?:Exception|Error|Repository|Provider|'
    r'Notifier|Controller|Service|Collector|Recorder)$',
  );
  static final _framePrefix = RegExp(r'^\s*(?:#\d+\s+|at\s+)[\w.$<> ]*$');
  static final _packagePrefix = RegExp(r'\(package:[\w./-]*$');
  static final _artifactPrefix = RegExp(
    r'(?:build\s?id|sourcesha|source\s?sha|commit)\s*[:=]\s*$',
    caseSensitive: false,
  );

  /// Standard email — local + `@` + domain. Avoids matching trailing
  /// punctuation by anchoring the TLD to a word boundary.
  static final RegExp _emailRegex = RegExp(
    r'[^\s@<>()\[\]{}"\\,:;=]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b',
  );

  /// Coordinate-shaped decimal pairs, comma- or cache-key-separated.
  static final RegExp _coordRegex = RegExp(
    r'-?\d{1,3}\.\d{2,}(?:\s*,\s*|_)-?\d{1,3}\.\d{2,}',
  );

  /// #3145/#3612 — explicit coordinate keys, including rounded values.
  /// A plain price (`diesel: 1.789`) is not a coordinate key.
  static final RegExp _coordKeyValueRegex = RegExp(
    r'\b(?:lat|latitude|lng|lon|longitude)\s*[=:]\s*-?\d{1,3}(?:\.\d+)?',
    caseSensitive: false,
  );

  /// Coordinate keys inside JSON, including escaped JSON strings (#4478).
  static final RegExp _coordJsonKeyRegex = RegExp(
    r'\\?"(?:lat|latitude|lng|lon|longitude)\\?"\s*:\s*\\?"?-?\d{1,3}(?:\.\d+)?',
    caseSensitive: false,
  );

  /// Token-like string: at least 20 alphanumeric characters in a row,
  /// no spaces. Catches API keys, JWT segments, anonymous Supabase
  /// session ids, and station-id+coord composites. Anchored on word
  /// boundaries so we don't redact half a sentence.
  static final RegExp _tokenRegex = RegExp(r'\b[A-Za-z0-9_-]{20,}\b');

  /// #3612 — remove a JWT whole, including short header/signature segments,
  /// before applying the generic token rule. Versions and file names stay.
  static final RegExp _jwtRegex = RegExp(
    r'\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b',
  );

  // --------------------------------------------------------------------------
  // Public API
  // --------------------------------------------------------------------------

  /// Returns [text] with every email, coordinate pair, and token-like
  /// substring replaced with a redaction marker. Order matters: emails
  /// and coords are matched first because they have stricter patterns
  /// than the generic token rule.
  ///
  /// Returns `null` if [text] is `null`. Returns the empty string for
  /// an empty input. Never throws.
  static String? scrubText(String? text, {bool preserveSymbols = false}) {
    if (text == null) return null;
    if (text.isEmpty) return text;
    if (text.length > maxTextLength) return truncatedMarker;
    var out = text.replaceAll(_emailRegex, emailMarker);
    out = out.replaceAll(_bearerRegex, tokenMarker);
    out = out.replaceAllMapped(_urlRegex, (match) {
      final uri = Uri.tryParse(match[0]!);
      return uri == null
          ? omittedMarker
          : '${uri.scheme}://${uri.host}/[REDACTED_PATH]';
    });
    // An unstructured credential assignment cannot be parsed safely in
    // every legacy/native format. Omit it whole, never a secret prefix.
    if (_credentialAssignment.hasMatch(out)) return omittedMarker;
    out = out.replaceAll(_macRegex, macMarker);
    out = out.replaceAllMapped(
      _vinRegex,
      (match) => RegExp(r'[0-9]').hasMatch(match[0]!) ? tokenMarker : match[0]!,
    );
    out = out.replaceAll(_coordRegex, coordMarker);
    out = out.replaceAll(_coordKeyValueRegex, coordMarker);
    out = out.replaceAll(_coordJsonKeyRegex, coordMarker);
    // JWT before the generic token rule so the whole three-segment token
    // collapses into ONE marker instead of per-segment fragments (#3612).
    out = out.replaceAll(_jwtRegex, tokenMarker);
    final message = out;
    out = out.replaceAllMapped(_tokenRegex, (match) {
      final token = match[0]!;
      if (_safeClass.hasMatch(token)) return token;
      final lineStart = message.lastIndexOf('\n', match.start) + 1;
      final prefix = message.substring(lineStart, match.start);
      if (DiagnosticFieldPolicy.artifact(token) &&
          _artifactPrefix.hasMatch(prefix)) {
        return token;
      }
      if (preserveSymbols) {
        if (_framePrefix.hasMatch(prefix) || _packagePrefix.hasMatch(prefix)) {
          return token;
        }
      }
      return tokenMarker;
    });
    return out;
  }

  /// Canonical bounded boundary for diagnostic JSON only, never user backups.
  /// Unsupported values are omitted rather than stringified; unknown keys
  /// and deep/large payloads cannot create a raw-copy escape hatch (#4478).
  static Map<String, dynamic> scrubMap(
    Map<dynamic, dynamic> raw, {
    DiagnosticScope scope = DiagnosticScope.unknown,
  }) {
    return scrubBoundedDiagnosticMap(
      raw,
      scrubField: (path, value) => _scrubField(path, value, scope),
      scrubKey: (key) =>
          DiagnosticFieldPolicy.schemaKey(key) ? key : scrubText(key)!,
      maxValues: maxValueCount,
      maxDepth: maxDepth,
      maxTextLength: maxTextLength,
      maxTotalTextLength: maxTotalTextLength,
      omittedMarker: omittedMarker,
      truncatedMarker: truncatedMarker,
    );
  }

  static Object? _scrubField(
    List<String> path,
    Object? value,
    DiagnosticScope scope,
  ) {
    if (value != null && DiagnosticFieldPolicy.privateField(path)) {
      return tokenMarker;
    }
    if (value is! String) return value;
    if (DiagnosticFieldPolicy.preserve(path, value, scope)) return value;
    final field = path.isEmpty ? '' : path.last.toLowerCase();
    return scrubText(
      value,
      preserveSymbols: field == 'stack' || field == 'stacktrace',
    );
  }

  /// Truncates [message] when it exceeds [maxBreadcrumbMessageLength]
  /// AND additionally runs [scrubText] against the result.
  ///
  /// Breadcrumbs are the most common source of accidental PII (route
  /// arguments, request paths, search queries) so we apply both rules
  /// instead of just one.
  static String? scrubBreadcrumbMessage(String? message) {
    if (message == null) return null;
    if (message.length > maxBreadcrumbMessageLength) {
      return truncatedMarker;
    }
    return scrubText(message);
  }

  // --------------------------------------------------------------------------
  // Sentry event mutation
  // --------------------------------------------------------------------------

  /// In-place scrub of a Sentry event before it leaves the device.
  ///
  /// Mutates the event so the SDK still has a valid object to ship —
  /// returning `null` would cause Sentry to drop the event entirely,
  /// which is *more* aggressive than we need (the operator still wants
  /// to see scrubbed exceptions for triage).
  ///
  /// Strips:
  /// * `event.user` — username/email/ip will leak through Sentry's
  ///   automatic user enrichment; we never need that to triage.
  /// * `event.request` — http path/query may carry station ids or
  ///   user-typed search strings.
  /// * `event.message.formatted` — runs through [scrubText].
  /// * `event.exceptions[*].value` — runs through [scrubText].
  /// * `event.breadcrumbs[*].message` — runs through
  ///   [scrubBreadcrumbMessage] (length cap + regex).
  ///
  /// Returns the same [event] for chaining.
  static SentryEvent scrubSentryEvent(SentryEvent event) {
    event.user = null;
    event.request = null;

    final message = event.message;
    if (message != null) {
      final scrubbed = scrubText(message.formatted);
      if (scrubbed != null && scrubbed != message.formatted) {
        // SentryMessage.formatted is mutable; set in place so we don't
        // need to clone the surrounding template/params metadata.
        message.formatted = scrubbed;
      }
    }

    final exceptions = event.exceptions;
    if (exceptions != null) {
      for (final exception in exceptions) {
        exception.value = scrubText(exception.value);
      }
    }

    final breadcrumbs = event.breadcrumbs;
    if (breadcrumbs != null) {
      for (final crumb in breadcrumbs) {
        crumb.message = scrubBreadcrumbMessage(crumb.message);
      }
    }

    return event;
  }

  // --------------------------------------------------------------------------
  // ErrorTrace (TraceUploader) scrub
  // --------------------------------------------------------------------------

  /// Returns a copy of [trace] with the same redaction policy applied to
  /// every free-form string field — `errorMessage`, the route + API +
  /// search-params snapshot in `appState`, every breadcrumb action /
  /// detail, and any `serviceChainState.attempts[*].errorMessage`.
  ///
  /// Stack data is scrubbed too, preserving recognized method/frame symbols.
  ///
  /// Pure function — `ErrorTrace` is a freezed record, so we copy.
  static et.ErrorTrace scrubErrorTrace(et.ErrorTrace trace) {
    return trace.copyWith(
      errorMessage: scrubText(trace.errorMessage) ?? trace.errorMessage,
      stackTrace: scrubText(trace.stackTrace, preserveSymbols: true)!,
      appState: trace.appState.copyWith(
        activeProfileId: null,
        activeProfileName: null,
        activeRoute: scrubText(trace.appState.activeRoute),
        lastApiEndpoint: scrubText(trace.appState.lastApiEndpoint),
        lastSearchParams: scrubText(trace.appState.lastSearchParams),
      ),
      serviceChainState: trace.serviceChainState == null
          ? null
          : trace.serviceChainState!.copyWith(
              attempts: [
                for (final attempt in trace.serviceChainState!.attempts)
                  attempt.copyWith(
                    errorMessage: scrubText(attempt.errorMessage),
                    stackTrace: scrubText(
                      attempt.stackTrace,
                      preserveSymbols: true,
                    ),
                  ),
              ],
            ),
      breadcrumbs: [
        for (final crumb in trace.breadcrumbs)
          crumb.copyWith(
            action: scrubBreadcrumbMessage(crumb.action) ?? crumb.action,
            detail: scrubBreadcrumbMessage(crumb.detail),
          ),
      ],
    );
  }
}
