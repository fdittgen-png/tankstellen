// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// Country-aware fuel resolution for profile creation (#4258, Epic #4257).
///
/// A [UserProfile]'s `preferredFuelType` is **not** portable across
/// countries: Austria's config sells E5/diesel/electric and no E10, so
/// cloning a German E10 profile into Austria would create a profile whose
/// grade has no priced data there — an empty country leg caused purely by
/// the copied fuel choice.
///
/// ## This is a capability question, not a compatibility question
///
/// `compatibleFuelsFor` (#713) answers "what can this *car* physically be
/// filled with", which is why it groups E85 with E5/E10/E98 — a petrol
/// engine accepts all of them at the pump. That is the wrong question
/// here. Substituting E5 for an E85 driver's profile would silently
/// change *which product the user buys*, so this resolver defines its own,
/// far narrower **price-substitution** equivalence and uses
/// [fuelCompatibilityFamily] only as a guard that a substitution can never
/// cross a family boundary.
///
/// ## The only sanctioned substitution is E5 ↔ E10
///
/// #2641/#2680 established it in the corridor price resolver: E5 and E10
/// are the two 95-octane unleaded representations of the same product.
///
/// Note the layer difference, because it changes the answer for Spain.
/// #2641 is about *station* pricing — Spain sells "Gasolina 95 E5" and
/// 769 of 798 province-08 stations price E5 while ~1 prices E10 — so the
/// route resolver swaps grade per station. This resolver answers the
/// *country capability* question instead, and Spain's config does list
/// `e10`, so an E10 profile is RETAINED for ES here. The countries that
/// genuinely lack E10 (Austria, Italy) are the ones that substitute.
/// Shared semantics, separate code: #4258 — "do not make generic nearby
/// search silently adopt route-specific sibling fallback".
///
/// E85, E98, diesel, LPG, CNG, hydrogen and electric have **no**
/// substitute. When the target country does not sell the grade, the
/// honest answer is that the country cannot be set up automatically —
/// never a quietly different product.
library;

import '../domain/fuel_type.dart';
import 'country_config.dart';

/// Why [CountryFuelCapability.resolveForCountry] returned what it did.
///
/// A reason **code**, not a message: the UI owns the wording (ARB), this
/// layer owns the decision. #4258 — "return a localization key/reason code
/// for UI rather than hard-coded text".
enum FuelResolutionReason {
  /// The source fuel is sold in the target country; it was kept as-is.
  retained,

  /// The source grade is not sold there, but its 95-octane unleaded
  /// sibling is (E5 ↔ E10, #2641). The user buys the same product under
  /// the country's own name for it.
  substitutedOctaneSibling,

  /// The country is known but sells none of the source grade and has no
  /// sanctioned substitute for it. The country cannot be configured
  /// automatically from this profile.
  unsupportedInCountry,

  /// No [CountryConfig] is registered for the code at all — an
  /// unsupported country rather than a fuel problem.
  unknownCountry,

  /// The source fuel is [FuelType.all], the search-time wildcard. It is
  /// never a real preference and so can never be cloned into a profile.
  sourceIsWildcard,
}

/// The outcome of resolving a source profile's fuel for a target country.
///
/// [fuel] is null exactly when [isResolved] is false, so a caller cannot
/// accidentally create a profile from an unusable result.
class CountryFuelResolution {
  const CountryFuelResolution._(this.fuel, this.reason);

  /// The grade to persist on the new country profile, or null when the
  /// country cannot be configured automatically.
  final FuelType? fuel;

  /// Why this is the answer — for UI copy and for tests.
  final FuelResolutionReason reason;

  /// Whether a profile can be created for the country from this result.
  bool get isResolved => fuel != null;

  @override
  String toString() =>
      'CountryFuelResolution(${fuel?.apiValue ?? 'none'}, ${reason.name})';
}

/// Resolves which fuel a cloned profile should carry in a target country,
/// reading the per-country `supportedFuelTypes` SSoT (`Countries`)
/// rather than holding a second copy of country/fuel knowledge.
///
/// `fuel_type_picker_provider.dart` (#703) anticipated exactly this
/// consumer: "Future: profile-save validator that rejects a
/// preferredFuelType not in this list."
class CountryFuelCapability {
  const CountryFuelCapability._();

  /// The 95-octane unleaded pair — the only grades this resolver will
  /// ever exchange for one another (#2641/#2680).
  static const Map<FuelType, FuelType> _octaneSiblings = {
    FuelType.e5: FuelType.e10,
    FuelType.e10: FuelType.e5,
  };

  /// The grades [countryCode] sells, wildcard excluded, or an empty set
  /// when the country is not registered.
  ///
  /// Mirrors `fuelTypePickerProvider`'s filter: [FuelType.all] is a
  /// search-time wildcard, never a storable preference.
  static Set<FuelType> supportedFuels(String countryCode) {
    final config = Countries.byCode(countryCode.toUpperCase());
    if (config == null) return const {};
    return config.supportedFuelTypes
        .where((FuelType f) => f != FuelType.all)
        .toSet();
  }

  /// Whether [countryCode] sells [fuel] as a priced grade.
  static bool supports(String countryCode, FuelType fuel) =>
      supportedFuels(countryCode).contains(fuel);

  /// Resolve [sourceFuel] — the fuel of the profile being used as a
  /// template — into the grade a new [countryCode] profile should carry.
  ///
  /// Priority, per #4258:
  /// 1. keep [sourceFuel] when the country sells it;
  /// 2. use the 95-octane sibling when that is what the country sells;
  /// 3. otherwise report the country as not automatically configurable.
  ///
  /// Step 3 deliberately does **not** fall back to "the country's default
  /// petrol grade": a diesel driver handed a petrol profile, or an E85
  /// driver handed E5, would be sent to buy the wrong product. An
  /// explanation beats a wrong default.
  static CountryFuelResolution resolveForCountry({
    required String countryCode,
    required FuelType sourceFuel,
  }) {
    if (sourceFuel == FuelType.all) {
      return const CountryFuelResolution._(
          null, FuelResolutionReason.sourceIsWildcard);
    }

    final supported = supportedFuels(countryCode);
    if (supported.isEmpty) {
      return const CountryFuelResolution._(
          null, FuelResolutionReason.unknownCountry);
    }

    if (supported.contains(sourceFuel)) {
      return CountryFuelResolution._(
          sourceFuel, FuelResolutionReason.retained);
    }

    final sibling = _octaneSiblings[sourceFuel];
    if (sibling != null && supported.contains(sibling)) {
      // Belt and braces: the sibling map only pairs E5/E10, which are the
      // same family by construction. The guard keeps that true if the map
      // is ever extended carelessly.
      if (fuelCompatibilityFamily(sibling) ==
          fuelCompatibilityFamily(sourceFuel)) {
        return CountryFuelResolution._(
            sibling, FuelResolutionReason.substitutedOctaneSibling);
      }
    }

    return const CountryFuelResolution._(
        null, FuelResolutionReason.unsupportedInCountry);
  }
}
