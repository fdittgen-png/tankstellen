import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Hero header for the setup screen: gas-pump icon, app title (announced
/// as a heading), and a one-line subtitle. Pulled out of
/// `setup_screen.dart` so the screen no longer carries this widget block
/// inline.
class SetupHeader extends StatelessWidget {
  const SetupHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Semantics(
          excludeSemantics: true,
          child: Icon(
            Icons.local_gas_station,
            size: 72,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text(
            l10n?.welcome ?? 'Fuel Prices',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n?.welcomeSubtitle ?? 'Find the cheapest fuel near you.',
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
