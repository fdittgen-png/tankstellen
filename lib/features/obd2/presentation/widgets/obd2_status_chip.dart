// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../providers/obd2_connection_state_provider.dart';
import 'obd2_adapter_picker.dart';

/// Title-bar OBD2 connection indicator (#797 phase 3).
///
/// Renders a 16 dp Bluetooth icon when the pinned adapter is
/// currently connected — a passive affordance that tells the user
/// "your car is plugged in" without competing with the
/// [Obd2StatusDot]'s traffic-light semantics in the global shell.
///
/// When an adapter IS paired but not currently connected (attempting,
/// unreachable, permission denied) the chip renders zero-size — the
/// [Obd2StatusDot] owns that "something is wrong" signal.
///
/// When NO adapter is paired at all (#1695), the chip instead shows a
/// discoverable "pair an OBD2 adapter" action: there is no status-dot
/// signal in that case either, so hiding entirely left pairing with no
/// entry point on the Consumption screen.
///
/// Tapping opens the adapter picker sheet so the user can pair / re-pair
/// on demand.
class Obd2StatusChip extends ConsumerWidget {
  const Obd2StatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(obd2ConnectionStatusProvider);
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (snapshot.state == Obd2ConnectionState.connected) {
      final name = snapshot.adapterName ?? '';
      final tooltip = l?.obd2ConnectedTooltip(name) ??
          'OBD2 connected: $name';
      return IconButton(
        key: const Key('obd2StatusChip'),
        tooltip: tooltip,
        icon: Icon(
          Icons.bluetooth_connected,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        // Shrink the hit region to keep the icon visually compact but
        // leave the real tap target at 48 dp so
        // androidTapTargetGuideline still passes.
        constraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        padding: EdgeInsets.zero,
        onPressed: () => showObd2AdapterPicker(context),
      );
    }

    // #1695 — not connected. When no adapter is paired to the active
    // vehicle, surface a discoverable "pair adapter" entry; when one IS
    // paired (transient disconnect) stay quiet and let the status dot
    // carry the signal.
    final pairedMac = ref.watch(activeVehicleProfileProvider)?.obd2AdapterMac;
    if (pairedMac != null && pairedMac.isNotEmpty) {
      return const SizedBox.shrink();
    }
    return IconButton(
      key: const Key('obd2PairChip'),
      tooltip: l?.obd2PairChipTooltip ?? 'Pair an OBD2 adapter',
      icon: Icon(
        Icons.bluetooth_searching,
        size: 16,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      constraints: const BoxConstraints(
        minWidth: 48,
        minHeight: 48,
      ),
      padding: EdgeInsets.zero,
      onPressed: () => showObd2AdapterPicker(context),
    );
  }
}
