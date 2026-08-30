// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/app_routes.dart';
import '../../../../../core/widgets/scope_badge.dart';
import '../../../../../core/widgets/settings_menu_tile.dart';
import '../../../../../l10n/app_localizations.dart';
import 'settings_topic_scaffold.dart';

/// Settings → Vehicles & OBD2 (#3884): the vehicle list (fuel type,
/// engine, tank size) and the per-vehicle OBD2 adapter pairing, which
/// lives on the Edit vehicle screen — hence the "This vehicle" badge.
class VehiclesObd2Screen extends StatelessWidget {
  const VehiclesObd2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SettingsTopicScaffold(
      title: l.settingsTopicVehiclesTitle,
      children: [
        SettingsMenuTile(
          key: const Key('settingsVehiclesTile'),
          icon: Icons.directions_car,
          title: l.vehiclesMenuTitle,
          subtitle: l.vehiclesMenuSubtitle,
          onTap: () => context.push(RoutePaths.vehicles),
        ),
        const SizedBox(height: 8),
        SettingsMenuTile(
          key: const Key('settingsObd2AdapterTile'),
          icon: Icons.bluetooth,
          title: l.settingsObd2AdapterTitle,
          subtitle: l.settingsObd2AdapterSubtitle,
          badge: const ScopeBadge(SettingsScope.thisVehicle),
          onTap: () => context.push(RoutePaths.vehicles),
        ),
      ],
    );
  }
}
