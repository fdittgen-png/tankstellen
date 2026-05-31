// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/profile/presentation/widgets/storage_bar.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  final testTheme = ThemeData.light();

  group('StorageBar', () {
    testWidgets('renders colored segments', (tester) async {
      await pumpApp(
        tester,
        StorageBar(
          segments: const [
            StorageSegment('Settings', 500, Colors.blue),
            StorageSegment('Cache', 1500, Colors.red),
          ],
          totalBytes: 2000,
          theme: testTheme,
        ),
      );

      expect(find.byType(StorageBar), findsOneWidget);
      expect(find.text('No storage used'), findsNothing);
    });

    testWidgets('shows empty message when totalBytes is 0', (tester) async {
      await pumpApp(
        tester,
        StorageBar(
          segments: const [
            StorageSegment('Settings', 0, Colors.blue),
          ],
          totalBytes: 0,
          theme: testTheme,
        ),
      );

      expect(find.text('No storage used'), findsOneWidget);
    });

    testWidgets('renders a legend that names every visible segment (#2116)',
        (tester) async {
      await pumpApp(
        tester,
        StorageBar(
          segments: const [
            StorageSegment('Settings', 500, Colors.blue),
            StorageSegment('Cache', 1500, Colors.red),
          ],
          totalBytes: 2000,
          theme: testTheme,
        ),
      );

      // The legend lives under the bar; each visible segment gets a
      // swatch + label pair, so the colours stop being arbitrary.
      expect(find.byKey(const Key('storage_bar_legend')), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Cache'), findsOneWidget);
    });

    testWidgets(
        'legend lists every non-zero segment, even a tiny one (#2490)',
        (tester) async {
      // #2490 — a small-but-real category (0.1 % here) must still appear
      // in both the bar and the legend; only truly empty categories drop.
      // Before #2490 the bar collapsed sub-1% slices to an invisible
      // hairline and the legend dropped them, so a couple of favourites
      // next to a huge cache silently vanished.
      await pumpApp(
        tester,
        StorageBar(
          segments: const [
            StorageSegment('Big', 9990, Colors.green),
            StorageSegment('Tiny', 10, Colors.purple), // 0.1 % → still shown
          ],
          totalBytes: 10000,
          theme: testTheme,
        ),
      );

      expect(find.byKey(const Key('storage_bar_legend')), findsOneWidget);
      expect(find.text('Big'), findsOneWidget);
      expect(find.text('Tiny'), findsOneWidget);
    });

    testWidgets('legend omits zero-byte segments (#2490)', (tester) async {
      await pumpApp(
        tester,
        StorageBar(
          segments: const [
            StorageSegment('HasData', 2000, Colors.green),
            StorageSegment('Empty', 0, Colors.purple),
          ],
          totalBytes: 2000,
          theme: testTheme,
        ),
      );

      expect(find.byKey(const Key('storage_bar_legend')), findsOneWidget);
      expect(find.text('HasData'), findsOneWidget);
      expect(find.text('Empty'), findsNothing);
    });

    testWidgets(
        'a tiny non-zero segment renders a visible sliver, not a hairline '
        '(#2490)', (tester) async {
      // The min-flex floor means a sub-1% segment is laid out wider than
      // its raw byte share. We assert it gets non-trivial width relative
      // to the dominant segment.
      tester.view.physicalSize = const Size(1000, 200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpApp(
        tester,
        StorageBar(
          segments: const [
            StorageSegment('Big', 9990, Colors.green),
            StorageSegment('Tiny', 10, Colors.purple),
          ],
          totalBytes: 10000,
          theme: testTheme,
        ),
      );

      final greenSize = tester.getSize(
        find.byWidgetPredicate(
          (w) => w is Container && w.color == Colors.green,
        ),
      );
      final purpleSize = tester.getSize(
        find.byWidgetPredicate(
          (w) => w is Container && w.color == Colors.purple,
        ),
      );
      // The tiny slice's raw share is 0.1 % of the bar, but the floor
      // gives it ~30/1020 ≈ 2.9 %, so it must be perceptibly wide.
      expect(purpleSize.width, greaterThan(10.0),
          reason: 'tiny segment must render a visible sliver');
      expect(greenSize.width, greaterThan(purpleSize.width),
          reason: 'the dominant segment is still the widest');
    });
  });

  group('StorageDetailRow', () {
    testWidgets('renders label, detail, and formatted bytes', (tester) async {
      await pumpApp(
        tester,
        const StorageDetailRow(
          label: 'Cache',
          detail: '12 entries',
          bytes: 2048,
          color: Colors.orange,
        ),
      );

      expect(find.text('Cache'), findsOneWidget);
      expect(find.text('12 entries'), findsOneWidget);
      // 2048 bytes = 2.0 KB
      expect(find.text('2.0 KB'), findsOneWidget);
    });
  });
}
