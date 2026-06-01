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
bool shouldConnectFromScan({
  required int? lastSuccessfulRssi,
  required int seenRssi,
  required int consecutiveBatchesSeen,
  String? transportHint,
  int relativeDropDbm = 15,
  int requiredConsecutiveBatches = 2,
}) {
  // #2565 — a bonded Classic sighting (no RSSI; the `0` sentinel) is in range
  // by construction: connect on the first batch, never wait for a second one.
  if (transportHint == 'classic' && seenRssi == 0) return true;
  final seenEnoughTimes = consecutiveBatchesSeen >= requiredConsecutiveBatches;
  if (lastSuccessfulRssi == null) return seenEnoughTimes;
  final strongEnough = seenRssi >= lastSuccessfulRssi - relativeDropDbm;
  return strongEnough || seenEnoughTimes;
}
