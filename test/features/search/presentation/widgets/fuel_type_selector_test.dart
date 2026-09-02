// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// The mocktail Mock* storage doubles are deprecated as a steering hint
// (prefer the stateful fakes) but remain sanctioned for widget tests that
// stub reads exclusively -- see test/helpers/mock_providers.dart (#3742).
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/feature_management/domain/feature_manifest.dart';
import 'package:tankstellen/features/search/presentation/widgets/fuel_type_selector.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('FuelTypeSelector', () {
    testWidgets('renders fuel type options for Germany', (tester) async {
      final storage = mockHiveStorageOverride();
      when(() => storage.mock.getActiveProfileId()).thenReturn(null);
      when(() => storage.mock.getSetting(any())).thenReturn(null);

      await pumpApp(
        tester,
        const FuelTypeSelector(),
        overrides: [
          storage.override,
          activeCountryOverride(Countries.germany),
          selectedFuelTypeOverride(FuelType.all),
        ],
      );

      // Germany should show: E5, E10, Diesel, Electric, All
      expect(find.text('Super E5'), findsOneWidget);
      expect(find.text('Super E10'), findsOneWidget);
      expect(find.text('Diesel'), findsOneWidget);
      expect(find.text('Electric \u26a1'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
    });

    testWidgets('renders fuel type options for France', (tester) async {
      final storage = mockHiveStorageOverride();
      when(() => storage.mock.getActiveProfileId()).thenReturn(null);
      when(() => storage.mock.getSetting(any())).thenReturn(null);

      await pumpApp(
        tester,
        const FuelTypeSelector(),
        overrides: [
          storage.override,
          activeCountryOverride(Countries.france),
          selectedFuelTypeOverride(FuelType.all),
        ],
      );

      // France has more types: E10, E5, E98, Diesel, E85, LPG, Electric, All
      expect(find.text('Super E10'), findsOneWidget);
      expect(find.text('Super E5'), findsOneWidget);
      expect(find.text('Super 98'), findsOneWidget);
      expect(find.text('Diesel'), findsOneWidget);
      expect(find.text('E85 / Bio\u00e9thanol'), findsOneWidget);
      expect(find.text('GPL / LPG'), findsOneWidget);
    });

    testWidgets('current selection is highlighted via ChoiceChip', (tester) async {
      final storage = mockHiveStorageOverride();
      when(() => storage.mock.getActiveProfileId()).thenReturn(null);
      when(() => storage.mock.getSetting(any())).thenReturn(null);

      await pumpApp(
        tester,
        const FuelTypeSelector(),
        overrides: [
          storage.override,
          activeCountryOverride(Countries.germany),
          selectedFuelTypeOverride(FuelType.diesel),
        ],
      );

      // Find all ChoiceChips
      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));

      // Exactly one chip should be selected
      final selectedChips = chips.where((c) => c.selected).toList();
      expect(selectedChips, hasLength(1));

      // The selected chip should be the Diesel one
      final dieselChip = selectedChips.first;
      final label = dieselChip.label as Text;
      expect(label.data, 'Diesel');
    });

    testWidgets('#3927 — the selected fuel is ordered first so it is '
        'always visible', (tester) async {
      final storage = mockHiveStorageOverride();
      when(() => storage.mock.getActiveProfileId()).thenReturn(null);
      when(() => storage.mock.getSetting(any())).thenReturn(null);

      await pumpApp(
        tester,
        const FuelTypeSelector(),
        overrides: [
          storage.override,
          activeCountryOverride(Countries.france),
          // E85 sits near the END of the French fuel list — the report
          // that started #3925 was "I cannot see that E85 is selected".
          selectedFuelTypeOverride(FuelType.e85),
        ],
      );

      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
      expect((chips.first.label as Text).data, 'E85 / Bioéthanol');
      expect(chips.first.selected, isTrue);
      // Its chip is laid out on screen, not clipped past an edge.
      final chipFinder = find.byKey(
        const ValueKey('criteria-fuel-e85'),
      );
      expect(chipFinder, findsOneWidget);
      expect(
        tester.getTopLeft(chipFinder).dx,
        lessThan(tester.view.physicalSize.width / tester.view.devicePixelRatio),
      );
    });

    testWidgets('tapping a fuel type chip triggers selection', (tester) async {
      final storage = mockHiveStorageOverride();
      when(() => storage.mock.getActiveProfileId()).thenReturn(null);
      when(() => storage.mock.getSetting(any())).thenReturn(null);

      await pumpApp(
        tester,
        const FuelTypeSelector(),
        overrides: [
          storage.override,
          activeCountryOverride(Countries.germany),
          selectedFuelTypeOverride(FuelType.all),
        ],
      );

      // Initially 'All' is selected
      final allChipBefore = tester.widgetList<ChoiceChip>(
        find.byType(ChoiceChip),
      ).firstWhere((c) => (c.label as Text).data == 'All');
      expect(allChipBefore.selected, isTrue);

      // Tap on E10 chip
      await tester.tap(find.text('Super E10'));
      await tester.pumpAndSettle();

      // After tapping, E10 should now be selected
      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
      final e10Chip = chips.firstWhere((c) => (c.label as Text).data == 'Super E10');
      expect(e10Chip.selected, isTrue);
    });

    testWidgets(
        '#2974 — tapping a fuel chip fires a selectionClick haptic, '
        'a scroll does NOT', (tester) async {
      final storage = mockHiveStorageOverride();
      when(() => storage.mock.getActiveProfileId()).thenReturn(null);
      when(() => storage.mock.getSetting(any())).thenReturn(null);

      final haptics = <String?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments as String?);
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await pumpApp(
        tester,
        const FuelTypeSelector(),
        overrides: [
          storage.override,
          activeCountryOverride(Countries.germany),
          selectedFuelTypeOverride(FuelType.all),
        ],
      );

      // #3927 — the strip wraps instead of scrolling; a drag across it
      // must still never buzz.
      await tester.drag(find.byType(Wrap).first, const Offset(-80, 0));
      await tester.pumpAndSettle();
      expect(haptics, isEmpty, reason: 'a drag must never fire a haptic');

      // A discrete chip tap fires exactly one selectionClick.
      await tester.tap(find.text('Super E10'));
      await tester.pumpAndSettle();
      expect(haptics, ['HapticFeedbackType.selectionClick']);
    });

    // #3927 (Epic #3925) — the promise the wrap layout replaced the
    // horizontal scroller for: whichever fuel is selected is ON SCREEN
    // without any scrolling. The old strip could park the selection off
    // the right edge (E85 selected, France), so the user could not see
    // their own choice. Replaces the three golden images this widget
    // used to carry: they pinned pixels of the scroller that no longer
    // exists, and locally regenerated goldens fail Linux CI anyway.
    testWidgets('the selected fuel is visible without scrolling (#3927)',
        (tester) async {
      final storage = mockHiveStorageOverride();
      when(() => storage.mock.getActiveProfileId()).thenReturn(null);
      when(() => storage.mock.getSetting(any())).thenReturn(null);

      await pumpApp(
        tester,
        const FuelTypeSelector(),
        overrides: [
          storage.override,
          activeCountryOverride(Countries.france),
          selectedFuelTypeOverride(FuelType.e85),
        ],
      );

      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
      final selected = chips.where((c) => c.selected).toList();
      expect(selected, hasLength(1), reason: 'exactly one fuel is selected');

      // The selected chip's rect must lie inside the viewport: no part of
      // it may sit beyond the right edge the way the scroller allowed.
      final selectedFinder = find.byWidgetPredicate(
        (w) => w is ChoiceChip && w.selected,
      );
      final rect = tester.getRect(selectedFinder);
      final view = tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(view.width));
    });

    testWidgets('has correct semantics labels', (tester) async {
      final storage = mockHiveStorageOverride();
      when(() => storage.mock.getActiveProfileId()).thenReturn(null);
      when(() => storage.mock.getSetting(any())).thenReturn(null);

      await pumpApp(
        tester,
        const FuelTypeSelector(),
        overrides: [
          storage.override,
          activeCountryOverride(Countries.germany),
          selectedFuelTypeOverride(FuelType.diesel),
        ],
      );

      // The selected fuel type should have ", selected" in its semantics
      expect(
        find.bySemanticsLabel(RegExp(r'Fuel type Diesel, selected')),
        findsOneWidget,
      );
    });

    testWidgets(
        'dead-code finding 6 — hides the Electric chip (and All, since '
        'fuel-only) when Feature.evCharging is disabled', (tester) async {
      final storage = mockHiveStorageOverride();
      when(() => storage.mock.getActiveProfileId()).thenReturn(null);
      when(() => storage.mock.getSetting(any())).thenReturn(null);

      await pumpApp(
        tester,
        const FuelTypeSelector(),
        overrides: [
          storage.override,
          activeCountryOverride(Countries.germany),
          selectedFuelTypeOverride(FuelType.e5),
          featureFlagsProvider.overrideWith(
            () => _FlagsWithout({Feature.evCharging}),
          ),
        ],
      );

      // Same shape as showElectric=false: no EV chip, no 'All'.
      expect(find.text('Electric ⚡'), findsNothing);
      expect(find.text('All'), findsNothing);
      expect(find.text('Super E5'), findsOneWidget);
      expect(find.text('Diesel'), findsOneWidget);
    });
  });
}

/// A [FeatureFlags] notifier whose enabled set is the manifest default
/// minus [_disabled] — the same test double the #1638 gate tests use.
class _FlagsWithout extends FeatureFlags {
  _FlagsWithout(this._disabled);

  final Set<Feature> _disabled;

  @override
  Set<Feature> build() =>
      FeatureManifest.defaultManifest.defaultEnabledSet().difference(_disabled);
}
