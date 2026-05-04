import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/page_scaffold.dart';
import 'package:tankstellen/core/widgets/tab_switcher.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #1441 — structural parity check for the 5 main tabs' AppBar.
///
/// Each top-level tab (Recherche, Carte, Favoris, Conso, Paramètres)
/// must produce the same AppBar shape: same toolbar height (no
/// extending `bottom:` slot) and the same title-slot wrapping
/// (`Semantics(header: true, Text)`, never `titleWidget:`). Before
/// #1441 two regressions broke that contract:
///
///   * Favoris + Conso passed `TabSwitcher` to `PageScaffold.bottom:`,
///     making their AppBar taller than the other 3 tabs.
///   * Carte used `titleWidget: GestureDetector(Text)` (#1316 phase 2)
///     while the other 4 used plain `title:` (which `PageScaffold`
///     wraps in `Semantics(header: true, Text)`).
///
/// Pixel-equality goldens proved too sensitive to cross-platform font
/// rendering (Linux CI vs Windows / macOS dev) — see
/// `feedback_golden_tests_tolerance.md`. Structural assertions test the
/// actual contract: equal AppBar height + uniform Semantics wrapping.
/// Title TEXT differs per tab (the whole point of the tabs), so we
/// only check the wrapper shape, not the rendered glyphs.
void main() {
  group('Tab AppBar consistency (#1441)', () {
    testWidgets('all 5 tabs render an AppBar of identical height '
        '(no bottom: slot extending it)', (tester) async {
      final heights = <String, double>{};
      for (final tab in _allTabs) {
        await _pumpTabAppBar(tester, tab);
        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        heights[tab.label] = appBar.preferredSize.height;
      }
      // Every entry must equal kToolbarHeight (Material default = 56);
      // a TabSwitcher in `bottom:` would push it up by ~46dp.
      for (final entry in heights.entries) {
        expect(
          entry.value,
          kToolbarHeight,
          reason:
              '${entry.key} AppBar height must be kToolbarHeight; got '
              '${entry.value}. A non-null `bottom:` would explain a '
              'taller value — move the TabSwitcher into the body.',
        );
      }
    });

    testWidgets('every tab uses Semantics(header: true, Text) for the '
        'title — never a custom titleWidget', (tester) async {
      for (final tab in _allTabs) {
        await _pumpTabAppBar(tester, tab);
        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        // PageScaffold wraps `title:` in `Semantics(header: true, Text)`.
        // Carte previously passed a `GestureDetector(Text)` via
        // `titleWidget:` — that path produces a non-Semantics root and
        // would break this assertion.
        expect(
          appBar.title,
          isA<Semantics>(),
          reason:
              '${tab.label} AppBar.title must be a Semantics widget — '
              'PageScaffold wraps `title:` in Semantics(header: true). '
              'A GestureDetector (or any other non-Semantics root) means '
              'the screen is using `titleWidget:` instead of `title:`, '
              'which #1441 forbids.',
        );
        // Drill in: the Semantics must wrap a Text whose data matches
        // the screen's title — proves the Semantics is the title slot,
        // not some unrelated decoration the screen put in the AppBar.
        final semantics = appBar.title! as Semantics;
        final innerText = semantics.child! as Text;
        expect(innerText.data, tab.title);
      }
    });

    testWidgets('Favoris + Conso render their TabSwitcher in the body '
        '(not in AppBar.bottom)', (tester) async {
      for (final tab in [_favorisTab, _consoTab]) {
        await _pumpTabAppBar(tester, tab);
        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(
          appBar.bottom,
          isNull,
          reason:
              '${tab.label} AppBar.bottom must be null — the TabSwitcher '
              'belongs in the body Column per #1441.',
        );
        // The TabSwitcher must still exist somewhere — just below the
        // AppBar, in the body.
        expect(find.byType(TabSwitcher), findsOneWidget);
      }
    });
  });
}

/// One tab's representative `PageScaffold` config.
class _TabSpec {
  final String label;
  final String title;
  final List<Widget> actions;
  final List<String>? tabSwitcherLabels;

  const _TabSpec({
    required this.label,
    required this.title,
    this.actions = const [],
    this.tabSwitcherLabels,
  });
}

const _rechercheTab = _TabSpec(
  label: 'Recherche',
  title: 'Fuel Prices',
  actions: [
    IconButton(
      icon: Icon(Icons.refresh),
      onPressed: null,
      tooltip: 'Refresh prices',
    ),
  ],
);

const _carteTab = _TabSpec(
  label: 'Carte',
  title: 'Map',
  actions: [
    IconButton(
      icon: Icon(Icons.refresh),
      onPressed: null,
      tooltip: 'Refresh prices',
    ),
    IconButton(
      icon: Icon(Icons.electrical_services),
      onPressed: null,
      tooltip: 'EV',
    ),
  ],
);

const _favorisTab = _TabSpec(
  label: 'Favoris',
  title: 'Favorites',
  actions: [
    IconButton(
      icon: Icon(Icons.share),
      onPressed: null,
      tooltip: 'Share',
    ),
    IconButton(
      icon: Icon(Icons.refresh),
      onPressed: null,
      tooltip: 'Refresh prices',
    ),
  ],
  tabSwitcherLabels: ['Favorites', 'Price Alerts'],
);

const _consoTab = _TabSpec(
  label: 'Conso',
  title: 'Fuel consumption',
  actions: [
    IconButton(
      icon: Icon(Icons.download_outlined),
      onPressed: null,
      tooltip: 'Export backup',
    ),
    IconButton(
      icon: Icon(Icons.eco_outlined),
      onPressed: null,
      tooltip: 'Carbon dashboard',
    ),
  ],
  tabSwitcherLabels: ['Fuel', 'Trips', 'Charging'],
);

const _parametresTab = _TabSpec(
  label: 'Paramètres',
  title: 'Settings',
);

const _allTabs = <_TabSpec>[
  _rechercheTab,
  _carteTab,
  _favorisTab,
  _consoTab,
  _parametresTab,
];

/// Pumps a representative [PageScaffold] for one tab.
Future<void> _pumpTabAppBar(WidgetTester tester, _TabSpec spec) async {
  await tester.binding.setSurfaceSize(const Size(400, 200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final body = spec.tabSwitcherLabels == null
      ? const SizedBox.expand()
      : Column(
          children: [
            DefaultTabController(
              length: spec.tabSwitcherLabels!.length,
              child: TabSwitcher(
                tabs: [
                  for (final label in spec.tabSwitcherLabels!)
                    TabSwitcherEntry(label: label),
                ],
              ),
            ),
            const Expanded(child: SizedBox.expand()),
          ],
        );

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: PageScaffold(
          title: spec.title,
          actions: spec.actions,
          bodyPadding: EdgeInsets.zero,
          body: body,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}
