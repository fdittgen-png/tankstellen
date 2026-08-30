// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../core/widgets/labeled_value_slider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/voice_announcement_settings_provider.dart';

/// Voice-announcement settings surface (#2569).
///
/// Hosted on Settings → Prices & alerts (#3884; moved out of
/// `DrivingSettingsSection`, where it sat four levels deep). The call
/// site gates visibility on `voiceAnnouncementsEnabledProvider` — the
/// `Feature.voiceAnnouncements` flag requires the radar, so the tile
/// only renders when both are on. Exposes the enable toggle plus the
/// three tunables the `AnnouncementEngine` reads — cheap-fuel price
/// threshold, proximity radius, and repeat cooldown — persisted by
/// [VoiceAnnouncementSettings]. The sliders are shown only while the
/// toggle is on, so the off-state stays a single compact row.
class VoiceAnnouncementsSettingsTile extends ConsumerWidget {
  const VoiceAnnouncementsSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final config = ref.watch(voiceAnnouncementSettingsProvider);
    final notifier = ref.read(voiceAnnouncementSettingsProvider.notifier);

    final double radiusKm = config.proximityRadiusKm.clamp(0.5, 5.0);
    final int cooldownMin = config.cooldown.inMinutes.clamp(5, 60);
    final double thresholdEur = (config.priceThreshold ?? 2.0).clamp(1.0, 2.5);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          key: const Key('voiceAnnouncementsToggle'),
          value: config.enabled,
          title: Text(l.voiceAnnouncementsTitle),
          subtitle: Text(
            l.voiceAnnouncementsDescription,
            style: theme.textTheme.bodySmall,
          ),
          onChanged: (v) => notifier.setEnabled(v),
          contentPadding: EdgeInsets.zero,
        ),
        if (config.enabled) ...[
          // Proximity radius — 0.5 … 5 km in 0.5 km steps. The current
          // value is shown as a persistent trailing readout (#2920) — a
          // bare `Slider.label` is only visible while dragging.
          LabeledValueSlider(
            sliderKey: const Key('voiceAnnouncementRadiusSlider'),
            label: l.voiceAnnouncementProximityRadius,
            // i18n-ignore: " km" is a language-neutral unit suffix (matches
            // ProfileRadiusSlider + the {km} ARB masks).
            valueLabel: UnitFormatter.formatDistance(radiusKm),
            labelStyle: theme.textTheme.bodyMedium,
            value: radiusKm,
            min: 0.5,
            max: 5.0,
            divisions: 9,
            onChanged: (v) => notifier.setProximityRadiusKm(v),
          ),
          // Repeat cooldown — 5 … 60 minutes in 5-minute steps.
          LabeledValueSlider(
            sliderKey: const Key('voiceAnnouncementCooldownSlider'),
            label: l.voiceAnnouncementCooldown,
            // i18n-ignore: " min" is a language-neutral unit abbreviation.
            valueLabel: '$cooldownMin min',
            labelStyle: theme.textTheme.bodyMedium,
            value: cooldownMin.toDouble(),
            min: 5,
            max: 60,
            divisions: 11,
            onChanged: (v) =>
                notifier.setCooldown(Duration(minutes: v.round())),
          ),
          // Cheap-fuel price ceiling — only stations at or below this
          // per-litre figure are announced. Its own distinct label
          // ("Maximum price") fixes the #2920 fallback that duplicated the
          // section subtitle; the value shows in the active currency.
          LabeledValueSlider(
            key: const Key('voiceAnnouncementThresholdTile'),
            sliderKey: const Key('voiceAnnouncementThresholdSlider'),
            label: l.voiceAnnouncementPriceLimit,
            valueLabel: PriceFormatter.formatPrice(thresholdEur),
            labelStyle: theme.textTheme.bodyMedium,
            value: thresholdEur,
            min: 1.0,
            max: 2.5,
            divisions: 30,
            onChanged: (v) => notifier.setPriceThreshold(v),
          ),
        ],
      ],
    );
  }
}
