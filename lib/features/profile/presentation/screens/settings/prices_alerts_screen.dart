// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/app_routes.dart';
import '../../../../../core/widgets/section_card.dart';
import '../../../../../core/widgets/settings_menu_tile.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../driving/api.dart' show VoiceAnnouncementsSettingsTile;
import '../../../../feature_management/api.dart';
import '../../../providers/voice_announcements_enabled_provider.dart';
import '../../widgets/feature_management/feature_group_card.dart';
import 'settings_topic_scaffold.dart';

/// Settings → Prices & alerts (#3884): the alerts list, the voice
/// announcements (toggle + three sliders, moved out of the driving
/// section) and the price-related feature switches bound to the central
/// feature flags — one home per price parameter.
class PricesAlertsScreen extends ConsumerWidget {
  const PricesAlertsScreen({super.key});

  /// The price-related flags surfaced here, in display order. Each is
  /// rendered with the same [FeatureToggle] row Feature management uses,
  /// so the dependency gate (`tflitePricePrediction` requires
  /// `priceHistory`) and the blocked-tooltip behave identically.
  static const priceFeatures = <Feature>[
    Feature.priceHistory,
    Feature.tflitePricePrediction,
    Feature.communityPriceReports,
    Feature.paymentQrScan,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final manifest = ref.watch(featureManifestProvider);
    final enabled = ref.watch(enabledFeaturesProvider);
    final channel = ref.watch(buildChannelProvider);
    final voiceOn = ref.watch(voiceAnnouncementsEnabledProvider);
    // #1675 — a feature not available in the current build channel never
    // renders as a switch.
    final visible = priceFeatures
        .where((f) => manifest.entries[f]?.isAvailableIn(channel) ?? false)
        .toList();

    return SettingsTopicScaffold(
      title: l.settingsTopicPricesTitle,
      children: [
        SettingsMenuTile(
          key: const Key('settingsAlertsTile'),
          icon: Icons.notifications_active_outlined,
          title: l.priceAlerts,
          subtitle: l.settingsAlertsTileSubtitle,
          onTap: () => context.push(RoutePaths.alerts),
        ),
        const SizedBox(height: 16),
        SettingsGroupHeader(
          icon: Icons.record_voice_over_outlined,
          title: l.voiceAnnouncementsTitle,
        ),
        // #2569 — gated on the effective flag (requires the radar): the
        // tile only renders when both are on; otherwise say where to
        // turn it on instead of showing nothing.
        if (voiceOn)
          const SectionCard(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: VoiceAnnouncementsSettingsTile(),
          )
        else
          SettingsHintText(l.settingsVoiceAnnouncementsOffHint),
        const SizedBox(height: 16),
        SettingsGroupHeader(
          icon: Icons.euro_outlined,
          title: l.settingsPriceFeaturesHeader,
        ),
        SectionCard(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final f in visible)
                FeatureToggle(
                  feature: f,
                  isEnabled: enabled.contains(f),
                  manifest: manifest,
                  currentlyEnabled: enabled,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
