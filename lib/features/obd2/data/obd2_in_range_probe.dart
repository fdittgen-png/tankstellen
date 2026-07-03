// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/telemetry/collectors/breadcrumb_collector.dart';
import 'adapter_reconnect_scanner.dart' show AdapterInRangeProbe;
import 'bluetooth_facade.dart';
import 'obd2_comm_diagnostics.dart' show redactObd2Mac;
import 'obd2_scan_governor.dart';

/// #3421 — build a REAL in-range probe for the [AdapterReconnectScanner].
///
/// The in-trip reconnect scanner's probe was a stub (`(mac) async => true`,
/// reconnect_scanner_factory.dart), so EVERY backoff cycle dialled a full
/// connect even with the adapter absent — part of the #3415 field signature
/// of 1479 connect attempts in one day. For a BLE adapter, a short passive
/// sighting question ("is the pinned MAC advertising right now?") is far
/// cheaper than a connect dance, so a miss now skips the connect entirely
/// and just re-arms the backoff.
///
/// Reuses the existing facade scan primitive ([BluetoothFacade.scan] — the
/// same flutter_blue_plus timed scan the picker and the #3014 scan-seed
/// use), unfiltered per #3097 so name-only clones are sighted too, bounded
/// by [scanWindow]. Every probe pays into the process-wide #3185 scan
/// governor so a dense reconnect episode can't trip Android's silent
/// 5-scans/30s throttle.
///
/// Transport dispatch ([transportHint] — the same live-link kind the
/// [ReconnectConnector] receives, read off the dead-but-typed service at
/// handle-drop time, #2565):
///  * `'ble'` — the real advert probe below.
///  * `'classic'` — always `true`: Classic SPP adapters do NOT advertise
///    (they are enumerated from the bonded list), so there is no advert to
///    sight; the bounded connect itself is the reachability check, and the
///    classic connect storm is bounded separately (#3422).
///  * `null` / unknown — conservatively `true`: probing an unknown-transport
///    pin over BLE would starve a Classic adapter forever (it can never be
///    sighted), so the pre-#3421 connect-always behaviour is kept.
///
/// A scan failure (BT off, plugin rejection) propagates to the scanner's
/// `_probeSafely`, which already de-noises it as a connect transient
/// (#2953) — no second classification layer here.
AdapterInRangeProbe buildObd2InRangeProbe({
  required BluetoothFacade bluetooth,
  required Obd2ScanGovernor scanGovernor,
  required String? transportHint,
  Duration scanWindow = const Duration(seconds: 3),
}) {
  if (transportHint != 'ble') {
    return (_) async => true;
  }
  return (mac) async {
    await scanGovernor.admitScanStart(reason: 'in-range-probe');
    final wanted = mac.toUpperCase();
    var seen = false;
    // The facade closes the stream at [scanWindow]; breaking out early on a
    // sighting cancels the subscription, which stops the radio scan (the
    // facade's onCancel path).
    await for (final batch in bluetooth.scan(
      serviceUuids: const {},
      timeout: scanWindow,
    )) {
      if (batch.any((c) => c.deviceId.toUpperCase() == wanted)) {
        seen = true;
        break;
      }
    }
    // #3421 acceptance — stamp every probe result so a field export shows
    // whether the reconnect loop skipped connects because the adapter was
    // genuinely out of range (miss) or dialled on a sighting.
    BreadcrumbCollector.add(
      'obd2-reconnect: ble-probe ${seen ? 'sighted' : 'miss'}',
      detail: 'mac=${redactObd2Mac(mac)} '
          'windowMs=${scanWindow.inMilliseconds}',
    );
    return seen;
  };
}
