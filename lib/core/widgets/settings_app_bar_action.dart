// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../navigation/app_routes.dart';
import '../navigation/current_shell_branch_provider.dart';
import '../../l10n/app_localizations.dart';

part 'settings_app_bar_action.g.dart';

/// The route each shell-branch index returns to, mirroring the branch order in
/// `shell_branches.dart` (#3061). Used to send the Settings back arrow to the
/// branch the user came from. Branch 4 is Settings itself, so it is never an
/// origin; anything unmapped falls back to home (`/`).
String routeForShellBranch(int branch) => switch (branch) {
      1 => '/map',
      2 => '/favorites',
      3 => '/consumption-tab',
      5 => '/trajets-tab',
      _ => '/', // 0 = Search / home
    };

/// Where the Settings (Profile) branch returns to when its top-left back arrow
/// is tapped (#3061). [SettingsAppBarAction] records it from the app's reliable
/// branch tracker the moment the gear is tapped, so `ProfileScreen`'s back
/// button is a TRUE "back" to wherever the user came from. Defaults to home
/// (`/`).
@riverpod
class SettingsReturnLocation extends _$SettingsReturnLocation {
  @override
  String build() => '/';

  void update(String location) => state = location;
}

/// Top-right app-bar action that opens the Settings (profile) screen
/// (#1874).
///
/// Settings is no longer a bottom-nav tab — every top-level destination
/// (Search / Map / Favorites / Consumption) carries this gear icon in
/// its `PageScaffold.actions`, mirroring the profile-avatar placement
/// of the reference design. Tapping it routes to branch 4 (`/profile`)
/// of the shell, so the screen's state is preserved across visits and
/// the bottom bar stays visible for navigating back out.
class SettingsAppBarAction extends ConsumerWidget {
  const SettingsAppBarAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      icon: const Icon(Icons.settings_outlined),
      tooltip: l10n?.settings ?? 'Settings',
      onPressed: () {
        // #3061 — record the branch the user is on (the shell keeps this
        // current) BEFORE switching to Settings, so the Settings back arrow
        // returns there instead of always dumping the user on home. The
        // branch switch below has no back-stack of its own.
        final from = routeForShellBranch(ref.read(currentShellBranchProvider));
        ref.read(settingsReturnLocationProvider.notifier).update(from);
        context.go(RoutePaths.profile);
      },
    );
  }
}
