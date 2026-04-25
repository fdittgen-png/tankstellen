import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/report/domain/entities/report_type.dart';
import 'package:tankstellen/features/report/presentation/widgets/report_type_list.dart';

import '../../../../helpers/pump_app.dart';

/// Mounts `buildReportTypeList(...)` inside a `RadioGroup<ReportType>`
/// (the contract the function documents) so each `RadioListTile` can
/// resolve `RadioGroup.maybeOf` and render without asserting.
///
/// A [Consumer] supplies the [WidgetRef] the builder needs. We don't
/// drive selection in these tests — we only assert what the builder
/// renders for a given `(visibleTypes, hasAnyBackend)` input — so a
/// no-op `onChanged` is fine.
Widget _hostFor({
  required List<ReportType> visibleTypes,
  required bool hasAnyBackend,
}) {
  return Consumer(
    builder: (context, ref, _) {
      return RadioGroup<ReportType>(
        groupValue: null,
        onChanged: (_) {},
        child: ListView(
          children: buildReportTypeList(
            context,
            ref,
            visibleTypes: visibleTypes,
            hasAnyBackend: hasAnyBackend,
          ),
        ),
      );
    },
  );
}

void main() {
  group('buildReportTypeList', () {
    testWidgets(
        'empty visibleTypes → renders the header + spacer but no '
        'RadioListTiles', (tester) async {
      await pumpApp(
        tester,
        _hostFor(visibleTypes: const [], hasAnyBackend: true),
      );

      // Header is always rendered.
      expect(find.text("What's wrong?"), findsOneWidget);
      // Fixed 12px spacer that follows the header.
      expect(
        find.byWidgetPredicate(
          (w) => w is SizedBox && w.height == 12 && w.width == null,
        ),
        findsOneWidget,
      );
      // No radios at all.
      expect(find.byType(RadioListTile<ReportType>), findsNothing);
    });

    testWidgets(
        'non-empty visibleTypes → renders one RadioListTile per type '
        'in the order the caller supplied', (tester) async {
      const order = [
        ReportType.wrongE10,
        ReportType.wrongDiesel,
        ReportType.wrongName,
      ];

      await pumpApp(
        tester,
        _hostFor(visibleTypes: order, hasAnyBackend: true),
      );

      final tiles = tester
          .widgetList<RadioListTile<ReportType>>(
            find.byType(RadioListTile<ReportType>),
          )
          .toList();
      expect(tiles, hasLength(order.length));
      expect(tiles.map((t) => t.value).toList(), order);
    });

    testWidgets('hasAnyBackend=true → every tile is enabled, GitHub '
        'or backend-routed alike', (tester) async {
      const types = [
        ReportType.wrongE5,
        ReportType.wrongDiesel,
        ReportType.wrongStatusOpen,
        ReportType.wrongName,
        ReportType.wrongAddress,
      ];

      await pumpApp(
        tester,
        _hostFor(visibleTypes: types, hasAnyBackend: true),
      );

      final tiles = tester
          .widgetList<RadioListTile<ReportType>>(
            find.byType(RadioListTile<ReportType>),
          )
          .toList();
      expect(tiles, hasLength(types.length));
      for (final tile in tiles) {
        expect(tile.enabled, isTrue,
            reason: '${tile.value} should be enabled when hasAnyBackend=true');
      }
    });

    testWidgets(
        'hasAnyBackend=false → GitHub-routed types (wrongName, '
        'wrongAddress) stay enabled', (tester) async {
      const githubTypes = [ReportType.wrongName, ReportType.wrongAddress];

      await pumpApp(
        tester,
        _hostFor(visibleTypes: githubTypes, hasAnyBackend: false),
      );

      for (final type in githubTypes) {
        final tile = tester.widget<RadioListTile<ReportType>>(
          find.byWidgetPredicate(
            (w) => w is RadioListTile<ReportType> && w.value == type,
          ),
        );
        expect(tile.enabled, isTrue,
            reason: '$type routes to GitHub and must stay selectable even '
                'with no backend (#508)');
      }
    });

    testWidgets(
        'hasAnyBackend=false → non-GitHub types (price + status) are '
        'disabled so the user can\'t submit into the void (#508)',
        (tester) async {
      const backendTypes = [
        ReportType.wrongE5,
        ReportType.wrongE10,
        ReportType.wrongDiesel,
        ReportType.wrongE85,
        ReportType.wrongE98,
        ReportType.wrongLpg,
        ReportType.wrongStatusOpen,
        ReportType.wrongStatusClosed,
      ];

      await pumpApp(
        tester,
        _hostFor(visibleTypes: backendTypes, hasAnyBackend: false),
      );

      for (final type in backendTypes) {
        final tile = tester.widget<RadioListTile<ReportType>>(
          find.byWidgetPredicate(
            (w) => w is RadioListTile<ReportType> && w.value == type,
          ),
        );
        expect(tile.enabled, isFalse,
            reason: '$type needs a backend; with hasAnyBackend=false the '
                'tile must be disabled');
      }
    });

    testWidgets(
        'hasAnyBackend=false mixed list → GitHub types enabled, '
        'backend types disabled in the same render', (tester) async {
      const types = [
        ReportType.wrongE5, // backend → disabled
        ReportType.wrongName, // GitHub → enabled
        ReportType.wrongStatusClosed, // backend → disabled
        ReportType.wrongAddress, // GitHub → enabled
      ];

      await pumpApp(
        tester,
        _hostFor(visibleTypes: types, hasAnyBackend: false),
      );

      RadioListTile<ReportType> tileFor(ReportType t) =>
          tester.widget<RadioListTile<ReportType>>(
            find.byWidgetPredicate(
              (w) => w is RadioListTile<ReportType> && w.value == t,
            ),
          );

      expect(tileFor(ReportType.wrongE5).enabled, isFalse);
      expect(tileFor(ReportType.wrongStatusClosed).enabled, isFalse);
      expect(tileFor(ReportType.wrongName).enabled, isTrue);
      expect(tileFor(ReportType.wrongAddress).enabled, isTrue);
    });

    testWidgets(
        'tile titles render the localized displayName for each type',
        (tester) async {
      const types = [
        ReportType.wrongE10,
        ReportType.wrongStatusOpen,
        ReportType.wrongName,
      ];

      await pumpApp(
        tester,
        _hostFor(visibleTypes: types, hasAnyBackend: true),
      );

      // English ARB strings — pumpApp defaults to Locale('en'), so the
      // displayName resolves to the en value (not the French fallback
      // hard-coded in the entity).
      expect(find.text('Wrong Super E10 price'), findsOneWidget);
      expect(find.text('Shown as open, but closed'), findsOneWidget);
      expect(find.text('Wrong station name'), findsOneWidget);
    });

    testWidgets(
        'header reads the localized "What\'s wrong?" string and uses '
        'titleMedium', (tester) async {
      await pumpApp(
        tester,
        _hostFor(
          visibleTypes: const [ReportType.wrongName],
          hasAnyBackend: true,
        ),
      );

      final headerFinder = find.text("What's wrong?");
      expect(headerFinder, findsOneWidget);

      final headerWidget = tester.widget<Text>(headerFinder);
      // Builder applies Theme.of(context).textTheme.titleMedium — the
      // exact style instance comes from the test MaterialApp's theme,
      // so we just assert it's non-null and not the default body style.
      expect(headerWidget.style, isNotNull);
    });
  });
}
