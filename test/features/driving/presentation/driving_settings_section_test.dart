// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/services/announcement_engine.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/core/widgets/labeled_value_slider.dart';
import 'package:tankstellen/core/widgets/section_header.dart';
import 'package:tankstellen/core/widgets/settings_menu_tile.dart';
import 'package:tankstellen/features/driving/presentation/widgets/driving_settings_section.dart';
import 'package:tankstellen/features/driving/providers/voice_announcement_settings_provider.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/glide_coach/providers/glide_coach_enabled_provider.dart';
import 'package:tankstellen/features/profile/presentation/widgets/gamification_settings_tile.dart';
import 'package:tankstellen/features/profile/providers/voice_announcements_enabled_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../fakes/fake_storage_repository.dart';
import '../../../helpers/pump_app.dart';

/// Widget coverage for [DrivingSettingsSection] (#1122).
///
/// As of #1373 phase 3a the haptic eco-coach toggle reads/writes
/// through the central [featureFlagsProvider] rather than the legacy
/// settings box. The widget surface (key, label, ordering) is
/// unchanged; the test overrides now point at a synthetic
/// in-memory feature-flag notifier ([_TestFeatureFlags]) instead of
/// the real Hive-backed repository to keep these tests fast and
/// platform-deterministic.
///
/// Two scenarios:
///   1. Default-OFF state renders the switch as off and tapping it
///      flips the central feature-flag set on (assertions inspect the
///      synthetic notifier's state directly).
///   2. Pre-seeded central state with hapticEcoCoach enabled hydrates
///      the switch to on on first paint.
///
/// We intentionally bypass the real [FeatureFlagsRepository] /
/// `featureFlagsRepositoryProvider` here because real Hive boxes
/// triggered hangs in `pumpAndSettle` on Windows after the toggle's
/// fire-and-forget save (see memory file
/// `feedback_hive_widget_test_teardown.md`). Persistence is covered
/// in `test/features/feature_management/feature_flags_provider_test.dart`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'renders the haptic eco-coach toggle in the off state by default and '
    'flips the central feature-flag set when tapped',
    (tester) async {
      // Seed prerequisite (obd2TripRecording) so the central enable
      // succeeds — without it the shim would silently swallow the
      // dependency-violation StateError.
      final fakeFlags = _TestFeatureFlags(<Feature>{Feature.obd2TripRecording});

      await pumpApp(
        tester,
        const DrivingSettingsSection(),
        overrides: [
          settingsStorageProvider.overrideWithValue(_FakeSettingsStorage()),
          storageRepositoryProvider.overrideWithValue(FakeStorageRepository()),
          featureFlagsProvider.overrideWith(() => fakeFlags),
        ],
      );

      final switchFinder = find.byKey(const Key('hapticEcoCoachToggle'));
      expect(switchFinder, findsOneWidget);
      final initial = tester.widget<SwitchListTile>(switchFinder);
      expect(
        initial.value,
        isFalse,
        reason: 'Default-OFF must hold for first-launch users (#1122).',
      );

      await tester.tap(switchFinder);
      // Two pumps: drain microtasks then advance simulated time so the
      // notifier's `enable` Future settles before assertion.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Central state must have flipped on.
      expect(
        fakeFlags.state.requireValue,
        contains(Feature.hapticEcoCoach),
        reason:
            'Tapping the toggle must enable hapticEcoCoach in the central '
            'feature-flag set so the setting survives an app restart via '
            'the central repository (#1373 phase 3a).',
      );
      final flipped = tester.widget<SwitchListTile>(switchFinder);
      expect(
        flipped.value,
        isTrue,
        reason: 'The switch must reflect the new central state immediately.',
      );
    },
  );

  testWidgets(
    'reads the persisted central state on build so the switch starts on',
    (tester) async {
      final fakeFlags = _TestFeatureFlags(<Feature>{
        Feature.obd2TripRecording,
        Feature.hapticEcoCoach,
      });

      await pumpApp(
        tester,
        const DrivingSettingsSection(),
        overrides: [
          settingsStorageProvider.overrideWithValue(_FakeSettingsStorage()),
          storageRepositoryProvider.overrideWithValue(FakeStorageRepository()),
          featureFlagsProvider.overrideWith(() => fakeFlags),
        ],
      );

      final switchFinder = find.byKey(const Key('hapticEcoCoachToggle'));
      final tile = tester.widget<SwitchListTile>(switchFinder);
      expect(
        tile.value,
        isTrue,
        reason:
            'A persisted-true central state must hydrate the toggle on '
            'first paint — otherwise the user would have to flip it twice '
            'on every cold start.',
      );
    },
  );

  testWidgets('composes vehicles + fuel-club tiles above the eco-coach toggle '
      '(#1242 — Console grouping)', (tester) async {
    await pumpApp(
      tester,
      const DrivingSettingsSection(),
      overrides: [
        settingsStorageProvider.overrideWithValue(_FakeSettingsStorage()),
        storageRepositoryProvider.overrideWithValue(FakeStorageRepository()),
        // #1517 / #1520 — the Fuel club cards tile is now gated by
        // `Feature.loyaltyCards`. Pin it on so this composition test
        // still asserts both tiles render together. Default-off
        // semantics are covered separately by the gating-audit
        // unit tests.
        featureFlagsProvider.overrideWith(
          () => _TestFeatureFlags(<Feature>{Feature.loyaltyCards}),
        ),
      ],
    );

    // #2566 — the vehicles tile is the first group (Vehicles); the
    // fuel-club tile lives in the Rewards & savings group.
    expect(
      find.byKey(const Key('consoleVehiclesTile')),
      findsOneWidget,
      reason:
          'My vehicles tile must render inside the Conso section '
          'as the first (Vehicles) group after #2566.',
    );
    expect(
      find.byKey(const Key('consoleFuelClubCardsTile')),
      findsOneWidget,
      reason:
          'Fuel club cards tile is part of the Rewards & savings '
          'group.',
    );

    final children = <Widget>[
      for (final t in tester.widgetList<SettingsMenuTile>(
        find.byType(SettingsMenuTile),
      ))
        t,
    ];
    expect(
      children.length,
      2,
      reason:
          'Exactly two SettingsMenuTile children: the vehicles tile '
          '(Vehicles group) + Fuel club cards (Rewards & savings group).',
    );
  });

  testWidgets(
    'regroups the section into the #2566 purpose-driven IA — Vehicles, '
    'Coaching while driving, Rewards & savings, Troubleshooting — in '
    'order, with the OBD2 diagnostic gated behind the OBD2 stack',
    (tester) async {
      // OBD2 stack on (obd2TripRecording) + loyalty + glide-coach + its
      // prereq so every group and both coaching toggles render. Override
      // glideCoachEnabledProvider directly so the toggle is visible.
      await pumpApp(
        tester,
        const DrivingSettingsSection(),
        overrides: [
          settingsStorageProvider.overrideWithValue(_FakeSettingsStorage()),
          storageRepositoryProvider.overrideWithValue(FakeStorageRepository()),
          featureFlagsProvider.overrideWith(
            () => _TestFeatureFlags(<Feature>{
              // showConsumptionTab + obd2TripRecording => ConsoMode
              // .fuelAndTrips, which surfaces the Troubleshooting group.
              Feature.showConsumptionTab,
              Feature.obd2TripRecording,
              Feature.loyaltyCards,
            }),
          ),
          glideCoachEnabledProvider.overrideWithValue(true),
        ],
      );

      // Resolve the localized group-header strings from the running app.
      final l = AppLocalizations.of(
        tester.element(find.byType(DrivingSettingsSection)),
      );
      final headerTitles = tester
          .widgetList<SectionHeader>(find.byType(SectionHeader))
          .map((h) => h.title)
          .toList();
      expect(
        headerTitles,
        <String>[
          l.consoGroupVehicles,
          l.consoGroupCoaching,
          l.consoGroupRewards,
          l.consoGroupTroubleshooting,
        ],
        reason:
            'The four purpose-driven groups must render in IA order '
            '(#2566): Vehicles, Coaching while driving, Rewards & savings, '
            'Troubleshooting.',
      );

      // Every preserved control + Key must still be present.
      expect(find.byKey(const Key('consoleVehiclesTile')), findsOneWidget);
      expect(find.byKey(const Key('hapticEcoCoachToggle')), findsOneWidget);
      expect(find.byKey(const Key('glideCoachToggle')), findsOneWidget);
      expect(find.byKey(const Key('consoleFuelClubCardsTile')), findsOneWidget);
      expect(find.byType(GamificationSettingsTile), findsOneWidget);
      expect(
        find.byKey(const Key('obd2DebugLoggingToggle')),
        findsOneWidget,
        reason:
            'The OBD2 debug-logging diagnostic lives in the '
            'Troubleshooting group, shown only when the OBD2 stack is on.',
      );

      // The two coaching toggles must sit together, eco-coach first then
      // glide-coach, between the Coaching and Rewards headers.
      final ecoY = tester
          .getTopLeft(find.byKey(const Key('hapticEcoCoachToggle')))
          .dy;
      final glideY = tester
          .getTopLeft(find.byKey(const Key('glideCoachToggle')))
          .dy;
      expect(
        ecoY < glideY,
        isTrue,
        reason:
            'Eco-coaching must render above glide-coach within the '
            'Coaching while driving group.',
      );
    },
  );

  testWidgets(
    'hides the Troubleshooting group (and OBD2 debug-logging) while the '
    'OBD2 stack is off (consoMode != fuelAndTrips)',
    (tester) async {
      await pumpApp(
        tester,
        const DrivingSettingsSection(),
        overrides: [
          settingsStorageProvider.overrideWithValue(_FakeSettingsStorage()),
          storageRepositoryProvider.overrideWithValue(FakeStorageRepository()),
          featureFlagsProvider.overrideWith(() => _TestFeatureFlags()),
        ],
      );

      final l = AppLocalizations.of(
        tester.element(find.byType(DrivingSettingsSection)),
      );
      final headerTitles = tester
          .widgetList<SectionHeader>(find.byType(SectionHeader))
          .map((h) => h.title)
          .toList();
      expect(
        headerTitles,
        isNot(contains(l.consoGroupTroubleshooting)),
        reason:
            'No Troubleshooting group without the OBD2 stack — the '
            'debug-logging diagnostic only concerns the OBD2 link.',
      );
      expect(find.byKey(const Key('obd2DebugLoggingToggle')), findsNothing);
    },
  );

  testWidgets(
    'glide-coach beta toggle stays invisible while Feature.glideCoach '
    'is off by default (#1125 phase 3b / #1824)',
    (tester) async {
      await pumpApp(
        tester,
        const DrivingSettingsSection(),
        overrides: [
          settingsStorageProvider.overrideWithValue(_FakeSettingsStorage()),
          storageRepositoryProvider.overrideWithValue(FakeStorageRepository()),
          featureFlagsProvider.overrideWith(() => _TestFeatureFlags()),
        ],
      );

      // `_TestFeatureFlags` starts with no features enabled, so
      // Feature.glideCoach is off — the toggle MUST stay invisible so
      // users cannot accidentally enable a half-baked feature.
      expect(
        find.byKey(const Key('glideCoachToggle')),
        findsNothing,
        reason:
            'A disabled Feature.glideCoach MUST hide the glide-coach '
            'toggle entirely.',
      );
    },
  );

  testWidgets('nests the gamification opt-out tile inside the Conso section '
      '(#1249 — moved out of the standalone settings card)', (tester) async {
    await pumpApp(
      tester,
      const DrivingSettingsSection(),
      overrides: [
        settingsStorageProvider.overrideWithValue(_FakeSettingsStorage()),
        storageRepositoryProvider.overrideWithValue(FakeStorageRepository()),
        featureFlagsProvider.overrideWith(() => _TestFeatureFlags()),
      ],
    );

    // The gamification toggle now lives as the last child of the
    // Consumption foldable instead of as a sibling Card on the
    // Settings page. Asserting it is present here pins that
    // placement so a future rewrite can't silently move it back.
    expect(
      find.byType(GamificationSettingsTile),
      findsOneWidget,
      reason:
          'Exactly one GamificationSettingsTile must render inside '
          'DrivingSettingsSection — duplication or absence indicates '
          'the #1249 placement regressed.',
    );
  });

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
        const DrivingSettingsSection(),
        overrides: [
          settingsStorageProvider.overrideWithValue(_FakeSettingsStorage()),
          storageRepositoryProvider.overrideWithValue(FakeStorageRepository()),
          featureFlagsProvider.overrideWith(() => _TestFeatureFlags()),
          // The voice-announcements tile is gated behind this master flag.
          voiceAnnouncementsEnabledProvider.overrideWithValue(true),
          voiceAnnouncementSettingsProvider.overrideWith(
            () => _FakeVoiceSettings(config),
          ),
        ],
      );

      // Sanity: the section rendered the new shared slider widget.
      expect(
        find.byType(LabeledValueSlider),
        findsNWidgets(3),
        reason:
            'All three voice sliders must use the shared '
            'LabeledValueSlider so the value is always visible.',
      );

      // The regression the user reported: each slider must show its value
      // as TEXT at rest, not only inside the (drag-only) Slider.label.
      expect(
        find.text('2.5 km'),
        findsOneWidget,
        reason:
            'The announcement-radius slider must show "2.5 km" at rest '
            '(#2920) — a bare Slider.label is invisible until dragged.',
      );
      expect(
        find.text('30 min'),
        findsOneWidget,
        reason: 'The repeat-interval slider must show "30 min" at rest.',
      );
      final priceText = PriceFormatter.formatPrice(2.0);
      expect(
        find.text(priceText),
        findsOneWidget,
        reason:
            'The price-limit slider must show the formatted price '
            '("$priceText") at rest.',
      );

      // The 3rd slider must carry its OWN distinct label, not the section
      // subtitle text it used to fall back to (#2920 mislabel).
      final l = AppLocalizations.of(
        tester.element(find.byType(DrivingSettingsSection)),
      );
      expect(
        find.text(l.voiceAnnouncementPriceLimit),
        findsOneWidget,
        reason:
            'The price-threshold slider must show a distinct '
            '"Maximum price" label — not the duplicated section subtitle.',
      );
      expect(
        find.text(l.voiceAnnouncementsDescription),
        findsOneWidget,
        reason:
            'The section subtitle text must appear exactly once (on the '
            'enable toggle) — never duplicated onto the price slider.',
      );
    },
  );
}

