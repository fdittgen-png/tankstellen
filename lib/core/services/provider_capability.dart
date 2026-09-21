// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// What a country's upstream data source can actually support (#4156,
/// Epic #4155).
///
/// > country ≠ provider capability.
///
/// The app treated every country's output as "stations with prices". The
/// reality behind that is wildly uneven: an official 5-minute feed, an
/// hourly bulk CSV, a weekly dump, brand-only coverage, an endpoint that
/// has been retired (#804 NSW FuelCheck), and one that never existed
/// publicly at all (#3194 Greece). Nothing in the type system said so,
/// so every consumer assumed the best case — and the best case is wrong
/// in eleven of seventeen countries.
///
/// [FuelServicePolicy] is NOT this. That is a *fetch* policy — how often
/// we may poll, and whether the source is a bulk file. It says nothing
/// about what the data supports or how far it may be trusted.
///
/// ## The rules this type is built to
///
///  * It describes the **upstream**, not the last response. A momentarily
///    empty result does not downgrade a good provider; sustained
///    violation is a separate signal — [freshnessViolatedBy].
///  * [confidence] is derived from named inputs ([freshnessTier],
///    [coverageTier], [identityTier]), each testable on its own. There is
///    no hand-tuned constant here that nobody can defend.
///  * **A claim the provider cannot support is unrepresentable.** The only
///    way to get an open/closed answer out of this type is [openState],
///    and it consults [openingHours] first. A caller cannot forget,
///    because there is nothing else to call.
///
/// ## Why the last rule matters, concretely
///
/// `RefuelDecision.confidentPick` (spec §3.1) required
/// `isOpenNow == true`. Eleven of the seventeen registered countries
/// populate `Station.isOpen` for nobody — their source publishes no
/// hours at all — so the conditional lead could not fire there, ever,
/// and nothing said why. "Unknown" was being read as "closed" because a
/// `bool?` has no way to distinguish *this station's hours are unknown*
/// from *this provider has never published hours for anyone*. Only the
/// six countries whose adapter derives an open state (DE, FR, AT, ES,
/// PT, CL) could ever reach the lead.
library;

import 'package:meta/meta.dart';

import '../domain/data_value.dart';

/// How much of a country a source actually covers.
enum ProviderCoverage {
  /// Every station in the country, or close enough that a gap is a bug.
  national,

  /// Some regions only — a national search silently under-reports.
  regional,

  /// Structurally incomplete: only participating brands, or a mirror of
  /// a feed we do not control.
  partial,

  /// Nothing. The source is retired or unreachable (#804).
  none,
}

/// How far a provider's output may be trusted, derived — never declared.
enum DataConfidence {
  high,
  medium,
  low,

  /// The provider publishes no prices at all; there is nothing to trust.
  none,
}

/// How far past its own promise a provider may drift before we treat the
/// promise as broken rather than late.
///
/// Three times the declared freshness. Not a tuning knob: one missed
/// publication is an outage, three consecutive ones is a provider that
/// has stopped publishing — which is exactly what #804 and #3194 were,
/// and both went unnoticed for months because nothing was watching.
const int kFreshnessViolationFactor = 3;

/// The contract for one country's upstream source.
///
/// Declared per country in `country_capabilities.dart` and carried on the
/// [CountryServiceEntry], so it is readable **without constructing the
/// service** — a UI that needs to know whether to offer an amenities
/// filter must not have to build an HTTP client to find out.
@immutable
class ProviderCapability {
  const ProviderCapability({
    required this.stationIdentity,
    required this.price,
    required this.expectedFreshness,
    required this.coverage,
    this.coordinates = true,
    this.historicalPrice = false,
    this.openingHours = false,
    this.amenities = false,
    this.priceTimestamp = false,
  });

  /// Station ids are stable across refreshes.
  ///
  /// False when the id is synthesised from the record's content (a hash
  /// of brand + address), because an upstream typo fix then silently
  /// becomes a different station — and a favorite or a price alert
  /// pointing at the old id stops matching anything.
  final bool stationIdentity;

  /// The source publishes real per-station coordinates.
  ///
  /// False for a source that publishes prices without locations and
  /// forces us to stand in virtual stations (LU's regulated national
  /// price, pinned at city centres).
  final bool coordinates;

  /// The source publishes prices at all. False only for a dead provider.
  final bool price;

  /// Past prices are retrievable, so a trend is measured rather than
  /// accumulated by us watching.
  final bool historicalPrice;

  /// The source publishes opening hours we can evaluate — a structured
  /// schedule, or an explicit open/closed flag. A free-text hours string
  /// we cannot parse is NOT this: it can be shown, never reasoned over.
  final bool openingHours;

  /// The source publishes station amenities (shop, car wash, toilets …).
  final bool amenities;

  /// Each price carries its own "as of" stamp.
  ///
  /// False for a source that stamps only the dataset — we then know when
  /// we downloaded it, not when the price was set, and a freshness gate
  /// built on that would be measuring our own network activity.
  final bool priceTimestamp;

  /// What the upstream **promises**, not what we observed and not how
  /// often we poll. The publication cadence the provider documents.
  final Duration expectedFreshness;

  /// How much of the country this source actually covers.
  final ProviderCoverage coverage;

