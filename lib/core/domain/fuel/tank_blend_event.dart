// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'fuel_grade.dart';

/// One immutable input to the tank blend fold (#4275): something that
/// physically changed what is in the tank.
///
/// The blend state is never edited in place — it is a fold of these events
/// in canonical order ([compareCanonically]). Identity is the [id]: an
/// event whose id was already applied is a no-op, which is what makes a
/// replay after a restart, a duplicate delivery or an offline catch-up
/// idempotent. The id must therefore be stable for the underlying fact
/// (a fill-up id, a trip id), never generated per delivery.
sealed class TankBlendEvent {
  TankBlendEvent({required this.id, required this.at}) {
    if (id.isEmpty) throw ArgumentError.value(id, 'id', 'must not be empty');
  }

  /// Stable identity of the underlying fact.
  final String id;

  /// When the fact happened. Orders the log; ties are broken by kind
  /// (consumption before fill) and then by [id].
  final DateTime at;

  /// Rank used to order two events at the same instant. Fuel burned "at"
  /// the moment of a fill was burned before the pump started.
  int get _kindRank;

  /// Canonical, deterministic encoding. Feeds the log fingerprint, so two
  /// events with equal JSON are the same fact and any payload change is
  /// visible to [TankBlendEngine.resume].
  Map<String, Object?> toJson();

  /// Total order over events: time, then kind, then id.
  static int compareCanonically(TankBlendEvent a, TankBlendEvent b) {
    final byTime = a.at.microsecondsSinceEpoch
        .compareTo(b.at.microsecondsSinceEpoch);
    if (byTime != 0) return byTime;
    final byKind = a._kindRank.compareTo(b._kindRank);
    if (byKind != 0) return byKind;
    return a.id.compareTo(b.id);
  }
}

/// Litres of one commercial grade entering the tank.
///
/// What the fill says about the fuel that was ALREADY in the tank is
/// carried as evidence, strongest first:
///
///  1. [fillsTank] with a known tank capacity — the residual is exactly
///     `capacity − litres`;
///  2. [levelBeforeLitres] — a reading of the residual (OBD2 or user);
///  3. neither — the engine uses the volume interval it has tracked.
///
/// [grade] may be [FuelGrade.unknown]: those litres enter the tank as
/// uncharacterised fuel and grow the unknown share rather than being
/// guessed. Non-liquid grades (CNG, hydrogen, electricity) and the search
/// wildcard are rejected — none of them is a litre in a fuel tank.
final class TankFillEvent extends TankBlendEvent {
  TankFillEvent({
    required super.id,
    required super.at,
    required this.grade,
    required this.litres,
    this.fillsTank = false,
    this.levelBeforeLitres,
  }) {
    if (!(grade.isLiquid || grade == FuelGrade.unknown)) {
      throw ArgumentError.value(grade, 'grade', 'not a liquid tank fuel');
    }
    if (!litres.isFinite || litres <= 0) {
      throw ArgumentError.value(litres, 'litres', 'must be finite and > 0');
    }
    final level = levelBeforeLitres;
    if (level != null && (!level.isFinite || level < 0)) {
      throw ArgumentError.value(level, 'levelBeforeLitres');
    }
  }

  final FuelGrade grade;
  final double litres;

  /// The user (or the flow) says the tank was brim-full afterwards.
  final bool fillsTank;

  /// Litres already in the tank when the pump started, when measured.
  final double? levelBeforeLitres;

  @override
  int get _kindRank => 1;

  @override
  Map<String, Object?> toJson() => {
        'type': 'fill',
        'id': id,
        'at': at.microsecondsSinceEpoch,
        'grade': grade.key,
        'litres': litres,
        'fillsTank': fillsTank,
        'levelBefore': levelBeforeLitres,
      };
}

/// Fuel leaving the tank, as an honest interval `[minLitres, maxLitres]`.
///
/// Consumption never changes the ratio of what is left — fuel is drawn
/// from a mixed tank — so it only moves the tracked volume. The interval
/// is how a caller states how far the figure can be trusted:
///
///  * [TankConsumptionEvent.exact] — a measured figure;
///  * [TankConsumptionEvent.unmeasured] — driving happened, the litres are
///    not known (`[0, ∞)`): the lower volume bound drops to zero and the
///    upper bound stays put. "Unknown is not zero" — an unmeasured drive
///    is NOT a zero-litre drive.
final class TankConsumptionEvent extends TankBlendEvent {
  TankConsumptionEvent({
    required super.id,
    required super.at,
    required this.minLitres,
    required this.maxLitres,
  }) {
    if (!minLitres.isFinite || minLitres < 0) {
      throw ArgumentError.value(minLitres, 'minLitres');
    }
    final max = maxLitres;
    if (max != null && (!max.isFinite || max < minLitres)) {
      throw ArgumentError.value(max, 'maxLitres', 'must be >= minLitres');
    }
  }

  /// A figure trusted as the actual litres burned.
  factory TankConsumptionEvent.exact({
    required String id,
    required DateTime at,
    required double litres,
  }) =>
      TankConsumptionEvent(id: id, at: at, minLitres: litres, maxLitres: litres);

  /// Driving whose fuel is not known at all.
  factory TankConsumptionEvent.unmeasured({
    required String id,
    required DateTime at,
  }) =>
      TankConsumptionEvent(id: id, at: at, minLitres: 0, maxLitres: null);

  final double minLitres;

  /// Null means unbounded — nothing caps what may have been burned.
  final double? maxLitres;

  bool get isExact => maxLitres == minLitres;

  @override
  int get _kindRank => 0;

  @override
  Map<String, Object?> toJson() => {
        'type': 'consumption',
        'id': id,
        'at': at.microsecondsSinceEpoch,
        'min': minLitres,
        'max': maxLitres,
      };
}
