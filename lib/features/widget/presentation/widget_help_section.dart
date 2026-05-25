// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// In-app help for the home-screen widget (#1806).
///
/// The Android widget's per-widget configuration is OS-mediated
/// (long-press → Reconfigure) and cannot be launched from inside the
/// app, so the discoverable surface is this explanatory section in
/// Settings: how to add the widget, how its taps behave, and how to
/// reach the reconfigure gesture.
class WidgetHelpSection extends StatelessWidget {
  const WidgetHelpSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lines = <String>[
      l?.widgetHelpIntro ??
          'Add the SparKilo widget to your home screen to see fuel and '
              'charging prices at a glance.',
      l?.widgetHelpAdd ??
          "Add it from your launcher's widget picker — long-press an "
              'empty area of the home screen, choose Widgets, and find '
              'SparKilo.',
      l?.widgetHelpTap ??
          'Tap a station in the widget to open it in the app. Tap the '
              'refresh icon to update prices.',
      l?.widgetHelpConfigure ??
          'On Android, long-press the widget and choose Reconfigure to '
              'change the profile, colour, and content.',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines) ...[
            Text(line, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
