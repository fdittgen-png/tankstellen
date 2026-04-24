import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/tab_switcher.dart';

void main() {
  group('TabSwitcher', () {
    Future<void> pumpWithController(
      WidgetTester tester, {
      required int length,
      int initialIndex = 0,
      ValueChanged<int>? onTap,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: DefaultTabController(
            length: length,
            initialIndex: initialIndex,
            child: Scaffold(
              appBar: AppBar(
                bottom: TabSwitcher(
                  tabs: const [
                    TabSwitcherEntry(label: 'Fuel'),
                    TabSwitcherEntry(label: 'EV'),
                  ],
                  onTap: onTap,
                ),
              ),
              body: const TabBarView(
                children: [
                  Center(child: Text('Fuel view')),
                  Center(child: Text('EV view')),
                ],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders every tab label', (tester) async {
      await pumpWithController(tester, length: 2);
      expect(find.text('Fuel'), findsOneWidget);
      expect(find.text('EV'), findsOneWidget);
    });

    testWidgets('applies primary indicator color and weight 3',
        (tester) async {
      late ThemeData capturedTheme;
      await tester.pumpWidget(
        MaterialApp(
          home: DefaultTabController(
            length: 2,
            child: Builder(
              builder: (context) {
                capturedTheme = Theme.of(context);
                return Scaffold(
                  appBar: AppBar(
                    bottom: const TabSwitcher(
                      tabs: [
                        TabSwitcherEntry(label: 'Fuel'),
                        TabSwitcherEntry(label: 'EV'),
                      ],
                    ),
                  ),
                  body: const SizedBox.shrink(),
                );
              },
            ),
          ),
        ),
      );
      final bar = tester.widget<TabBar>(find.byType(TabBar));
      expect(bar.indicatorColor, capturedTheme.colorScheme.primary);
      expect(bar.indicatorWeight, 3);
      expect(bar.labelColor, capturedTheme.colorScheme.primary);
      expect(
        bar.unselectedLabelColor,
        capturedTheme.colorScheme.onSurfaceVariant,
      );
      expect(bar.labelStyle?.fontWeight, FontWeight.w600);
    });

    testWidgets('propagates tap events via onTap', (tester) async {
      var tapped = -1;
      await pumpWithController(
        tester,
        length: 2,
        onTap: (index) => tapped = index,
      );
      await tester.tap(find.text('EV'));
      await tester.pumpAndSettle();
      expect(tapped, 1);
    });

    testWidgets('accepts an explicit controller', (tester) async {
      final controller = _createController(length: 3, initialIndex: 0);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              bottom: TabSwitcher(
                controller: controller,
                tabs: const [
                  TabSwitcherEntry(label: 'A'),
                  TabSwitcherEntry(label: 'B'),
                  TabSwitcherEntry(label: 'C'),
                ],
              ),
            ),
            body: TabBarView(
              controller: controller,
              children: const [
                Center(child: Text('A body')),
                Center(child: Text('B body')),
                Center(child: Text('C body')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('A'), findsOneWidget);
      await tester.tap(find.text('C'));
      await tester.pumpAndSettle();
      expect(controller.index, 2);
    });

    testWidgets('respects isScrollable flag', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                bottom: const TabSwitcher(
                  isScrollable: true,
                  tabs: [
                    TabSwitcherEntry(label: 'Fuel'),
                    TabSwitcherEntry(label: 'EV'),
                  ],
                ),
              ),
              body: const SizedBox.shrink(),
            ),
          ),
        ),
      );
      final bar = tester.widget<TabBar>(find.byType(TabBar));
      expect(bar.isScrollable, isTrue);
    });
  });
}

TabController _createController({
  required int length,
  int initialIndex = 0,
}) {
  return TabController(
    length: length,
    initialIndex: initialIndex,
    vsync: const TestVSync(),
  );
}
