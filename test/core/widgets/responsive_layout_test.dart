// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/responsive_layout.dart';

void main() {
  group('screenSizeFromWidth', () {
    test('returns compact for phone width (< 600)', () {
      expect(screenSizeFromWidth(360), ScreenSize.compact);
      expect(screenSizeFromWidth(599), ScreenSize.compact);
    });

    test('returns medium for tablet portrait width (600-840)', () {
      expect(screenSizeFromWidth(600), ScreenSize.medium);
      expect(screenSizeFromWidth(768), ScreenSize.medium);
      expect(screenSizeFromWidth(839), ScreenSize.medium);
    });

    test('returns expanded for tablet landscape / desktop (> 840)', () {
      expect(screenSizeFromWidth(840), ScreenSize.expanded);
      expect(screenSizeFromWidth(1024), ScreenSize.expanded);
      expect(screenSizeFromWidth(1440), ScreenSize.expanded);
    });

    test('handles edge case at exact breakpoints', () {
      expect(screenSizeFromWidth(600), ScreenSize.medium);
      expect(screenSizeFromWidth(840), ScreenSize.expanded);
    });

    test('handles zero and negative widths as compact', () {
      expect(screenSizeFromWidth(0), ScreenSize.compact);
    });
  });

  group('isWideScreen', () {
    testWidgets('returns false for phone-size screen', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late bool result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            result = isWideScreen(context);
            return const SizedBox();
          }),
        ),
      );

      expect(result, isFalse);
    });

    testWidgets('returns true for tablet-size screen', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late bool result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            result = isWideScreen(context);
            return const SizedBox();
          }),
        ),
      );

      expect(result, isTrue);
    });
  });

  group('screenSizeOf', () {
    testWidgets('returns compact for phone (360x640)', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late ScreenSize result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            result = screenSizeOf(context);
            return const SizedBox();
          }),
        ),
      );

      expect(result, ScreenSize.compact);
    });

    testWidgets('returns medium for tablet portrait (768x1024)',
        (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late ScreenSize result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            result = screenSizeOf(context);
            return const SizedBox();
          }),
        ),
      );

      expect(result, ScreenSize.medium);
    });

    testWidgets('returns expanded for tablet landscape (1024x768)',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late ScreenSize result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            result = screenSizeOf(context);
            return const SizedBox();
          }),
        ),
      );

      expect(result, ScreenSize.expanded);
    });

    testWidgets('returns medium for foldable (884x1104)', (tester) async {
      tester.view.physicalSize = const Size(884, 1104);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late ScreenSize result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            result = screenSizeOf(context);
            return const SizedBox();
          }),
        ),
      );

      expect(result, ScreenSize.expanded);
    });
  });

  // ResponsiveLayoutWrapper (the old internal delegate of
  // ResponsiveMasterDetail) was dead outside this file and deleted in #3133 —
  // its breakpoint/split/hinge logic now lives directly in
  // ResponsiveMasterDetail, covered by the group below.
  group('ResponsiveMasterDetail', () {
    // The two flex panes of the wrapper's Row are the only `Expanded`s in
    // these trees, in master-then-detail order.
    List<int> paneFlex(WidgetTester tester) => tester
        .widgetList<Expanded>(find.byType(Expanded))
        .map((e) => e.flex)
        .toList();

    testWidgets('shows only master on compact (one pane)', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveMasterDetail(
              master: Text('Master'),
              detail: Text('Detail'),
            ),
          ),
        ),
      );

      expect(find.text('Master'), findsOneWidget);
      expect(find.text('Detail'), findsNothing);
      expect(find.byType(VerticalDivider), findsNothing);
    });

    testWidgets('shows two panes (1:1) on medium', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveMasterDetail(
              master: Text('Master'),
              detail: Text('Detail'),
            ),
          ),
        ),
      );

      expect(find.text('Master'), findsOneWidget);
      expect(find.text('Detail'), findsOneWidget);
      expect(find.byType(VerticalDivider), findsOneWidget);
      expect(paneFlex(tester), [1, 1]);
    });

    testWidgets('shows two panes with the 2:3 ratio on expanded',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveMasterDetail(
              master: Text('Master'),
              detail: Text('Detail'),
            ),
          ),
        ),
      );

      expect(find.text('Master'), findsOneWidget);
      expect(find.text('Detail'), findsOneWidget);
      // Master flex 2, detail flex 3 — the shared expanded ratio.
      expect(paneFlex(tester), [2, 3]);
    });

    testWidgets('falls back to detailPlaceholder when detail is null',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveMasterDetail(
              master: Text('Master'),
              detailPlaceholder: Text('Placeholder'),
            ),
          ),
        ),
      );

      expect(find.text('Master'), findsOneWidget);
      expect(find.text('Placeholder'), findsOneWidget);
    });

    testWidgets('detail takes precedence over detailPlaceholder',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveMasterDetail(
              master: Text('Master'),
              detail: Text('Detail'),
              detailPlaceholder: Text('Placeholder'),
            ),
          ),
        ),
      );

      expect(find.text('Detail'), findsOneWidget);
      expect(find.text('Placeholder'), findsNothing);
    });

    testWidgets('master full-width when both detail and placeholder are null',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveMasterDetail(master: Text('Master')),
          ),
        ),
      );

      expect(find.text('Master'), findsOneWidget);
      expect(find.byType(VerticalDivider), findsNothing);
    });

    testWidgets('forceSplit shows two panes (1:1) even on compact',
        (tester) async {
      // The Favorites "landscape OR ≥600dp" trigger relies on forceSplit to
      // keep the side-by-side layout on a sub-600 landscape phone.
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveMasterDetail(
              forceSplit: true,
              master: Text('Master'),
              detail: Text('Detail'),
            ),
          ),
        ),
      );

      expect(find.text('Master'), findsOneWidget);
      expect(find.text('Detail'), findsOneWidget);
      expect(find.byType(VerticalDivider), findsOneWidget);
      expect(paneFlex(tester), [1, 1]);
    });
  });

  group('displayHingeOf', () {
    testWidgets('returns null when no display features', (tester) async {
      late Rect? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            result = displayHingeOf(context);
            return const SizedBox();
          }),
        ),
      );

      expect(result, isNull);
    });
  });
}
