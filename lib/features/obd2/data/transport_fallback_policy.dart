// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'adapter_registry.dart';

/// Pure decision for the Classic↔BLE transport fallback (#2908).
///
/// When the transport the live link was using ([droppedTransport], the
/// `'ble'` / `'classic'` link-kind read off the dead service) exhausts its
/// own reconnect budget — a BLE GATT-133 storm or a Classic rfcomm-open-fail
/// across every direct + scan attempt — the in-trip reconnect should try the
/// OTHER transport for the same adapter rather than spin the backoff on the
/// transport that keeps failing. Many ELM327 clones expose BOTH a Classic SPP
/// and a BLE GATT endpoint, so the alternate often connects when the
/// preferred one is wedged.
///
/// Returns the transport to attempt next, or `null` when there is no usable
/// alternate:
///   * a Classic drop falls back to [BluetoothTransport.ble] (always
///     available — the BLE facade is mandatory), and
///   * a BLE / unknown drop falls back to [BluetoothTransport.classic] ONLY
///     when a Classic facade is wired ([hasClassicFacade]); a BLE-only build
///     (most test configs) has no alternate, so `null`.
///
/// [droppedTransport] is matched case-insensitively against the `'classic'`
/// link-kind tag; anything else (including `null` / `'ble'`) is treated as a
/// BLE-side drop, so an unknown live transport conservatively tries Classic.
BluetoothTransport? alternateReconnectTransport({
  required String? droppedTransport,
  required bool hasClassicFacade,
}) {
  final wasClassic = droppedTransport?.toLowerCase() == 'classic';
  if (wasClassic) {
    // Classic kept failing ⇒ try BLE (the BLE facade is always present).
    return BluetoothTransport.ble;
  }
  // BLE / unknown kept failing ⇒ try Classic, but only if it is wired.
  return hasClassicFacade ? BluetoothTransport.classic : null;
}
