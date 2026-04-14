import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/language/language_provider.dart';
import 'package:tankstellen/features/setup/presentation/widgets/language_selector.dart';

void main() {
  group('LanguageSelector', () {
    Future<void> pumpSelector(
      WidgetTester tester, {
      required AppLanguage selected,
      required ValueChanged<AppLanguage> onSelect,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LanguageSelector(
                selected: selected,
                onSelect: onSelect,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders one ChoiceChip per supported language',
        (tester) async {
      await pumpSelector(
        tester,
        selected: AppLanguages.all.first,
        onSelect: (_) {},
      );
      expect(
        find.byType(ChoiceChip),
        findsNWidgets(AppLanguages.all.length),
      );
    });

    testWidgets('marks the chip matching `selected` as selected',
        (tester) async {
      final german =
          AppLanguages.all.firstWhere((l) => l.code == 'de');
      await pumpSelector(
        tester,
        selected: german,
        onSelect: (_) {},
      );
      final selectedChip = tester.widget<ChoiceChip>(
        find.ancestor(
          of: find.text(german.nativeName),
          matching: find.byType(ChoiceChip),
        ),
      );
      expect(selectedChip.selected, isTrue);
    });

    testWidgets('forwards taps to onSelect with the chosen language',
        (tester) async {
      AppLanguage? captured;
      final french =
          AppLanguages.all.firstWhere((l) => l.code == 'fr');
      await pumpSelector(
        tester,
        selected: AppLanguages.all.first,
        onSelect: (lang) => captured = lang,
      );
      // Scroll the French chip into view in case the wrap row pushes it down.
      await tester.ensureVisible(find.text(french.nativeName));
      await tester.pumpAndSettle();
      await tester.tap(find.text(french.nativeName));
      expect(captured?.code, 'fr');
    });

    testWidgets(
        'announces selected state via the Semantics label so screen '
        'readers know which language is active', (tester) async {
      final english =
          AppLanguages.all.firstWhere((l) => l.code == 'en');
      await pumpSelector(
        tester,
        selected: english,
        onSelect: (_) {},
      );
      expect(
        find.bySemanticsLabel(
          RegExp('Language ${english.nativeName}, selected'),
        ),
        findsAtLeast(1),
      );
    });
  });
}
