// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Chemical components. Unknown is explicit and never equivalent to zero.
enum FuelComponent { petrol, ethanol, diesel, lpg, unknown }

/// Validated volume fractions from composition evidence, not grade names.
/// Fractions sum to one; absent known components mean exactly zero only when
/// [unknownFraction] is zero. Nominal E5/E10/E85 labels alone remain unknown.
final class FuelComposition {
  FuelComposition(Map<FuelComponent, double> fractions)
      : fractions = Map.unmodifiable(fractions) {
    if (fractions.isEmpty ||
        fractions.values.any((v) => !v.isFinite || v < 0 || v > 1) ||
        (fractions.values.fold(0.0, (a, b) => a + b) - 1).abs() > 1e-9) {
      throw ArgumentError.value(fractions, 'fractions');
    }
  }

  factory FuelComposition.unknown() =>
      FuelComposition({FuelComponent.unknown: 1});

  final Map<FuelComponent, double> fractions;
  double get unknownFraction => fractions[FuelComponent.unknown] ?? 0;

  /// Null when an uncharacterized part could contain this component.
  double? exactFraction(FuelComponent component) => unknownFraction > 0
      ? null
      : fractions[component] ?? 0;

  Map<String, Object?> toJson() => {
        for (final component in FuelComponent.values)
          if (fractions.containsKey(component))
            component.name: fractions[component],
      };

  factory FuelComposition.fromJson(Map<String, Object?> json) =>
      FuelComposition({
        for (final entry in json.entries)
          FuelComponent.values.byName(entry.key): (entry.value as num).toDouble(),
      });
}
