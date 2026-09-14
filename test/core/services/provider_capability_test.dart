// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/core/services/country_service_registry.dart';
import 'package:tankstellen/core/services/provider_capability.dart';

/// #4156 — country ≠ provider capability.
///
/// Two halves. The first pins the CONTRACT: a claim the provider cannot
/// support is unrepresentable, and confidence is derived from named
/// inputs rather than declared. The second pins the DATA: every
/// registered country declares one, and the known-degraded ones carry
/// honest values rather than aspirational ones — which is the failure
/// mode the whole file exists to prevent.
void main() {
  group('a claim the provider cannot support is unrepresentable', () {
    const publishesHours = ProviderCapability(
      stationIdentity: true,
      price: true,
      openingHours: true,
      expectedFreshness: Duration(minutes: 5),
      coverage: ProviderCoverage.national,
    );
    const publishesNoHours = ProviderCapability(
      stationIdentity: true,
      price: true,
      expectedFreshness: Duration(minutes: 5),
      coverage: ProviderCoverage.national,
    );

    test('a provider with no hours cannot produce an open state at all', () {
      // Not "produces false" and not "produces null" — both of those are
      // answers. It produces the reason there is no answer.
      expect(
        publishesNoHours.openState(true),
        const DataValue<bool>.unknown(
          reason: DataUnknownReason.notPublishedByProvider,
        ),
        reason: 'even a true handed in must not become a claim the '
            'provider never made',
      );
    });

    test('a provider WITH hours distinguishes its own gaps', () {
      expect(publishesHours.openState(true), const DataValue.measured(true));
      expect(publishesHours.openState(false), const DataValue.measured(false));
      expect(
        publishesHours.openState(null),
        const DataValue<bool>.unknown(
          reason: DataUnknownReason.notPublishedForThisItem,
        ),
        reason: 'a gap this provider could have filled is a different '
            'fact from a question it never answers',
      );
    });

    test('an unstamped price yields no age, whatever we computed', () {
      const noStamps = publishesNoHours;
      expect(
        noStamps.priceAge(const Duration(minutes: 3)),
        const DataValue<Duration>.unknown(
          reason: DataUnknownReason.notPublishedByProvider,
        ),
        reason: 'that duration is our download clock, not the provider’s '
            'price clock',
      );
    });

    test('a stamped price keeps its age, and its absence stays specific', () {
      const stamps = ProviderCapability(
        stationIdentity: true,
        price: true,
        priceTimestamp: true,
        expectedFreshness: Duration(hours: 1),
        coverage: ProviderCoverage.national,
      );
      expect(stamps.priceAge(const Duration(minutes: 3)),
          const DataValue.measured(Duration(minutes: 3)));
      expect(
        stamps.priceAge(null),
        const DataValue<Duration>.unknown(
          reason: DataUnknownReason.notPublishedForThisItem,
        ),
      );
    });

    test('the capability holds no freshness THRESHOLD', () {
      // What counts as too old is a product decision (spec §3.1), not a
      // property of the upstream. A capability that decided it would
      // bury the rule where nobody reviewing the spec would find it.
      const stamps = ProviderCapability(
        stationIdentity: true,
        price: true,
        priceTimestamp: true,
        expectedFreshness: Duration(minutes: 5),
        coverage: ProviderCoverage.national,
      );
      expect(stamps.priceAge(const Duration(days: 9)),
          const DataValue.measured(Duration(days: 9)));
    });
  });

  group('confidence is derived from named inputs, never declared', () {
    ProviderCapability cap({
      Duration freshness = const Duration(minutes: 5),
      ProviderCoverage coverage = ProviderCoverage.national,
      bool identity = true,
      bool price = true,
    }) =>
        ProviderCapability(
          stationIdentity: identity,
          price: price,
          expectedFreshness: freshness,
          coverage: coverage,
        );

    test('freshness tiers on the promise, not on our polling', () {
      expect(cap(freshness: const Duration(minutes: 5)).freshnessTier,
          DataConfidence.high);
      expect(cap(freshness: const Duration(hours: 1)).freshnessTier,
          DataConfidence.high);
      expect(cap(freshness: const Duration(hours: 12)).freshnessTier,
          DataConfidence.medium);
      expect(cap(freshness: const Duration(days: 7)).freshnessTier,
          DataConfidence.low);
    });

    test('coverage tiers', () {
      expect(cap(coverage: ProviderCoverage.national).coverageTier,
          DataConfidence.high);
      expect(cap(coverage: ProviderCoverage.regional).coverageTier,
          DataConfidence.medium);
      expect(cap(coverage: ProviderCoverage.partial).coverageTier,
          DataConfidence.low);
      expect(cap(coverage: ProviderCoverage.none).coverageTier,
          DataConfidence.none);
    });

    test('a synthesised id caps at medium, it does not sink to low', () {
      // It does not make today's price wrong; it makes favorites and
      // alerts unreliable. Those are different magnitudes of harm.
      expect(cap(identity: false).identityTier, DataConfidence.medium);
      expect(cap(identity: false).confidence, DataConfidence.medium);
    });

    test('confidence is the WEAKEST named tier — no weights, no blend', () {
      final mixed = cap(
        freshness: const Duration(minutes: 5), // high
        coverage: ProviderCoverage.partial, // low
      );
      expect(mixed.confidence, DataConfidence.low,
          reason: 'a chain is as strong as its weakest link, and unlike a '
              'weighted score this is explainable to the user whose '
              'country is the low one');
    });

    test('no prices means nothing to trust, whatever the other tiers say',
        () {
      final dead = cap(price: false, coverage: ProviderCoverage.none);
      expect(dead.confidence, DataConfidence.none);
    });

    test('a breach of the provider’s own promise is detectable', () {
      // #804 and #3194 both died quietly because nothing was watching.
      const hourly = ProviderCapability(
        stationIdentity: true,
        price: true,
        expectedFreshness: Duration(hours: 1),
        coverage: ProviderCoverage.national,
      );
      expect(hourly.freshnessViolatedBy(const Duration(hours: 2)), isFalse,
          reason: 'one missed publication is an outage, not a death');
      expect(hourly.freshnessViolatedBy(const Duration(hours: 4)), isTrue);
    });
  });

  group('every registered country declares one, and declares it honestly',
      () {
    test('no country is registered without a capability', () {
      // The constructor field is required, so this cannot fail by
      // omission — it fails if someone reaches for a shared placeholder
      // to satisfy the compiler.
      for (final code in CountryServiceRegistry.registeredCountryCodes) {
        expect(CountryServiceRegistry.capabilityFor(code), isNotNull,
            reason: '$code has no ProviderCapability');
      }
    });

    test('capabilities are distinct objects, not one placeholder reused', () {
      // Seventeen countries that all declare the same thing would mean
      // the file was filled in to make the compiler happy. They differ,
      // because the providers differ.
      final distinct = {
        for (final code in CountryServiceRegistry.registeredCountryCodes)
          CountryServiceRegistry.capabilityFor(code).toString(),
      };
      expect(distinct.length, greaterThan(3));
    });

    test('AU is declared DEAD, because it is (#804)', () {
      // AustraliaStationService.searchStations throws on every call. A
      // capability claiming prices are one request away is exactly the
      // aspirational value this contract exists to forbid.
      final au = CountryServiceRegistry.capabilityFor('AU')!;
      expect(au.price, isFalse);
      expect(au.coverage, ProviderCoverage.none);
      expect(au.confidence, DataConfidence.none);
    });

    test('GR is prefecture-level, so it claims no coordinates (#576)', () {
      final gr = CountryServiceRegistry.capabilityFor('GR')!;
      expect(gr.coordinates, isFalse);
      expect(gr.coverage, ProviderCoverage.partial);
    });

    test('DK covers three brands, not a country', () {
      final dk = CountryServiceRegistry.capabilityFor('DK')!;
      expect(dk.coverage, ProviderCoverage.partial,
          reason: 'OK + Shell + Q8 is roughly 800 of Denmark’s stations; a '
              '"cheapest around you" built on it overstates what we know');
    });

    test('LU prices are national but its coordinates are invented', () {
      // The two facts are not in tension — they are different questions,
      // and a single "quality" number could not have expressed both.
      final lu = CountryServiceRegistry.capabilityFor('LU')!;
      expect(lu.coverage, ProviderCoverage.national);
      expect(lu.coordinates, isFalse);
    });

    test('AR synthesises its station ids, so identity is false', () {
      final ar = CountryServiceRegistry.capabilityFor('AR')!;
      expect(ar.stationIdentity, isFalse,
          reason: 'ar-<hash of empresa+direccion>: an upstream address fix '
              'silently becomes a different station, and a favorite or '
              'alert on the old id stops matching');
    });

    test('only the countries whose adapter derives an open state claim '
        'opening hours', () {
      // Read off the adapters, not off the providers’ marketing. SI
      // publishes hours as free text we render and cannot evaluate, and
      // is deliberately NOT in this set.
      final claiming = {
        for (final code in CountryServiceRegistry.registeredCountryCodes)
          if (CountryServiceRegistry.capabilityFor(code)!.openingHours) code,
      };
      expect(claiming, {'DE', 'FR', 'AT', 'ES', 'PT', 'CL'});
    });

    test('only FR claims amenities, because only FR parses them', () {
      // A country without amenity data must not render an amenities
      // filter that silently matches nothing — #3308 was this bug.
      final claiming = {
        for (final code in CountryServiceRegistry.registeredCountryCodes)
          if (CountryServiceRegistry.capabilityFor(code)!.canFilterByAmenities)
            code,
      };
      expect(claiming, {'FR'});
    });

    test('priceTimestamp is claimed only where the adapter sets updatedAt',
        () {
      final claiming = {
        for (final code in CountryServiceRegistry.registeredCountryCodes)
          if (CountryServiceRegistry.capabilityFor(code)!.priceTimestamp) code,
      };
      expect(claiming, {'FR', 'PT', 'IT', 'DK', 'LU', 'AR', 'GR', 'RO'});
    });

    test('nobody claims historical prices, because nobody has them', () {
      for (final code in CountryServiceRegistry.registeredCountryCodes) {
        expect(CountryServiceRegistry.capabilityFor(code)!.historicalPrice,
            isFalse,
            reason: '$code: a trend in this app is accumulated by us '
                'watching, never retrieved');
      }
    });
  });
}
