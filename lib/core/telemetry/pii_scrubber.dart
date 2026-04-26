import 'package:sentry_flutter/sentry_flutter.dart';

import '../error_tracing/models/error_trace.dart' as et;

/// Pure, side-effect-free PII redaction primitives shared between the
/// Sentry `beforeSend` hook (#1109) and the local `TraceUploader` payload
/// pipeline.
///
/// **Scope.** The user can disable telemetry entirely (consent gate in
/// `AppInitializer`), but once they have opted in we still must not ship
/// PII that an exception/breadcrumb might incidentally carry — emails,
/// raw lat/lng pairs, API tokens, free-form route arguments, or the
/// Sentry-injected `user` / `request` blocks.
///
/// **Design.** All public methods are pure functions of their input —
/// no I/O, no globals, no Riverpod — so they can be unit-tested without
/// any test harness and reused from both the Flutter UI isolate (Sentry
/// `beforeSend`) and the background isolate (`TraceUploader.upload`).
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

  // --------------------------------------------------------------------------
  // Regex catalog
  // --------------------------------------------------------------------------

  /// Standard email — local + `@` + domain. Avoids matching trailing
  /// punctuation by anchoring the TLD to a word boundary.
  static final RegExp _emailRegex = RegExp(
    r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b',
  );

  /// Lat/lng pair — two signed decimals separated by a comma (with
  /// optional whitespace). Each component must be a plausible coordinate
  /// (latitude up to 90, longitude up to 180), so we tolerate -90..90
  /// and -180..180 with up to 6 decimal places. We deliberately use a
  /// loose numeric pattern (-?\d+\.\d+) and bound each side: it's
  /// cheaper than a strict bounded regex and still rejects obvious
  /// non-coordinates like timestamps.
  static final RegExp _coordRegex = RegExp(
    r'-?\d{1,3}\.\d{2,}\s*,\s*-?\d{1,3}\.\d{2,}',
  );

  /// Token-like string: at least 20 alphanumeric characters in a row,
  /// no spaces. Catches API keys, JWT segments, anonymous Supabase
  /// session ids, and station-id+coord composites. Anchored on word
  /// boundaries so we don't redact half a sentence.
  static final RegExp _tokenRegex = RegExp(r'\b[A-Za-z0-9_-]{20,}\b');

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
  static String? scrubText(String? text) {
    if (text == null) return null;
    if (text.isEmpty) return text;
    var out = text.replaceAll(_emailRegex, emailMarker);
    out = out.replaceAll(_coordRegex, coordMarker);
    out = out.replaceAll(_tokenRegex, tokenMarker);
    return out;
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
  /// We deliberately do NOT touch `stackTrace`: it's structurally
  /// formatted and dropping the regex on it tends to swallow real
  /// frame paths. If a stack frame *does* leak PII the right answer is
  /// to fix the throwing code, not to mangle the frame.
  ///
  /// Pure function — `ErrorTrace` is a freezed record, so we copy.
  static et.ErrorTrace scrubErrorTrace(et.ErrorTrace trace) {
    return trace.copyWith(
      errorMessage: scrubText(trace.errorMessage) ?? trace.errorMessage,
      appState: trace.appState.copyWith(
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
