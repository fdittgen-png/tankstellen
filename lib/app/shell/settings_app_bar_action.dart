import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';

/// Top-right app-bar action that opens the Settings (profile) screen
/// (#1874).
///
/// Settings is no longer a bottom-nav tab — every top-level destination
/// (Search / Map / Favorites / Consumption) carries this gear icon in
/// its `PageScaffold.actions`, mirroring the profile-avatar placement
/// of the reference design. Tapping it routes to branch 4 (`/profile`)
/// of the shell, so the screen's state is preserved across visits and
/// the bottom bar stays visible for navigating back out.
class SettingsAppBarAction extends StatelessWidget {
  const SettingsAppBarAction({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      icon: const Icon(Icons.settings_outlined),
      tooltip: l10n?.settings ?? 'Settings',
      onPressed: () => context.go('/profile'),
    );
  }
}
