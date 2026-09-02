// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../obd2/api.dart';

/// "OBD2 adapter" section on the vehicle edit screen (#779).
///
/// Renders one of two states depending on whether the vehicle has
/// an adapter persisted:
/// - Paired: shows the adapter name, MAC, and a "Forget" button.
/// - Unpaired: shows a "Pair adapter" button that opens the pair-only
///   picker and calls [onPaired] with the user's choice.
///
/// Stateless. Callers own the adapter state and pass it in via
/// [adapterMac] / [adapterName] — we just render + forward events.
class VehicleAdapterSection extends ConsumerWidget {
  final String? adapterMac;
  final String? adapterName;
  final void Function(String name, String mac) onPaired;
  final VoidCallback onForget;

  const VehicleAdapterSection({
    super.key,
    required this.adapterMac,
    required this.adapterName,
    required this.onPaired,
    required this.onForget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final mac = adapterMac;
    final name = adapterName;
    final paired = mac != null && mac.isNotEmpty;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.bluetooth),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.vehicleAdapterSectionTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (paired) ...[
              Text(
                name == null || name.isEmpty ? (l.vehicleAdapterUnnamed) : name,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 4),
              Text(
                mac,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 12),
              // #3676 — hard reset: ATZ chip reset on the dongle (best
              // effort), full link recycle, fresh dial. Sits beside
              // Forget so every link-lifecycle action lives in one card.
              // #3899 — an OverflowBar, not a Row: the two labels share
              // one row only when both fit, otherwise they stack into
              // two full-width rows (each label then wraps inside its
              // button). Nothing is ever clipped ("Oublier l'adap").
              OverflowBar(
                key: const Key('vehicleAdapterActions'),
                alignment: MainAxisAlignment.end,
                spacing: 8,
                overflowAlignment: OverflowBarAlignment.end,
                overflowSpacing: 4,
                children: [
                  const _ResetConnectionButton(),
                  TextButton.icon(
                    key: const Key('vehicleAdapterForget'),
                    onPressed: onForget,
                    icon: const Icon(Icons.link_off),
                    label: Text(l.vehicleAdapterForget),
                  ),
                ],
              ),
            ] else ...[
              Text(l.vehicleAdapterEmpty, style: theme.textTheme.bodySmall),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  key: const Key('vehicleAdapterPair'),
                  onPressed: () => _onPair(context),
                  icon: const Icon(Icons.bluetooth_searching),
                  label: Text(l.vehicleAdapterPair),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _onPair(BuildContext context) async {
    final result = await showObd2AdapterPairer(context);
    if (result == null) return;
    final name = result.candidate.deviceName.isEmpty
        ? result.profile.displayName
        : result.candidate.deviceName;
    onPaired(name, result.candidate.deviceId);
  }
}

/// #3676 — "Reset connection": sends an ATZ chip reset to the dongle
/// (best effort — the closest software equivalent to power-cycling
/// it), tears the link down completely and re-dials fresh. Stateful
/// only for the busy spinner; the actual work lives on
/// [Obd2Reconnect.resetConnection].
class _ResetConnectionButton extends ConsumerStatefulWidget {
  const _ResetConnectionButton();

  @override
  ConsumerState<_ResetConnectionButton> createState() =>
      _ResetConnectionButtonState();
}

class _ResetConnectionButtonState
    extends ConsumerState<_ResetConnectionButton> {
  bool _busy = false;

  Future<void> _reset() async {
    setState(() => _busy = true);
    // #3678 — the shared reset run (guarded + honest snackbar; the
    // messenger is captured inside, before the await).
    await runObd2ConnectionReset(context, ref);
    if (!mounted) return;
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return TextButton.icon(
      key: const Key('vehicleAdapterReset'),
      onPressed: _busy ? null : _reset,
      icon: _busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.restart_alt),
      label: Text(l.obd2ResetConnection),
    );
  }
}
