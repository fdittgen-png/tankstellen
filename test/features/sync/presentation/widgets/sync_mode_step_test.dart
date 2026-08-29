// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/constants/app_constants.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/features/sync/presentation/widgets/sync_mode_step.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  group('SyncModeStep', () {
    Future<void> pumpStep(
      WidgetTester tester, {
      required ValueChanged<SyncMode> onSelectMode,
      required VoidCallback onStayOffline,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SyncModeStep(
              onSelectMode: onSelectMode,
              onStayOffline: onStayOffline,
            ),
          ),
        ),
      );
    }

    testWidgets('renders three sync mode cards + stay-offline button', (
      tester,
    ) async {
      await pumpStep(tester, onSelectMode: (_) {}, onStayOffline: () {});

      expect(find.text('Sparkilo Community'), findsOneWidget);
      expect(find.text('Private Database'), findsOneWidget);
      expect(find.text('Join a Group'), findsOneWidget);
      expect(find.text('Stay offline'), findsOneWidget);
    });

    testWidgets('tapping community card invokes onSelectMode(community)', (
      tester,
    ) async {
      SyncMode? captured;
      await pumpStep(
        tester,
        onSelectMode: (mode) => captured = mode,
        onStayOffline: () {},
      );

      await tester.tap(find.text('Sparkilo Community'));
      await tester.pump();

      expect(captured, SyncMode.community);
    });

    testWidgets('tapping private card invokes onSelectMode(private)', (
      tester,
    ) async {
      SyncMode? captured;
      await pumpStep(
        tester,
        onSelectMode: (mode) => captured = mode,
        onStayOffline: () {},
      );

      await tester.tap(find.text('Private Database'));
      await tester.pump();

      expect(captured, SyncMode.private);
    });

    testWidgets('tapping join card invokes onSelectMode(joinExisting)', (
      tester,
    ) async {
      SyncMode? captured;
      await pumpStep(
        tester,
        onSelectMode: (mode) => captured = mode,
        onStayOffline: () {},
      );

      await tester.tap(find.text('Join a Group'));
      await tester.pump();

      expect(captured, SyncMode.joinExisting);
    });

    testWidgets('tapping stay-offline invokes onStayOffline', (tester) async {
      var called = false;
      await pumpStep(
        tester,
        onSelectMode: (_) {},
        onStayOffline: () => called = true,
      );

      await tester.tap(find.text('Stay offline'));
      await tester.pump();

      expect(called, isTrue);
    });

    // #3871 (Epic #3865, GDPR) — the picker says WHO the controller is
    // under every card, the community subtitle no longer claims "share
    // favorites & ratings", and the privacy policy is one tap away.
    group('controller notices (#3871)', () {
      testWidgets('community card names the operator, the EU region and '
          'every synced data category', (tester) async {
        await pumpStep(tester, onSelectMode: (_) {}, onStayOffline: () {});

        final notice = find.byKey(
          const Key('sync_mode_community_controller_notice'),
        );
        expect(notice, findsOneWidget);
        expect(
          find.descendant(
            of: notice,
            matching: find.textContaining(AppConstants.dataControllerName),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: notice,
            matching: find.textContaining('EU (Frankfurt)'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: notice,
            matching: find.textContaining('trips with GPS'),
          ),
          findsOneWidget,
        );
      });

      testWidgets('private card says the user is the controller',
          (tester) async {
        await pumpStep(tester, onSelectMode: (_) {}, onStayOffline: () {});

        expect(
          find.descendant(
            of: find.byKey(const Key('sync_mode_private_controller_notice')),
            matching: find.textContaining('You are the controller'),
          ),
          findsOneWidget,
        );
      });

      testWidgets('join card says the database owner is the controller',
          (tester) async {
        await pumpStep(tester, onSelectMode: (_) {}, onStayOffline: () {});

        expect(
          find.descendant(
            of: find.byKey(const Key('sync_mode_join_controller_notice')),
            matching: find.textContaining('owns the shared database'),
          ),
          findsOneWidget,
        );
      });

      testWidgets('community subtitle is the accurate one, not the old '
          '"share favorites & ratings" claim', (tester) async {
        await pumpStep(tester, onSelectMode: (_) {}, onStayOffline: () {});

        expect(
          find.text('Shared database run by the developer — see what syncs '
              'below'),
          findsOneWidget,
        );
        expect(find.textContaining('Share favorites'), findsNothing);
      });

      testWidgets('a privacy-policy link is present on the step',
          (tester) async {
        await pumpStep(tester, onSelectMode: (_) {}, onStayOffline: () {});

        final link = find.byKey(const Key('sync_mode_privacy_policy_link'));
        expect(link, findsOneWidget);
        expect(
          find.descendant(of: link, matching: find.text('Privacy Policy')),
          findsOneWidget,
        );
        expect(
          tester.widget<TextButton>(link).onPressed,
          isNotNull,
          reason: 'the link must be tappable (opens privacyPolicyUrl)',
        );
      });
    });
  });
}
