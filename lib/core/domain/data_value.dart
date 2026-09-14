// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// One shape for "measured / estimated / stale / unknown" (#4160, Epic
/// #4155).
///
/// The app already knew this distinction in the four places where getting
/// it wrong was most expensive, and invented it four times:
///
///  * `FuelConsumptionFigure` carries `measured` / `estimated`, and
///    `docs/specs/refuel-economics.md` trust rule 2 makes an explanation
///    built on an estimate read as `≈`;
///  * `TripSummary.distanceSource` distinguishes GPS from virtual;
///  * `RefuelProfile` carries a `consumptionIsEstimated` bool beside the
///    number;
///  * price freshness is a `priceAge` the caller has to remember to check.
///
/// Each of those is a flag *beside* a value, and nothing stops the flag
/// being dropped on the way to a widget — which is exactly how a `≈` goes
/// missing. A sealed type cannot be silently lost: a caller either
/// switches exhaustively or does not compile.
///
/// [Unknown] carrying a reason is the other half. Trust rule 1 says a
/// missing input is *stated*, never defaulted, and a nullable `double`
/// cannot say **why** it is null. The reason is an enum, not prose, so
/// what the user reads comes out of the ARB like every other string
/// (HARD RULE #1).
///
/// ## Scope, deliberately staged
///
/// Adopted where the distinction already exists and is load-bearing —
/// consumption, distance source, price freshness, provider-published
/// facts. Deliberately NOT swept through every model: a generalisation
/// applied everywhere is how a good abstraction becomes ceremony.
library;

import 'package:meta/meta.dart';

/// Why a value is not known.
///
/// An enum rather than a `String` so the user-facing text is an ARB key
/// (`DataValueLabels.unknownReason`) and the set of reasons is closed —
/// a new reason has to be translated, not invented at a call site.
enum DataUnknownReason {
  /// The upstream provider does not publish this fact at all — a fact
  /// about the PROVIDER, not about this row. #4156's capability contract
  /// is what can say this.
  notPublishedByProvider,

  /// The provider publishes it, but not for this particular row.
  notPublishedForThisItem,

  /// We could measure it, but the user has no history yet.
  notMeasuredYet,

  /// The input the calculation needs is missing from the vehicle profile.
  missingVehicleData,

  /// The upstream sent something we could not read. A parse failure is
  /// not the same as an absence and must not read like one.
  unreadable,
}

/// What an estimate is built on.
///
/// Same rule as [DataUnknownReason]: closed set, ARB-backed text. "≈" on
/// its own tells the user the number is modelled; the basis tells them
/// whether that model knows anything about *their* car.
enum DataBasis {
  /// A published figure for the vehicle model (catalogue / manufacturer).
  vehicleCatalog,

  /// A class average — nothing specific to this vehicle.
  fleetAverage,

  /// Derived from other measured values rather than observed directly
  /// (e.g. a route distance scaled by the crow-flies road factor).
  derived,
}

/// A value that carries how much it may be trusted.
///
/// Sealed: `switch` over it is exhaustive, so a rendering path cannot
/// forget a case. Prefer switching over reaching for [valueOrNull] —
/// the point of the type is that the provenance travels with the number.
@immutable
sealed class DataValue<T> {
  const DataValue();

  /// Observed. [at] is when, where that is known and worth showing.
  const factory DataValue.measured(T value, {DateTime? at}) = Measured<T>;

  /// Modelled. [basis] says from what.
  const factory DataValue.estimated(T value, {required DataBasis basis}) =
      Estimated<T>;

  /// Measured once, but too long ago to present as current. [age] is how
  /// long ago; the caller decides the threshold, this type only records
  /// that the decision came out "stale".
  const factory DataValue.stale(T value, {required Duration age}) = Stale<T>;

  /// Not known, and why.
  const factory DataValue.unknown({required DataUnknownReason reason}) =
      Unknown<T>;

  /// The value when there is one, else null.
  ///
  /// The escape hatch for arithmetic, which genuinely does not care how
  /// a number was obtained. It is NOT the way to render one — see the
  /// class doc.
  T? get valueOrNull => switch (this) {
        Measured<T>(:final value) => value,
        Estimated<T>(:final value) => value,
        Stale<T>(:final value) => value,
        Unknown<T>() => null,
      };

  /// Whether a value is present at all (of any provenance).
  bool get isKnown => this is! Unknown<T>;

  /// Whether presenting this value requires a caveat — the `≈` of trust
  /// rule 2, or a "last seen" for a stale one.
  bool get isQualified => this is Estimated<T> || this is Stale<T>;

  /// Apply [transform] to the value, keeping the provenance. An unknown
  /// stays unknown *with its reason*, which is the whole point: mapping
  /// must not be able to launder a missing value into a present one.
  DataValue<R> map<R>(R Function(T value) transform) => switch (this) {
        Measured<T>(:final value, :final at) =>
          DataValue<R>.measured(transform(value), at: at),
        Estimated<T>(:final value, :final basis) =>
          DataValue<R>.estimated(transform(value), basis: basis),
        Stale<T>(:final value, :final age) =>
          DataValue<R>.stale(transform(value), age: age),
        Unknown<T>(:final reason) => DataValue<R>.unknown(reason: reason),
      };
}

/// Observed.
@immutable
final class Measured<T> extends DataValue<T> {
  const Measured(this.value, {this.at});

  final T value;

  /// When it was observed, where the source tells us.
  final DateTime? at;

  @override
  bool operator ==(Object other) =>
      other is Measured<T> && other.value == value && other.at == at;

  @override
  int get hashCode => Object.hash(value, at);

  @override
  String toString() => 'Measured($value)';
}

/// Modelled rather than observed.
@immutable
final class Estimated<T> extends DataValue<T> {
  const Estimated(this.value, {required this.basis});

  final T value;
  final DataBasis basis;

  @override
  bool operator ==(Object other) =>
      other is Estimated<T> && other.value == value && other.basis == basis;

  @override
  int get hashCode => Object.hash(value, basis);

  @override
  String toString() => 'Estimated($value, ${basis.name})';
}

/// Measured, but too long ago to present as current.
@immutable
final class Stale<T> extends DataValue<T> {
  const Stale(this.value, {required this.age});

  final T value;
  final Duration age;

  @override
  bool operator ==(Object other) =>
      other is Stale<T> && other.value == value && other.age == age;

  @override
  int get hashCode => Object.hash(value, age);

  @override
  String toString() => 'Stale($value, ${age.inMinutes}min)';
}

/// Not known, and why.
@immutable
final class Unknown<T> extends DataValue<T> {
  const Unknown({required this.reason});

  final DataUnknownReason reason;

  @override
  bool operator ==(Object other) =>
      other is Unknown<T> && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;

  @override
  String toString() => 'Unknown(${reason.name})';
}
