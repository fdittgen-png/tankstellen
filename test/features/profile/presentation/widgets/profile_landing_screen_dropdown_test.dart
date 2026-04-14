import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/profile/domain/entities/user_profile.dart';
import 'package:tankstellen/features/profile/presentation/widgets/profile_landing_screen_dropdown.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  group('ProfileLandingScreenDropdown', () {
    Future<void> pumpDropdown(
      WidgetTester tester, {
      required LandingScreen value,
      ValueChanged<LandingScreen>? onChanged,
      Locale locale = const Locale('en'),
    }) {
      return tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ProfileLandingScreenDropdown(
              value: value,
              onChanged: onChanged ?? (_) {},
            ),
          ),
        ),
      );
    }

    testWidgets('renders the localized English label for the selected option',
        (tester) async {
      await pumpDropdown(tester, value: LandingScreen.nearest);
      expect(find.text('Nearest stations'), findsOneWidget);
    });

    testWidgets('renders the localized German label when locale is de',
        (tester) async {
      await pumpDropdown(
        tester,
        value: LandingScreen.cheapest,
        locale: const Locale('de'),
      );
      expect(find.text('Günstigste'), findsOneWidget);
    });

    testWidgets(
        'opening the menu shows every LandingScreen option except `map`',
        (tester) async {
      await pumpDropdown(tester, value: LandingScreen.nearest);
      await tester.tap(find.byType(DropdownButtonFormField<LandingScreen>));
      await tester.pumpAndSettle();

      // 4 enum values - 1 (map filtered out) = 3 items in the menu, plus 1
      // for the field display => 4 occurrences of "Nearest stations" once
      // selected. We just check map's English label is absent.
      expect(find.text('Map'), findsNothing);
      expect(find.text('Favorites'), findsAtLeast(1));
      expect(find.text('Cheapest nearby'), findsAtLeast(1));
      expect(find.text('Nearest stations'), findsAtLeast(1));
    });

    testWidgets('forwards selection to onChanged when user picks a new option',
        (tester) async {
      LandingScreen? captured;
      await pumpDropdown(
        tester,
        value: LandingScreen.nearest,
        onChanged: (v) => captured = v,
      );
      await tester.tap(find.byType(DropdownButtonFormField<LandingScreen>));
      await tester.pumpAndSettle();
      // Tap the menu entry for "Cheapest nearby" — there are two entries
      // showing this label inside the open menu (the one in the field and
      // the menu item); .last is the menu item.
      await tester.tap(find.text('Cheapest nearby').last);
      await tester.pumpAndSettle();
      expect(captured, LandingScreen.cheapest);
    });
  });
}
