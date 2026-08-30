// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/announcement_engine.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/core/widgets/labeled_value_slider.dart';
import 'package:tankstellen/features/driving/presentation/widgets/voice_announcements_settings_tile.dart';
import 'package:tankstellen/features/driving/providers/voice_announcement_settings_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/pump_app.dart';

/// Widget coverage for [VoiceAnnouncementsSettingsTile] (#2569 / #2920),
/// moved out of `DrivingSettingsSection` to Settings → Prices & alerts
/// (#3884). The tile owns the enable toggle and the three sliders.
void main() {
  testWidgets(
    'voice-announcement sliders show their CURRENT value as visible text at '
    'rest — radius, repeat interval and the price limit (#2920)',
    (tester) async {
      // A known config the user would see on the settings screen: 2.5 km
      // radius, a 30-minute repeat interval, and a 2.0 €/L price ceiling.
      const config = AnnouncementConfig(
        enabled: true,
        proximityRadiusKm: 2.5,
        cooldown: Duration(minutes: 30),
        priceThreshold: 2.0,
      );

      await pumpApp(
        tester,
        const VoiceAnnouncementsSettingsTile(),
        overrides: [
          voiceAnnouncementSettingsProvider.overrideWith(
            () => _FakeVoiceSettings(config),
          ),
        ],
      );

      // Sanity: the tile rendered the shared slider widget.
      expect(
        find.byType(LabeledValueSlider),
        findsNWidgets(3),
        reason:
            'All three voice sliders must use the shared '
            'LabeledValueSlider so the value is always visible.',
      );

      // Each slider must show its value as TEXT at rest, not only inside
      // the (drag-only) Slider.label.
      expect(find.text('2,5 km'), findsOneWidget,
          reason: 'The announcement-radius slider must show "2.5 km" at '
              'rest (#2920) — a bare Slider.label is invisible until dragged.');
      expect(find.text('30 min'), findsOneWidget,
          reason: 'The repeat-interval slider must show "30 min" at rest.');
      final priceText = PriceFormatter.formatPrice(2.0);
      expect(find.text(priceText), findsOneWidget,
          reason: 'The price-limit slider must show the formatted price '
              '("$priceText") at rest.');

      // The 3rd slider must carry its OWN distinct label, not the section
      // subtitle text it used to fall back to (#2920 mislabel).
      final l = AppLocalizations.of(
        tester.element(find.byType(VoiceAnnouncementsSettingsTile)),
      );
      expect(find.text(l.voiceAnnouncementPriceLimit), findsOneWidget,
          reason: 'The price-threshold slider must show a distinct '
              '"Maximum price" label — not the duplicated section subtitle.');
      expect(find.text(l.voiceAnnouncementsDescription), findsOneWidget,
          reason: 'The section subtitle text must appear exactly once (on '
              'the enable toggle) — never duplicated onto the price slider.');
    },
  );

  testWidgets('off-state collapses to the single enable row', (tester) async {
    await pumpApp(
      tester,
      const VoiceAnnouncementsSettingsTile(),
      overrides: [
        voiceAnnouncementSettingsProvider.overrideWith(
          () => _FakeVoiceSettings(const AnnouncementConfig(enabled: false)),
        ),
      ],
    );
    expect(find.byKey(const Key('voiceAnnouncementsToggle')), findsOneWidget);
    expect(find.byType(LabeledValueSlider), findsNothing);
  });
}

/// In-memory [VoiceAnnouncementSettings] for widget tests.
///
/// Returns the seeded [AnnouncementConfig] from `build()` synchronously,
/// bypassing the real notifier's `SharedPreferences` `_load()` so the
/// tile renders the exact config under test without platform plumbing.
class _FakeVoiceSettings extends VoiceAnnouncementSettings {
  _FakeVoiceSettings(this._config);

  final AnnouncementConfig _config;

  @override
  AnnouncementConfig build() => _config;
}
