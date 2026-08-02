// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/error/guarded.dart';
import '../../../../core/logging/error_logger.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/obd2_connection_errors.dart';
import '../obd2_connection_error_l10n.dart';

/// Error state for the OBD2 adapter picker: a scan or connect attempt
/// failed with a known [Obd2ConnectionError].
///
/// Extracted from `obd2_adapter_picker.dart` as part of the tracked
/// decomposition of that god-class (#3140). The picker's `_buildBody`
/// held three inline branches; this is the second of them to move out,
/// after [Obd2ScanEmptyState]. Behaviour and widget keys are unchanged
/// so the existing picker tests keep asserting the same surface.
///
/// ## The permission CTA
///
/// When the underlying error is a permission denial the widget surfaces
/// a second action — "Open settings" — alongside Retry. This unblocks
/// users who already dismissed the system Bluetooth prompt: once the
/// OS stops re-prompting, Retry alone can never reach a granted state,
/// so the only way forward is the settings deep link.
class Obd2ScanErrorState extends StatelessWidget {
  const Obd2ScanErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  /// The failure to explain. Null renders the generic unknown-error copy.
  final Obd2ConnectionError? error;

  /// Re-runs the scan.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isPermissionError = error is Obd2PermissionDenied;

    return Column(
      key: const Key('obdPickerError'),
      children: [
        Icon(
          Icons.error_outline,
          color: Theme.of(context).colorScheme.error,
          size: 48,
        ),
        const SizedBox(height: 8),
        Text(
          error?.localizedMessage(l) ?? l.errorUnknown,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('obdPickerRetry'),
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(l.retry),
        ),
        if (isPermissionError) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('obdPickerOpenSettings'),
            onPressed: _openAppSettings,
            icon: const Icon(Icons.settings),
            label: Text(l.obdPermissionDenied),
          ),
        ],
      ],
    );
  }

  static void _openAppSettings() {
    // Fire-and-forget: the OS owns the deep link and the resolved bool
    // adds nothing. A platform failure leaves the picker in its error
    // state with Retry still reachable — but it is now TRACED rather
    // than dropped, so "the settings button does nothing" is
    // diagnosable from an exported error log.
    unawaited(
      guardAsync<bool>(
        openAppSettings,
        where: 'Obd2ScanErrorState: openAppSettings failed',
        fallback: false,
        layer: ErrorLayer.ui,
      ),
    );
  }
}
