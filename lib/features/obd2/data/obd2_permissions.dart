// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'classic_method_channel.dart';

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

  /// Request the runtime POST_NOTIFICATIONS permission (#2282 concern 2).
  ///
  /// Android 13+ (API 33) gates the auto-record foreground-service
  /// notification behind a runtime grant; without it the persistent
  /// "Trip auto-record" notification is silently dropped and the user
  /// has no visible signal the service is armed. Auto-record calls this
  /// BEFORE arming so the prompt appears at a moment the user
  /// understands ("I just turned on hands-free recording").
  ///
  /// Returns `true` when notifications may be posted (granted, or the
  /// platform has no such gate — iOS, Android ≤ 12), `false` when the
  /// user denied. A `false` is non-fatal: the caller proceeds to arm
  /// regardless, the service simply runs without a visible notification.
  Future<bool> requestNotifications();
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
/// iOS 13+: a single unified `Permission.bluetooth` check, backed by
/// `NSBluetoothAlwaysUsageDescription` in `Info.plist`. The first call
/// to [request] surfaces the system Bluetooth-permission prompt;
/// `denied` covers both the "not yet asked" and "user tapped Don't
/// Allow" cases. `permanentlyDenied` triggers when iOS will no longer
/// re-prompt — the picker UI offers an "Open Settings" deep link in
/// that branch.
class PluginObd2Permissions implements Obd2Permissions {
  /// [sdkIntProvider] is the Android SDK-level probe (#3183) — injectable so
  /// tests can drive the permission-set selection without a platform channel.
  /// Defaults to the real native `Build.VERSION.SDK_INT` probe.
  const PluginObd2Permissions({
    Future<int> Function() sdkIntProvider = _probeAndroidSdkInt,
  }) : _sdkIntProvider = sdkIntProvider;

  final Future<int> Function() _sdkIntProvider;

  @override
  Future<Obd2PermissionState> request() async {
    if (Platform.isIOS) {
      final status = await Permission.bluetooth.request();
      return _stateFromStatus(status);
    }
    if (!Platform.isAndroid) return Obd2PermissionState.denied;
    final sdkInt = await _androidSdkInt();
    final needed = _permissionsFor(sdkInt);
    final results = await needed.request();
    return _aggregate(results);
  }

  @override
  Future<Obd2PermissionState> current() async {
    if (Platform.isIOS) {
      final status = await Permission.bluetooth.status;
      return _stateFromStatus(status);
    }
    if (!Platform.isAndroid) return Obd2PermissionState.denied;
    final sdkInt = await _androidSdkInt();
    final needed = _permissionsFor(sdkInt);
    final statuses = <Permission, PermissionStatus>{};
    for (final p in needed) {
      statuses[p] = await p.status;
    }
    return _aggregate(statuses);
  }

  @override
  Future<bool> requestNotifications() async {
    // POST_NOTIFICATIONS is an Android 13+ (API 33) runtime gate only.
    // iOS surfaces notification consent through its own
    // `LocalNotificationService` flow and Android ≤ 12 grants it at
    // install time, so there is nothing to prompt for there — report
    // "may post" so the caller doesn't treat those platforms as denied.
    if (!Platform.isAndroid) return true;
    final sdkInt = await _androidSdkInt();
    if (sdkInt < 33) return true;
    final status = await Permission.notification.request();
    // `isLimited` never applies to notifications, but treating it as
    // "may post" keeps the mapping defensive against future plugin
    // states. Anything else (denied / permanentlyDenied / restricted)
    // means the channel will be silenced — non-fatal for the caller.
    return status.isGranted || status.isLimited;
  }

  /// Map the single iOS [PermissionStatus] (Bluetooth is a unified perm
  /// since iOS 13) onto our coarse three-value state.
  static Obd2PermissionState _stateFromStatus(PermissionStatus status) {
    if (status.isGranted || status.isLimited) {
      return Obd2PermissionState.granted;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return Obd2PermissionState.permanentlyDenied;
    }
    return Obd2PermissionState.denied;
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

  /// #3183 — the device's REAL SDK level via the injected probe. The old
  /// implementation hard-coded 33, which made the `< 31` legacy
  /// location-permission branch in [_permissionsFor] unreachable — on
  /// Android ≤ 11 the BLE scan was "granted" without any location
  /// permission and silently returned zero results. Falls back to 33
  /// (the modern split-permission model) when the probe fails — e.g. an
  /// old native side without the `sdkInt` method — because biasing newer
  /// is safer than wrongly showing the legacy location prompt on a modern
  /// device.
  Future<int> _androidSdkInt() async {
    try {
      return await _sdkIntProvider();
    } catch (_) {
      // Best-effort probe with a documented bias: a missing/old native
      // method must never break the permission flow.
      return 33;
    }
  }

  /// #3183 test seam — the permission set [request]/[current] would ask for,
  /// resolved through the (injectable) SDK probe + its 33 fallback.
  @visibleForTesting
  Future<List<Permission>> debugRequiredPermissions() async =>
      _permissionsFor(await _androidSdkInt());
}

/// #3183 — default production probe: `Build.VERSION.SDK_INT` over the
/// existing in-repo Classic plugin's MethodChannel (no extra dependency —
/// the alternative, device_info_plus, is not in the dependency set).
Future<int> _probeAndroidSdkInt() => const Obd2ClassicMethodChannel().sdkInt();

@Riverpod(keepAlive: true)
Obd2Permissions obd2Permissions(Ref ref) => const PluginObd2Permissions();
