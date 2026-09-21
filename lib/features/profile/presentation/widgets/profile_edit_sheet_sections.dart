// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The two leaf sections of the profile edit sheet that need nothing from
/// its private scope (#4297).
///
/// Both were `part` classes of `profile_edit_sheet.dart`, which reached
/// **exactly** the 889 effective lines its `file_length_test` baseline
/// pins it to — leaving no room for the one-line fix #4295 deferred here
/// (an import plus a wrap, +2). #3141's anti-re-grandfathering guard
/// forbids raising the baseline, and the ratchet's own remedy is this:
/// extract a collaborator, so the number moves *down*. It now reads 857.
///
/// These two were the honest choice rather than the largest one. Each
/// already took `ProfileEditState` and `ProfileEditController` as
/// explicit constructor parameters and closed over nothing private, so
/// promoting them to public widgets is a rename and an import list — not
/// a redesign. The bigger `_RouteSegmentSection` would have freed four
/// times as many lines and carried four times the risk for a change that
/// needs two.
library;

import 'package:flutter/material.dart';

import '../../../../core/language/language_provider.dart';
import '../../providers/profile_edit_provider.dart';
import 'radar_settings_card.dart';

/// The approach-overlay (radar) settings block.
///
/// Delegates wholly to [RadarSettingsCard], which is already its own
/// file and documents this call site.
class ApproachOverlaySection extends StatelessWidget {
  final ProfileEditState state;
  final ProfileEditController ctrl;

  const ApproachOverlaySection({
    super.key,
    required this.state,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return RadarSettingsCard(
      radiusKm: state.approachRadiusKm,
      priceMode: state.approachPriceMode,
      minPollSeconds: state.approachMinPollSeconds,
      onRadiusChanged: ctrl.setApproachRadiusKm,
      onPriceModeChanged: ctrl.setApproachPriceMode,
      onMinPollSecondsChanged: ctrl.setApproachMinPollSeconds,
    );
  }
}

/// Language selector rendered as a wrap of ChoiceChips with native names.
///
/// The chip labels are each language's own [AppLanguage.nativeName] — a
/// proper noun in its own script, never translated. A German reader
/// picking Greek looks for `Ελληνικά`, not `Griechisch`.
class LanguageSection extends StatelessWidget {
  final ProfileEditState state;
  final ProfileEditController ctrl;

  const LanguageSection({
    super.key,
    required this.state,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: AppLanguages.all.map((l) {
        return ChoiceChip(
          label: Text(l.nativeName),
          selected: l.code == state.languageCode,
          onSelected: (_) => ctrl.setLanguageCode(l.code),
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }
}
