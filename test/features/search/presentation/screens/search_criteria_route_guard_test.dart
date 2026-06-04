// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/presentation/screens/search_criteria_screen.dart';

/// #2810 — the shared guard every search-criteria push site uses to refuse
/// stacking a duplicate modal (the "search just re-opens the same form again
/// and again" bug). Tested against a real [NavigatorState] with a route stack,
/// so it pins the actual top-route detection without the heavy criteria screen.
void main() {
  final navKey = GlobalKey<NavigatorState>();

  Future<void> pumpNav(WidgetTester tester) => tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            key: navKey,
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('root')),
            ),
          ),
        ),
      );

  testWidgets('false when the criteria route is not on top', (tester) async {
    await pumpNav(tester);
    expect(searchCriteriaRouteIsCurrent(navKey.currentState!), isFalse);

    // An unrelated (unnamed) route on top is still not the criteria route.
    unawaited(navKey.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Scaffold()),
    ));
    await tester.pumpAndSettle();
    expect(searchCriteriaRouteIsCurrent(navKey.currentState!), isFalse);
  });

  testWidgets('true when the criteria route is current — and the guard does '
      'not pop it', (tester) async {
    await pumpNav(tester);
    unawaited(navKey.currentState!.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: kSearchCriteriaRouteName),
        builder: (_) => const Scaffold(body: Text('criteria')),
      ),
    ));
    await tester.pumpAndSettle();

    expect(searchCriteriaRouteIsCurrent(navKey.currentState!), isTrue);
    // Inspecting must be non-destructive — the route is still there.
    expect(searchCriteriaRouteIsCurrent(navKey.currentState!), isTrue);
    expect(find.text('criteria'), findsOneWidget);
    expect(navKey.currentState!.canPop(), isTrue);
  });
}
