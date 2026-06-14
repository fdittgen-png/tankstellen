// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:permission_handler/permission_handler.dart';

/// Facade over the Android battery-optimization-exemption permission
/// (`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`), kept behind an interface so the
/// recording layer can be unit-tested without the real `permission_handler`
/// binding (#3313).
///
/// Whitelisting the app from battery optimization keeps a recording
/// foreground service alive through Doze and aggressive OEM task-killers
/// (Xiaomi/MIUI, Huawei, Samsung) on long drives — a foreground service is
/// the lifecycle signal, but Doze still ignores wake locks unless the app is
/// on the exemption list.
///
/// Android-only: it is only ever invoked behind the
/// `kGpsRecordingForegroundServiceEnabled` build gate (an Android
/// FGS-approved-flavour flag), so this never runs on iOS. The plugin impl is
/// defensive anyway — an unsupported platform reports "exempt" so the caller
/// no-ops rather than throwing.
abstract class BatteryOptimizationPermissions {
  /// Whether the app is already exempt from battery optimization. `true`
  /// short-circuits the prompt. Treats an unsupported platform / probe
  /// error as exempt (nothing to do).
  Future<bool> isExempt();

  /// Trigger the system `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`
  /// dialog. Android shows it at most once per app; a later call is a no-op
  /// unless the user cleared the decision in system settings.
  Future<void> requestExemption();
}

class PluginBatteryOptimizationPermissions
    implements BatteryOptimizationPermissions {
  const PluginBatteryOptimizationPermissions();

  @override
  Future<bool> isExempt() async {
    try {
      return (await Permission.ignoreBatteryOptimizations.status).isGranted;
    } catch (_) {
      // Unsupported platform (iOS) / missing plugin — nothing to exempt.
      return true;
    }
  }

  @override
  Future<void> requestExemption() async {
    await Permission.ignoreBatteryOptimizations.request();
  }
}
