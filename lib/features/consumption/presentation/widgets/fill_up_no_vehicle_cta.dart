import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/page_scaffold.dart';
import '../../../../l10n/app_localizations.dart';

/// Empty-state CTA shown by the Add-Fill-up screen when the vehicle
/// list is empty (#706). Consumption requires a vehicle, so instead of
/// rendering a useless form we pivot to a "Add a vehicle first" prompt
/// that links straight into the vehicle editor.
///
/// Pulled out of `add_fill_up_screen.dart` (#563 extraction) so the
/// screen file drops well below 300 LOC. The PageScaffold wrapper is
/// included here because the empty state owns the whole screen — it
/// is not a body fragment.
class FillUpNoVehicleCta extends StatelessWidget {
  const FillUpNoVehicleCta({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return PageScaffold(
      title: l?.addFillUp ?? 'Add fill-up',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: l?.tooltipBack ?? 'Back',
        onPressed: () => context.pop(),
      ),
      bodyPadding: const EdgeInsets.all(32),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              l?.consumptionNoVehicleTitle ?? 'Add a vehicle first',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l?.consumptionNoVehicleBody ??
                  'Fill-ups are attributed to a vehicle. Add your car '
                      'to start logging consumption.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/vehicles/edit'),
              icon: const Icon(Icons.add),
              label: Text(l?.vehicleAdd ?? 'Add vehicle'),
            ),
          ],
        ),
      ),
    );
  }
}
