// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// One shape for every reason to interrupt someone (#4149, epic #4148).
///
/// Three alert kinds exist — station+threshold, radius+threshold, and the
/// drop detector — and each carried its own shape, its own firing rule
/// and its own dedup store. Adding a fourth reason to notify meant a
/// fourth of everything, and nothing could compare two reasons against
/// each other to decide which was worth a notification.
///
/// Pure Dart over primitives, deliberately the same shape as
/// `core/domain/refuel_economics.dart`: no Flutter, no Hive, no Riverpod,
/// so the whole chain is testable without a notification channel or a
/// background isolate — and runnable INSIDE one, which is where it
/// actually executes.
///
/// ## What an opportunity is not
///
/// It is not "a number moved". `docs/specs/refuel-economics.md` trust
/// rule 4 applies here with more force than anywhere else in the app,
/// because this is the one surface that interrupts someone who did not
/// ask: every saving must be reproducible from the fields shown, and
/// [reference] names what it was measured against. A notification the
/// user cannot check is a notification they learn to dismiss.
library;

import 'package:meta/meta.dart';

import '../../../core/domain/data_value.dart';
import '../../../core/services/provider_capability.dart';

/// Why this is worth someone's attention.
enum OpportunityKind {
  /// The best stop available right now, near where they are.
  bestStopNow,

  /// The best stop along a route they are driving.
  bestStopOnRoute,

  /// The tank is low enough that a stop is coming whether or not the
  /// price is good.
  refuelSoon,

  /// A price that is unusual for this area, not merely below a number.
  exceptionalLocalPrice,

  /// A price that is unusual against THIS user's own history.
  personalBaseline,

  /// Prices moving across several nearby stations at once — the
  /// velocity detector's case.
  localMovement,

  /// A station the user asked to be told about.
  favouriteStation,
}

/// What a saving was measured against.
///
/// An enum, not a `String`. The issue that specified this model asked
/// for a `String referenceLabel` — "what that reference IS, in words" —
/// and words are the one thing a detector cannot produce: it runs in a
/// background isolate with no `BuildContext`, and a literal it built
/// itself would be untranslatable by construction (HARD RULE #1). The
/// notification layer renders these; the detector only names which one
/// applies.
enum OpportunityReference {
  /// The threshold the user set on this alert themselves.
  thresholdYouSet,

  /// The median of what this user has actually been paying.
  yourMedian,

  /// The median price around them right now.
  localMedian,

  /// What this same station was charging earlier.
  priceEarlier,

  /// The cheapest station on the route they are driving.
  cheapestOnRoute,

  /// The cheapest station within range.
  cheapestNearby,
}

/// One reason to interrupt someone, with everything needed to justify it.
@immutable
class Opportunity {
  const Opportunity({
    required this.kind,
    required this.fuelType,
    required this.currentPrice,
    required this.reference,
    required this.distanceKm,
    required this.priceAge,
    required this.confidence,
    required this.detectedAt,
    required this.expiresAt,
    this.stationId,
    this.stationName,
    this.referencePrice,
    this.grossSaving,
    this.detourCost,
    this.netSaving,
    this.detourTime,
  });

  final OpportunityKind kind;

  /// The station this is about, when it is about one. Null for a
  /// movement across several ([OpportunityKind.localMovement]).
  final String? stationId;

  /// What to call it in the notification — the brand/name the adapter
  /// already had. Never built into a sentence here.
  final String? stationName;

  /// `FuelType.apiValue`, matching the storage convention the alert
  /// entities already use so no conversion is needed at the seam.
  final String fuelType;

  final double currentPrice;

  /// What [currentPrice] is being compared WITH, and [reference] says
  /// what that is. Null when the comparison is categorical rather than
  /// numeric.
  final double? referencePrice;
  final OpportunityReference reference;

  /// Price difference × the litres this user actually buys. Null when
  /// the opportunity could not be priced — see [isPriceable].
  final double? grossSaving;

  /// What getting there costs in fuel. Null for the same reason.
  final double? detourCost;

  /// [grossSaving] − [detourCost]. Never stored independently of them:
  /// trust rule 4 says a claim must be reproducible from what is shown,
  /// and a net figure that does not equal the difference of the two
  /// figures beside it is the exact shape of a number nobody can check.
  final double? netSaving;

  final double distanceKm;
  final Duration? detourTime;

  /// How old the price behind this is, as far as the country's provider
  /// can say (#4156).
  ///
  /// A `DataValue`, not a `Duration`. Nine of the seventeen registered
  /// providers stamp no prices at all, so for those the only age we
  /// could compute is our own download clock — and presenting that as
  /// freshness is precisely the bug `RefuelDecision.confidentPick` had
  /// before #4156. `ProviderCapability.priceAge` produces this.
  final DataValue<Duration> priceAge;

  /// How far the provider behind this may be trusted.
  ///
  /// Derived from [ProviderCapability.confidence], never invented here.
  /// A second, alert-specific confidence scale would be the fourth
  /// independent invention of one idea, which is the thing #4160 exists
  /// to stop.
  final DataConfidence confidence;

  final DateTime detectedAt;

  /// When this stops being true. A price is not an opportunity forever,
  /// and a notification that arrives after its reason expired is worse
  /// than none: it teaches the user that the app's alerts are stale.
  final DateTime expiresAt;

  /// Whether the money side could be computed at all.
  ///
  /// False when the user has no consumption figure, so a detour cost —
  /// and therefore a NET saving — cannot be derived. Such an
  /// opportunity may still be worth showing (a cheap station is a cheap
  /// station), but it must never be RANKED on money it does not have.
  bool get isPriceable => netSaving != null;

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);

  /// Trust rule 4, as an executable check rather than a promise.
  ///
  /// Exposed so the scorer and the tests can assert it on any
  /// opportunity from any detector, including ones written later.
  bool get savingIsReproducible {
    final gross = grossSaving, detour = detourCost, net = netSaving;
    if (gross == null && detour == null && net == null) return true;
    if (gross == null || detour == null || net == null) return false;
    return (gross - detour - net).abs() < 0.0001;
  }

  @override
  bool operator ==(Object other) =>
      other is Opportunity &&
      other.kind == kind &&
      other.stationId == stationId &&
      other.fuelType == fuelType &&
      other.currentPrice == currentPrice &&
      other.reference == reference &&
      other.referencePrice == referencePrice &&
      other.netSaving == netSaving &&
      other.distanceKm == distanceKm &&
      other.detectedAt == detectedAt &&
      other.expiresAt == expiresAt;

  @override
  int get hashCode => Object.hash(kind, stationId, fuelType, currentPrice,
      reference, referencePrice, netSaving, distanceKm, detectedAt, expiresAt);

  @override
  String toString() => 'Opportunity(${kind.name}, $stationId, '
      'net=$netSaving, ${confidence.name})';
}