  // -------------------------------------------------------------------
  // Claims — the only way to get an answer out of a capability
  // -------------------------------------------------------------------

  /// Whether a station is open, as far as this provider can say.
  ///
  /// [published] is what the adapter parsed: `true`/`false` when the row
  /// carried an answer, null when it did not. The three outcomes are
  /// genuinely different and a `bool?` conflated two of them:
  ///
  ///  * provider publishes no hours → [DataUnknownReason.notPublishedByProvider]
  ///    — a gate on openness is not applicable and withholding a result
  ///    over it would disable the feature in a whole country;
  ///  * provider publishes hours but not for this row →
  ///    [DataUnknownReason.notPublishedForThisItem] — a real gap, and the
  ///    honest response is to withhold;
  ///  * an answer → [Measured].
  DataValue<bool> openState(bool? published) {
    if (!openingHours) {
      return const DataValue.unknown(
        reason: DataUnknownReason.notPublishedByProvider,
      );
    }
    if (published == null) {
      return const DataValue.unknown(
        reason: DataUnknownReason.notPublishedForThisItem,
      );
    }
    return DataValue.measured(published);
  }

  /// How old this row's price is, as far as this provider can say.
  ///
  /// Three outcomes, and the middle one is the one a `Duration?` could
  /// not express:
  ///
  ///  * the provider stamps no prices ([priceTimestamp] false) →
  ///    [DataUnknownReason.notPublishedByProvider]. Whatever age the
  ///    adapter derived is OUR download clock, not the provider's price
  ///    clock, and a freshness gate built on it would be measuring our
  ///    own polling;
  ///  * the provider stamps prices but this row carried none →
  ///    [DataUnknownReason.notPublishedForThisItem] — a real gap;
  ///  * a stamp → [Measured].
  ///
  /// No threshold here on purpose. What counts as too old is a product
  /// decision (`docs/specs/refuel-economics.md` §3.1), not a property of
  /// the upstream, and pushing it in here would bury it where nobody
  /// reviewing the spec would find it.
  DataValue<Duration> priceAge(Duration? age) {
    if (!priceTimestamp) {
      return const DataValue.unknown(
        reason: DataUnknownReason.notPublishedByProvider,
      );
    }
    if (age == null) {
      return const DataValue.unknown(
        reason: DataUnknownReason.notPublishedForThisItem,
      );
    }
    return DataValue.measured(age);
  }

  /// Whether this provider has nothing to fetch — retired, or publishing
  /// no prices at all (#4348, #804 Australia).
  ///
  /// Structural, not transient: a request would fail the same way every
  /// time, so the search chain refuses before spending one and the UI
  /// names the state instead of offering a retry that cannot help.
  bool get isUnavailable => !price || coverage == ProviderCoverage.none;

  /// Whether an amenity claim may be made at all. A country whose source
  /// publishes none must not render an amenities filter that silently
  /// matches nothing — #3308 was exactly this class of bug.
  bool get canFilterByAmenities => amenities;

  // -------------------------------------------------------------------
  // Confidence — derived from named, individually testable inputs
  // -------------------------------------------------------------------

  /// How current the provider promises to be.
  DataConfidence get freshnessTier {
    if (expectedFreshness <= const Duration(hours: 1)) {
      return DataConfidence.high;
    }
    if (expectedFreshness <= const Duration(hours: 24)) {
      return DataConfidence.medium;
    }
    return DataConfidence.low;
  }

  /// How much of the country the answer speaks for.
  DataConfidence get coverageTier => switch (coverage) {
        ProviderCoverage.national => DataConfidence.high,
        ProviderCoverage.regional => DataConfidence.medium,
        ProviderCoverage.partial => DataConfidence.low,
        ProviderCoverage.none => DataConfidence.none,
      };

  /// Whether the thing we name today is the same thing tomorrow.
  ///
  /// A synthesised id does not make today's price wrong — it makes
  /// favorites and alerts unreliable — so it caps confidence at medium
  /// rather than dropping it to low.
  DataConfidence get identityTier =>
      stationIdentity ? DataConfidence.high : DataConfidence.medium;

  /// The weakest of the named tiers — no weights, no blend.
  ///
  /// A chain is as strong as its weakest link, and unlike a weighted
  /// score this can be explained in one sentence to the user whose
  /// country is the low one.
  DataConfidence get confidence {
    if (!price) return DataConfidence.none;
    var worst = DataConfidence.high;
    for (final tier in [freshnessTier, coverageTier, identityTier]) {
      if (tier.index > worst.index) worst = tier;
    }
    return worst;
  }

  /// Whether an observed age breaks the provider's own promise by enough
  /// to mean it has stopped publishing rather than published late
  /// (#804, #3194).
  ///
  /// Deliberately a question about ONE observation. Whether the
  /// violation is *sustained* — the thing that actually means death — is
  /// the caller's to accumulate; this type describes the upstream, not
  /// our history with it.
  bool freshnessViolatedBy(Duration observedAge) =>
      observedAge > expectedFreshness * kFreshnessViolationFactor;

  @override
  String toString() => 'ProviderCapability(${coverage.name}, '
      '${expectedFreshness.inMinutes}min, ${confidence.name})';
}
