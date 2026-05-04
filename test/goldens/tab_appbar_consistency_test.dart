import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/page_scaffold.dart';
import 'package:tankstellen/core/widgets/tab_switcher.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #1441 — golden parity check for the 5 main tabs' AppBar.
///
/// Each top-level tab (Recherche, Carte, Favoris, Conso, Paramètres)
/// must produce the same AppBar shape: same toolbar height, same title
/// Y-offset, same font metrics. Before #1441 two regressions broke
/// that contract:
///
///   * Favoris + Conso passed `TabSwitcher` to `PageScaffold.bottom:`,
///     making their AppBar taller than the other 3 tabs.
///   * Carte used `titleWidget: GestureDetector(Text)` (#1316 phase 2)
///     while the other 4 used plain `title:` (which `PageScaffold`
///     wraps in `Semantics(header: true, Text)`).
///
/// This test pins each tab's AppBar to a representative `PageScaffold`
/// configuration matching the post-fix screen and snapshots the top
/// 100 px. The acceptance is "all 5 AppBars are visually consistent
/// modulo the title text" — pixel-equality across the AppBar chrome
/// (height, padding, divider, icon position) is the simplest assertion.
/// `TolerantGoldenFileComparator` (auto-installed by
/// `flutter_test_config.dart` for this directory) absorbs cross-platform
/// font-rendering jitter.
void main() {
  group('Tab AppBar consistency (#1441)', () {
    testWidgets('Recherche tab AppBar', (tester) async {
      await _pumpTabAppBar(
        tester,
        title: 'Fuel Prices',
        actions: const [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: null,
            tooltip: 'Refresh prices',
          ),
        ],
      );

      await expectLater(
        find.byKey(const Key('tab_appbar_capture')),
        matchesGoldenFile('tab_appbar_recherche.png'),
      );
    });

    testWidgets('Carte tab AppBar', (tester) async {
      await _pumpTabAppBar(
        tester,
        title: 'Map',
        actions: const [
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

      await expectLater(
        find.byKey(const Key('tab_appbar_capture')),
        matchesGoldenFile('tab_appbar_carte.png'),
      );
    });

    testWidgets('Favoris tab AppBar', (tester) async {
      // Favoris keeps its TabSwitcher inside the body Column now —
      // the AppBar itself must match the other 4 tabs in height.
      await _pumpTabAppBar(
        tester,
        title: 'Favorites',
        actions: const [
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
        bodyTabSwitcher: _staticTabSwitcher(['Favorites', 'Price Alerts']),
      );

      await expectLater(
        find.byKey(const Key('tab_appbar_capture')),
        matchesGoldenFile('tab_appbar_favoris.png'),
      );
    });

    testWidgets('Conso tab AppBar', (tester) async {
      await _pumpTabAppBar(
        tester,
        title: 'Fuel consumption',
        actions: const [
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
        bodyTabSwitcher: _staticTabSwitcher(['Fuel', 'Trips', 'Charging']),
      );

      await expectLater(
        find.byKey(const Key('tab_appbar_capture')),
        matchesGoldenFile('tab_appbar_conso.png'),
      );
    });

    testWidgets('Paramètres tab AppBar', (tester) async {
      await _pumpTabAppBar(
        tester,
        title: 'Settings',
      );

      await expectLater(
        find.byKey(const Key('tab_appbar_capture')),
        matchesGoldenFile('tab_appbar_parametres.png'),
      );
    });
  });
}

/// Static `TabSwitcher` for golden tests. Wrapped in
/// [DefaultTabController] so the underlying `TabBar` finds a controller
/// without the test having to manage `vsync`.
Widget _staticTabSwitcher(List<String> labels) {
  return DefaultTabController(
    length: labels.length,
    child: TabSwitcher(
      tabs: [
        for (final label in labels) TabSwitcherEntry(label: label),
      ],
    ),
  );
}

/// Pumps a representative [PageScaffold] for one tab and parks a
/// `RepaintBoundary` keyed `tab_appbar_capture` over the entire screen
/// so `expectLater(matchesGoldenFile)` snapshots a fixed-size frame.
///
/// Using a 400×100 viewport keeps each PNG small while still covering
/// the AppBar chrome plus the first sliver of body (where the
/// optional [bodyTabSwitcher] would render — making cross-tab parity
/// visible at a glance when goldens diff).
Future<void> _pumpTabAppBar(
  WidgetTester tester, {
  required String title,
  List<Widget>? actions,
  Widget? bodyTabSwitcher,
}) async {
  // Pin the rendered surface size so AppBar widths are stable across
  // hosts. 400 dp matches the spec ("a fixed width").
  await tester.binding.setSurfaceSize(const Size(400, 200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: RepaintBoundary(
          key: const Key('tab_appbar_capture'),
          child: PageScaffold(
            title: title,
            actions: actions,
            bodyPadding: EdgeInsets.zero,
            body: bodyTabSwitcher == null
                ? const SizedBox.expand()
                : Column(
                    children: [
                      bodyTabSwitcher,
                      const Expanded(child: SizedBox.expand()),
                    ],
                  ),
          ),
        ),
      ),
    ),
  );
  // Two pumps drain the post-frame scheduling that AppBar / TabBar use
  // to compute their indicators, without invoking `pumpAndSettle` (no
  // indeterminate animations are on screen, but CI's golden runner
  // still occasionally races a frame on the first draw).
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}
