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

    testWidgets('renders floatingActionButton when provided', (tester) async {
      await pump(
        tester,
        PageScaffold(
          title: 'Map',
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            child: const Icon(Icons.drive_eta),
          ),
          body: const SizedBox.shrink(),
        ),
      );
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('passes floatingActionButtonLocation through to Scaffold',
        (tester) async {
      await pump(
        tester,
        PageScaffold(
          title: 'Map',
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          body: const SizedBox.shrink(),
        ),
      );
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(
        scaffold.floatingActionButtonLocation,
        FloatingActionButtonLocation.centerDocked,
      );
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

    testWidgets('passes titleTextStyle through to AppBar', (tester) async {
      await pump(
        tester,
        const PageScaffold(
          title: 'Map',
          titleTextStyle: TextStyle(fontSize: 16),
          body: SizedBox.shrink(),
        ),
      );
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.titleTextStyle?.fontSize, 16);
    });

    testWidgets('passes titleSpacing through to AppBar', (tester) async {
      await pump(
        tester,
        const PageScaffold(
          title: 'Map',
          titleSpacing: 12,
          body: SizedBox.shrink(),
        ),
      );
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.titleSpacing, 12);
    });

    testWidgets('forwards bottomNavigationBar to the scaffold',
        (tester) async {
      await pump(
        tester,
        const PageScaffold(
          title: 'Add fill-up',
          body: SizedBox.shrink(),
          bottomNavigationBar: SizedBox(
            key: Key('pinned_save_bar'),
            height: 56,
          ),
        ),
      );
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.bottomNavigationBar, isNotNull);
      expect(find.byKey(const Key('pinned_save_bar')), findsOneWidget);
    });

    testWidgets('passes bottom through to AppBar', (tester) async {
      const bottomHeight = 48.0;
      await pump(
        tester,
        PageScaffold(
          title: 'Favorites',
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(bottomHeight),
            child: Container(
              key: const Key('tab_bar_stub'),
              height: bottomHeight,
            ),
          ),
          body: const SizedBox.shrink(),
        ),
      );
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.bottom, isNotNull);
      expect(appBar.bottom!.preferredSize.height, bottomHeight);
      expect(find.byKey(const Key('tab_bar_stub')), findsOneWidget);
    });

    testWidgets('forwards leading to the app bar', (tester) async {
      var tapped = false;
      await pump(
        tester,
        PageScaffold(
          title: 'Add fill-up',
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => tapped = true,
          ),
          body: const SizedBox.shrink(),
        ),
      );
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back));
      expect(tapped, isTrue);
    });

    testWidgets('renders titleWidget when provided', (tester) async {
      await pump(
        tester,
        const PageScaffold(
          titleWidget: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_gas_station, key: Key('brand_icon')),
              SizedBox(width: 8),
              Text('Custom Brand Title'),
            ],
          ),
          body: SizedBox.shrink(),
        ),
      );
      // The custom title widget renders inside the AppBar.
      final appBarFinder = find.byType(AppBar);
      expect(appBarFinder, findsOneWidget);
      expect(
        find.descendant(
          of: appBarFinder,
          matching: find.byKey(const Key('brand_icon')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: appBarFinder,
          matching: find.text('Custom Brand Title'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('titleWidget wins when both title and titleWidget are passed',
        (tester) async {
      await pump(
        tester,
        const PageScaffold(
          title: 'Plain title',
          titleWidget: Text('Widget title', key: Key('title_widget')),
          body: SizedBox.shrink(),
        ),
      );
      // titleWidget takes precedence; the plain `title` is not rendered.
      expect(find.byKey(const Key('title_widget')), findsOneWidget);
      expect(find.text('Plain title'), findsNothing);
    });

    test('assertion fires when both title and titleWidget are null', () {
      expect(
        () => PageScaffold(body: const SizedBox.shrink()),
        throwsA(isA<AssertionError>()),
      );
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
