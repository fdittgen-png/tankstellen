import 'package:meta/meta.dart';

/// What kind of refueling a [RefuelProvider] dispenses. Used to
/// dispatch UI affordances (pump icon vs charging-bolt icon) and to
/// filter unified search results.
///
/// `both` covers operators that run mixed sites (e.g. a Total station
/// with on-site DC fast chargers). For phase 1 the value is informative
/// only — phase 2 adapters will set it from the underlying entity.
enum RefuelProviderKind {
  /// Liquid / gaseous fuel only (Tankerkönig, Prix Carburants, …).
  fuel,

  /// EV charging only (OpenChargeMap, Ionity, …).
  ev,

  /// Site offers both fuel pumps and chargers.
  both,
}

/// Identity of a refueling operator — brand for fuel, network for EV.
///
/// Phase 1 of the fuel/EV unification (#1116). Kept intentionally
/// minimal: a display [name] and a [kind] tag. Phase 2 adapters will
/// derive instances from `Station.brand` (fuel) or
/// `ChargingStation.operator` (EV).
@immutable
class RefuelProvider {
  /// Human-readable brand or network name (e.g. `"Total"`,
  /// `"Ionity"`, `"Tesla Supercharger"`). Empty string is a valid
  /// "unknown brand" sentinel — see [unknown].
  final String name;

  /// Whether this provider dispenses fuel, electrons, or both.
  final RefuelProviderKind kind;

  const RefuelProvider({
    required this.name,
    required this.kind,
  });

  /// Const sentinel used by adapters when the underlying station's
  /// brand / operator field is null or empty. Equality is by value,
  /// so two `RefuelProvider.unknown` references compare equal.
  static const RefuelProvider unknown = RefuelProvider(
    name: '',
    kind: RefuelProviderKind.fuel,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RefuelProvider && other.name == name && other.kind == kind;

  @override
  int get hashCode => Object.hash(name, kind);

  @override
  String toString() => 'RefuelProvider(name: $name, kind: $kind)';
}
