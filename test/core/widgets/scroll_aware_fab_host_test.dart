// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/scroll_aware_fab_host.dart';

import '../../helpers/pump_app.dart';

/// #4120 — the FAB gets out of the way of the controls it floats over.
///
/// The overlap it fixes is transient, which is why the answer is not
/// more clearance: that would push the whole screen further from the
/// thumb at rest to fix something that only happens mid-gesture.
void main() {
  Widget host({required List<Widget> children}) => ScrollAwareFabHost(
        builder: (context, scrolling) => Scaffold(
          floatingActionButton: Text(scrolling ? 'collapsed' : 'extended'),
          body: ListView(children: children),
        ),
      );

  final rows = [
    for (var i = 0; i < 40; i++) SizedBox(height: 60, child: Text('row $i')),
  ];

  testWidgets('at rest the FAB is in its resting state', (tester) async {
    await pumpApp(tester, host(children: rows));

    expect(find.text('extended'), findsOneWidget);
  });

  testWidgets('a drag collapses it, and letting go restores it',
      (tester) async {
    await pumpApp(tester, host(children: rows));

    final gesture = await tester.startGesture(const Offset(200, 300));
    await gesture.moveBy(const Offset(0, -120));
    await tester.pump();

    expect(find.text('collapsed'), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();

    // Back to the labelled form the moment the list is still — the
    // label is the whole point of the FAB (#3337).
    expect(find.text('extended'), findsOneWidget);
  });

  testWidgets('the notification is never absorbed', (tester) async {
    // The shell's own scroll-driven chrome listens further up the tree;
    // swallowing the notification here would silently break it.
    var seenOutside = 0;
    await pumpApp(
      tester,
      NotificationListener<ScrollNotification>(
        onNotification: (_) {
          seenOutside++;
          return false;
        },
        child: host(children: rows),
      ),
    );

    final gesture = await tester.startGesture(const Offset(200, 300));
    await gesture.moveBy(const Offset(0, -120));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(seenOutside, greaterThan(0));
  });

  testWidgets('a drag on a body with nothing to scroll collapses it too',
      (tester) async {
    // Documented rather than prevented: Flutter reports the user's
    // scroll intent even when there is nothing to move, and a page too
    // short to scroll has nothing under the FAB to reach in the first
    // place. Not worth a special case.
    await pumpApp(tester, host(children: [const Text('row 0')]));

    final gesture = await tester.startGesture(const Offset(200, 300));
    await gesture.moveBy(const Offset(0, -120));
    await tester.pump();

    expect(find.text('collapsed'), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('extended'), findsOneWidget);
  });
}
