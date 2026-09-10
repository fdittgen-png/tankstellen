// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../protocol/adapter_registry.dart';

/// #3572 — the no-scan profile fallbacks for the direct-connect-by-MAC
/// paths, where no scan resolved a profile and the quirks still have to
/// fit the real hardware.
///
/// #4035 (epic #4032) — a library of its own rather than a `part` of
/// `obd2_connection_service.dart`: both functions read the adapter
/// registry and nothing else, so they take the registry instead of the
/// service and never needed its private scope.

/// Generic FFF0 BLE profile used for direct/passive connect quirks +
/// display name when no scan resolved a profile.
Obd2AdapterProfile genericBleProfile(Obd2AdapterRegistry registry) =>
    registry.profiles.firstWhere(
      (p) => p.id == 'generic-fff0',
      orElse: () => registry.profiles.firstWhere(
        (p) => p.transport == BluetoothTransport.ble,
      ),
    );

/// Best Classic profile for an in-trip reconnect (#2565). No scan ran, so
/// the socket itself can't be name-matched — but the caller often KNOWS the
/// stored device name (#3572): name-match it against the registry first so
/// the init quirks fit the real hardware. Without a match, prefer the
/// `vlinker-fs-classic` profile (the dominant field adapter + the one in
/// the reconnect-storm report) and fall back to the first Classic profile.
/// The Classic adapter quirks are a safe superset for ELM327 SPP — the
/// fallback governs QUIRKS only, never the displayed identity.
Obd2AdapterProfile classicProfileForReconnect(
  Obd2AdapterRegistry registry, {
  String? adapterName,
}) {
  if (adapterName != null && adapterName.isNotEmpty) {
    for (final p in registry.profiles) {
      if (p.transport == BluetoothTransport.classic &&
          p.matchesName(adapterName)) {
        return p;
      }
    }
  }
  return registry.profiles.firstWhere(
    (p) => p.id == 'vlinker-fs-classic',
    orElse: () => registry.profiles.firstWhere(
      (p) => p.transport == BluetoothTransport.classic,
    ),
  );
}
