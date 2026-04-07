/// Data for a cross-border price comparison banner.
///
/// Shows the user how prices in a neighboring country compare
/// to the current search results.
class CrossBorderComparison {
  /// The neighboring country's config code (e.g., 'FR').
  final String neighborCode;

  /// The neighboring country's display name (e.g., 'France').
  final String neighborName;

  /// The neighboring country's flag emoji.
  final String neighborFlag;

  /// The neighboring country's currency symbol.
  final String neighborCurrency;

  /// Average price in the current country's search results.
  final double currentAvgPrice;

  /// Distance to the nearest border crossing in km.
  final double borderDistanceKm;

  /// Number of stations used to compute [currentAvgPrice].
  final int stationCount;

  const CrossBorderComparison({
    required this.neighborCode,
    required this.neighborName,
    required this.neighborFlag,
    required this.neighborCurrency,
    required this.currentAvgPrice,
    required this.borderDistanceKm,
    required this.stationCount,
  });
}
