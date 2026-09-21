// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// One contract suite every country service must pass (#4157, epic #4155).
///
/// `test/features/station_services/` has a directory per country, each
/// testing what its author thought to test, so "does this provider
/// behave like a provider" was answered differently seventeen times — and
/// a new country was only as safe as the tests someone remembered to
/// copy.
///
/// ## What it asserts against
///
/// Not a hand-written expectation of what the country *should* return.
/// The contract checks the parsed [Station] list against **the country's
/// own declarations**: its [ProviderCapability] (#4156) and its
/// [CountryBoundingBox]. That is the payoff of having declared them — a
/// provider that claims `priceTimestamp: true` must actually stamp, and
/// a provider that claims `coordinates: false` is not asked for any.
///
/// ## Why the input must be a RECORDED real response
///
/// `feedback_fake_services_false_green`: a fake that echoes the request
/// hid the cross-border bug **three times** — it returned the E10 that
/// was asked for, which the real Spanish API never sends. So callers
/// drive the REAL service against a checked-in recording, and a country
/// with no recording does not quietly pass: see
/// `station_service_contract_coverage_test.dart`.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/services/country_service_registry.dart';
import 'package:tankstellen/core/services/provider_capability.dart';
import 'package:tankstellen/core/utils/station_extensions.dart';

/// A contract case a country may be excused from, always with a reason.
///
/// An exemption is a statement in the repository, not a silent skip:
/// `station_service_contract_coverage_test` requires every one to carry
/// a linked issue.
enum ContractExemption {
  /// The id is synthesised from the record's content, so it is not
  /// stable across refreshes (AR: `ar-<hash of empresa+direccion>`).
  unstableIds,

  /// The service stands in virtual stations rather than real ones, so
  /// its coordinates are centroids (LU cities, GR prefectures).
  syntheticCoordinates,

  /// The recording is a narrow slice that legitimately contains one
  /// station, so duplicate/collapse behaviour cannot be observed.
  sliceTooNarrowForDuplicates,
}

/// The lowest price per litre any real fuel has ever had, and the
/// highest, in EUR. A value outside this is a unit or decimal-separator
/// bug, not a cheap forecourt — the #3308 class of defect lives exactly
/// here.
const double kMinSanePricePerLitre = 0.10;
const double kMaxSanePricePerLitre = 10.0;

/// The plausible price-per-litre range in each currency a registered
/// country prices in (#4180).
///
/// Services store prices in the country's OWN currency, so one EUR bound
/// rejected every correct DKK or MXN price. Each non-EUR row is the EUR
/// range scaled by a rounded 2026 exchange rate, so a factor-100 unit bug
/// (pence, øre, centavos) or a thousands-separator misread still lands
/// outside it. ARS is widened for inflation. A currency missing here fails
/// the contract rather than passing unchecked.
const Map<String, ({double min, double max})> kSanePricePerLitreByCurrency = {
  // Unchanged from the original EUR-only contract.
  'EUR': (min: kMinSanePricePerLitre, max: kMaxSanePricePerLitre),
  // ~0.85 GBP/EUR; pump prices ~1.3–1.9 GBP. A pence value (152.7) fails.
  'GBP': (min: 0.10, max: 10.0),
  // Pegged at ~7.46 DKK/EUR (ERM II); recorded OK/Shell 15.59–18.29 DKK.
  'DKK': (min: 0.75, max: 75.0),
  // ~5 RON/EUR; recorded Monitorul prices ~8–9 RON.
  'RON': (min: 0.50, max: 50.0),
  // ~20 MXN/EUR; recorded CRE prices 22.77–29.69 MXN.
  'MXN': (min: 2.0, max: 200.0),
  // ~1.65 AUD/EUR; NSW FuelCheck published ~1.8–2.3 AUD (cents would fail).
  'AUD': (min: 0.15, max: 20.0),
  // ~1000 CLP/EUR; CNE prices ~1200–1500 CLP.
  'CLP': (min: 100.0, max: 10000.0),
  // ~1500 KRW/EUR; OPINET prices ~1600–1900 KRW.
  'KRW': (min: 150.0, max: 15000.0),
  // ~1000+ ARS/EUR and high inflation; widened in both directions.
  'ARS': (min: 10.0, max: 100000.0),
};

