import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/charging_log_readout.dart';

/// Renders the EUR/100 km + kWh/100 km line below the cost field on
/// the Add-Charging-Log form (#582 phase 2). Pulled out of
/// `add_charging_log_screen.dart` so the screen drops a private
/// widget class and the rendering logic gets its own widget test.
///
/// Three states (see [ChargingLogReadout]):
///
///  * [readout] is `null` — render nothing (zero-height shrink).
///  * [readout] is empty — render the "need a previous log to
///    compare" helper line in the muted on-surface-variant colour.
///  * [readout] has values — render the formatted EUR/kWh per-100-km
///    row with the insights icon in the primary colour.
class ChargingLogDerivedReadoutPanel extends StatelessWidget {
  final ChargingLogReadout? readout;

  const ChargingLogDerivedReadoutPanel({super.key, required this.readout});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = readout;
    if (r == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.primary,
    );
    if (!r.hasValues) {
      return Padding(
        padding: const EdgeInsets.only(top: 6, left: 12),
        child: Text(
          l?.chargingDerivedHelper ?? 'Need a previous log to compare',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          key: const Key('charging_derived_helper'),
        ),
      );
    }
    final eurStr = r.eurPer100km!.toStringAsFixed(2);
    final kwhStr = r.kwhPer100km!.toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 12),
      child: Row(
        key: const Key('charging_derived_readout'),
        children: [
          Icon(Icons.insights_outlined,
              size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '${l?.chargingEurPer100km(eurStr) ?? '$eurStr EUR / 100 km'}'
              '  •  '
              '${l?.chargingKwhPer100km(kwhStr) ?? '$kwhStr kWh / 100 km'}',
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}
