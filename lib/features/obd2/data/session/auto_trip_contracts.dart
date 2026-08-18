// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import 'obd2_service.dart';
import 'obd2_speed_stream.dart';

/// Immutable snapshot of the auto-record fields off [VehicleProfile]
/// (#1004 phase 1) the coordinator needs to make decisions.
///
/// Modelled as a value object instead of holding the whole profile
/// because the coordinator doesn't care about brand, fuel type, or
/// odometer — only the MAC to filter on, the speed threshold to count
/// against, and the disconnect debounce window. Detaching from the
/// profile also makes this safe to copy into a future
/// background-isolate hand-off without dragging Hive types.
@immutable
class AutoRecordConfig {
  /// MAC address of the paired ELM327 adapter, sourced from
  /// `VehicleProfile.obd2AdapterMac`. The coordinator drops every
  /// event whose MAC does not equal this string — the multi-vehicle
  /// case (a household with two paired cars) only treats the active
  /// profile's adapter as live.
  final String mac;

  /// Speed (km/h) above which a sustained run kicks `startTrip()`.
  /// Sourced from `VehicleProfile.movementStartThresholdKmh`. Default
  /// in the profile is 5 km/h — low enough to catch pulling out of a
  /// parking spot, high enough to filter the brief speed spikes BLE
  /// adapters sometimes report on first connect.
  final double movementStartThresholdKmh;

  /// Debounce window before a disconnect triggers `stopAndSave`.
  /// Sourced from `VehicleProfile.disconnectSaveDelaySec`. Default in
  /// the profile is 60 s — long enough to absorb a tunnel or a
  /// parking-garage lift, short enough that the user sees a saved
  /// trip when they walk into the kitchen.
  final Duration disconnectSaveDelay;

  const AutoRecordConfig({
    required this.mac,
    required this.movementStartThresholdKmh,
    required this.disconnectSaveDelay,
  });
}

/// Callback that opens an [Obd2Service] for the configured MAC on
/// `AdapterConnected`. Returns null when the service can't be opened
/// (adapter already taken, scan timed out, init failed) so the
/// coordinator can stay idle until the next event without throwing.
///
/// Production wiring resolves to `Obd2ConnectionService.connectByMac`;
/// tests inject a fake that returns a stub service whose
/// `readSpeedKmh()` is wired to a queue.
typedef Obd2SessionOpener = Future<Obd2Service?> Function(String mac);

/// Opener used by the foreground-active arming fallback (#2282
/// concern 1). Distinct from [Obd2SessionOpener] only by intent:
/// production wires this to `Obd2ConnectionService.connectByMacDirect`
/// (a no-scan `BluetoothDevice.fromId` connect with `autoConnect`),
/// which wakes ELM327 clones that stop advertising in standby — exactly
/// the case the disabled foreground service can no longer cover while
/// the app is in front. Same null-on-failure contract as the scan
/// opener.
typedef Obd2ForegroundSessionOpener = Future<Obd2Service?> Function(String mac);

/// Factory that wraps an open [Obd2Service] in a polled km/h stream.
/// Test seam — production code uses [Obd2SpeedStream.new]; tests pass
/// a shorter `pollPeriod` so the timer fires inside `pumpEventQueue`.
typedef Obd2SpeedStreamFactory = Obd2SpeedStream Function(
  Obd2Service service, {
  String? mac,
});
