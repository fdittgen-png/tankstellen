/// Actionable cross-border suggestion shown when the user is close to a
/// neighbor country whose fuel is cheaper than the current search.
///
/// Built by `crossBorderSuggestionProvider`; consumed by `CrossBorderBanner`.
/// `priceDeltaPerLiter` is positive when the neighbor is cheaper than the
/// current country's average (e.g. 0.12 means "€0.12/L cheaper across the
/// border"); negative or zero values mean "not actually cheaper" — those
/// are filtered out at the provider level so the banner only shows wins.
class CrossBorderSuggestion {
  /// ISO 3166-1 alpha-2 code of the neighboring country (e.g. 'FR').
  final String neighborCountryCode;

  /// Localized display name of the neighbor (e.g. 'France').
  final String neighborName;

  /// Flag emoji for the neighbor (e.g. '🇫🇷').
  final String neighborFlag;

  /// Distance from the user to the closest border crossing point (km).
  final double distanceKm;

  /// How much cheaper the neighbor's stations are vs. the current country
  /// for the user's fuel type (€/L, positive = cheaper across the border).
  final double priceDeltaPerLiter;

  /// Number of neighbor stations sampled to compute the average.
  final int sampleCount;

  const CrossBorderSuggestion({
    required this.neighborCountryCode,
    required this.neighborName,
    required this.neighborFlag,
    required this.distanceKm,
    required this.priceDeltaPerLiter,
    required this.sampleCount,
  });
}
