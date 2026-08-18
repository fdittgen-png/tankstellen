// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'obd2_connection_service.dart';

// #3572 — no-scan profile fallbacks for the direct-connect-by-MAC paths,
// extracted from `obd2_connect_by_mac.dart` (same library, keeps
// private-member access) when that part hit the 400-line guard.

/// Generic FFF0 BLE profile used for direct/passive connect quirks +
/// display name when no scan resolved a profile.
Obd2AdapterProfile _genericBleProfile(Obd2ConnectionService svc) =>
    svc.registry.profiles.firstWhere(
      (p) => p.id == 'generic-fff0',
      orElse: () => svc.registry.profiles.firstWhere(
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
Obd2AdapterProfile _classicProfileForReconnect(
  Obd2ConnectionService svc, {
  String? adapterName,
}) {
  if (adapterName != null && adapterName.isNotEmpty) {
    for (final p in svc.registry.profiles) {
      if (p.transport == BluetoothTransport.classic &&
          p.matchesName(adapterName)) {
        return p;
      }
    }
  }
  return svc.registry.profiles.firstWhere(
    (p) => p.id == 'vlinker-fs-classic',
    orElse: () => svc.registry.profiles.firstWhere(
      (p) => p.transport == BluetoothTransport.classic,
    ),
  );
}
