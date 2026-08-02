// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/error/guarded.dart';
import '../../../../core/logging/error_logger.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/obd2_scan_readiness.dart';

/// Diagnostic empty state for the OBD2 adapter picker: a scan finished
/// and found nothing, so tell the user *why* and what to do next.
///
/// ## Why this widget exists
///
/// An empty scan has five causes and, before [Obd2ScanReadiness], the
/// picker rendered the same blank column for all of them. From the
/// user's side every one looks identical — spinner, then nothing —
/// which makes "it doesn't find my adapter" an unanswerable report.
/// The worst case is Android with location services switched off
/// system-wide: the scan *succeeds* and returns an empty list, with no
/// error anywhere and every permission showing green.
///
/// Each state maps to one instruction and, where the fix lives in
/// system settings, one button that goes there.
class Obd2ScanEmptyState extends ConsumerWidget {
  const Obd2ScanEmptyState({super.key, required this.onRetry});

  /// Re-runs the scan. Always offered — even when a blocker is present,
  /// because the user may have cleared it from the notification shade
  /// while this sheet was open.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final readiness = ref.watch(obd2ScanReadinessProvider);

    // While the probe resolves, and if it somehow fails, fall back to
    // the "everything is fine, check the adapter" message — the least
    // wrong thing to say when we do not know.
    final state = readiness.asData?.value ?? Obd2ScanReadiness.ready;

    return Column(
      key: const Key('obdPickerEmpty'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          _iconFor(state),
          size: 48,
          color: state.canScan
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.error,
        ),
        const SizedBox(height: 12),
        Text(
          l.obd2ScanEmptyTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          _messageFor(state, l),
          key: const Key('obdPickerEmptyReason'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('obdPickerEmptyRetry'),
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(l.retry),
        ),
        if (_settingsTargetFor(state) case final target?) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('obdPickerEmptyOpenSettings'),
            onPressed: () => _openSettings(target),
            icon: const Icon(Icons.settings),
            label: Text(l.obd2ScanOpenSettings),
          ),
        ],
      ],
    );
  }

  static IconData _iconFor(Obd2ScanReadiness state) => switch (state) {
        Obd2ScanReadiness.ready => Icons.search_off,
        Obd2ScanReadiness.unsupported => Icons.bluetooth_disabled,
        Obd2ScanReadiness.bluetoothOff => Icons.bluetooth_disabled,
        Obd2ScanReadiness.permissionDenied ||
        Obd2ScanReadiness.permissionPermanentlyDenied =>
          Icons.lock_outline,
        Obd2ScanReadiness.locationServicesOff => Icons.location_off,
      };

  static String _messageFor(Obd2ScanReadiness state, AppLocalizations l) =>
      switch (state) {
        Obd2ScanReadiness.ready => l.obd2ScanEmptyReady,
        Obd2ScanReadiness.unsupported => l.obd2ScanBlockedUnsupported,
        Obd2ScanReadiness.bluetoothOff => l.obd2ScanBlockedBluetoothOff,
        Obd2ScanReadiness.permissionDenied => l.obd2ScanBlockedPermission,
        Obd2ScanReadiness.permissionPermanentlyDenied =>
          l.obd2ScanBlockedPermissionSettings,
        Obd2ScanReadiness.locationServicesOff =>
          l.obd2ScanBlockedLocationServices,
      };

  /// Which settings screen clears this blocker, or null when the fix is
  /// not in settings at all (nothing to offer for `ready`, and nothing
  /// that helps on unsupported hardware).
  static _SettingsTarget? _settingsTargetFor(Obd2ScanReadiness state) =>
      switch (state) {
        Obd2ScanReadiness.ready => null,
        Obd2ScanReadiness.unsupported => null,
        // Re-prompting a plain denial is the picker's own retry path,
        // so settings is only offered once the system stops prompting.
        Obd2ScanReadiness.permissionDenied => null,
        Obd2ScanReadiness.permissionPermanentlyDenied => _SettingsTarget.app,
        Obd2ScanReadiness.bluetoothOff => _SettingsTarget.app,
        Obd2ScanReadiness.locationServicesOff => _SettingsTarget.location,
      };

  static void _openSettings(_SettingsTarget target) {
    // Fire-and-forget: the OS owns the deep link and the resolved bool
    // adds nothing. A failure leaves the sheet in place with Retry
    // still reachable, which is the correct degradation.
    unawaited(
      guardAsync<bool>(
        () async => switch (target) {
          _SettingsTarget.app => await openAppSettings(),
          _SettingsTarget.location => await Geolocator.openLocationSettings(),
        },
        where: 'Obd2ScanEmptyState: open $target settings failed',
        fallback: false,
        layer: ErrorLayer.ui,
      ),
    );
  }
}

enum _SettingsTarget { app, location }
