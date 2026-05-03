/// Runtime capability tier of the connected ELM327-compatible adapter
/// (#1401 phase 1).
///
/// Orthogonal to [Obd2AdapterCompatibility] in `adapter_registry.dart`,
/// which classifies hardware MODELS we've verified work end-to-end.
/// This enum captures what the *current* connected adapter session can
/// actually do at runtime — derived from the firmware-version string
/// the adapter returns to `ATI`. Two units of the same physical model
/// can land on different capability tiers (e.g. a real OBDLink MX+
/// vs. a counterfeit clone selling under the same name).
///
/// Order matters. The comparator semantics are
///   passiveCanCapable >= oemPidsCapable >= standardOnly
/// — phases 2-7 of the epic gate behaviour with `>=` checks against
/// these values, so reordering would silently flip those gates.
enum Obd2AdapterCapability {
  /// OBD-II standard mode 01-09 PIDs only. Cheap clones, ELM327 v1.x.
  standardOnly,

  /// Manufacturer-specific PIDs reachable via header switching + raw
  /// commands. Genuine ELM327 v2.x and equivalent clones.
  oemPidsCapable,

  /// Listen-mode CAN bus access (passive sniffing of broadcast frames).
  /// STN-chip family — OBDLink MX+/LX/CX/EX (STN1110 / STN2120).
  passiveCanCapable,
}

/// Pure parser: classify an `ATI` firmware-version response string into
/// a runtime capability tier.
///
/// Matching rules (case-insensitive, leading/trailing whitespace
/// trimmed before matching):
///   * Starts with `STN1110` or `STN2120` (any version) →
///     [Obd2AdapterCapability.passiveCanCapable].
///   * `ELM327 v2.2`, `v2.3`, ..., `v3.x`, ... (genuine v2.2+) →
///     [Obd2AdapterCapability.oemPidsCapable].
///   * Anything else, including `ELM327 v2.0`, `ELM327 v2.1`,
///     `ELM327 v1.x`, empty, null, garbage →
///     [Obd2AdapterCapability.standardOnly].
///
/// Phase 1 trusts the version string. The well-known
/// "v2.1 clone claiming v2.2" trap is explicitly out of scope here —
/// a runtime feature-probe that downgrades lying clones is filed in
/// the epic (#1401) caveats and lands in a later phase.
Obd2AdapterCapability detectCapabilityFromFirmwareString(String? ati) {
  if (ati == null) return Obd2AdapterCapability.standardOnly;
  final normalized = ati.trim().toUpperCase();
  if (normalized.isEmpty) return Obd2AdapterCapability.standardOnly;

  // STN-chip family — passive CAN listen-mode capable.
  if (normalized.startsWith('STN1110') || normalized.startsWith('STN2120')) {
    return Obd2AdapterCapability.passiveCanCapable;
  }

  // Genuine ELM327 v2.2+ — OEM-PID capable.
  // Pattern: `ELM327 v(2.[2-9]|[3-9](\.\d+)?)` — accepts v2.2, v2.3,
  // ..., v2.9, v3, v3.x, v4, ... but NOT v2.0 / v2.1 / v1.x.
  final match =
      RegExp(r'^ELM327\s+V(\d+)(?:\.(\d+))?').firstMatch(normalized);
  if (match != null) {
    final major = int.parse(match.group(1)!);
    final minor = int.tryParse(match.group(2) ?? '0') ?? 0;
    if (major >= 3) return Obd2AdapterCapability.oemPidsCapable;
    if (major == 2 && minor >= 2) return Obd2AdapterCapability.oemPidsCapable;
  }

  return Obd2AdapterCapability.standardOnly;
}
