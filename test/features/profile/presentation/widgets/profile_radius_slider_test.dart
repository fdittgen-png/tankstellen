import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/profile/presentation/widgets/profile_radius_slider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  group('ProfileRadiusSlider', () {
    Future<void> pumpSlider(
      WidgetTester tester, {
      required double value,
      ValueChanged<double>? onChanged,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ProfileRadiusSlider(
              value: value,
              onChanged: onChanged ?? (_) {},
            ),
          ),
        ),
      );
    }

    testWidgets('renders the trailing readout matching the value rounded to '
        'the nearest km', (tester) async {
      await pumpSlider(tester, value: 12.4);
      expect(find.text('12 km'), findsOneWidget);
    });

    testWidgets('exposes the slider with the correct min/max/divisions',
        (tester) async {
      await pumpSlider(tester, value: 5);
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, 1);
      expect(slider.max, 25);
      expect(slider.divisions, 24);
      expect(slider.value, 5);
    });

    testWidgets('forwards drag changes to onChanged', (tester) async {
      double? captured;
      await pumpSlider(
        tester,
        value: 5,
        onChanged: (v) => captured = v,
      );
      // Drag the thumb to the far right end of the slider.
      await tester.drag(find.byType(Slider), const Offset(500, 0));
      await tester.pump();
      expect(captured, isNotNull);
      expect(captured, greaterThan(5));
    });

    testWidgets('renders the leading localized "Default radius:" label',
        (tester) async {
      await pumpSlider(tester, value: 1);
      // The English ARB resolves `defaultRadius` to "Default radius".
      expect(find.text('Default radius:'), findsOneWidget);
      expect(find.text('1 km'), findsOneWidget);
    });
  });
}
