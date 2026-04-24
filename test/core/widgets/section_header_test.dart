import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/section_header.dart';

void main() {
  group('SectionHeader', () {
    Future<void> pump(WidgetTester tester, Widget child) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('renders the supplied title', (tester) async {
      await pump(tester, const SectionHeader(title: 'Favorites'));
      expect(find.text('Favorites'), findsOneWidget);
    });

    testWidgets('omits the subtitle when null', (tester) async {
      await pump(tester, const SectionHeader(title: 'Favorites'));
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('renders the subtitle when provided', (tester) async {
      await pump(
        tester,
        const SectionHeader(
          title: 'Favorites',
          subtitle: 'Your saved stations',
        ),
      );
      expect(find.text('Your saved stations'), findsOneWidget);
    });

    testWidgets('renders the leading icon when provided', (tester) async {
      await pump(
        tester,
        const SectionHeader(
          title: 'Favorites',
          leadingIcon: Icons.local_gas_station,
        ),
      );
      expect(find.byIcon(Icons.local_gas_station), findsOneWidget);
    });

    testWidgets('renders a trailing widget when provided', (tester) async {
      var tapped = false;
      await pump(
        tester,
        SectionHeader(
          title: 'Favorites',
          trailing: TextButton(
            onPressed: () => tapped = true,
            child: const Text('Edit'),
          ),
        ),
      );
      expect(find.text('Edit'), findsOneWidget);
      await tester.tap(find.text('Edit'));
      expect(tapped, isTrue);
    });

    testWidgets('applies titleMedium weight 600 to the title', (tester) async {
      await pump(tester, const SectionHeader(title: 'Favorites'));
      final text = tester.widget<Text>(find.text('Favorites'));
      expect(text.style?.fontWeight, FontWeight.w600);
    });
  });
}
