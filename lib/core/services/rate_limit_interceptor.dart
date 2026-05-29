// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// `RequestOptions.extra` key under which a parsed `Retry-After` [Duration] is
/// stashed by [RateLimitInterceptor] when a 429 / Retry-After response is seen,
/// so that the downstream `throwApiException` converter can surface it on the
/// resulting `ApiException.retryAfter` (#2255).
const String kRetryAfterExtraKey = 'tankstellen.retryAfter';

/// Serialises requests on a single Dio instance so consecutive calls are
/// at least [minInterval] apart (with randomised jitter), and reacts to a
/// `429 Too Many Requests` / `Retry-After` response by widening that interval
/// into a per-service cooldown so callers back off instead of hammering the
/// upstream (#2255).
///
/// This protects rate-limited country APIs (Tankerkoenig, Prix Carburants,
/// MIMIT, …) from a thundering-herd burst on app resume or background
/// refresh. Each Dio instance owns its own interceptor — the gating is
/// per-instance, not global, so unrelated services don't block each other.
///
/// ## Cooldown on 429 / Retry-After
///
/// When [onResponse] or [onError] sees a 429 (or any response carrying a
/// `Retry-After` header), it:
/// 1. parses `Retry-After` (delta-seconds or an HTTP-date) into a [Duration],
/// 2. stashes that [Duration] on `requestOptions.extra[kRetryAfterExtraKey]`
///    so `throwApiException` can surface it as `ApiException.retryAfter`, and
/// 3. sets a cooldown deadline so the *next* request on this Dio waits until at
///    least `now + retryAfter` (falling back to [defaultCooldown] when the
///    header was absent/unparseable). The cooldown only ever widens the
///    existing [minInterval] gate — it never shortens it.
///
/// Use [DioFactory.create] to obtain a Dio with this interceptor already
/// installed; opt out per call site with `rateLimit: null` for endpoints
/// that should fire immediately (user-triggered actions like submitting
/// a station report or uploading an error trace).
class RateLimitInterceptor extends Interceptor {
  RateLimitInterceptor({
    this.minInterval = const Duration(seconds: 1),
    this.jitterBaseMs = 0,
    this.jitterRangeMs = 500,
    this.defaultCooldown = const Duration(seconds: 5),
    Random? random,
    DateTime Function()? clock,
  })  : _random = random ?? Random(),
        _now = clock ?? DateTime.now;

  final Duration minInterval;
  final int jitterBaseMs;
  final int jitterRangeMs;

  /// Cooldown applied after a 429 with no (or an unparseable) `Retry-After`.
  final Duration defaultCooldown;

  final Random _random;
  final DateTime Function() _now;
  DateTime? _lastRequest;

  /// Deadline until which all requests on this Dio are held back after a 429 /
  /// Retry-After. Null when no cooldown is active. Visible for testing so the
  /// cooldown can be asserted without sleeping a real five seconds.
  @visibleForTesting
  DateTime? cooldownUntil;

