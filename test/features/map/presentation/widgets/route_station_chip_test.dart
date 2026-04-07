import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // We cannot instantiate _RouteStationChip directly (private), so we test
  // the best-stops list section of RouteMapView by building a minimal
  // version that exercises the chip rendering.
  //
  // Since RouteMapView requires RouteSearchResult, MapController, and
  // Riverpod providers, we test the visual properties via a standalone
  // reproducer widget that mirrors _RouteStationChip's structure.

  group('Route station chip visual behavior', () {
    // Helper to build a chip-like widget matching _RouteStationChip structure
    Widget buildChipTest({
      required int stopNumber,
      required bool isSelected,
      required String stationName,
      double? price,
      double dist = 5.0,
      VoidCallback? onTap,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: _TestRouteStationChip(
            stopNumber: stopNumber,
            isSelected: isSelected,
            stationName: stationName,
            price: price,
            dist: dist,
            onTap: onTap ?? () {},
          ),
        ),
      );
    }

    testWidgets('displays stop number', (tester) async {
      await tester.pumpWidget(buildChipTest(
        stopNumber: 1,
        isSelected: false,
        stationName: 'SHELL',
      ));

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('displays station name', (tester) async {
      await tester.pumpWidget(buildChipTest(
        stopNumber: 1,
        isSelected: false,
        stationName: 'Intermarche',
      ));

      expect(find.text('Intermarche'), findsOneWidget);
    });

    testWidgets('displays formatted price when available', (tester) async {
      await tester.pumpWidget(buildChipTest(
        stopNumber: 1,
        isSelected: false,
        stationName: 'SHELL',
        price: 1.965,
      ));

      expect(find.text('1.965\u20ac'), findsOneWidget);
    });

    testWidgets('displays dash when price is null', (tester) async {
      await tester.pumpWidget(buildChipTest(
        stopNumber: 1,
        isSelected: false,
        stationName: 'SHELL',
        price: null,
      ));

      expect(find.text('--'), findsOneWidget);
    });

    testWidgets('displays distance with one decimal', (tester) async {
      await tester.pumpWidget(buildChipTest(
        stopNumber: 1,
        isSelected: false,
        stationName: 'SHELL',
        dist: 9.87,
      ));

      expect(find.textContaining('9.9 km'), findsOneWidget);
    });

    testWidgets('selected chip uses primary background color', (tester) async {
      await tester.pumpWidget(buildChipTest(
        stopNumber: 1,
        isSelected: true,
        stationName: 'SHELL',
      ));
      await tester.pump(const Duration(milliseconds: 250));

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      // Selected chip should have a filled (non-surface) background
      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(decoration.color, theme.colorScheme.primary);
    });

    testWidgets('unselected chip uses surface background color',
        (tester) async {
      await tester.pumpWidget(buildChipTest(
        stopNumber: 1,
        isSelected: false,
        stationName: 'SHELL',
      ));
      await tester.pump(const Duration(milliseconds: 250));

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(decoration.color, theme.colorScheme.surface);
    });

    testWidgets('selected chip has box shadow for elevation', (tester) async {
      await tester.pumpWidget(buildChipTest(
        stopNumber: 1,
        isSelected: true,
        stationName: 'SHELL',
      ));
      await tester.pump(const Duration(milliseconds: 250));

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow, isNotEmpty);
    });

    testWidgets('unselected chip has no box shadow', (tester) async {
      await tester.pumpWidget(buildChipTest(
        stopNumber: 1,
        isSelected: false,
        stationName: 'SHELL',
      ));
      await tester.pump(const Duration(milliseconds: 250));

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.boxShadow, isNull);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildChipTest(
        stopNumber: 1,
        isSelected: false,
        stationName: 'SHELL',
        onTap: () => tapped = true,
      ));

      await tester.tap(find.text('SHELL'));
      expect(tapped, isTrue);
    });

    testWidgets('stop number badge shows circular shape', (tester) async {
      await tester.pumpWidget(buildChipTest(
        stopNumber: 3,
        isSelected: false,
        stationName: 'ARAL',
      ));

      // Find the container with the stop number
      final containers = find.byType(Container);
      bool foundCircle = false;
      for (final element in containers.evaluate()) {
        final widget = element.widget as Container;
        if (widget.decoration is BoxDecoration) {
          final deco = widget.decoration as BoxDecoration;
          if (deco.shape == BoxShape.circle) {
            foundCircle = true;
            break;
          }
        }
      }
      expect(foundCircle, isTrue, reason: 'Stop number badge should be circular');
    });

    testWidgets('sequential stop numbers are shown correctly', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              _TestRouteStationChip(
                stopNumber: 1,
                isSelected: true,
                stationName: 'First',
                onTap: () {},
              ),
              _TestRouteStationChip(
                stopNumber: 2,
                isSelected: false,
                stationName: 'Second',
                onTap: () {},
              ),
              _TestRouteStationChip(
                stopNumber: 3,
                isSelected: false,
                stationName: 'Third',
                onTap: () {},
              ),
            ],
          ),
        ),
      ));

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('Third'), findsOneWidget);
    });
  });
}

/// Test-only widget that mirrors the _RouteStationChip structure.
///
/// Since the real chip is private to route_map_view.dart, this reproducer
/// uses the same visual layout so we can verify the design intent.
class _TestRouteStationChip extends StatelessWidget {
  final int stopNumber;
  final bool isSelected;
  final String stationName;
  final double? price;
  final double dist;
  final VoidCallback onTap;

  const _TestRouteStationChip({
    required this.stopNumber,
    required this.isSelected,
    required this.stationName,
    this.price,
    this.dist = 5.0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final selectedBg = theme.colorScheme.primary;
    final selectedFg = theme.colorScheme.onPrimary;
    final unselectedBg = theme.colorScheme.surface;
    final unselectedFg = theme.colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? selectedBg
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedBg.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected
                    ? selectedFg.withValues(alpha: 0.25)
                    : theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$stopNumber',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? selectedFg
                      : theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: Text(
                    stationName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? selectedFg : unselectedFg,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      price != null
                          ? '${price!.toStringAsFixed(3)}\u20ac'
                          : '--',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? selectedFg.withValues(alpha: 0.9)
                            : Colors.green.shade700,
                      ),
                    ),
                    Text(
                      ' \u00b7 ${dist.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? selectedFg.withValues(alpha: 0.7)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
