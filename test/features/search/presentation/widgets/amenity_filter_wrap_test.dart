import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/station_amenity.dart';
import 'package:tankstellen/features/search/presentation/widgets/amenity_filter_wrap.dart';

void main() {
  group('AmenityFilterWrap', () {
    Future<void> pumpWrap(
      WidgetTester tester, {
      required Set<StationAmenity> selected,
      required ValueChanged<StationAmenity> onToggle,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AmenityFilterWrap(
              selected: selected,
              onToggle: onToggle,
            ),
          ),
        ),
      );
    }

    testWidgets('renders one FilterChip per amenity value', (tester) async {
      await pumpWrap(tester, selected: const {}, onToggle: (_) {});
      expect(
        find.byType(FilterChip),
        findsNWidgets(StationAmenity.values.length),
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

    testWidgets('tapping a chip invokes onToggle with that amenity',
        (tester) async {
      StationAmenity? captured;
      await pumpWrap(
        tester,
        selected: const {},
        onToggle: (a) => captured = a,
      );
      await tester.tap(find.text('Shop'));
      await tester.pump();
      expect(captured, StationAmenity.shop);
    });

    testWidgets('every chip carries a stable ValueKey', (tester) async {
      await pumpWrap(tester, selected: const {}, onToggle: (_) {});
      for (final amenity in StationAmenity.values) {
        expect(
          find.byKey(ValueKey('criteria-amenity-${amenity.name}')),
          findsOneWidget,
        );
      }
    });
  });
}
