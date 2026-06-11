// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:hive/hive.dart';

import 'adapter_registry.dart';
import 'bluetooth_obd2_transport.dart';
import 'elm_byte_channel.dart';
import 'negotiated_protocol_cache.dart';
import 'obd2_service.dart';
import 'supported_pids_cache.dart';
import '../../../core/storage/hive_boxes.dart';

/// Map a resolved [BluetoothTransport] to the comm-diagnostics link-kind
/// tag (#2465 — `'ble'` / `'classic'`). Kept beside [buildObd2Session]
/// so the link-kind label lives next to where it is stamped.
String obd2LinkKindOf(BluetoothTransport transport) => switch (transport) {
      BluetoothTransport.ble => 'ble',
      BluetoothTransport.classic => 'classic',
    };

/// Opens the deferred OBD2 caches the live [Obd2ConnectionService] wires
/// into every session. Each returns null when its Hive box isn't open
/// yet (early-boot connect, or a bare test harness that never
/// initialised Hive) so building the connection service can never throw
/// — the session then runs with the pre-cache behaviour (blind PID
/// querying / cold ATSP0 auto-search every connect).

/// #811 supported-PID bitmap cache.
SupportedPidsCache? openSupportedPidsCache() {
  if (!Hive.isBoxOpen(HiveBoxes.obd2SupportedPids)) return null;
  return SupportedPidsCache(Hive.box<String>(HiveBoxes.obd2SupportedPids));
}

/// #2261 negotiated-protocol warm cache.
NegotiatedProtocolCache? openNegotiatedProtocolCache() {
  if (!Hive.isBoxOpen(HiveBoxes.obd2NegotiatedProtocol)) return null;
  return NegotiatedProtocolCache(
    Hive.box<String>(HiveBoxes.obd2NegotiatedProtocol),
  );
}

/// Build the [Obd2Service] for a freshly-opened [channel], wiring in the
/// #811 supported-PID cache (#2253) and the #2261 negotiated-protocol
/// warm cache and stamping the adapter [mac]/[name]. Centralised here so
/// the scan and direct/passive connect paths in [Obd2ConnectionService]
/// produce a byte-for-byte identical session. The vehicle [make]/[model]/
/// [year]/[vin] refine the cache keys; null fields collapse to
/// adapterMac-only keying. [linkKind] (#2465 — `'ble'` / `'classic'`)
/// is stamped so the gated comm-diagnostics session can record the
/// transport flavour without the data layer reaching into the registry.
Obd2Service buildObd2Session({
  required ElmByteChannel channel,
  required String mac,
  required String name,
  SupportedPidsCache? pidsCache,
  NegotiatedProtocolCache? protocolCache,
  String? make,
  String? model,
  int? year,
  String? vin,
  String? linkKind,
}) {
  final service = Obd2Service(
    BluetoothObd2Transport(channel),
    pidsCache: pidsCache,
    vehicleFallbackKey: pidsCache == null
        ? null
        : SupportedPidsCache.productionKey(
            adapterMac: mac,
            make: make,
            model: model,
            year: year,
          ),
    protocolCache: protocolCache,
    protocolCacheKey: protocolCache == null
        ? null
        : NegotiatedProtocolCache.keyFor(adapterMac: mac, vin: vin),
  );
  service.adapterMac = mac;
  service.adapterName = name;
  service.linkKind = linkKind;
  return service;
}
