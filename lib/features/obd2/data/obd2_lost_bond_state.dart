// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

/// #3423 — the lost-bond guided-re-pair state (Epic #3415 task 6).
///
/// A Bluetooth **Classic** adapter can only ever open an RFCOMM socket to a
/// device the OS currently lists in `bondedDevices` — when Android drops the
/// bond (a "forget device", a BT-stack reset, an OS upgrade), every connect
/// and reconnect to the pinned MAC is doomed *by construction*. Before
/// #3423 that surfaced as an endless generic `rfcomm-open-fail` /
/// scan-empty loop with no hint that the ONLY fix is re-pairing in the
/// system Bluetooth settings.
///
/// The Classic connect chokepoint (`_connectByMacClassicDirect`) now checks
/// the bonded list before dialling; on a definite miss it stamps the
/// distinct `bond-lost` failure on the connect trace and raises the event
/// here so the UI can show **guided re-pair**.
///
/// ### UI seam (deliberately state-only)
/// No banner / button ships with #3423: there is no native
/// `openBluetoothSettings` hook on any channel yet, and the #3422
/// wedge-recovery escalation ladder (in flight on its own branch) owns the
/// recovery-guidance banner. That banner is the intended consumer: listen
/// on [current] and, while non-null, render the re-pair guidance with a
/// deep-link into the system Bluetooth settings
/// (`Settings.ACTION_BLUETOOTH_SETTINGS` via whatever settings-intent hook
/// #3422 lands; `openAppSettings` from permission_handler is the closest
/// existing in-app pattern). Until it lands, the state is still visible in
/// the exported connect trace (`bond-lost` step + failureDetail).
///
/// Static singleton on purpose — it mirrors the [Obd2LinkDropSignal] /
/// `Obd2CommDiagnostics.instance` static-sink seams the same connect path
/// already writes to, so the deep connect internals need no extra plumbing.
class Obd2LostBondState {
  Obd2LostBondState._();

  static final Obd2LostBondState instance = Obd2LostBondState._();

  /// The most recent lost-bond observation, or null while the pinned
  /// Classic adapter is (as far as the last check knew) still bonded.
  /// A [ValueNotifier] so widget-layer consumers can
  /// `ValueListenableBuilder` on it directly.
  final ValueNotifier<Obd2LostBondEvent?> current =
      ValueNotifier<Obd2LostBondEvent?>(null);

  /// Record that [mac] is missing from the OS bonded list. Idempotent per
  /// MAC: the reconnect scanner re-checks every backoff cycle (~5 s+), and
  /// re-publishing an identical event each cycle would just churn listener
  /// rebuilds — the timestamp of the FIRST observation is the useful one.
  void noteLostBond(String mac, {DateTime Function() now = DateTime.now}) {
    final existing = current.value;
    if (existing != null && _sameMac(existing.mac, mac)) return;
    current.value = Obd2LostBondEvent(mac: mac, at: now());
  }

  /// Clear the state when [mac] is observed bonded again (the user
  /// re-paired in system settings — the very next connect cycle notices).
  /// A no-op when the current event is for a different MAC or absent.
  void clearFor(String mac) {
    final existing = current.value;
    if (existing == null || !_sameMac(existing.mac, mac)) return;
    current.value = null;
  }

  /// Test seam — drop any recorded event unconditionally.
  void reset() => current.value = null;

  static bool _sameMac(String a, String b) =>
      a.trim().toUpperCase() == b.trim().toUpperCase();
}

/// One lost-bond observation (#3423).
class Obd2LostBondEvent {
  /// The pinned Classic MAC that is no longer in the OS bonded list.
  final String mac;

  /// When the lost bond was FIRST observed this episode.
  final DateTime at;

  const Obd2LostBondEvent({required this.mac, required this.at});

  @override
  String toString() => 'Obd2LostBondEvent(mac: $mac, at: $at)';
}
