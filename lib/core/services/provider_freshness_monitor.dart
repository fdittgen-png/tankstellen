// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import '../data/storage_repository.dart';
import '../domain/station.dart';
import '../logging/app_log.dart';
import '../logging/error_logger.dart';
import '../time/app_clock.dart';
import 'country_service_registry.dart';
import 'provider_capability.dart';

/// Watches whether a country's provider is still publishing (#4171).
///
/// [ProviderCapability.freshnessViolatedBy] answers the question for ONE
/// observation and says so in its own doc: *"Whether the violation is
/// sustained — the thing that actually means death — is the caller's to
/// accumulate; this type describes the upstream, not our history with
/// it."* Until now it had no caller at all. This is that caller.
///
/// ## Why the app has to notice this itself
///
/// #804 (NSW FuelCheck, retired) and #3194 (Greece, never public) both
/// went unnoticed for months, because a provider that quietly stops
/// publishing looks exactly like a provider with no stations near you.
/// `kGrCapability`'s own comment names the gap: the Greek mirror "can
/// vanish without notice — [ProviderCapability.freshnessViolatedBy] is
/// how that becomes detectable instead of mysterious".
///
/// The connectivity suite that caught Argentina is `@Tags(['network'])`
/// and excluded from CI, so nothing watches these sources unless a human
/// runs an excluded test by hand.
///
/// ## What counts as a violation
///
/// The FRESHEST price stamp in the response, not the oldest and not the
/// average. One stale station proves nothing — a forecourt that closed
/// last year still sits in a national dataset. But when even the newest
/// row breaches the provider's own promise by
/// [kFreshnessViolationFactor] (×3), the feed itself has stopped moving.
/// For a 24-hour provider that is three days without a single update.
///
/// A response whose stations carry no stamp at all is not evidence
/// either way: [ProviderCapability.priceTimestamp] is false for those
/// sources, so there is nothing to age. Those countries are skipped.
///
/// ## One observation is never death
///
/// The consecutive count is what matters, and any fresh observation
/// resets it to zero. A provider that was late once is not a provider
/// that stopped — which is exactly the distinction #4171 asks for before
/// anyone touches a capability declaration.
class ProviderFreshnessMonitor {
  /// Settings-key prefix for the per-country consecutive-violation count.
  /// The country code is appended (`provider_stale_streak:AR`).
  static const String keyPrefix = 'provider_stale_streak:';

  /// Consecutive violating responses before the monitor says a provider
  /// looks dead rather than late.
  ///
  /// Three, matching [kFreshnessViolationFactor]: with a 24-hour promise
  /// that is three separate searches, each already ≥72 h stale, before
  /// the app draws a conclusion a human should act on.
  static const int deadStreakThreshold = 3;

  ProviderFreshnessMonitor(
    this._storage, {
    this._clock = const SystemClock(),
    this._capabilityFor = CountryServiceRegistry.capabilityFor,
  });

  final StorageRepository _storage;
  final AppClock _clock;

  /// Country → its provider's declared capability. Injected so a test can
  /// pin one without standing up the registry; defaults to the real one,
  /// so a caller that forgets cannot silently get a monitor that watches
  /// nothing.
  final ProviderCapability? Function(String country) _capabilityFor;

  static String _keyFor(String country) => '$keyPrefix$country';

  /// Consecutive violating responses recorded for [country]; 0 when the
  /// provider last answered with fresh data (or has never been seen).
  int staleStreak(String country) {
    final raw = _storage.getSetting(_keyFor(country));
    return raw is int ? raw : 0;
  }

  /// Whether [country]'s provider has now missed its own freshness
  /// promise [deadStreakThreshold] times running.
  ///
  /// This is a signal to a maintainer, not a switch the app flips by
  /// itself: #4171 is explicit that a capability becomes `price: false` /
  /// `coverage: none` only after a sustained outage is established, and
  /// one client's view of the network is not that evidence.
  bool looksUnpublished(String country) =>
      staleStreak(country) >= deadStreakThreshold;

  /// Record what [stations] say about [country]'s freshness.
  ///
  /// Called on every successful UPSTREAM response (cache hits tell us
  /// nothing about the provider). Fire-and-forget: the storage write is
  /// started, not awaited, so the network success path is never slowed
  /// by it.
  void recordResponse(String country, List<Station> stations) {
    final capability = _capabilityFor(country);
    if (capability == null) return;
    // No stamp published for anyone → nothing to age. Not a violation.
    if (!capability.priceTimestamp) return;

    final freshest = _freshestAge(stations);
    if (freshest == null) return;

    final violated = capability.freshnessViolatedBy(freshest);
    final previous = staleStreak(country);
    final next = violated ? previous + 1 : 0;
    if (next == previous) return;

    _persist(country, next);

    if (violated && next == deadStreakThreshold) {
      // The transition, logged once rather than on every later response:
      // this is the moment the evidence became worth a human's attention.
      log.warn(
        'provider has missed its freshness promise $next times running',
        tag: 'freshness',
        context: {
          'country': country,
          'expectedFreshness': capability.expectedFreshness.toString(),
          'observedAge': freshest.toString(),
        },
      );
    }
  }

  /// The age of the NEWEST price stamp in [stations], or null when not
  /// one of them carries a stamp.
  Duration? _freshestAge(List<Station> stations) {
    DateTime? newest;
    for (final station in stations) {
      final stamp = station.priceUpdatedAt;
      if (stamp == null) continue;
      if (newest == null || stamp.isAfter(newest)) newest = stamp;
    }
    if (newest == null) return null;
    final age = _clock.now().difference(newest);
    // A stamp in the future is a provider clock problem, not staleness.
    return age.isNegative ? Duration.zero : age;
  }

  void _persist(String country, int streak) {
    unawaited(
      _storage.putSetting(_keyFor(country), streak).catchError(
        (Object e, StackTrace st) {
          // A missed streak update costs one round of evidence, never a
          // search. Logged rather than swallowed (#3981).
          log.error(e, st, layer: ErrorLayer.storage, context: {
            'where': 'ProviderFreshnessMonitor._persist',
            'country': country,
          });
        },
      ),
    );
  }
}
