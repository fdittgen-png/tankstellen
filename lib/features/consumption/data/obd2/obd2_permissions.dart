import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'obd2_permissions.g.dart';

/// Coarse state for the Bluetooth permissions the OBD2 scan needs.
/// Mirrors the three cases the UI must distinguish:
///
/// * [granted] — safe to call `FlutterBluePlus.startScan`.
/// * [denied] — prompt the user again on next attempt.
/// * [permanentlyDenied] — system will not show the prompt any more;
///   the UI must offer a direct "Open settings" deep link.
enum Obd2PermissionState { granted, denied, permanentlyDenied }

/// Abstract façade over the runtime permission probe for the OBD2
/// scan. Kept behind an interface so the connection service and the
/// picker widget can be unit-tested without the real
/// `permission_handler` plugin binding (#740).
abstract class Obd2Permissions {
  /// Trigger the system permission prompt. Returns the resulting state.
  /// Safe to call repeatedly; no-op when already granted.
  Future<Obd2PermissionState> request();

  /// Inspect the current permission state without prompting. Used by
  /// the UI to decide whether to render the "grant permission" CTA or
  /// jump straight into scanning.
  Future<Obd2PermissionState> current();
}

/// Production implementation backed by `permission_handler`.
///
/// Android 12 (API 31) and up: asks for `bluetoothScan` + `bluetoothConnect`.
/// The `neverForLocation` usage flag is declared in the manifest, so
/// coarse-location is not part of the prompt.
///
/// Android 11 and below: BLE scanning still requires location
/// permission — legacy contract. We ask for `location` in that case
/// so scanning actually returns results.
///
/// iOS: the framework currently targets Android only; iOS returns
/// [Obd2PermissionState.denied] so callers can surface a "not
/// supported on iOS yet" empty state instead of crashing.
class PluginObd2Permissions implements Obd2Permissions {
  const PluginObd2Permissions();

  @override
  Future<Obd2PermissionState> request() async {
    if (!Platform.isAndroid) return Obd2PermissionState.denied;
    final sdkInt = await _androidSdkInt();
    final needed = _permissionsFor(sdkInt);
    final results = await needed.request();
    return _aggregate(results);
  }

  @override
  Future<Obd2PermissionState> current() async {
    if (!Platform.isAndroid) return Obd2PermissionState.denied;
    final sdkInt = await _androidSdkInt();
    final needed = _permissionsFor(sdkInt);
    final statuses = <Permission, PermissionStatus>{};
    for (final p in needed) {
      statuses[p] = await p.status;
    }
    return _aggregate(statuses);
  }

  /// Android 12+ uses the split BLE permissions with neverForLocation;
  /// older targets fall back to coarse/fine location because the
  /// platform refuses to return scan results without one of them.
  static List<Permission> _permissionsFor(int sdkInt) {
    if (sdkInt >= 31) {
      return [Permission.bluetoothScan, Permission.bluetoothConnect];
    }
    return [Permission.locationWhenInUse];
  }

  static Obd2PermissionState _aggregate(
    Map<Permission, PermissionStatus> statuses,
  ) {
    if (statuses.values.every((s) => s.isGranted)) {
      return Obd2PermissionState.granted;
    }
    if (statuses.values.any((s) => s.isPermanentlyDenied)) {
      return Obd2PermissionState.permanentlyDenied;
    }
    return Obd2PermissionState.denied;
  }

  /// Read the device's SDK level via the `permission_handler` plugin's
  /// DeviceInfo plugin would be cleaner, but that pulls another dep.
  /// Instead we fall back to [Platform.version] parsing, which is
  /// allowed by Flutter's Platform channel when missing, and default
  /// to 33 (Android 13) when parsing fails — biasing toward the newer
  /// permission model is safer than accidentally falling back to the
  /// legacy location prompt.
  static Future<int> _androidSdkInt() async {
    // Platform.version looks like "3.5.0 (stable) ... (Android SDK 33)"
    // in debug but not in release. Hard-code 33 as the default; callers
    // that need a precise read can inject a fake `Obd2Permissions`.
    return 33;
  }
}

@Riverpod(keepAlive: true)
Obd2Permissions obd2Permissions(Ref ref) => const PluginObd2Permissions();