  Future<void> _gate = Future.value();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Serialise by chaining each call onto the previous one.
    final previous = _gate;
    final current = Completer<void>();
    _gate = current.future;
    try {
      await previous;
      final now = _now();
      // The next request may proceed no earlier than (a) minInterval after the
      // previous one and (b) the active 429 cooldown deadline — whichever is
      // later. Cooldown only ever widens the gate.
      DateTime? earliest;
      if (_lastRequest != null) {
        earliest = _lastRequest!.add(minInterval);
      }
      if (cooldownUntil != null &&
          (earliest == null || cooldownUntil!.isAfter(earliest))) {
        earliest = cooldownUntil;
      }
      if (earliest != null && earliest.isAfter(now)) {
        final remaining = earliest.difference(now);
        final jitter = jitterRangeMs > 0 ? _random.nextInt(jitterRangeMs) : 0;
        await Future<void>.delayed(
          remaining + Duration(milliseconds: jitterBaseMs + jitter),
        );
      }
      _lastRequest = _now();
      // Clear an elapsed cooldown so it doesn't linger.
      if (cooldownUntil != null && !cooldownUntil!.isAfter(_now())) {
        cooldownUntil = null;
      }
    } finally {
      current.complete();
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _applyCooldownIfRateLimited(
      response.statusCode,
      response.headers,
      response.requestOptions,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _applyCooldownIfRateLimited(
      err.response?.statusCode,
      err.response?.headers,
      err.requestOptions,
    );
    handler.next(err);
  }

  /// Detect a 429 / `Retry-After` carrier, parse the delay, stash it on the
  /// request's `extra`, and arm the per-service cooldown.
  void _applyCooldownIfRateLimited(
    int? statusCode,
    Headers? headers,
    RequestOptions options,
  ) {
    final retryAfterRaw = headers?.value('retry-after');
    final isRateLimited = statusCode == 429 || retryAfterRaw != null;
    if (!isRateLimited) return;

    final parsed = parseRetryAfter(retryAfterRaw, now: _now());
    // Surface the parsed delay to throwApiException via extra.
    options.extra[kRetryAfterExtraKey] = parsed;

    final cooldown = parsed ?? defaultCooldown;
    final deadline = _now().add(cooldown);
    // Only ever widen the cooldown.
    if (cooldownUntil == null || deadline.isAfter(cooldownUntil!)) {
      cooldownUntil = deadline;
    }
    debugPrint(
      'RateLimitInterceptor: 429/Retry-After on '
      '${options.uri.path} → cooldown ${cooldown.inMilliseconds} ms',
    );
  }
}

/// Parse a `Retry-After` header value into a [Duration].
///
/// Accepts the two RFC 7231 forms:
/// - **delta-seconds** — a non-negative integer number of seconds, and
/// - **HTTP-date** — an RFC 1123 date; the delay is `date - now` (clamped to
///   ≥ 0).
///
/// Returns `null` for a null/blank/unparseable value. [now] is injectable so
/// the date branch is testable.
Duration? parseRetryAfter(String? raw, {DateTime? now}) {
  if (raw == null) return null;
  final value = raw.trim();
  if (value.isEmpty) return null;

  // delta-seconds form.
  final seconds = int.tryParse(value);
  if (seconds != null) {
    return Duration(seconds: seconds < 0 ? 0 : seconds);
  }

  // HTTP-date form.
  final date = HttpDate.tryParse(value);
  if (date != null) {
    final reference = now ?? DateTime.now();
    final delta = date.difference(reference);
    return delta.isNegative ? Duration.zero : delta;
  }
  return null;
}

/// Extract a `Retry-After` [Duration] from a [DioException] — first from the
/// value the [RateLimitInterceptor] stashed on `requestOptions.extra`, then by
/// parsing the response header directly (covers the path where no interceptor
/// ran, e.g. a unit-test stub).
Duration? retryAfterFromDio(DioException e) {
  final stashed = e.requestOptions.extra[kRetryAfterExtraKey];
  if (stashed is Duration) return stashed;
  return parseRetryAfter(e.response?.headers.value('retry-after'));
}

/// RFC 1123 HTTP-date parsing without an `http` package dependency (Dio only
/// ships header values as strings). Tolerant: returns `null` on any failure.
class HttpDate {
  HttpDate._();

  static const _months = <String, int>{
    'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
    'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
  };

  /// Parse an IMF-fixdate, e.g. `Wed, 21 Oct 2015 07:28:00 GMT`. Returns a
  /// UTC [DateTime], or `null` if the string is not a recognised HTTP-date.
  static DateTime? tryParse(String value) {
    // "Wed, 21 Oct 2015 07:28:00 GMT"
    final m = RegExp(
      r'^[A-Za-z]+,\s+(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})\s+'
      r'(\d{2}):(\d{2}):(\d{2})\s+GMT$',
    ).firstMatch(value.trim());
    if (m == null) return null;
    final month = _months[m.group(2)];
    if (month == null) return null;
    try {
      return DateTime.utc(
        int.parse(m.group(3)!),
        month,
        int.parse(m.group(1)!),
        int.parse(m.group(4)!),
        int.parse(m.group(5)!),
        int.parse(m.group(6)!),
      );
    } catch (_) {
      return null;
    }
  }
}
