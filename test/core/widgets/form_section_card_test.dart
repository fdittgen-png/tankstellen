import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/form_section_card.dart';

void main() {
  Future<void> pumpWithTheme(
    WidgetTester tester,
    Widget child, {
    ThemeData? theme,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(body: child),
      ),
    );
  }

  group('FormSectionCard', () {
    testWidgets('renders the title and all children', (tester) async {
      await pumpWithTheme(
        tester,
        const FormSectionCard(
          title: 'What you filled',
          children: [
            Text('First row'),
            Text('Second row'),
            Text('Third row'),
          ],
        ),
      );

      expect(find.text('What you filled'), findsOneWidget);
      expect(find.text('First row'), findsOneWidget);
      expect(find.text('Second row'), findsOneWidget);
      expect(find.text('Third row'), findsOneWidget);
    });

    testWidgets('omits the subtitle text when subtitle is null',
        (tester) async {
      await pumpWithTheme(
        tester,
        const FormSectionCard(
          title: 'Title only',
          children: [Text('Body')],
        ),
      );

      // Only the title should be visible — no extra body-small text node.
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .toList();
      expect(texts, contains('Title only'));
      expect(texts, contains('Body'));
      expect(texts.length, 2);
    });

    testWidgets('renders the subtitle text when provided', (tester) async {
      await pumpWithTheme(
        tester,
        const FormSectionCard(
          title: 'Title',
          subtitle: 'Helpful sub-text',
          children: [Text('Body')],
        ),
      );

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Helpful sub-text'), findsOneWidget);
    });

    testWidgets('does not render a leading icon tile when icon is null',
        (tester) async {
      await pumpWithTheme(
        tester,
        const FormSectionCard(
          title: 'No icon',
          children: [Text('Body')],
        ),
      );

      // No Icon should exist anywhere because there is no FormFieldTile icon
      // either.
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('renders a leading icon tile when icon is provided',
        (tester) async {
      await pumpWithTheme(
        tester,
        const FormSectionCard(
          title: 'With icon',
          icon: Icons.local_gas_station,
          children: [Text('Body')],
        ),
      );

      expect(find.byIcon(Icons.local_gas_station), findsOneWidget);
    });

    testWidgets('uses theme.colorScheme.primary for the header icon when '
        'accent is null', (tester) async {
      final theme = ThemeData.from(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      );

      await pumpWithTheme(
        tester,
        const FormSectionCard(
          title: 'Themed',
          icon: Icons.bolt,
          children: [Text('Body')],
        ),
        theme: theme,
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.bolt));
      expect(icon.color, theme.colorScheme.primary);
    });

    testWidgets('uses the explicit accent color for the header icon',
        (tester) async {
      const accent = Color(0xFFFF1744);

      await pumpWithTheme(
        tester,
        const FormSectionCard(
          title: 'Branded',
          icon: Icons.directions_car,
          accent: accent,
          children: [Text('Body')],
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.directions_car));
      expect(icon.color, accent);
    });

    testWidgets('renders children in their declared order beneath the header',
        (tester) async {
      await pumpWithTheme(
        tester,
        const FormSectionCard(
          title: 'Section',
          children: [
            Text('A'),
            Text('B'),
            Text('C'),
          ],
        ),
      );

      final aPos = tester.getTopLeft(find.text('A')).dy;
      final bPos = tester.getTopLeft(find.text('B')).dy;
      final cPos = tester.getTopLeft(find.text('C')).dy;
      final titlePos = tester.getTopLeft(find.text('Section')).dy;

      expect(titlePos, lessThan(aPos));
      expect(aPos, lessThan(bPos));
      expect(bPos, lessThan(cPos));
    });

    testWidgets('header is wrapped in ExcludeSemantics', (tester) async {
      await pumpWithTheme(
        tester,
        const FormSectionCard(
          title: 'Decorative header',
          subtitle: 'Sub',
          icon: Icons.info_outline,
          children: [Text('Body')],
        ),
      );

      // The decorative header lives behind ExcludeSemantics.
      final excludeSemantics = find.descendant(
        of: find.byType(FormSectionCard),
        matching: find.byType(ExcludeSemantics),
      );
      expect(excludeSemantics, findsWidgets);
    });

    testWidgets('uses surfaceContainerLow as background', (tester) async {
      late ThemeData capturedTheme;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedTheme = Theme.of(context);
              return const Scaffold(
                body: FormSectionCard(
                  title: 'Bg check',
                  children: [Text('Body')],
                ),
              );
            },
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.color, capturedTheme.colorScheme.surfaceContainerLow);
      expect(card.elevation, 0);
      expect(card.margin, EdgeInsets.zero);
    });
  });

  group('FormFieldTile', () {
    testWidgets('renders the content widget', (tester) async {
      await pumpWithTheme(
        tester,
        const FormFieldTile(
          content: Text('Field content'),
        ),
      );

      expect(find.text('Field content'), findsOneWidget);
    });

    testWidgets('omits the leading icon when icon is null', (tester) async {
      await pumpWithTheme(
        tester,
        const FormFieldTile(
          content: Text('Field'),
        ),
      );

      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('renders the leading icon when provided', (tester) async {
      await pumpWithTheme(
        tester,
        const FormFieldTile(
          icon: Icons.numbers,
          content: Text('Field'),
        ),
      );

      expect(find.byIcon(Icons.numbers), findsOneWidget);
    });

    testWidgets('uses theme.colorScheme.primary when no color is provided',
        (tester) async {
      final theme = ThemeData.from(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      );

      await pumpWithTheme(
        tester,
        const FormFieldTile(
          icon: Icons.calendar_today,
          content: Text('Field'),
        ),
        theme: theme,
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.calendar_today));
      expect(icon.color, theme.colorScheme.primary);
    });

    testWidgets('uses the explicit color override for the icon',
        (tester) async {
      const tileColor = Color(0xFF00BFA5);

      await pumpWithTheme(
        tester,
        const FormFieldTile(
          icon: Icons.directions_car,
          color: tileColor,
          content: Text('Field'),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.directions_car));
      expect(icon.color, tileColor);
    });

    testWidgets('wraps the leading icon tile in ExcludeSemantics',
        (tester) async {
      await pumpWithTheme(
        tester,
        const FormFieldTile(
          icon: Icons.info_outline,
          content: Text('Field'),
        ),
      );

      // The decorative tile must be hidden from screen readers; the field
      // label below is the announced node.
      final excludeSemantics = find.ancestor(
        of: find.byIcon(Icons.info_outline),
        matching: find.byType(ExcludeSemantics),
      );
      expect(excludeSemantics, findsWidgets);
    });
  });

  group('FormSectionCard + FormFieldTile integration', () {
    testWidgets('renders header icon and field icons with distinct colors',
        (tester) async {
      const headerAccent = Color(0xFFFF5722);
      const fieldColor = Color(0xFF3F51B5);

      await pumpWithTheme(
        tester,
        const FormSectionCard(
          title: 'Mixed',
          icon: Icons.local_gas_station,
          accent: headerAccent,
          children: [
            FormFieldTile(
              icon: Icons.attach_money,
              color: fieldColor,
              content: Text('Price'),
            ),
          ],
        ),
      );

      final headerIcon =
          tester.widget<Icon>(find.byIcon(Icons.local_gas_station));
      final fieldIcon = tester.widget<Icon>(find.byIcon(Icons.attach_money));

      expect(headerIcon.color, headerAccent);
      expect(fieldIcon.color, fieldColor);
      expect(find.text('Price'), findsOneWidget);
    });

    testWidgets('passes Android tap-target guideline when content is tappable',
        (tester) async {
      final handle = tester.ensureSemantics();

      await pumpWithTheme(
        tester,
        FormSectionCard(
          title: 'Tappable',
          children: [
            FormFieldTile(
              icon: Icons.edit,
              content: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Edit'),
                ),
              ),
            ),
          ],
        ),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  });
}
