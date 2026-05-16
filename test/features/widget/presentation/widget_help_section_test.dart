import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/widget/presentation/widget_help_section.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('WidgetHelpSection renders the home-screen widget help (#1806)',
      (tester) async {
    await pumpApp(tester, const WidgetHelpSection());

    final l = AppLocalizations.of(
      tester.element(find.byType(WidgetHelpSection)),
    )!;
    expect(find.text(l.widgetHelpIntro), findsOneWidget);
    expect(find.text(l.widgetHelpAdd), findsOneWidget);
    expect(find.text(l.widgetHelpTap), findsOneWidget);
    expect(find.text(l.widgetHelpConfigure), findsOneWidget);
  });
}
