import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/page_scaffold.dart';
import 'package:tankstellen/features/sync/presentation/screens/link_device_screen.dart';
import 'package:tankstellen/features/sync/presentation/widgets/link_device_how_it_works_card.dart';
import 'package:tankstellen/features/sync/presentation/widgets/link_device_import_card.dart';
import 'package:tankstellen/features/sync/presentation/widgets/link_device_this_device_card.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('LinkDeviceScreen', () {
    testWidgets('renders PageScaffold with the localized title',
        (tester) async {
      await pumpApp(tester, const LinkDeviceScreen());

      expect(find.byType(PageScaffold), findsOneWidget);
      expect(find.text('Link Device'), findsOneWidget);
    });

    testWidgets('PageScaffold uses zero body padding for full-bleed ListView',
        (tester) async {
      await pumpApp(tester, const LinkDeviceScreen());

      final scaffold = tester.widget<PageScaffold>(find.byType(PageScaffold));
      expect(scaffold.bodyPadding, EdgeInsets.zero);
    });

    testWidgets('renders the three child cards in a ListView', (tester) async {
      await pumpApp(tester, const LinkDeviceScreen());

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(LinkDeviceThisDeviceCard), findsOneWidget);
      expect(find.byType(LinkDeviceImportCard), findsOneWidget);
      expect(find.byType(LinkDeviceHowItWorksCard), findsOneWidget);
    });

    testWidgets(
        'LinkDeviceThisDeviceCard receives myId=null when no Supabase session',
        (tester) async {
      // TankSyncClient.client is a static singleton that returns null when
      // [init] has not been called — which is the case in widget tests.
      // The screen reads `client?.auth.currentUser?.id` which therefore
      // resolves to null.
      await pumpApp(tester, const LinkDeviceScreen());

      final card = tester.widget<LinkDeviceThisDeviceCard>(
        find.byType(LinkDeviceThisDeviceCard),
      );
      expect(card.myId, isNull);
    });

    testWidgets('LinkDeviceImportCard receives a non-null TextEditingController',
        (tester) async {
      await pumpApp(tester, const LinkDeviceScreen());

      final card = tester.widget<LinkDeviceImportCard>(
        find.byType(LinkDeviceImportCard),
      );
      // ignore: unnecessary_null_comparison
      expect(card.codeController, isNotNull);
      expect(card.codeController, isA<TextEditingController>());
    });

    testWidgets('disposing the screen does not throw', (tester) async {
      await pumpApp(tester, const LinkDeviceScreen());

      // Replace the LinkDeviceScreen with an empty widget — this causes
      // _LinkDeviceScreenState.dispose() to run, which in turn disposes the
      // internally-owned TextEditingController. A double-dispose or missing
      // dispose would surface as a Flutter test failure here.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      expect(find.byType(LinkDeviceScreen), findsNothing);
    });
  });
}
