// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/station_amenity.dart';
import 'package:tankstellen/features/search/presentation/widgets/amenity_filter_wrap.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  group('AmenityFilterWrap', () {
    Future<void> pumpWrap(
      WidgetTester tester, {
      required Set<StationAmenity> selected,
      required ValueChanged<StationAmenity> onToggle,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AmenityFilterWrap(selected: selected, onToggle: onToggle),
          ),
        ),
      );
    }

    testWidgets('#3927 — collapsed shows the first rows plus a Show more '
        'chip, expanded shows every amenity', (tester) async {
      await pumpWrap(tester, selected: const {}, onToggle: (_) {});
      final hidden =
          StationAmenity.values.length - AmenityFilterWrap.collapsedCount;
      expect(
        find.byType(FilterChip),
        findsNWidgets(AmenityFilterWrap.collapsedCount),
      );
      expect(find.text('Show more ($hidden)'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('criteria-amenity-show-more')));
      await tester.pumpAndSettle();

      expect(
        find.byType(FilterChip),
        findsNWidgets(StationAmenity.values.length),
      );
      expect(find.text('Show less'), findsOneWidget);
    });

    testWidgets('#3927 — a selected amenity past the collapse cut stays '
        'visible without expanding', (tester) async {
      final last = StationAmenity.values.last;
      await pumpWrap(tester, selected: {last}, onToggle: (_) {});
      expect(
        find.byKey(ValueKey('criteria-amenity-${last.name}')),
        findsOneWidget,
      );
    });

    testWidgets('selected chips render in selected state', (tester) async {
      await pumpWrap(
        tester,
        selected: {StationAmenity.shop, StationAmenity.toilet},
        onToggle: (_) {},
      );
      final chips = tester.widgetList<FilterChip>(find.byType(FilterChip));
      final selectedCount = chips.where((c) => c.selected).length;
      expect(selectedCount, 2);
    });

    testWidgets('tapping a chip invokes onToggle with that amenity', (
      tester,
    ) async {
      StationAmenity? captured;
      await pumpWrap(tester, selected: const {}, onToggle: (a) => captured = a);
      await tester.tap(find.text('Shop'));
      await tester.pump();
      expect(captured, StationAmenity.shop);
    });

    testWidgets('every chip carries a stable ValueKey', (tester) async {
      await pumpWrap(tester, selected: const {}, onToggle: (_) {});
      await tester.tap(find.byKey(const ValueKey('criteria-amenity-show-more')));
      await tester.pumpAndSettle();
      for (final amenity in StationAmenity.values) {
        expect(
          find.byKey(ValueKey('criteria-amenity-${amenity.name}')),
          findsOneWidget,
        );
      }
    });
  });
}
