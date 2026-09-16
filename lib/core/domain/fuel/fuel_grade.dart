// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Commercial grades, separate from chemical composition and price aliases.
/// E98 denotes octane, not 98% ethanol. No grade asserts an exact blend.
enum FuelGrade {
  e5('e5'),
  e10('e10'),
  e98('e98'),
  e85('e85'),
  diesel('diesel'),
  dieselPremium('diesel_premium'),
  lpg('lpg'),
  cng('cng'),
  hydrogen('hydrogen'),
  electric('electric'),
  wildcard('all'),
  unknown('unknown');

  const FuelGrade(this.key);
  final String key;

  static FuelGrade fromKey(String raw) {
    final key = raw.toLowerCase();
    if (key == 'dieselpremium') return dieselPremium;
    return values.firstWhere((g) => g.key == key, orElse: () => unknown);
  }

  bool get isLiquid => switch (this) {
        e5 || e10 || e98 || e85 || diesel || dieselPremium || lpg => true,
        _ => false,
      };
}

/// Explicit vehicle approval. A primary preference or a station price never
/// creates this contract. An empty approval set represents unknown capability.
final class VehicleFuelCapability {
  VehicleFuelCapability({
    required Iterable<FuelGrade> approvedGrades,
    required this.provenance,
  }) : approvedGrades = Set.unmodifiable(approvedGrades) {
    if (this.approvedGrades.any(
        (g) => g == FuelGrade.unknown || g == FuelGrade.wildcard)) {
      throw ArgumentError.value(approvedGrades, 'approvedGrades');
    }
    if (provenance.isEmpty) throw ArgumentError.value(provenance, 'provenance');
  }

  final Set<FuelGrade> approvedGrades;
  final String provenance;

  bool permits(FuelGrade grade) => approvedGrades.contains(grade);

  Map<String, Object?> toJson() => {
        'approvedGrades': approvedGrades.map((g) => g.key).toList()..sort(),
        'provenance': provenance,
      };

  factory VehicleFuelCapability.fromJson(Map<String, Object?> json) =>
      VehicleFuelCapability(
        approvedGrades: (json['approvedGrades'] as List<Object?>)
            .map((key) => FuelGrade.fromKey(key as String)),
        provenance: json['provenance'] as String,
      );
}
