// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Pure decision for the in-trip reconnect SCAN fallback (#2245).
///
/// The reconnect path tries a direct GATT connect first; a scan is only
/// used as the ultimate fallback. When the scan path IS reached we must
/// decide whether a seen candidate is worth a connect attempt — a
/// far-away or one-off blip is a waste of a connect dance (and risks
/// latching onto the wrong, weaker advertisement of a neighbouring car's
/// adapter).
///
/// Deliberately NOT an absolute −85 dBm cutoff: the RSSI a given car +
/// phone combination sees at the dashboard varies wildly between
/// vehicles. Instead we gate RELATIVELY against the RSSI observed at the
/// last SUCCESSFUL connect this session, and additionally accept any MAC
/// that has been seen across two consecutive scan batches (a stable,
/// repeatable sighting, even if weak).
///
/// Connect when EITHER:
///   * the just-seen RSSI is within [relativeDropDbm] of the baseline
///     [lastSuccessfulRssi] (i.e. `seenRssi >= lastSuccessfulRssi −
///     relativeDropDbm`), OR
///   * the MAC has appeared in at least [requiredConsecutiveBatches]
///     consecutive scan batches.
///
/// When [lastSuccessfulRssi] is null (no successful connect recorded
/// yet this session) there is no relative baseline, so the decision
/// falls back to the consecutive-batches rule alone.
///
/// #2565 — Bluetooth **Classic** has no RSSI: a bonded device is reported by
/// the OS exactly once per scan window with [seenRssi] pinned at the `0`
/// sentinel (`ClassicBluetoothFacade` sets `rssi: 0`). Intervening BLE
/// batches reset the consecutive-batch counter, so a bonded Classic adapter
/// would never reach the two-consecutive-batches rule — the storm signature.
/// A bonded sighting is, by definition, in range and reachable, so when
/// [transportHint] is `'classic'` AND the sentinel RSSI is seen, the gate
/// passes on the FIRST batch. This is scoped to the Classic transport only —
/// a real BLE adapter never reports a 0 dBm RSSI, so the BLE gate is unchanged.
///
/// #2907 — the RECOVERY relaxation. The default gate (two consecutive batches
/// OR within 15 dBm of the last-good RSSI) is tuned for the INITIAL pick: it
/// guards against latching a neighbouring car's weaker adapter. But during an
/// in-trip RECONNECT the MAC is already pinned — there is no risk of picking
/// the wrong device — and a marginal, single-batch sighting of the pinned
/// adapter is exactly the recovery we want to attempt rather than spin the
/// backoff for another window. When [recovery] is true the gate therefore:
///   * widens the relative-RSSI tolerance to [recoveryRelativeDropDbm]
///     (default 35 dBm — a far weaker but still-reachable link is attempted
///     on the FIRST sighting), and
///   * with no baseline yet this drop, attempts ANY first sighting of the
///     pinned MAC, and
///   * still lets a SECOND consecutive sighting override even a beyond-the-
///     widened-window RSSI (a stable-but-very-weak link).
/// [recovery] defaults to false so every initial-pick call site is unchanged.
bool shouldConnectFromScan({
  required int? lastSuccessfulRssi,
  required int seenRssi,
  required int consecutiveBatchesSeen,
  String? transportHint,
  bool recovery = false,
  int relativeDropDbm = 15,
  int requiredConsecutiveBatches = 2,
  int recoveryRelativeDropDbm = 35,
}) {
  // #2565 — a bonded Classic sighting (no RSSI; the `0` sentinel) is in range
  // by construction: connect on the first batch, never wait for a second one.
  if (transportHint == 'classic' && seenRssi == 0) return true;
  // #2907 — RECOVERY: the pinned MAC was just seen, so attempt it eagerly.
  // No baseline ⇒ any first sighting connects; with a baseline the RSSI bar
  // is the widened recovery window (a far-but-reachable link on the first
  // sighting), and a second consecutive sighting overrides even that.
  if (recovery) {
    if (lastSuccessfulRssi == null) return true;
    return seenRssi >= lastSuccessfulRssi - recoveryRelativeDropDbm ||
        consecutiveBatchesSeen >= 2;
  }
  final seenEnoughTimes = consecutiveBatchesSeen >= requiredConsecutiveBatches;
  if (lastSuccessfulRssi == null) return seenEnoughTimes;
  final strongEnough = seenRssi >= lastSuccessfulRssi - relativeDropDbm;
  return strongEnough || seenEnoughTimes;
}
