// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

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

  /// Decodes a persisted composition.
  ///
  /// A component name this build does not know is folded into
  /// [FuelComponent.unknown] rather than thrown on: a record written by a
  /// newer model version must still decode, and "there is some fuel here
  /// whose nature I cannot name" is exactly what `unknown` means. Throwing
  /// would make a forward-version record unreadable, which is the same
  /// class of failure as losing it.
  ///
  /// Folding is additive because several unrecognized components may
  /// collapse onto the one bucket, and the fractions must still sum to 1.
  factory FuelComposition.fromJson(Map<String, Object?> json) {
    final byName = {for (final c in FuelComponent.values) c.name: c};
    final folded = <FuelComponent, double>{};
    for (final entry in json.entries) {
      final component = byName[entry.key] ?? FuelComponent.unknown;
      final value = (entry.value as num).toDouble();
      folded[component] = (folded[component] ?? 0) + value;
    }
    return FuelComposition(folded);
  }
}
