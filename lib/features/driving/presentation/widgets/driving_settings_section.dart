import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/settings_menu_tile.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../consumption/providers/obd2_debug_logging_provider.dart';
import '../../../feature_management/application/feature_flags_provider.dart';
import '../../../feature_management/domain/conso_mode.dart';
import '../../../feature_management/domain/feature.dart';
import '../../../feature_management/domain/feature_dependency_graph.dart';
import '../../../glide_coach/providers/glide_coach_enabled_provider.dart';
import '../../../glide_coach/providers/glide_coach_settings_provider.dart';
import '../../../profile/presentation/widgets/gamification_settings_tile.dart';
import '../../providers/haptic_eco_coach_provider.dart';

/// Consumption / driving settings group on the profile screen.
///
/// Surfaced inside the Settings → Conso foldable, this widget is the
/// single child responsible for rendering every Conso-related
/// parameter. After #1572 it splits into three labelled sub-sections so
/// the user can see which functionality each parameter pairs with:
///
///   1. **My vehicles** — always visible when the foldable is rendered.
///      The vehicles tile is the primary affordance for both Medium
///      (manual fill-up tier) and Full (OBD2 trip tier).
///   2. **Trips (OBD2)** — only when [ConsoMode.fuelAndTrips]. Houses
///      the glide-coach beta toggle and reserves room for future
///      OBD2-specific parameters.
///   3. **Driving** — always visible. Real-time eco-coach,
///      gamification, and (when [Feature.loyaltyCards] is on) the fuel-
///      club entry-point.
class DrivingSettingsSection extends ConsumerWidget {
  const DrivingSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ecoEnabled = ref.watch(hapticEcoCoachEnabledProvider);
    final flags = ref.watch(enabledFeaturesProvider);
    // #1608 — the haptic eco-coach toggle must pre-check the dependency:
    // enabling it while `obd2TripRecording` is off throws a StateError
    // in the central provider. When the parent is off (and the toggle
    // isn't already on) the switch is disabled rather than letting the
    // tap fail.
    final canToggleEco = ecoEnabled ||
        canEnable(
          Feature.hapticEcoCoach,
          ref.watch(featureManifestProvider),
          flags,
        );
    // #1517 / #1520 — gate the Loyalty tile by the new
    // [Feature.loyaltyCards] flag. Default-off; only the
    // `AppProfile.full` preset turns it on, so Basic + Medium users
    // never see the Fuel club cards entry-point in Settings.
    final loyaltyOn = flags.contains(Feature.loyaltyCards);
    final mode = consoModeFromFlags(flags);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Mes véhicules sub-section — always present (the foldable
        //    itself is hidden when consumptionOn is false in
        //    ProfileScreen, so reaching this widget already means the
        //    Conso surface is on).
        SectionHeader(
          title: l?.consoSubsectionVehicles ?? 'My vehicles',
          leadingIcon: Icons.directions_car,
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
        ),
        SettingsMenuTile(
          key: const Key('consoleVehiclesTile'),
          icon: Icons.directions_car,
          title: l?.vehiclesMenuTitle ?? 'My vehicles',
          subtitle: l?.vehiclesMenuSubtitle ??
              'Battery, connectors, charging preferences',
          onTap: () => context.push('/vehicles'),
        ),

        // 2. Trips (OBD2) sub-section — only when the OBD2 stack is on
        //    (consoMode == fuelAndTrips). Houses glide-coach beta and
        //    leaves room for future Trajets-specific parameters.
        if (mode == ConsoMode.fuelAndTrips) ...[
          const SizedBox(height: 8),
          SectionHeader(
            title: l?.consoSubsectionTrajets ?? 'Trips (OBD2)',
            leadingIcon: Icons.route_outlined,
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
          ),
          if (ref.watch(glideCoachEnabledProvider))
            const _GlideCoachToggleTile(),
          const _Obd2DebugLoggingToggleTile(),
        ],

        // 3. Driving sub-section — eco-coach + gamification + fuel-club.
        const SizedBox(height: 8),
        SectionHeader(
          title: l?.consoSubsectionToggles ?? 'Driving',
          leadingIcon: Icons.tune,
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
        ),
        if (loyaltyOn)
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
          value: ecoEnabled,
          title: Text(
            l?.hapticEcoCoachSettingTitle ?? 'Real-time eco coaching',
          ),
          subtitle: Text(
            l?.hapticEcoCoachSettingSubtitle ??
                'Gentle haptic + on-screen tip when you floor it '
                    'during cruise',
            style: theme.textTheme.bodySmall,
          ),
          onChanged: canToggleEco
              ? (v) =>
                  ref.read(hapticEcoCoachEnabledProvider.notifier).set(v)
              : null,
          contentPadding: EdgeInsets.zero,
        ),
        const GamificationSettingsTile(),
      ],
    );
  }
}

/// Beta opt-in tile for the glide-coach haptic (#1125 phase 3b).
///
/// Rendered only when the `Feature.glideCoach` flag is enabled; the
/// call site in [DrivingSettingsSection] gates visibility via
/// `if (ref.watch(glideCoachEnabledProvider))`.
class _GlideCoachToggleTile extends ConsumerWidget {
  const _GlideCoachToggleTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final settings = ref.watch(glideCoachSettingsProvider);
    return SwitchListTile(
      key: const Key('glideCoachToggle'),
      value: settings.enabled,
      title: Text(l?.glideCoachBetaTitle ?? 'Glide-coach beta (experimental)'),
      subtitle: Text(
        l?.glideCoachBetaSubtitle ??
            'Subtle haptic when slowing down ahead of a red light. '
                'Off by default — distraction risk.',
        style: theme.textTheme.bodySmall,
      ),
      onChanged: (v) => ref
          .read(glideCoachSettingsProvider.notifier)
          .setEnabled(v),
      contentPadding: EdgeInsets.zero,
    );
  }
}

/// Opt-in toggle for OBD2 debug-session logging (#1925).
///
/// When on, every OBD2 connection is recorded — init handshake, data
/// gaps, drops and reconnects — as an exportable XML session log the
/// user can hand to a developer. Off by default; lives in the Trips
/// (OBD2) sub-section because it only concerns the OBD2 link.
class _Obd2DebugLoggingToggleTile extends ConsumerWidget {
  const _Obd2DebugLoggingToggleTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final enabled = ref.watch(obd2DebugSessionLoggingProvider);
    return SwitchListTile(
      key: const Key('obd2DebugLoggingToggle'),
      value: enabled,
      title: Text(l?.obd2DebugLoggingTitle ?? 'OBD2 debug logging'),
      subtitle: Text(
        l?.obd2DebugLoggingSubtitle ??
            'Record each OBD2 session — connection, handshake, data '
                'gaps and reconnects — to an exportable XML log. Off by '
                'default.',
        style: theme.textTheme.bodySmall,
      ),
      onChanged: (v) =>
          ref.read(obd2DebugSessionLoggingProvider.notifier).set(v),
      contentPadding: EdgeInsets.zero,
    );
  }
}
