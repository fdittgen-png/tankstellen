// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Per-PID configuration vocabulary shared by the `PidScheduler` selection
/// core and the `PidBandwidthGovernor` policy: the tiebreaker priority, the
/// cadence tier, and the [ScheduledPid] config object itself. Kept in its
/// own file so neither collaborator has to depend on the other just to
/// name a tier (#2457).
library;

/// Priority tier used as a tiebreaker when two subscribed PIDs have an
/// identical weight under the weighted round-robin selector.
///
/// The scheduler's primary selection metric is `(now − lastReadAt) × hz`,
/// so priority only matters when two PIDs are _exactly_ tied — e.g. both
/// subscribed on the same tick, or both have deterministic elapsed time.
enum PidPriority { high, medium, low }

/// Cadence class a subscribed PID belongs to (#2457). The four tiers
/// re-express the previous 3-tier layout on the same weighted round-robin
/// and give the bandwidth governor a coarse axis along which to demote the
/// least time-critical reads when an adapter can't keep up.
///
/// Carries no scheduling power of its own — selection is still driven
/// purely by `(now − lastReadAt) × hz`. It only tells the governor which
/// PIDs are safe to slow down (deeper = more expendable); [dynamics] is
/// NEVER demoted, so speed / RPM never starve.
enum PidTier {
  /// ~5 Hz — RPM, speed, throttle, fuel-rate driver. Protected by the floor.
  dynamics,

  /// ~2 Hz — commanded λ, engine load. Mixture under load.
  mixture,

  /// ~0.5 Hz — STFT, LTFT, IAT, baro. Slow ECU corrections / ambient.
  slowCorrection,

  /// ~0.1 Hz — coolant, fuel-tank level. Thermal / context; demoted first.
  thermalContext,
}

/// Configuration for a single subscribed PID in the `PidScheduler`.
///
/// The scheduler uses [hz] as the target refresh rate and computes each
/// tick's winner from `(now − lastReadAt) × hz`. A higher [hz] drags the
/// last-read timestamp toward "now" more aggressively, so fast-tier PIDs
/// naturally win more ticks than slow-tier PIDs.
///
/// [priority] is consulted only to break weight ties — it is _not_ a
/// hard override. A high-priority 0.1 Hz PID will still lose most ticks
/// to a medium-priority 5 Hz PID because its weight grows 50× slower.
class ScheduledPid {
  ScheduledPid({
    required this.hz,
    this.priority = PidPriority.medium,
    this.tier = PidTier.dynamics,
  })  : assert(hz > 0, 'hz must be > 0'),
        lastReadAt = null;

  /// Target refresh rate in hertz (reads per second).
  final double hz;

  /// Tiebreaker when two PIDs have an identical weight this tick.
  final PidPriority priority;

  /// Cadence class this PID belongs to (#2457). Drives nothing in the core
  /// selection math — it only tells the bandwidth governor which PIDs may
  /// be slowed down ([PidTier.dynamics] is never demoted).
  final PidTier tier;

  /// Timestamp of the most recent completed read, or `null` if the PID
  /// has been subscribed but never read yet. A `null` here makes the PID
  /// win the next tick unconditionally — a brand-new subscription should
  /// get one initial read before the round-robin math kicks in.
  DateTime? lastReadAt;
}
