import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import 'obd2_adapter_picker.dart';

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
                    l?.vehicleAdapterSectionTitle ?? 'OBD2 adapter',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (paired) ...[
              Text(
                name == null || name.isEmpty
                    ? (l?.vehicleAdapterUnnamed ?? 'Unknown adapter')
                    : name,
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: const Key('vehicleAdapterForget'),
                  onPressed: onForget,
                  icon: const Icon(Icons.link_off),
                  label: Text(
                    l?.vehicleAdapterForget ?? 'Forget adapter',
                  ),
                ),
              ),
            ] else ...[
              Text(
                l?.vehicleAdapterEmpty ??
                    'No adapter paired. Pair one so the app can reconnect automatically next time.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  key: const Key('vehicleAdapterPair'),
                  onPressed: () => _onPair(context),
                  icon: const Icon(Icons.bluetooth_searching),
                  label: Text(l?.vehicleAdapterPair ?? 'Pair adapter'),
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
