// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import '../error/exceptions.dart';
import 'service_result.dart';
import 'station_failure_classifier.dart';

/// Single-shot transient-error retry for [StationServiceChain] (#2842).
///
/// Extracted verbatim from the chain so the orchestration file stays under the
/// 400-line cap. Behaviour is unchanged — the retry decision still routes on
/// [effectiveFailureKind] (#2255), still honours a capped `Retry-After`
/// (#2255), and the in-chain delay is still the same tunable static the chain
/// exposed (re-exported as `StationServiceChain.transientRetryDelay`).

/// Delay between the first and second attempt of [callWithTransientRetry].
/// 500 ms keeps the user-visible latency tight (most browsers stall ≥1 s
/// before a user even notices), and is long enough for an overloaded
/// upstream to clear a 503 burst.
///
/// Production code only ever reads this; the single mutating surface is the
/// `@visibleForTesting StationServiceChain.transientRetryDelay` accessor the
/// retry tests use to run without sleeping a real half-second (#2842).
Duration stationTransientRetryDelay = const Duration(milliseconds: 500);

/// Wraps a single [apiCall] with one retry on transient remote errors.
/// Transience is decided by [FailureKind] (#2255): a network blip, a
/// timeout, or a rate-limit response are the kinds a short retry could
/// plausibly recover from. One retry only — the goal is to absorb a
/// transient blip, not to mask sustained outages from the chain's
/// fall-through to stale cache or to the user-visible error dialog.
///
/// Returns the second attempt's result on success; rethrows the second
/// attempt's exception on failure so the caller observes the same
/// `on Exception` semantics as a plain `await apiCall()`. Non-transient
/// errors (auth, notFound, parse, unsupported, unknown) skip the retry —
/// those are not going to fix themselves in 500 ms.
Future<ServiceResult<T>> callWithTransientRetry<T>(
  Future<ServiceResult<T>> Function() apiCall,
) async {
  try {
    return await apiCall();
  } on ApiException catch (e, st) {
    if (!isTransientFailure(e)) rethrow;
    // Single retry — dev-console only (no production listener). Stack
    // included to satisfy `catch_block_stacktrace_coverage` (#1103).
    debugPrint(
      'StationServiceChain: retrying after transient error '
      '(status=${e.statusCode}, kind=${effectiveFailureKind(e).name})\n$st',
    );
    // Honour an upstream Retry-After (#2255) but cap it at
    // [stationTransientRetryDelay] so a long server hint never stretches the
    // in-chain retry latency — sustained rate-limits fall through to cache.
    final delay =
        e.retryAfter != null && e.retryAfter! < stationTransientRetryDelay
            ? e.retryAfter!
            : stationTransientRetryDelay;
    await Future<void>.delayed(delay);
    return apiCall();
  }
}
