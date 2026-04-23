import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../providers/obd2_connection_state_provider.dart';
import 'obd2_adapter_picker.dart';

/// Title-bar OBD2 connection indicator (#797 phase 3).
///
/// Renders a 16 dp Bluetooth icon when the pinned adapter is
/// currently connected — a passive affordance that tells the user
/// "your car is plugged in" without competing with the
/// [Obd2StatusDot]'s traffic-light semantics in the global shell.
///
/// When the adapter is not connected (attempting, unreachable,
/// permission denied, idle) the chip renders zero-size — this keeps
/// the AppBar quiet and lets the status dot remain the authoritative
/// "something is wrong" signal.
///
/// Tapping opens the adapter picker sheet so the user can re-pair
/// on demand.
class Obd2StatusChip extends ConsumerWidget {
  const Obd2StatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(obd2ConnectionStatusProvider);
    if (snapshot.state != Obd2ConnectionState.connected) {
      return const SizedBox.shrink();
    }
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
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
}
