/// OEM-specific PID table abstraction (#1401 phase 3).
///
/// Standard OBD-II PID `0x2F` reports fuel level as 0-100% in coarse
/// steps (5-10% on most pre-2018 vehicles, 1% on modern PSAs).
/// For accurate fill-up reconciliation we want exact litres in tank,
/// which requires manufacturer-specific PIDs reachable only via
/// capable adapters (genuine ELM327 v2.2+ or STN-chip family — see
/// [Obd2AdapterCapability]).
///
/// Each [OemPidTable] subclass encapsulates one OEM's quirks:
///   * which 3-character VIN WMI prefixes the table claims
///     (e.g. PSA owns `VF3`, `VF7`, `VR1`, `VR3`)
///   * how to issue the OEM-specific request (header switch + Mode 22
///     / Mode 21 command) and parse the response into litres.
///
/// Phase 3 ships the abstraction and the lookup registry only — no
/// concrete tables. Phase 4 will register the first concrete table
/// (PSA, header `0x6FA`, command `21 51`, scaling `byte * 0.5` →
/// litres). Until then [OemPidRegistry] resolves to an empty list and
/// callers behave as if the feature were off — this serves as the
/// kill-switch while a feature-flag wiring (per epic #1401) is built
/// out alongside #1373's feature-management rework.
///
/// ## Parameter choice — [Obd2RawCommandPort] facade vs [Obd2Service]
///
/// Concrete tables need exactly one capability from the service:
/// "send a raw ELM327 command, give me the raw string response".
/// Reaching for the full [Obd2Service] would force test doubles to
/// stub a transport, supported-PID cache, breadcrumb collector and
/// adapter — none of which are relevant to an OEM read.
///
/// The narrow [Obd2RawCommandPort] facade exposes that single method.
/// [Obd2Service] adopts the interface via `implements`, so production
/// callers pass the live service unchanged. Tests pass a 5-line fake.
library;

/// Narrow port for OEM tables to issue raw commands against the
/// connected adapter (#1401 phase 3).
///
/// [Obd2Service] implements this interface formally — production
/// callers pass the live service unchanged. Tests pass a fake that
/// records the command and returns a canned response. Keeping the
/// surface to one method is deliberate: an OEM read is "send this
/// command, parse the bytes". Anything more belongs on the service
/// itself, not on this port.
abstract class Obd2RawCommandPort {
  /// Send [command] to the adapter and return the raw response string
  /// exactly as the adapter delivered it (CR/LF, prompt, headers and
  /// all). Implementations must not throw on transport hiccups —
  /// translate errors into an empty / NO-DATA-style response so the
  /// caller's parser can branch uniformly.
  ///
  /// [command] must already be CR-terminated (e.g. `'2151\r'`) — same
  /// contract as [Obd2Service.sendCommand]; this port is a verbatim
  /// pass-through.
  Future<String> sendRaw(String command);
}

/// Per-OEM table mapping a VIN's WMI prefix to a fuel-level read
/// strategy (#1401 phase 3).
///
/// Subclasses are intentionally tiny — one OEM, one or a handful of
/// WMI prefixes, one [readFuelLevelLitres] implementation. Adding a
/// new OEM is a new file plus a registry registration.
abstract class OemPidTable {
  const OemPidTable();

  /// Stable identifier used for logging / diagnostics
  /// (e.g. `'PSA'`, `'VAG'`, `'TOYOTA'`). Not user-facing — the UI
  /// derives the marketing name from the [VehicleProfile.make] string.
  String get oemKey;

  /// 3-character VIN WMI prefixes this OEM owns. Lookup is performed
  /// by [OemPidRegistry] after upper-casing the candidate prefix, so
  /// values stored here MUST be upper-case (e.g. `'VF3'`, not `'vf3'`).
  ///
  /// One table can claim multiple prefixes — PSA spans Peugeot
  /// (`'VF3'`), Citroën (`'VF7'`), and DS / overseas plants
  /// (`'VR1'`, `'VR3'`, ...).
  Set<String> get supportedWmiPrefixes;

  /// Read the exact fuel level in litres via the OEM-specific
  /// command. Returns null when:
  ///   * the adapter / ECU returned NO DATA (the car implements a
  ///     different platform than this table targets — older PSAs vs
  ///     EMP2, for example),
  ///   * the response was malformed (bad header echo, truncated
  ///     multi-frame),
  ///   * any transport-level error swallowed by the [port].
  ///
  /// The caller (typically the trip-recording fuel sampler or the
  /// fill-up reconciliation flow) treats null as "fall back to PID
  /// 0x2F percentage * tank capacity" — never as "tank is empty".
  Future<double?> readFuelLevelLitres(Obd2RawCommandPort port);
}
