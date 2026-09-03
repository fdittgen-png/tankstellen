// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// The bubble only ever READS the settings box (a shown flag and an int
// position), so the sanctioned stub-reads-only mock is the right double
// here — see test/helpers/mock_providers.dart (#3742).
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/widgets/help/help_tips.dart';
import 'package:tankstellen/core/widgets/help_banner.dart';

import '../../helpers/mock_providers.dart';
import '../../mocks/mocks.dart';
import '../../helpers/pump_app.dart';

void main() {
  group('HelpBanner', () {
    testWidgets('shows banner on first open', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.getSetting(any())).thenReturn(null);
      when(
        () => test.mockStorage.putSetting(any(), any<dynamic>()),
      ).thenAnswer((_) async {});

      await pumpApp(
        tester,
        const HelpBanner(
          storageKey: 'test_banner',
          icon: Icons.info,
          message: 'Test help message',
        ),
        overrides: test.overrides,
      );

      expect(find.text('Test help message'), findsOneWidget);
    });

    testWidgets('does not show banner when already dismissed', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.getSetting(any())).thenReturn(null);
      when(() => test.mockStorage.getSetting('test_banner')).thenReturn(true);

      await pumpApp(
        tester,
        const HelpBanner(
          storageKey: 'test_banner',
          icon: Icons.info,
          message: 'Test help message',
        ),
        overrides: test.overrides,
      );

      expect(find.text('Test help message'), findsNothing);
    });

    testWidgets('dismissing banner stores the flag', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.getSetting(any())).thenReturn(null);
      when(
        () => test.mockStorage.putSetting(any(), any<dynamic>()),
      ).thenAnswer((_) async {});

      await pumpApp(
        tester,
        const HelpBanner(
          storageKey: 'test_banner',
          icon: Icons.info,
          message: 'Test help message',
        ),
        overrides: test.overrides,
      );

      // Tap "Got it" button
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      verify(() => test.mockStorage.putSetting('test_banner', true)).called(1);
      expect(find.text('Test help message'), findsNothing);
    });

    testWidgets('shows correct icon', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.getSetting(any())).thenReturn(null);

      await pumpApp(
        tester,
        const HelpBanner(
          storageKey: 'test_banner',
          icon: Icons.lightbulb_outline,
          message: 'Test',
        ),
        overrides: test.overrides,
      );

      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    });

    // ── #3938 — a one-message surface must stay EXACTLY what it was ──
    testWidgets('a single-message surface renders no chevrons and no '
        'indicator (#3938)', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.getSetting(any())).thenReturn(null);

      await pumpApp(
        tester,
        const HelpBanner(
          storageKey: 'test_banner',
          icon: Icons.info,
          message: 'Only one thing to say',
        ),
        overrides: test.overrides,
      );

      expect(find.text('Only one thing to say'), findsOneWidget);
      expect(find.byIcon(Icons.navigate_before), findsNothing);
      expect(find.byIcon(Icons.navigate_next), findsNothing);
      expect(
        find.byKey(const ValueKey('help-bubble-position-test_banner')),
        findsNothing,
      );
      // …and it never writes a position it will never read.
      verifyNever(
        () => test.mockStorage.putSetting(
          'test_banner_position',
          any<dynamic>(),
        ),
      );
    });
  });

  group('HelpBanner — the paged bubble (#3938)', () {
    const key = StorageKeys.helpBannerSearchResults;
    const bubble = HelpBanner(
      storageKey: key,
      icon: Icons.lightbulb_outline,
      surface: HelpSurface.searchResults,
    );

    ({List<Object> overrides, MockStorageRepository mock}) seeded({
      int? storedPosition,
    }) {
      final test = standardTestOverrides();
      when(() => test.mockStorage.getSetting(any())).thenReturn(null);
      when(
        () => test.mockStorage.getSetting(
          StorageKeys.helpBannerSearchResultsPosition,
        ),
      ).thenReturn(storedPosition);
      when(
        () => test.mockStorage.putSetting(any(), any<dynamic>()),
      ).thenAnswer((_) async {});
      return (overrides: test.overrides, mock: test.mockStorage);
    }

    testWidgets('a catalogued surface pages with chevrons and an n/N '
        'indicator', (tester) async {
      final seed = seeded();
      await pumpApp(tester, bubble, overrides: seed.overrides);

      expect(find.byIcon(Icons.navigate_before), findsOneWidget);
      expect(find.byIcon(Icons.navigate_next), findsOneWidget);

      final indicator = tester.widget<Text>(
        find.byKey(const ValueKey('help-bubble-position-$key')),
      );
      // A never-visited surface opens on tip 1 of N.
      expect(indicator.data, startsWith('1/'));
      final total = int.parse(indicator.data!.split('/').last);
      expect(total, greaterThanOrEqualTo(3));
      expect(total, lessThanOrEqualTo(5));
    });

    testWidgets('next advances the indicator and wraps at the end', (
      tester,
    ) async {
      final seed = seeded();
      await pumpApp(tester, bubble, overrides: seed.overrides);

      String position() => tester
          .widget<Text>(find.byKey(const ValueKey('help-bubble-position-$key')))
          .data!;

      final total = int.parse(position().split('/').last);
      expect(position(), '1/$total');

      for (var i = 2; i <= total; i++) {
        await tester.tap(find.byKey(const ValueKey('help-bubble-next-$key')));
        await tester.pumpAndSettle();
        expect(position(), '$i/$total');
      }

      // One more wraps back to the first tip.
      await tester.tap(find.byKey(const ValueKey('help-bubble-next-$key')));
      await tester.pumpAndSettle();
      expect(position(), '1/$total');
    });

    testWidgets('previous wraps backwards from the first tip to the last', (
      tester,
    ) async {
      final seed = seeded();
      await pumpApp(tester, bubble, overrides: seed.overrides);

      String position() => tester
          .widget<Text>(find.byKey(const ValueKey('help-bubble-position-$key')))
          .data!;

      final total = int.parse(position().split('/').last);
      await tester.tap(find.byKey(const ValueKey('help-bubble-prev-$key')));
      await tester.pumpAndSettle();
      expect(position(), '$total/$total');
    });

    testWidgets('a horizontal swipe pages, in both directions', (tester) async {
      final seed = seeded();
      await pumpApp(tester, bubble, overrides: seed.overrides);

      String position() => tester
          .widget<Text>(find.byKey(const ValueKey('help-bubble-position-$key')))
          .data!;

      final total = int.parse(position().split('/').last);
      final pager = find.byKey(const ValueKey('help-bubble-pager-$key'));

      // Swiping left reveals the NEXT tip …
      await tester.drag(pager, const Offset(-120, 0));
      await tester.pumpAndSettle();
      expect(position(), '2/$total');

      // … and swiping right goes back.
      await tester.drag(pager, const Offset(120, 0));
      await tester.pumpAndSettle();
      expect(position(), '1/$total');
    });

    testWidgets('a drag shorter than the swipe threshold does NOT page', (
      tester,
    ) async {
      final seed = seeded();
      await pumpApp(tester, bubble, overrides: seed.overrides);

      final pager = find.byKey(const ValueKey('help-bubble-pager-$key'));
      await tester.drag(pager, const Offset(-20, 0));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('help-bubble-position-$key')),
            )
            .data,
        startsWith('1/'),
      );
    });

    testWidgets('the tip on screen changes with the page', (tester) async {
      final seed = seeded();
      await pumpApp(tester, bubble, overrides: seed.overrides);

      final first = tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(const ValueKey('help-bubble-tip-$key-0')),
              matching: find.byType(Text),
            ),
          )
          .data;
      expect(first, isNotEmpty);

      await tester.tap(find.byKey(const ValueKey('help-bubble-next-$key')));
      await tester.pumpAndSettle();

      final second = tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(const ValueKey('help-bubble-tip-$key-1')),
              matching: find.byType(Text),
            ),
          )
          .data;
      expect(second, isNot(first));
    });

    testWidgets('a fresh visit opens on the tip AFTER the stored one', (
      tester,
    ) async {
      // Last visit ended on tip index 1 → this visit opens on index 2.
      final seed = seeded(storedPosition: 1);
      await pumpApp(tester, bubble, overrides: seed.overrides);

      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('help-bubble-position-$key')),
            )
            .data,
        startsWith('3/'),
      );
    });

    testWidgets('the stored position wraps when it points past the end', (
      tester,
    ) async {
      // A device that stored an index from a longer tip list.
      final seed = seeded(storedPosition: 99);
      await pumpApp(tester, bubble, overrides: seed.overrides);

      final data = tester
          .widget<Text>(find.byKey(const ValueKey('help-bubble-position-$key')))
          .data!;
      final total = int.parse(data.split('/').last);
      final index = int.parse(data.split('/').first);
      expect(index, inInclusiveRange(1, total));
    });

    testWidgets('paging persists the new position for the next visit', (
      tester,
    ) async {
      final seed = seeded();
      await pumpApp(tester, bubble, overrides: seed.overrides);

      await tester.tap(find.byKey(const ValueKey('help-bubble-next-$key')));
      await tester.pumpAndSettle();

      verify(
        () => seed.mock.putSetting(
          StorageKeys.helpBannerSearchResultsPosition,
          1,
        ),
      ).called(1);
    });

    testWidgets('dismissal persists per surface and hides the bubble', (
      tester,
    ) async {
      final seed = seeded();
      await pumpApp(tester, bubble, overrides: seed.overrides);

      expect(find.byIcon(Icons.navigate_next), findsOneWidget);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      verify(() => seed.mock.putSetting(key, true)).called(1);
      expect(find.byIcon(Icons.navigate_next), findsNothing);
    });

    testWidgets('a dismissed surface never renders again', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.getSetting(any())).thenReturn(null);
      when(() => test.mockStorage.getSetting(key)).thenReturn(true);

      await pumpApp(tester, bubble, overrides: test.overrides);

      expect(find.byIcon(Icons.navigate_next), findsNothing);
      expect(find.text('Got it'), findsNothing);
    });

    testWidgets('the chevrons carry a tooltip AND a screen-reader label, and '
        'meet the 48 dp tap target', (tester) async {
      final handle = tester.ensureSemantics();
      final seed = seeded();
      await pumpApp(tester, bubble, overrides: seed.overrides);

      expect(find.byTooltip('Previous tip'), findsOneWidget);
      expect(find.byTooltip('Next tip'), findsOneWidget);
      expect(find.bySemanticsLabel('Previous tip'), findsOneWidget);
      expect(find.bySemanticsLabel('Next tip'), findsOneWidget);

      // The compact "1/5" mask is read out as a full sentence.
      expect(find.bySemanticsLabel(RegExp(r'^Tip 1 of \d+$')), findsOneWidget);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('no inner Scrollable — an extra one breaks scrollUntilVisible',
        (tester) async {
      final seed = seeded();
      await pumpApp(tester, bubble, overrides: seed.overrides);

      expect(find.byType(PageView), findsNothing);
      expect(find.byType(Scrollable), findsNothing);
    });
  });

  group('initialTipIndex', () {
    test('a never-visited surface opens on the first tip', () {
      expect(initialTipIndex(null, 5), 0);
    });

    test('a visited surface opens on the tip AFTER the stored one', () {
      expect(initialTipIndex(0, 5), 1);
      expect(initialTipIndex(3, 5), 4);
    });

    test('it wraps at the end so every visit keeps rotating', () {
      expect(initialTipIndex(4, 5), 0);
    });

    test('a stored index from a longer list is taken modulo the catalog', () {
      expect(initialTipIndex(99, 5), 0);
    });

    test('an empty catalog is index 0, never a crash', () {
      expect(initialTipIndex(3, 0), 0);
    });
  });
}
