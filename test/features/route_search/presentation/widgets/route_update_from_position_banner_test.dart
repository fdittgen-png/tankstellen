// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/route_progress.dart';
import 'package:tankstellen/features/route_search/api.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/pump_app.dart';

/// #4432 — "Update route from your position" (new in #4464) across
/// locales, the expansion pseudo-locale, a narrow screen and enlarged
/// text, following the #4465 pattern for the refuel-plan card.
class _FixedProgress extends RouteLiveProgressController {
  _FixedProgress(this.value);
  final RouteLiveProgress value;

  @override
  RouteLiveProgress build() => value;

  @override
  void pause() {}

  @override
  void resume() {}
}

class _CountingSearch extends RouteSearchState {
  int refreshes = 0;

  @override
  AsyncValue<RouteSearchResult?> build() => const AsyncValue.data(null);

  @override
  Future<bool> refresh() async {
    refreshes++;
    return true;
  }
}

void main() {
  const offRoute = RouteLiveProgress(
    revision: 3,
    status: RouteProgressStatus.offRoute,
  );

  Future<_CountingSearch> pumpBanner(
    WidgetTester tester, {
    RouteLiveProgress progress = offRoute,
    Locale locale = const Locale('en'),
    double textScale = 1,
    Size size = const Size(400, 800),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final search = _CountingSearch();
    await pumpApp(
      tester,
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: const SingleChildScrollView(
          child: RouteUpdateFromPositionBanner(),
        ),
      ),
      overrides: [
        routeLiveProgressControllerProvider
            .overrideWith(() => _FixedProgress(progress)),
        routeSearchStateProvider.overrideWith(() => search),
      ],
      locale: locale,
    );
    return search;
  }

  final banner = find.byKey(const ValueKey('route-update-from-position'));

  testWidgets('hidden while the driver is on the route', (tester) async {
    await pumpBanner(
      tester,
      progress: const RouteLiveProgress(
        revision: 3,
        status: RouteProgressStatus.onRoute,
      ),
    );
    expect(banner, findsNothing);
  });

  testWidgets('shown for an unreliable position too, not only off-route',
      (tester) async {
    await pumpBanner(
      tester,
      progress: const RouteLiveProgress(
        revision: 3,
        status: RouteProgressStatus.unreliable,
      ),
    );
    expect(banner, findsOneWidget);
  });

  testWidgets('French: the notice and the action are French, with no '
      'English fallback', (tester) async {
    await pumpBanner(tester, locale: const Locale('fr'));

    final fr = await AppLocalizations.delegate.load(const Locale('fr'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(fr.routeLeftRouteNotice), findsOneWidget);
    expect(find.text(fr.routeUpdateFromPosition), findsOneWidget);
    // Distinct strings, so these negatives can actually fail.
    expect(fr.routeUpdateFromPosition, isNot(en.routeUpdateFromPosition));
    expect(find.text(en.routeLeftRouteNotice), findsNothing);
    expect(find.text(en.routeUpdateFromPosition), findsNothing);
  });

  testWidgets('the en_XA expansion pseudo-locale fits 320 dp', (tester) async {
    await pumpBanner(
      tester,
      locale: const Locale('en', 'XA'),
      size: const Size(320, 800),
    );

    expect(tester.takeException(), isNull);
    expect(banner, findsOneWidget);
    final xa =
        await AppLocalizations.delegate.load(const Locale('en', 'XA'));
    expect(find.text(xa.routeUpdateFromPosition), findsOneWidget);
  });

  testWidgets('double text scale on a narrow screen: no overflow, and the '
      'action still fires exactly one refresh', (tester) async {
    final search = await pumpBanner(
      tester,
      textScale: 2,
      size: const Size(320, 1600),
    );

    expect(tester.takeException(), isNull);
    final button = find.widgetWithText(TextButton, 'Update route from your position');
    expect(button, findsOneWidget);
    // The action stays inside the screen, not pushed off by the notice.
    expect(tester.getRect(button).right, lessThanOrEqualTo(320));

    await tester.tap(button);
    await tester.pump();
    expect(search.refreshes, 1);
  });

  testWidgets('the action is an accessible, adequately sized button',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpBanner(tester);

    expect(
      find.bySemanticsLabel('Update route from your position'),
      findsOneWidget,
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
  });
}
