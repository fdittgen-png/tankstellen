// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/obd2_wedge_recovery.dart';

/// #3422 (epic #3415) — rung 4 of the wedge-recovery escalation ladder: the
/// ONE-TIME actionable hint for a wedged Classic adapter.
///
/// Shown only while [Obd2WedgeRecovery.hintPending] is raised — which the
/// ladder does at most once per wedge episode, after the in-app rungs (SDP
/// refresh, guarded re-bond, consent BT cycle) all failed. The copy names
/// the physical recoveries (ignition off/on, replug) and the Bluetooth
/// toggle; the button deep-links straight into the system Bluetooth
/// settings (the #3404 floor — no silent BT toggle exists on API 31+).
///
/// Renders zero-height whenever the hint is down (no wedge, dismissed, or
/// the wedge cleared), so it is safe inside always-on chrome. Styled as the
/// same compact status strip as [Obd2ReconnectRetryBanner] (#3306).
class Obd2WedgeRecoveryBanner extends StatelessWidget {
  const Obd2WedgeRecoveryBanner({super.key, Obd2WedgeRecovery? recovery})
      : _recovery = recovery;

  /// Test seam; production uses the process-wide [Obd2WedgeRecovery.instance].
  final Obd2WedgeRecovery? _recovery;

  Obd2WedgeRecovery get _r => _recovery ?? Obd2WedgeRecovery.instance;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _r.hintPending,
      builder: (context, pending, _) {
        if (!pending) return const SizedBox.shrink();
        final l = AppLocalizations.of(context);
        final theme = Theme.of(context);
        final fg = theme.colorScheme.onErrorContainer;
        return Container(
          key: const Key('obd2WedgeHintBanner'),
          width: double.infinity,
          color: theme.colorScheme.errorContainer,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Center(
                      child: Icon(Icons.usb_off, size: 20, color: fg),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.obd2WedgeHintBody,
                      style:
                          theme.textTheme.bodyMedium?.copyWith(color: fg),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    key: const Key('obd2WedgeHintBtSettingsButton'),
                    style: TextButton.styleFrom(foregroundColor: fg),
                    // Best-effort deep-link; the hint stays up (the user may
                    // come back from Settings with the adapter still wedged).
                    onPressed: () => unawaited(_r.openBluetoothSettings()),
                    child: Text(l.obd2WedgeHintOpenBtSettings),
                  ),
                  IconButton(
                    key: const Key('obd2WedgeHintDismissButton'),
                    icon: Icon(Icons.close, size: 18, color: fg),
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: _r.dismissHint,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
