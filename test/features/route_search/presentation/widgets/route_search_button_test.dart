import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/route_search/presentation/widgets/route_search_button.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  Widget buildButton({
    required TextEditingController startController,
    required TextEditingController endController,
    bool isSearching = false,
    VoidCallback? onSearch,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: RouteSearchButton(
          startController: startController,
          endController: endController,
          isSearching: isSearching,
          onSearch: onSearch ?? () {},
        ),
      ),
    );
  }

  group('RouteSearchButton', () {
    late TextEditingController start;
    late TextEditingController end;

    setUp(() {
      start = TextEditingController();
      end = TextEditingController();
    });

    tearDown(() {
      start.dispose();
      end.dispose();
    });

    testWidgets('renders the localized "Search along route" label',
        (tester) async {
      await tester.pumpWidget(
        buildButton(startController: start, endController: end),
      );
      await tester.pumpAndSettle();

      expect(find.text('Search along route'), findsOneWidget);
    });

    testWidgets('is disabled when both controllers are empty', (tester) async {
      await tester.pumpWidget(
        buildButton(startController: start, endController: end),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('is disabled when only the start controller is filled',
        (tester) async {
      start.text = 'Berlin';
      await tester.pumpWidget(
        buildButton(startController: start, endController: end),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('is disabled when only the end controller is filled',
        (tester) async {
      end.text = 'Munich';
      await tester.pumpWidget(
        buildButton(startController: start, endController: end),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets(
        'is enabled when both controllers are filled and isSearching is false',
        (tester) async {
      start.text = 'Berlin';
      end.text = 'Munich';
      await tester.pumpWidget(
        buildButton(
          startController: start,
          endController: end,
          isSearching: false,
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets(
        'is disabled when both controllers are filled but isSearching is true',
        (tester) async {
      start.text = 'Berlin';
      end.text = 'Munich';
      await tester.pumpWidget(
        buildButton(
          startController: start,
          endController: end,
          isSearching: true,
        ),
      );
      // CircularProgressIndicator animates forever; use pump() not
      // pumpAndSettle().
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('renders Icons.route when isSearching is false',
        (tester) async {
      await tester.pumpWidget(
        buildButton(
          startController: start,
          endController: end,
          isSearching: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.route), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
        'renders a CircularProgressIndicator (and not Icons.route) when isSearching is true',
        (tester) async {
      await tester.pumpWidget(
        buildButton(
          startController: start,
          endController: end,
          isSearching: true,
        ),
      );
      // CircularProgressIndicator animates forever; use pump() not
      // pumpAndSettle().
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.route), findsNothing);
    });

    testWidgets('tapping the enabled button invokes onSearch', (tester) async {
      var taps = 0;
      start.text = 'Berlin';
      end.text = 'Munich';
      await tester.pumpWidget(
        buildButton(
          startController: start,
          endController: end,
          onSearch: () => taps++,
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('tapping the disabled button does not invoke onSearch',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        buildButton(
          startController: start,
          endController: end,
          onSearch: () => taps++,
        ),
      );
      await tester.pumpAndSettle();

      // Sanity-check disabled state.
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);

      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump();

      expect(taps, 0);
    });

    testWidgets(
        'flips from disabled to enabled when controller text is set after build',
        (tester) async {
      await tester.pumpWidget(
        buildButton(startController: start, endController: end),
      );
      await tester.pumpAndSettle();

      // Initially disabled.
      var button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);

      // Simulate user typing into both fields.
      start.text = 'Berlin';
      end.text = 'Munich';
      await tester.pump();

      button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });
  });
}
