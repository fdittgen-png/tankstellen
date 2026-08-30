// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/scope_badge.dart';
import '../../../../../core/widgets/section_card.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../search/api.dart' show radarAutoPinProvider;
import '../../../domain/entities/user_profile.dart';
import '../../../providers/profile_provider.dart';
import '../../widgets/radar_settings_card.dart';
import 'settings_topic_scaffold.dart';

/// Settings → Driving & consumption → Fuel Station Radar (#3884).
///
/// Hosts the ACTIVE profile's radar parameters (radius, price mode, min
/// poll — the same [RadarSettingsCard] the profile edit sheet uses) and
/// the app-wide "always pin when the radar starts" switch (#2785), which
/// was previously reachable only from the radar pin help sheet.
///
/// Edits persist immediately on the active profile (no Save button —
/// like the widget-defaults editor). A local draft mirrors the profile
/// while a slider is dragged so the thumb never lags the async Hive
/// write.
class RadarSettingsScreen extends ConsumerStatefulWidget {
  const RadarSettingsScreen({super.key});

  @override
  ConsumerState<RadarSettingsScreen> createState() =>
      _RadarSettingsScreenState();
}

class _RadarSettingsScreenState extends ConsumerState<RadarSettingsScreen> {
  UserProfile? _draft;

  void _persist(UserProfile next) {
    setState(() => _draft = next);
    // Fire-and-forget like the widget-defaults editor (#2106): the
    // provider repaints when Hive returns; failures are logged by the
    // notifier itself.
    unawaited(ref.read(activeProfileProvider.notifier).updateProfile(next));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final active = ref.watch(activeProfileProvider);
    // Re-seed the draft whenever the active profile changes identity.
    final profile = (_draft != null && _draft!.id == active?.id)
        ? _draft!
        : active;
    final autoPin = ref.watch(radarAutoPinProvider);

    return SettingsTopicScaffold(
      title: l.approachOverlaySection,
      children: [
        if (profile == null)
          SettingsHintText(l.settingsRadarNoProfileHint)
        else ...[
          SettingsGroupHeader(
            icon: Icons.radar,
            title: l.approachOverlaySection,
            subtitle: profile.name,
            trailing: const ScopeBadge(SettingsScope.thisProfile),
          ),
          SectionCard(
            child: RadarSettingsCard(
              radiusKm: profile.approachRadiusKm,
              priceMode: profile.approachPriceMode,
              minPollSeconds: profile.approachMinPollSeconds,
              onRadiusChanged: (v) =>
                  _persist(profile.copyWith(approachRadiusKm: v)),
              onPriceModeChanged: (v) =>
                  _persist(profile.copyWith(approachPriceMode: v)),
              onMinPollSecondsChanged: (v) =>
                  _persist(profile.copyWith(approachMinPollSeconds: v)),
            ),
          ),
        ],
        const SizedBox(height: 16),
        SettingsGroupHeader(
          icon: Icons.push_pin_outlined,
          title: l.settingsRadarPinHeader,
          trailing: const ScopeBadge(SettingsScope.allProfiles),
        ),
        SectionCard(
          padding: EdgeInsets.zero,
          child: SwitchListTile(
            key: const Key('settingsRadarAutoPinToggle'),
            value: autoPin,
            title: Text(l.radarAutoPinTitle),
            subtitle: Text(l.radarAutoPinSubtitle),
            onChanged: (v) =>
                unawaited(ref.read(radarAutoPinProvider.notifier).set(v)),
          ),
        ),
      ],
    );
  }
}
