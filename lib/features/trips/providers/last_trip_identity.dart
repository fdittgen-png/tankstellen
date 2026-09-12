// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Who the most recent trip belonged to and when it began — owned by the
/// recording notifier as a collaborator rather than as three loose fields
/// in its shared `part` scope (#4036, epic #4032).
///
/// The three travel together everywhere they are used: the save-as-fill-up
/// auto-link needs the vehicle to filter trajets by (#888) and the start
/// time as the "latest-known driving activity" lower bound when no prior
/// fill-up exists, and the WAL seed stamps all three so the recovery badge
/// and the saved entry know whether the trip was hands-free (#3251).
///
/// They were written from four of the library's files — the notifier's own
/// start path, the lifecycle part, the WAL-snapshot rehydrate and the host
/// adapter — with three different assignment shapes (hard set, fill-in-if-
/// absent, restore-from-snapshot). Each of those is a named method here,
/// so a caller picks the shape deliberately instead of reaching for `=`
/// or `??=` and hoping.
class LastTripIdentity {
  String? _vehicleId;
  DateTime? _startedAt;
  bool _automatic = false;

  /// Most recent vehicle id the provider kicked a trip for. Null before
  /// the first call, or after a reset / fresh build.
  String? get vehicleId => _vehicleId;

  /// Timestamp captured on the most recent start call.
  DateTime? get startedAt => _startedAt;

  /// #3251 — whether the live trip started hands-free.
  bool get automatic => _automatic;

  /// A start that KNOWS both: overwrite whatever a previous trip left.
  void begin({required String? vehicleId, required DateTime startedAt}) =>
      restore(vehicleId: vehicleId, startedAt: startedAt); // #4073 — one body

  /// #769 — the internal start path fills in only what the public entry
  /// did not already record, so a start that came through [begin] keeps
  /// its resolved values and one that did not still gets a lower bound.
  /// [vehicleIdIfAbsent] is a callback because resolving it costs a
  /// provider read that must not happen when the value is already there.
  void fillIn({
    required DateTime startedAtIfAbsent,
    required String? Function() vehicleIdIfAbsent,
  }) {
    _startedAt ??= startedAtIfAbsent;
    _vehicleId ??= vehicleIdIfAbsent();
  }

  /// #1347 — rehydrate from a WAL snapshot on cold-start recovery.
  void restore({required String? vehicleId, required DateTime? startedAt}) {
    _vehicleId = vehicleId;
    _startedAt = startedAt;
  }

  /// #3251 — stamp the trip's auto-record provenance for the WAL seed.
  void setAutomatic(bool value) => _automatic = value;

  /// Driven by the recording host adapter, whose setter-shaped contract
  /// predates this class.
  void setVehicleId(String? value) => _vehicleId = value;
  void setStartedAt(DateTime? value) => _startedAt = value;
}
