// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter/foundation.dart' show debugPrint;

import 'impl/obd2_scan_platform.dart';
import 'obd2_permissions.dart';

part 'obd2_scan_readiness.g.dart';

/// Why a scan will — or will not — find an adapter, resolved as ONE
/// value the UI can render and a support conversation can act on.
///
/// ## Why this exists
///
/// An OBD2 scan that returns an empty list has **five** distinct causes
/// and, until this probe, the app could distinguish only two of them.
/// From the user's side every one of them looks identical: they tap
/// "scan", a spinner runs, nothing appears. "It doesn't find my
/// adapter" is then an unanswerable bug report.
///
/// The individual signals already existed — [Obd2Permissions] knew
/// about grants, `BluetoothFacade` knew about the radio — but nothing
/// combined them, and two causes were not checked at all:
///
/// * **No BLE hardware / unsupported platform.** `FlutterBluePlus`
///   simply yields nothing; there was no `isSupported` probe.
/// * **Android location services switched off system-wide.** On many
///   Android builds a BLE scan requires *location services enabled*,
///   not merely the location permission granted. The scan then
///   succeeds and returns an empty list, with no error anywhere. This
///   is the single most confusing failure in the whole flow, because
///   the permission screen shows everything green.
///
/// Each state below maps to a different, actionable instruction. That
/// is the entire point: a probe that cannot tell the user what to do
/// next is just a spinner with extra steps.
enum Obd2ScanReadiness {
  /// Hardware present, radio on, permissions granted, location
  /// services satisfied. A scan that finds nothing genuinely means no
  /// adapter is in range.
  ready,

  /// No Bluetooth Low Energy hardware, or a platform we do not scan on.
  /// The scan path should be hidden entirely rather than offered and
  /// then failing.
  unsupported,

  /// Hardware present, radio switched OFF in system settings.
  /// Actionable: ask the user to turn Bluetooth on.
  bluetoothOff,

  /// Permission not granted. Actionable: prompt, or — when the system
  /// will no longer prompt — deep-link to app settings.
  permissionDenied,

  /// Permission granted, but the system will not prompt again.
  /// Actionable: deep-link to app settings; re-prompting does nothing
  /// and looks broken.
  permissionPermanentlyDenied,

  /// Android only: permissions granted but **location services are off
  /// system-wide**, so a BLE scan silently returns nothing.
  /// Actionable: ask the user to enable location services.
  locationServicesOff,
}

/// Whether a scan can actually run right now.
extension Obd2ScanReadinessX on Obd2ScanReadiness {
  bool get canScan => this == Obd2ScanReadiness.ready;

  /// Whether the blocker is something the user can fix from inside the
  /// app's own permission prompt (as opposed to a system settings trip).
  bool get isPromptable => this == Obd2ScanReadiness.permissionDenied;
}

/// Resolves [Obd2ScanReadiness]. Every dependency is injectable so the
/// whole matrix is unit-testable without a radio.
class Obd2ScanReadinessProbe {
  Obd2ScanReadinessProbe({
    required this._permissions,
    Future<bool> Function()? isSupported,
    Future<BluetoothAdapterState> Function()? adapterState,
    Future<bool> Function()? locationServicesEnabled,
    bool Function()? isAndroid,
  })  : _isSupported = isSupported ?? _defaultIsSupported,
        _adapterState = adapterState ?? _defaultAdapterState,
        _locationServicesEnabled =
            locationServicesEnabled ?? _defaultLocationServicesEnabled,
        _isAndroid = isAndroid ?? _defaultIsAndroid;

  final Obd2Permissions _permissions;
  final Future<bool> Function() _isSupported;
  final Future<BluetoothAdapterState> Function() _adapterState;
  final Future<bool> Function() _locationServicesEnabled;
  final bool Function() _isAndroid;

