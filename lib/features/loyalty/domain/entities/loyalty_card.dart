import 'package:freezed_annotation/freezed_annotation.dart';

part 'loyalty_card.freezed.dart';
part 'loyalty_card.g.dart';

/// Fuel-club / loyalty programs supported by the discount aggregator
/// (#1120).
///
/// The pilot ships with a single brand — `totalEnergies` — and the
/// other entries reserve their canonical name for the next phase so
/// users that already keep a card "on paper" can be onboarded later
/// without an enum migration.
///
/// The enum value maps 1:1 to a canonical brand string in
/// [BrandRegistry] (see `lib/features/search/domain/entities/brand_registry.dart`)
/// so the discount can be matched against a station's brand without a
/// second registry.
enum LoyaltyBrand {
  /// Total Energies "Club Total" — the pilot brand. Heavy France
  /// market overlap.
  totalEnergies('TotalEnergies'),

  /// Aral payback / Aral Loyalty (Germany). Reserved for phase 2.
  aral('Aral'),

  /// Shell SmartDeal / Shell ClubSmart. Reserved for phase 2.
  shell('Shell'),

  /// BP / BPme rewards. Reserved for phase 2.
  bp('BP'),

  /// Esso Extras. Reserved for phase 2.
  esso('Esso');

  const LoyaltyBrand(this.canonicalBrand);

  /// Canonical brand string used by [BrandRegistry] and Station data.
  /// Match a station's `brand` field against this string (after running
  /// it through `BrandRegistry.canonicalize`) to know whether a card
  /// applies.
  final String canonicalBrand;

  /// Resolve a [LoyaltyBrand] from the canonical brand string returned
  /// by `BrandRegistry.canonicalize`. Returns `null` when no card brand
  /// matches — the caller falls through to "no discount".
  static LoyaltyBrand? fromCanonical(String? canonical) {
    if (canonical == null) return null;
    for (final brand in LoyaltyBrand.values) {
      if (brand.canonicalBrand == canonical) return brand;
    }
    return null;
  }
}

/// A user-registered fuel-club card (#1120 pilot).
///
/// The pilot is deliberately offline — the discount is a
/// user-entered number per card (e.g. `0.05 €/L Club Total`). Real
/// network integration with each operator's API is the next phase
/// (see issue body) and would replace [discountPerLiter] with a
/// fetched value while keeping the rest of the entity unchanged.
///
/// Stored as a plain JSON payload in the encrypted `settings` Hive
/// box (same idiom as the other settings-side entities), so the
/// pilot needs no new Hive box and no Hive adapter.
@freezed
abstract class LoyaltyCard with _$LoyaltyCard {
  const factory LoyaltyCard({
    /// Stable id, generated client-side. UUID-ish strings are fine —
    /// the field is opaque to the storage layer.
    required String id,

    /// The fuel-club brand this card belongs to. Matched against a
    /// station's canonical brand at price-display time.
    required LoyaltyBrand brand,

    /// Per-litre discount in the active country's currency, applied
    /// when the user fills up at a [brand] station. Stored as a
    /// positive number; the price-display layer subtracts it.
    /// Validated `> 0` at create time; defensive code in the price
    /// formatter still guards against negative values surviving a
    /// hand-edited Hive dump.
    required double discountPerLiter,

    /// Free-form short label the user attaches to the card so they
    /// can tell two cards of the same brand apart (e.g. "Personal"
    /// vs. "Company"). Optional — defaults to the brand's
    /// `canonicalBrand` when blank.
    required String label,

    /// When the card was added. Used purely for display ordering on
    /// the settings sub-screen (newest-first).
    required DateTime addedAt,

    /// User toggle that hides this card from the active discount map
    /// without deleting it. Disabled cards never apply a discount and
    /// never produce a badge on the station card.
    @Default(true) bool enabled,
  }) = _LoyaltyCard;

  factory LoyaltyCard.fromJson(Map<String, dynamic> json) =>
      _$LoyaltyCardFromJson(json);
}
