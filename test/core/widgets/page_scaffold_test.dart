import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/page_scaffold.dart';

void main() {
  group('PageScaffold', () {
    Future<void> pump(WidgetTester tester, Widget page) {
      return tester.pumpWidget(MaterialApp(home: page));
    }

    testWidgets('renders the title inside the app bar', (tester) async {
      await pump(
        tester,
        const PageScaffold(
          title: 'Privacy',
          body: Text('Body content'),
        ),
      );
      expect(find.text('Privacy'), findsOneWidget);
      expect(find.text('Body content'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('renders the body', (tester) async {
      await pump(
        tester,
        const PageScaffold(
          title: 'Privacy',
          body: Text('Body content'),
        ),
      );
      expect(find.text('Body content'), findsOneWidget);
    });

    testWidgets('renders no banner when bannerIcon is null', (tester) async {
      await pump(
        tester,
        const PageScaffold(
          title: 'Privacy',
          body: SizedBox.shrink(),
        ),
      );
      // No icon in the body tree aside from whatever the app bar puts there.
      expect(find.byIcon(Icons.dark_mode), findsNothing);
    });

    testWidgets('renders a banner with icon + subtitle when bannerIcon is set',
        (tester) async {
      await pump(
        tester,
        const PageScaffold(
          title: 'Dark mode',
          subtitle: 'Pick how the app follows your device theme',
          bannerIcon: Icons.dark_mode,
          body: SizedBox.shrink(),
        ),
      );
      expect(find.byIcon(Icons.dark_mode), findsOneWidget);
      expect(
        find.text('Pick how the app follows your device theme'),
        findsOneWidget,
      );
      // The title appears both in the app bar and in the banner.
      expect(find.text('Dark mode'), findsNWidgets(2));
    });

    testWidgets('forwards actions to the app bar', (tester) async {
      var tapped = false;
      await pump(
        tester,
        PageScaffold(
          title: 'Privacy',
          actions: [
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: () => tapped = true,
            ),
          ],
          body: const SizedBox.shrink(),
        ),
      );
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      await tester.tap(find.byIcon(Icons.refresh));
      expect(tapped, isTrue);
    });

    testWidgets('forwards the FAB to the scaffold', (tester) async {
      await pump(
        tester,
        PageScaffold(
          title: 'Privacy',
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
          body: const SizedBox.shrink(),
        ),
      );
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('passes toolbarHeight through to AppBar', (tester) async {
      await pump(
        tester,
        const PageScaffold(
          title: 'Search',
          toolbarHeight: 40,
          body: SizedBox.shrink(),
        ),
      );
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.toolbarHeight, 40);
    });

    testWidgets('title has header semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        const PageScaffold(
          title: 'Privacy',
          body: SizedBox.shrink(),
        ),
      );
      // The title Text is wrapped in Semantics(header: true, ...).
      // Locate the Semantics node that carries both the header flag
      // and the "Privacy" label — asserting the flag is the whole
      // point of the test, so we don't fall back to find.text.
      final semantics = tester
          .getSemantics(find.text('Privacy'))
          .getSemanticsData();
      expect(
        semantics.flagsCollection.isHeader,
        isTrue,
        reason: 'PageScaffold title must expose the TalkBack heading role',
      );
      handle.dispose();
    });
  });
}
