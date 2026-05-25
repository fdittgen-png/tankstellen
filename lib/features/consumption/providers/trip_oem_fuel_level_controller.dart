// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/obd2/adapter_capability.dart';
import '../data/obd2/oem_pid_registry.dart';
import '../data/obd2/oem_pid_table.dart';

/// Owns the #1615 experimental OEM-PID exact-fuel-level concern: a slow
/// poll that reads exact litres-in-tank via a manufacturer [OemPidTable]
/// and pushes the value back into the trip-recording fuel sampler.
///
/// This is a provider-layer collaborator modelled on
/// [TripGpsStreamController] — the data-layer [TripRecordingController]
/// stays flag-unaware. The provider reads the `experimentalOemPids`
/// feature flag and hands the result to [start] as the [enabled] bool;
/// the [OemPidRegistry] only ever lives here.
///
///   * When [enabled] is false, [start] returns immediately, resolves
///     no table, and starts no timer — the bit-for-bit-unchanged
///     guarantee for every existing user (the `percent × capacity`
///     path keeps running untouched).
///   * The OEM read ([OemPidTable.readFuelLevelLitres]) is a
///     multi-command async sequence that does NOT fit the per-PID
///     `PidScheduler`, so it runs on a dedicated slow [Timer.periodic]
///     here — never on the scheduler tick and never on the controller's
///     emit timer. Fuel level changes slowly; a 10 s cadence matches
///     the standard 0.1 Hz `0x2F` subscription.
///
/// When [enabled] is true but the connected adapter is not
/// OEM-PID-capable (or the VIN resolves no manufacturer table), [start]
/// also returns without starting the timer — the latch is never
/// written and the sampler keeps running the coarse path.
class TripOemFuelLevelController {
  TripOemFuelLevelController({OemPidRegistry? registry})
      : _registry = registry ?? OemPidRegistry.withDefaults();

  /// The OEM-table registry. Production uses [OemPidRegistry.withDefaults]
  /// (PSA today; more OEMs in later issues). Tests inject a registry
  /// holding a fake table so the unit test never depends on a specific
  /// OEM wire protocol.
  final OemPidRegistry _registry;

  /// The slow OEM-read poll. Null whenever the feature is off for this
  /// trip — flag disabled, incapable adapter, or no matching table.
  Timer? _timer;

  /// The resolved OEM table for the current trip, captured at [start].
  OemPidTable? _table;

  /// Raw-command port for the connected adapter. [Obd2Service]
  /// implements [Obd2RawCommandPort]; captured at [start].
  Obd2RawCommandPort? _port;

  /// Sink for each successful litres reading — wired to
  /// `TripRecordingController.updateOemFuelLevelLitres` by the provider.
  void Function(double? litres)? _onLitres;

  /// Poll cadence. Fuel level drifts slowly, so a coarse interval keeps
  /// the adapter-channel cost negligible — it matches the standard
  /// `fuelTankLevelCommand` 0.1 Hz scheduler tier.
  static const Duration _readInterval = Duration(seconds: 10);

  /// Resolve the OEM table and, when one applies, start the slow poll.
  ///
  /// No-op (returns before touching the registry or any timer) when:
  ///   * [enabled] is false — `Feature.experimentalOemPids` is off, the
  ///     default for every user; this is the "otherwise
  ///     `percent × capacity` runs" branch of the #1615 acceptance,
  ///     kept bit-for-bit unchanged;
  ///   * the adapter is not OEM-PID-capable or [vin] resolves no
  ///     manufacturer table ([OemPidRegistry.resolveForCapability]
  ///     returns null) — the flag-on-incapable case.
  ///
  /// [onLitres] receives the exact litres on every successful read; a
  /// read returning null (NO DATA / negative response / transport
  /// error) leaves the previous latch untouched so a single bad poll
  /// does not blank a good reading.
  void start({
    required bool enabled,
    required String? vin,
    required Obd2AdapterCapability capability,
    required Obd2RawCommandPort port,
    required void Function(double? litres) onLitres,
  }) {
    if (!enabled) return;
    final table = _registry.resolveForCapability(vin, capability);
    if (table == null) return;
    _table = table;
    _port = port;
    _onLitres = onLitres;
    // Fire one read immediately so the first exact-litre value lands
    // without waiting a full interval, then poll on the slow timer.
    unawaited(_readOnce());
    _timer = Timer.periodic(_readInterval, (_) => unawaited(_readOnce()));
  }

  /// Tear down the poll. Best-effort: a null timer is the common case
  /// (flag off) and clearing the captured collaborators keeps a late
  /// timer callback from touching a torn-down trip.
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _table = null;
    _port = null;
    _onLitres = null;
  }

  /// One OEM read → latch push. Errors are logged and swallowed: an
  /// OEM read failure must never derail the OBD2 trip recording (same
  /// discipline as the GPS-stream collaborator). A null result is
  /// intentionally NOT forwarded — the sampler keeps the last good
  /// value rather than flapping to the percent path on one bad poll.
  Future<void> _readOnce() async {
    final table = _table;
    final port = _port;
    final onLitres = _onLitres;
    if (table == null || port == null || onLitres == null) return;
    try {
      final litres = await table.readFuelLevelLitres(port);
      if (litres != null) onLitres(litres);
    } catch (e, st) {
      debugPrint('TripRecording OEM fuel-level read failed: $e\n$st');
    }
  }

  /// Exposed for tests: run a single OEM read + latch push without
  /// waiting for the [Timer.periodic] cadence.
  @visibleForTesting
  Future<void> debugReadOnce() => _readOnce();

  /// Exposed for tests: true when [start] resolved a table and armed
  /// the poll (flag-on + OEM-capable adapter + matching table).
  @visibleForTesting
  bool get debugIsPolling => _timer != null;
}