/// Synthetic in-memory [FeatureFlags] notifier for widget tests.
///
/// Unlike the real notifier, this implementation:
///   - has no Hive dependency (no `pumpAndSettle` hangs on Windows);
///   - returns the seeded `initial` set synchronously from `build`;
///   - implements `enable` / `disable` as pure in-memory mutations
///     that throw [StateError] for prerequisite violations to mirror
///     the real central-provider contract the shim relies on.
class _TestFeatureFlags extends FeatureFlags {
  _TestFeatureFlags([Set<Feature>? initial])
    : _initial = initial ?? <Feature>{};

  final Set<Feature> _initial;

  @override
  Set<Feature> build() => {..._initial};

  @override
  Future<void> enable(Feature feature) async {
    final current = state.value ?? const <Feature>{};
    if (current.contains(feature)) return;
    state = AsyncData({...current, feature});
  }

  @override
  Future<void> disable(Feature feature) async {
    final current = state.value ?? const <Feature>{};
    if (!current.contains(feature)) return;
    state = AsyncData({...current}..remove(feature));
  }
}

/// In-memory [VoiceAnnouncementSettings] for widget tests.
///
/// Returns the seeded [AnnouncementConfig] from `build()` synchronously,
/// bypassing the real notifier's `SharedPreferences` `_load()` so the
/// section renders the exact config under test without platform plumbing.
class _FakeVoiceSettings extends VoiceAnnouncementSettings {
  _FakeVoiceSettings(this._config);

  final AnnouncementConfig _config;

  @override
  AnnouncementConfig build() => _config;
}

class _FakeSettingsStorage implements SettingsStorage {
  final Map<String, dynamic> data = {};

  @override
  dynamic getSetting(String key) => data[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    data[key] = value;
  }

  @override
  bool get isSetupComplete => false;
  @override
  bool get isSetupSkipped => false;
  @override
  Future<void> skipSetup() async {}
  @override
  Future<void> resetSetupSkip() async {}
}