/// Run the contract for [countryCode] over the stations [stationsOf]
/// returns, which must have come from the REAL service driven against a
/// recorded response.
///
/// A **getter**, not a list: `runStationServiceContract` is called while
/// `main()` registers tests, and the caller's stations are parsed in
/// `setUpAll`, which has not run yet. Taking the value eagerly reads an
/// uninitialised late field and the file fails to load — which is how
/// this was written the first time.
///
/// [now] is injected so "a timestamp is not in the future" is a stable
/// assertion rather than one that depends on when the suite runs.
void runStationServiceContract({
  required String countryCode,
  required List<Station> Function() stationsOf,
  required DateTime now,
  Set<ContractExemption> exemptions = const {},
}) {
  final entry = CountryServiceRegistry.entryFor(countryCode);
  final capability = entry?.capability;

  group('$countryCode — provider contract (#4157)', () {
    test('the country is registered and declares a capability', () {
      expect(entry, isNotNull,
          reason: 'a contract case for an unregistered country tests '
              'nothing');
      expect(capability, isNotNull);
    });

    test('a recording that parses to nothing is a broken recording', () {
      // An empty dataset is a valid ANSWER from a live provider, but a
      // recording captured to exercise a parser and yielding zero rows
      // means the parser stopped matching the feed.
      expect(stationsOf(), isNotEmpty);
    });

    test('every station has a non-empty id', () {
      expect(stationsOf().where((s) => s.id.trim().isEmpty), isEmpty);
    });

    test('ids are unique — a duplicate is a station shown twice', () {
      if (exemptions.contains(ContractExemption.sliceTooNarrowForDuplicates)) {
        return;
      }
      final ids = stationsOf().map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('ids carry the country prefix, so #516 can route them', () {
      // `Countries.countryCodeForStationId` dispatches on the prefix;
      // an id without one cannot be attributed to its country later.
      if (exemptions.contains(ContractExemption.unstableIds)) return;
      for (final s in stationsOf()) {
        expect(CountryServiceRegistry.countryForStationId(s.id), countryCode,
            reason: '"${s.id}" does not resolve to $countryCode');
      }
    });

    test('coordinates land inside the country bounding box', () {
      if (capability?.coordinates != true) return;
      if (exemptions.contains(ContractExemption.syntheticCoordinates)) return;
      final box = entry!.boundingBox;
      for (final s in stationsOf()) {
        expect(box.contains(s.lat, s.lng), isTrue,
            reason: '"${s.id}" at ${s.lat},${s.lng} is outside $countryCode');
      }
    });

    test('a missing price is ABSENT, never 0.00', () {
      // A zero renders as free fuel and sorts first — the most
      // expensive possible way to be wrong about a price.
      for (final s in stationsOf()) {
        for (final fuel in FuelType.values) {
          if (fuel == FuelType.all) continue;
          final p = s.priceFor(fuel);
          if (p == null) continue;
          expect(p, greaterThan(0),
              reason: '"${s.id}" has ${fuel.apiValue} = $p');
        }
      }
    });

    test('prices are in a sane range — a separator bug is not a bargain',
        () {
      final currency = Countries.byCode(countryCode)?.currency;
      final range = kSanePricePerLitreByCurrency[currency];
      expect(range, isNotNull,
          reason: '$countryCode prices in "$currency", which has no row in '
              'kSanePricePerLitreByCurrency — add one with its rationale '
              'rather than letting the price check pass unchecked');
      for (final s in stationsOf()) {
        for (final fuel in FuelType.values) {
          if (fuel == FuelType.all || fuel == FuelType.electric) continue;
          final p = s.priceFor(fuel);
          if (p == null) continue;
          expect(p, inInclusiveRange(range!.min, range.max),
              reason: '"${s.id}" ${fuel.apiValue} = $p $currency — off by a '
                  'factor of 100 or a comma read as a thousands separator');
        }
      }
    });

    test('at least one station carries a price for a declared fuel', () {
      if (capability?.price != true) return;
      final declared = entry!.availableFuelTypes
          .where((f) => f != FuelType.all)
          .toList();
      final priced = stationsOf().any(
        (s) => declared.any((f) => s.priceFor(f) != null),
      );
      expect(priced, isTrue,
          reason: 'the country declares ${declared.map((f) => f.apiValue)} '
              'and the recording prices none of them');
    });

    test('timestamps parse, and none is in the future', () {
      // A stamp in the future is a broken feed, and every staleness
      // decision downstream inherits it.
      //
      // #4180 — reads `priceUpdatedAt`, the machine-readable stamp, not
      // `updatedAt`. Since #4189 `updatedAt` is the DISPLAY label
      // (`dd/MM HH:mm`) and is documented "never parse this"; parsing it
      // here failed every country that follows that rule, and would have
      // passed a country that stamps a parseable label but drops the
      // instant the freshness gate actually reads — the #4189 defect.
      if (capability?.priceTimestamp != true) return;
      final stamped =
          stationsOf().where((s) => s.priceUpdatedAt != null).toList();
      expect(stamped, isNotEmpty,
          reason: 'the country declares priceTimestamp: true and the '
              'recording stamps nothing (updatedAt labels: '
              '${stationsOf().map((s) => s.updatedAt).toSet()})');
      for (final s in stamped) {
        expect(
            s.priceUpdatedAt!.isAfter(now.add(const Duration(days: 1))),
            isFalse,
            reason: '"${s.id}" is stamped in the future: '
                '${s.priceUpdatedAt}');
      }
    });

    test('opening hours appear only where the country claims them', () {
      // The other direction of #4156: a provider that publishes no hours
      // must not be seen producing them, or the capability is a lie in
      // the optimistic direction.
      if (capability?.openingHours == true) return;
      expect(stationsOf().where((s) => s.openingHours != null), isEmpty,
          reason: '$countryCode declares openingHours: false but the '
              'recording produced some — fix the capability, or the '
              'adapter');
    });
  });
}
