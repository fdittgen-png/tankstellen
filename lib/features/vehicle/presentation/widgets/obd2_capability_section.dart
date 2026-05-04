import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../consumption/data/obd2/adapter_capability.dart';
import '../../../consumption/providers/obd2_capability_provider.dart';

/// Card on the vehicle settings stack that surfaces the connected
/// adapter's runtime [Obd2AdapterCapability] tier (#1401 phase 6).
///
/// Three behaviours by capability:
///   * `null` (no adapter connected, or producer hasn't stamped a
///     capability yet) — collapses to [SizedBox.shrink] so the card
///     doesn't take vertical space on the screen.
///   * `passiveCanCapable` / `oemPidsCapable` — renders the tier label
///     and a matching icon with no upgrade hint.
///   * `standardOnly` — renders the tier label PLUS a one-line
///     informational hint pointing at the OBDLink STN-chip family.
///     No affiliate link, no purchase button.
///
/// Stateless `ConsumerWidget` — every change comes from
/// [currentObd2CapabilityProvider], which is itself derived from the
/// connection-state provider.
class Obd2CapabilitySection extends ConsumerWidget {
  const Obd2CapabilitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capability = ref.watch(currentObd2CapabilityProvider);
    if (capability == null) return const SizedBox.shrink();

    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SectionCard(
      title: l?.obd2CapabilitySectionTitle ?? 'Adapter capabilities',
      leadingIcon: Icons.memory,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(_iconFor(capability), color: cs.primary),
              const SizedBox(width: Spacing.lg),
              Expanded(
                child: Text(
                  _labelFor(capability, l),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ],
          ),
          if (capability == Obd2AdapterCapability.standardOnly) ...[
            const SizedBox(height: Spacing.md),
            Text(
              l?.obd2CapabilityUpgradeHintStandard ??
                  'For exact litres-in-tank on Peugeot/Citroën, the app '
                      'supports OBDLink MX+/LX/CX (STN chip).',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(Obd2AdapterCapability capability) {
    switch (capability) {
      case Obd2AdapterCapability.standardOnly:
        return Icons.usb;
      case Obd2AdapterCapability.oemPidsCapable:
        return Icons.tune;
      case Obd2AdapterCapability.passiveCanCapable:
        return Icons.bolt;
    }
  }

  String _labelFor(
    Obd2AdapterCapability capability,
    AppLocalizations? l,
  ) {
    switch (capability) {
      case Obd2AdapterCapability.standardOnly:
        return l?.obd2CapabilityStandardOnly ?? 'Standard';
      case Obd2AdapterCapability.oemPidsCapable:
        return l?.obd2CapabilityOemPids ?? 'OEM PIDs';
      case Obd2AdapterCapability.passiveCanCapable:
        return l?.obd2CapabilityFullCan ?? 'Full CAN';
    }
  }
}
