// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/price_formatter.dart';
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
import '../../../profile/providers/voice_announcements_enabled_provider.dart';
import '../../providers/haptic_eco_coach_provider.dart';
import '../../providers/voice_announcement_settings_provider.dart';

/// Consumption / driving settings group on the profile screen.
///
/// Surfaced inside the Settings → Conso foldable, this widget is the
/// single child responsible for rendering every Conso-related
/// parameter. After #2566 it groups parameters by *purpose* — each group
/// gathers controls that serve the same job, so the user can tell at a
/// glance what each setting affects:
///
///   1. **Vehicles** — always visible when the foldable is rendered.
///      The vehicles tile is the primary affordance for both Medium
///      (manual fill-up tier) and Full (OBD2 trip tier); the subtitle
///      describes what `/vehicles` manages (fuel type, engine, tank
///      size) for both combustion and EV cars.
///   2. **Coaching while driving** — the two haptic driving assists
///      gathered together: real-time eco-coaching (gated by the
///      `obd2TripRecording` dependency via [canEnable]) followed by the
///      glide-coach beta (visible only when [Feature.glideCoach] is on).
///   3. **Rewards & savings** — the fuel-club entry-point (when
///      [Feature.loyaltyCards] is on) and the gamification opt-out.
///   4. **Troubleshooting** — only when the OBD2 stack is on
///      ([ConsoMode.fuelAndTrips]). Houses the OBD2 debug-logging
///      diagnostic, clearly separated from the user-facing features.
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
        // 1. Vehicles — always present (the foldable itself is hidden
        //    when consumptionOn is false in ProfileScreen, so reaching
        //    this widget already means the Conso surface is on). One
        //    clear header; the tile carries an accurate subtitle that
        //    describes what /vehicles manages for both fuel + EV cars.
        SectionHeader(
          title: l?.consoGroupVehicles ?? 'Vehicles',
          leadingIcon: Icons.directions_car,
          padding: const EdgeInsets.fromLTRB(0, Spacing.sm, 0, Spacing.sm),
        ),
        SettingsMenuTile(
          key: const Key('consoleVehiclesTile'),
          icon: Icons.directions_car,
          title: l?.vehiclesMenuTitle ?? 'My vehicles',
          subtitle: l?.vehiclesMenuSubtitle ??
              'Your cars — fuel type, engine and tank size for accurate '
                  'consumption estimates',
          onTap: () => context.push('/vehicles'),
        ),

        // 2. Coaching while driving — the two haptic driving assists
        //    grouped together. Real-time eco-coaching keeps the #1608
        //    `canToggleEco` dependency gate verbatim; the glide-coach
        //    beta keeps its `glideCoachEnabledProvider` visibility gate.
        const SizedBox(height: Spacing.md),
        SectionHeader(
          title: l?.consoGroupCoaching ?? 'Coaching while driving',
          leadingIcon: Icons.self_improvement,
          padding: const EdgeInsets.fromLTRB(0, Spacing.sm, 0, Spacing.sm),
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
        if (ref.watch(glideCoachEnabledProvider))
          const _GlideCoachToggleTile(),
        // #2569 — spoken nearby-cheap-fuel announcements. Visible only
        // when the `Feature.voiceAnnouncements` flag is effectively on
        // (it requires the approach overlay, so the gate is false unless
        // both are enabled). Fits the coaching theme: it is hands-free
        // driving guidance, like the haptic coaches above.
        if (ref.watch(voiceAnnouncementsEnabledProvider))
          const _VoiceAnnouncementsTile(),

        // 3. Rewards & savings — the fuel-club entry-point (when
        //    [Feature.loyaltyCards] is on) and the gamification opt-out.
        const SizedBox(height: Spacing.md),
        SectionHeader(
          title: l?.consoGroupRewards ?? 'Rewards & savings',
          leadingIcon: Icons.emoji_events_outlined,
          padding: const EdgeInsets.fromLTRB(0, Spacing.sm, 0, Spacing.sm),
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
        const GamificationSettingsTile(),

        // 4. Troubleshooting — only when the OBD2 stack is on
        //    (consoMode == fuelAndTrips). The OBD2 debug-logging toggle
        //    is a developer diagnostic, kept clearly apart from the
        //    user-facing features above.
        if (mode == ConsoMode.fuelAndTrips) ...[
          const SizedBox(height: Spacing.md),
          SectionHeader(
            title: l?.consoGroupTroubleshooting ?? 'Troubleshooting',
            leadingIcon: Icons.bug_report_outlined,
            padding: const EdgeInsets.fromLTRB(0, Spacing.sm, 0, Spacing.sm),
          ),
          const _Obd2DebugLoggingToggleTile(),
        ],
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

/// Voice-announcement settings surface (#2569).
///
/// Rendered only when the `Feature.voiceAnnouncements` flag is
/// effectively enabled (the call site gates visibility via
/// `if (ref.watch(voiceAnnouncementsEnabledProvider))`). Exposes the
/// enable toggle plus the three tunables the dormant
/// `AnnouncementEngine` already reads — cheap-fuel price threshold,
/// proximity radius, and repeat cooldown — persisted by
/// [VoiceAnnouncementSettings]. The sliders are shown only while the
/// toggle is on, so the off-state stays a single compact row.
class _VoiceAnnouncementsTile extends ConsumerWidget {
  const _VoiceAnnouncementsTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final config = ref.watch(voiceAnnouncementSettingsProvider);
    final notifier = ref.read(voiceAnnouncementSettingsProvider.notifier);

    final thresholdLabel = config.priceThreshold != null
        ? (l?.voiceAnnouncementThreshold(
                PriceFormatter.formatPrice(config.priceThreshold)) ??
            'Only below ${PriceFormatter.formatPrice(config.priceThreshold)}')
        : (l?.voiceAnnouncementsDescription ??
            'Announce nearby cheap stations while driving');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          key: const Key('voiceAnnouncementsToggle'),
          value: config.enabled,
          title: Text(l?.voiceAnnouncementsTitle ?? 'Voice Announcements'),
          subtitle: Text(
            l?.voiceAnnouncementsDescription ??
                'Announce nearby cheap stations while driving',
            style: theme.textTheme.bodySmall,
          ),
          onChanged: (v) => notifier.setEnabled(v),
          contentPadding: EdgeInsets.zero,
        ),
        if (config.enabled) ...[
          // Proximity radius — 0.5 … 5 km in 0.5 km steps.
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l?.voiceAnnouncementProximityRadius ?? 'Announcement radius',
              style: theme.textTheme.bodyMedium,
            ),
            subtitle: Slider(
              key: const Key('voiceAnnouncementRadiusSlider'),
              value: config.proximityRadiusKm.clamp(0.5, 5.0),
              min: 0.5,
              max: 5.0,
              divisions: 9,
              label: '${config.proximityRadiusKm.toStringAsFixed(1)} km',
              onChanged: (v) => notifier.setProximityRadiusKm(v),
            ),
          ),
          // Repeat cooldown — 5 … 60 minutes in 5-minute steps.
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l?.voiceAnnouncementCooldown ?? 'Repeat interval',
              style: theme.textTheme.bodyMedium,
            ),
            subtitle: Slider(
              key: const Key('voiceAnnouncementCooldownSlider'),
              value: config.cooldown.inMinutes.clamp(5, 60).toDouble(),
              min: 5,
              max: 60,
              divisions: 11,
              label: '${config.cooldown.inMinutes} min',
              onChanged: (v) =>
                  notifier.setCooldown(Duration(minutes: v.round())),
            ),
          ),
          // Cheap-fuel price threshold — current value shown in the
          // active currency; the slider spans a sensible per-litre band.
          ListTile(
            key: const Key('voiceAnnouncementThresholdTile'),
            contentPadding: EdgeInsets.zero,
            title: Text(thresholdLabel, style: theme.textTheme.bodyMedium),
            subtitle: Slider(
              key: const Key('voiceAnnouncementThresholdSlider'),
              value: (config.priceThreshold ?? 2.0).clamp(1.0, 2.5),
              min: 1.0,
              max: 2.5,
              divisions: 30,
              label: PriceFormatter.formatPrice(config.priceThreshold ?? 2.0),
              onChanged: (v) => notifier.setPriceThreshold(v),
            ),
          ),
        ],
      ],
    );
  }
}

/// Opt-in toggle for OBD2 debug-session logging (#1925).
///
/// When on, every OBD2 connection is recorded — init handshake, data
/// gaps, drops and reconnects — as an exportable XML session log the
/// user can hand to a developer. Off by default; lives in the
/// Troubleshooting group because it is a diagnostic, not a feature, and
/// only concerns the OBD2 link (#2566).
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
