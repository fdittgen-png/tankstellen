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

/// The grades a flex-fuel petrol vehicle is built for: E0–E85 (#4324). The
/// one approval set both a configured E85 multi-fuel car and a declared
/// flex-fuel approval resolve to.
const List<FuelGrade> kFlexFuelGrades = [
  FuelGrade.e5,
  FuelGrade.e10,
  FuelGrade.e98,
  FuelGrade.e85,
];

/// Explicit vehicle approval. A primary preference or a station price never
/// creates this contract.
///
/// ## Unknown is a state, not an empty set
///
/// "The manufacturer approves nothing" is not a thing that exists, so an
/// empty [approvedGrades] would be an unreachable value masquerading as a
/// meaningful one. #4274 requires `unknown` to stay distinguishable from
/// an exact zero, so absence of knowledge gets its own representation
/// ([VehicleFuelCapability.unknown]) and [isUnknown] reports it. This
/// mirrors [FuelComposition.exactFraction], which answers `null` rather
/// than `0` when an uncharacterized part could contain the component.
///
/// [permits] therefore returns `false` for every grade when the capability
/// is unknown — "not known to be approved" — and callers that need to tell
/// "no" from "don't know" must consult [isUnknown]. Silently treating
/// unknown as approval is how an E85 fill reaches a car that cannot take
/// it.
///
/// ## Not the same question as `compatibleFuelsFor`
///
/// `fuelCompatibilityFamily` / `compatibleFuelsFor` in
/// `core/domain/fuel_type.dart` answer "what will physically go into this
/// filler neck" (#713) — a petrol car accepts any of E5/E10/E98/E85 at the
/// pump. This type answers "what the manufacturer approves", which is
/// strictly narrower: every E85-incapable petrol car accepts E85
/// physically and is damaged by it. The two must never be conflated, and
/// #4274 is explicit that approval is never inferred from an E5/E10
/// sibling mapping.
final class VehicleFuelCapability {
  VehicleFuelCapability({
    required Iterable<FuelGrade> approvedGrades,
    required this.provenance,
  }) : approvedGrades = Set.unmodifiable(approvedGrades) {
    if (this.approvedGrades.isEmpty) {
      throw ArgumentError.value(approvedGrades, 'approvedGrades',
          'empty means unknown — use VehicleFuelCapability.unknown()');
    }
    if (this.approvedGrades.any(
        (g) => g == FuelGrade.unknown || g == FuelGrade.wildcard)) {
      throw ArgumentError.value(approvedGrades, 'approvedGrades');
    }
    if (provenance.isEmpty) throw ArgumentError.value(provenance, 'provenance');
  }

  /// No approval information. Distinct from an approval set that happens
  /// to exclude a grade: this one knows nothing, so [permits] is `false`
  /// for everything and [isUnknown] is `true`.
  const VehicleFuelCapability.unknown()
      : approvedGrades = const <FuelGrade>{},
        provenance = 'unknown';

  final Set<FuelGrade> approvedGrades;
  final String provenance;

  /// Whether this carries no approval information at all.
  bool get isUnknown => approvedGrades.isEmpty;

  /// Whether [grade] is *known to be* approved. Always `false` when
  /// [isUnknown] — check that first if you need to distinguish "no" from
  /// "unknown".
  bool permits(FuelGrade grade) => approvedGrades.contains(grade);

  Map<String, Object?> toJson() => {
        'approvedGrades': approvedGrades.map((g) => g.key).toList()..sort(),
        'provenance': provenance,
      };

  /// Decodes a persisted capability.
  ///
  /// Grade keys this build does not recognize are **dropped**, not mapped
  /// onto [FuelGrade.unknown]: that sentinel is rejected by the
  /// constructor, so decoding it would turn a forward-version record into
  /// a crash. Dropping keeps the grades we do understand and never invents
  /// an approval. A record whose every grade is unrecognized decodes to
  /// [VehicleFuelCapability.unknown] rather than throwing.
  factory VehicleFuelCapability.fromJson(Map<String, Object?> json) {
    final byKey = {for (final g in FuelGrade.values) g.key: g};
    final known = <FuelGrade>{
      for (final raw in (json['approvedGrades'] as List<Object?>))
        if (byKey[(raw as String).toLowerCase()] case final FuelGrade g
            when g != FuelGrade.unknown && g != FuelGrade.wildcard)
          g,
    };
    final provenance = json['provenance'] as String;
    if (known.isEmpty) return const VehicleFuelCapability.unknown();
    return VehicleFuelCapability(
      approvedGrades: known,
      provenance: provenance.isEmpty ? 'unknown' : provenance,
    );
  }
}
