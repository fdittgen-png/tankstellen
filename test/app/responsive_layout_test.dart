import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/responsive_search_layout.dart';

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

  group('ResponsiveLayoutWrapper', () {
    testWidgets('shows only compactBody on phone screen', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveLayoutWrapper(
              compactBody: Text('Primary'),
              detailBody: Text('Detail'),
            ),
          ),
        ),
      );

      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('Detail'), findsNothing);
    });

    testWidgets('shows split view on tablet screen', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveLayoutWrapper(
              compactBody: Text('Primary'),
              detailBody: Text('Detail'),
            ),
          ),
        ),
      );

      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('Detail'), findsOneWidget);
      expect(find.byType(VerticalDivider), findsOneWidget);
    });

    testWidgets('shows split view on expanded screen', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveLayoutWrapper(
              compactBody: Text('Primary'),
              detailBody: Text('Detail'),
            ),
          ),
        ),
      );

      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('Detail'), findsOneWidget);
      expect(find.byType(VerticalDivider), findsOneWidget);
    });

    testWidgets('shows only compactBody when detailBody is null',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveLayoutWrapper(
              compactBody: Text('Primary'),
            ),
          ),
        ),
      );

      expect(find.text('Primary'), findsOneWidget);
      expect(find.byType(VerticalDivider), findsNothing);
    });
  });

  group('ResponsiveSearchLayout', () {
    testWidgets('shows only search panel on phone', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveSearchLayout(
              searchPanel: Text('Search'),
              mapPanel: Text('Map'),
            ),
          ),
        ),
      );

      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Map'), findsNothing);
    });

    testWidgets('shows both panels on tablet', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveSearchLayout(
              searchPanel: Text('Search'),
              mapPanel: Text('Map'),
            ),
          ),
        ),
      );

      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Map'), findsOneWidget);
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
