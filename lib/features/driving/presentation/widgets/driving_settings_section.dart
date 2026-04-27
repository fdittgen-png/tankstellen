import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/settings_menu_tile.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/haptic_eco_coach_provider.dart';

/// Consumption / driving settings group on the profile screen.
///
/// Surfaced under the Conso-tab-aliased "Consumption" foldable, this
/// section composes everything the user might want to tune for the
/// vehicle they are currently driving:
///   1. **My vehicles** (battery, connectors, charging prefs).
///   2. **Fuel club cards** (per-litre discounts).
///   3. **Real-time eco coaching** (haptic when over-driving on cruise).
///
/// The first two were standalone `SettingsMenuTile`s on the Settings
/// page; pulling them inside one foldable that matches the "Conso" tab
/// label keeps the per-vehicle controls clustered (#1122 follow-up).
///
/// Default of the eco-coach toggle is **off** —
/// `HapticEcoCoachEnabled` reads the persisted Hive setting, which is
/// null for first-launch users and only flips to true after an
/// explicit tap.
class DrivingSettingsSection extends ConsumerWidget {
  const DrivingSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final enabled = ref.watch(hapticEcoCoachEnabledProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingsMenuTile(
          key: const Key('consoleVehiclesTile'),
          icon: Icons.directions_car,
          title: l?.vehiclesMenuTitle ?? 'My vehicles',
          subtitle: l?.vehiclesMenuSubtitle ??
              'Battery, connectors, charging preferences',
          onTap: () => context.push('/vehicles'),
        ),
        const SizedBox(height: 8),
        SettingsMenuTile(
          key: const Key('consoleFuelClubCardsTile'),
          icon: Icons.card_membership,
          title: l?.loyaltyMenuTitle ?? 'Fuel club cards',
          subtitle: l?.loyaltyMenuSubtitle ??
              'Apply per-litre discounts from Total, Aral, Shell, …',
          onTap: () => context.push('/loyalty-settings'),
        ),
        SwitchListTile(
          key: const Key('hapticEcoCoachToggle'),
          value: enabled,
          title: Text(
            l?.hapticEcoCoachSettingTitle ?? 'Real-time eco coaching',
          ),
          subtitle: Text(
            l?.hapticEcoCoachSettingSubtitle ??
                'Gentle haptic when you floor it during cruise',
            style: theme.textTheme.bodySmall,
          ),
          onChanged: (v) =>
              ref.read(hapticEcoCoachEnabledProvider.notifier).set(v),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
