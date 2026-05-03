import 'adapter_capability.dart';
import 'oem_pid_table.dart';

/// Registry of [OemPidTable] implementations keyed by VIN WMI prefix
/// (#1401 phase 3).
///
/// Phase 3 ships the registry empty by default — the first concrete
/// table (PSA) lands in phase 4. Until then, [resolveForCapability]
/// returns null for every VIN, so callers behave as if the feature
/// were off. This serves as the implicit kill-switch while a proper
/// `experimental_oem_pids` feature flag is plumbed in alongside the
/// #1373 feature-management rework.
///
/// ## Capability gate
///
/// [resolveForCapability] is the SINGLE entry point production
/// callers should use. It encodes the rule that OEM-specific PIDs are
/// only attempted when the connected adapter is at tier
/// [Obd2AdapterCapability.oemPidsCapable] or higher. Bypassing the
/// gate via [lookupByVin] / [lookupByWmi] would let `standardOnly`
/// cheap clones attempt header-switching commands they cannot route,
/// hanging the OBD-II loop on guaranteed timeouts.
///
/// ## Overlap precedence
///
/// If two registered tables both claim the same WMI prefix, the
/// FIRST table in registration order wins. This is documented and
/// intentional — registration order is controlled by the same code
/// that ships the tables, so a clash is a programming error caught
/// in review, not a runtime surprise. The "first-wins" rule is
/// simpler than asserting (which would crash on adapter pair) and
/// easier than throwing (which would force every call site to
/// try/catch). Tests cover the precedence contract explicitly.
class OemPidRegistry {
  /// Tables registered with this registry, in registration order.
  /// Lookups iterate this list and stop at the first match — see
  /// "Overlap precedence" in the class docstring.
  final List<OemPidTable> _tables;

  /// Create a registry holding [tables]. The default empty list is
  /// the production path until phase 4 lands the PSA table; tests
  /// inject fakes via the parameter.
  OemPidRegistry({List<OemPidTable> tables = const []})
      : _tables = List.unmodifiable(tables);

  /// Find the table claiming [wmiPrefix] (3 upper-case VIN chars).
  ///
  /// Comparison is case-insensitive — callers may pass `'vf3'` and
  /// hit a table that registered `'VF3'`. Returns null when:
  ///   * no table claims the prefix,
  ///   * [wmiPrefix] is shorter than 3 characters,
  ///   * the registry is empty (phase 3 default state).
  ///
  /// This method does NOT enforce the [Obd2AdapterCapability] gate —
  /// it's a primitive lookup. Production code should call
  /// [resolveForCapability] instead.
  OemPidTable? lookupByWmi(String wmiPrefix) {
    if (wmiPrefix.length < 3) return null;
    final normalized = wmiPrefix.substring(0, 3).toUpperCase();
    for (final table in _tables) {
      if (table.supportedWmiPrefixes.contains(normalized)) {
        return table;
      }
    }
    return null;
  }

  /// Convenience: extract the WMI prefix (first 3 chars) from [vin]
  /// and delegate to [lookupByWmi]. Returns null when [vin] is
  /// shorter than 3 characters; otherwise behaves identically to
  /// passing `vin.substring(0, 3)` directly.
  ///
  /// Does NOT enforce the capability gate — see [resolveForCapability]
  /// for the safe entry point.
  OemPidTable? lookupByVin(String vin) {
    if (vin.length < 3) return null;
    return lookupByWmi(vin.substring(0, 3));
  }

  /// Resolve the OEM table that should be used for [vin] given the
  /// connected adapter's [capability]. Returns null when:
  ///   * [capability] is [Obd2AdapterCapability.standardOnly] (cheap
  ///     clones can't route OEM commands — even attempting one stalls
  ///     the OBD-II loop on a guaranteed timeout),
  ///   * [vin] is null or shorter than 3 characters (no WMI prefix
  ///     available),
  ///   * no registered table claims the WMI prefix (most cars in the
  ///     wild — only PSA / VAG / a handful of OEMs are worth tabling),
  ///   * the registry is empty (phase 3 default).
  ///
  /// Tiers [Obd2AdapterCapability.oemPidsCapable] and
  /// [Obd2AdapterCapability.passiveCanCapable] both pass the gate —
  /// passive-CAN-capable adapters are a strict superset of OEM-PID
  /// capable ones. The semantics match the existing `>=` comparator
  /// promise on the enum.
  ///
  /// This is the ONE method callers should reach for. The
  /// capability check is encoded here so call sites can't
  /// accidentally bypass it by routing through [lookupByVin] /
  /// [lookupByWmi] (which stay public for tests + diagnostics).
  OemPidTable? resolveForCapability(
    String? vin,
    Obd2AdapterCapability capability,
  ) {
    if (capability == Obd2AdapterCapability.standardOnly) return null;
    if (vin == null) return null;
    return lookupByVin(vin);
  }
}
