import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/report/presentation/widgets/no_backend_banner.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('NoBackendBanner', () {
    testWidgets('renders the error icon and warning text',
        (tester) async {
      await pumpApp(tester, const NoBackendBanner());

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.textContaining('signalements'), findsOneWidget);
      expect(
        find.textContaining('TankSync'),
        findsOneWidget,
      );
    });

    testWidgets('carries the valueKey used by the report screen tests',
        (tester) async {
      // report_screen.dart conditionally mounts this banner and the
      // screen test locates it by this key — pin the contract here
      // so a refactor can't silently change it.
      await pumpApp(tester, const NoBackendBanner());
      expect(find.byKey(const ValueKey('report-no-backend-banner')),
          findsOneWidget);
    });

    testWidgets('uses the error-container colour scheme for alarm cue',
        (tester) async {
      await pumpApp(tester, const NoBackendBanner());

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(8));
      // Background colour comes from Theme.errorContainer — just
      // assert it's set to something non-default.
      expect(decoration.color, isNotNull);
    });
  });
}
