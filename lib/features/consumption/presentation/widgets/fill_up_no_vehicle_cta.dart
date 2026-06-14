// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
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
    // #3311 — guard the pop: this CTA owns the whole Add-Fill-up screen,
    // which is reached both by a push (poppable) AND as the "Carburant"
    // tab root (nothing to pop). An unguarded `context.pop()` on the tab
    // root threw `GoError: There is nothing to pop` (7 traces in one
    // session). Only show the back affordance when there's something to pop.
    // Use `GoRouter.maybeOf` (not `context.canPop()`, which asserts a
    // GoRouter ancestor): the screen is also mounted under a bare MaterialApp
    // in widget tests, where building must not throw "No GoRouter found".
    final router = GoRouter.maybeOf(context);
    final canPop = router?.canPop() ?? false;
    return PageScaffold(
      title: l.addFillUp,
      leading: canPop
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: l.tooltipBack,
              onPressed: () {
                if (router?.canPop() ?? false) router!.pop();
              },
            )
          : null,
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
              l.consumptionNoVehicleTitle,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l.consumptionNoVehicleBody,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => const EditVehicleRoute().push<void>(context),
              icon: const Icon(Icons.add),
              label: Text(l.vehicleAdd),
            ),
          ],
        ),
      ),
    );
  }
}