  /// Resolve the current readiness. Ordered most-fundamental first, so
  /// the returned state names the blocker the user must clear *next*
  /// rather than an incidental one behind it.
  ///
  /// Resolved fresh on every call and never cached — the user can flip
  /// Bluetooth or location services in the notification shade while the
  /// sheet is open, which is exactly what they will do after reading
  /// the message this drives. A cached answer would make the app's own
  /// instruction appear not to work.
  ///
  /// Never throws: any probe failure degrades to the state that hides
  /// or blocks the scan path rather than crashing the picker.
  Future<Obd2ScanReadiness> resolve() async {
    // 1. Hardware. Nothing else matters if there is no radio.
    //
    // EVERY probe fault in this method degrades OPTIMISTICALLY (fail
    // open): `resolve()` gates the scan path, and a transient probe
    // failure — a missing platform binding in a test harness, a flaky
    // platform channel — must never hide a scan that would have worked.
    // Only a POSITIVE answer ("isSupported returned false", "the adapter
    // state is off") may block. This mirrors the fail-open contract of
    // the BLE adapter-state gate (#3182).
    if (!await _quietProbe(_isSupported, fallback: true, what: 'isSupported')) {
      return Obd2ScanReadiness.unsupported;
    }

    // 2. Permissions before radio state: on Android 12+ reading the
    //    adapter state itself can require BLUETOOTH_CONNECT, so an
    //    ungranted app may observe a misleading `unknown`.
    // `denied` is the fail-open value HERE: a plain denial is promptable,
    // so callers let the scan run — and the scan is what prompts.
    final permission = await _quietProbe(
      _permissions.current,
      fallback: Obd2PermissionState.denied,
      what: 'permission',
    );
    switch (permission) {
      case Obd2PermissionState.permanentlyDenied:
        return Obd2ScanReadiness.permissionPermanentlyDenied;
      case Obd2PermissionState.denied:
        return Obd2ScanReadiness.permissionDenied;
      case Obd2PermissionState.granted:
        break;
    }

    // 3. Radio.
    final state = await _quietProbe(
      _adapterState,
      fallback: BluetoothAdapterState.unknown,
      what: 'adapter-state',
    );
    if (state == BluetoothAdapterState.off ||
        state == BluetoothAdapterState.turningOff) {
      return Obd2ScanReadiness.bluetoothOff;
    }
    if (state == BluetoothAdapterState.unavailable) {
      return Obd2ScanReadiness.unsupported;
    }

    // 4. Android's silent one: location services OFF system-wide makes
    //    a BLE scan return an empty list with no error at all. Checked
    //    LAST because it is the least fundamental — and skipped on
    //    platforms where it does not apply, so iOS never sees a
    //    location message it cannot act on.
    if (_isAndroid()) {
      final locationOn = await _quietProbe(
        _locationServicesEnabled,
        fallback: true,
        what: 'location-services',
      );
      if (!locationOn) return Obd2ScanReadiness.locationServicesOff;
    }

    return Obd2ScanReadiness.ready;
  }

  /// Best-effort probe wrapper: a fault resolves to [fallback] with a
  /// debug line only — deliberately NOT `guardAsync`/`errorLogger`.
  ///
  /// Probe faults here are EXPECTED environmental conditions (a missing
  /// platform binding in a test harness, an unbound plugin channel), and
  /// this method runs on every picker open: ERROR-logging each one would
  /// spam the bounded trace ring with noise — the exact anti-pattern the
  /// #2745 de-noise pass removed from the connect path. Real device
  /// failures still surface through the scan's own tracing (#3184),
  /// because the probe fails OPEN into that scan.
  static Future<T> _quietProbe<T>(
    Future<T> Function() probe, {
    required T fallback,
    required String what,
  }) async {
    try {
      return await probe();
    } catch (e, st) {
      debugPrint(
        'Obd2ScanReadinessProbe: $what probe failed (fail-open): $e\n$st',
      );
      return fallback;
    }
  }

  static Future<bool> _defaultIsSupported() => FlutterBluePlus.isSupported;

  static Future<BluetoothAdapterState> _defaultAdapterState() async =>
      FlutterBluePlus.adapterStateNow;

  static Future<bool> _defaultLocationServicesEnabled() =>
      Geolocator.isLocationServiceEnabled();

  // The platform fork itself lives in `impl/` (ADR 0009) so this file
  // carries no inline platform branching.
  static bool _defaultIsAndroid() => scanNeedsLocationServices();
}

@Riverpod(keepAlive: true)
Obd2ScanReadinessProbe obd2ScanReadinessProbe(Ref ref) =>
    Obd2ScanReadinessProbe(permissions: ref.watch(obd2PermissionsProvider));

/// Auto-disposing read of the current readiness. Deliberately NOT
/// cached across rebuilds — see [Obd2ScanReadinessProbe.resolve].
@riverpod
Future<Obd2ScanReadiness> obd2ScanReadiness(Ref ref) =>
    ref.watch(obd2ScanReadinessProbeProvider).resolve();
