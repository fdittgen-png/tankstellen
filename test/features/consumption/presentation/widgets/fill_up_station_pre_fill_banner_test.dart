import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fill_up_station_pre_fill_banner.dart';

/// Widget tests for [FillUpStationPreFillBanner] (#581 affordance,
/// restyled by #751 phase 2 / #563 extraction).
///
/// The banner sits above the form to surface the pre-filled station
/// without stealing visual weight from the "What you filled" card.
/// The visible chrome is a labelled icon + label + station name. The
/// accessibility contract collapses both texts into a single Semantics
/// container labelled "$label: $stationName" so a screen reader hears
/// the affordance as one announcement.
void main() {
  Future<void> pumpBanner(
    WidgetTester tester, {
    String stationName = 'Shell Beziers',
    String label = 'From station',
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FillUpStationPreFillBanner(
            stationName: stationName,
            label: label,
          ),
        ),
      ),
    );
  }

  testWidgets('renders both the label and the station name plus the icon',
      (tester) async {
    await pumpBanner(tester);
    await tester.pumpAndSettle();

    expect(find.text('From station'), findsOneWidget);
    expect(find.text('Shell Beziers'), findsOneWidget);
    expect(find.byIcon(Icons.place_outlined), findsOneWidget);
  });

  testWidgets(
      'exposes a single combined "label: stationName" Semantics announcement',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpBanner(
      tester,
      stationName: 'Total Castelnau',
      label: 'Pre-filled from',
    );
    await tester.pumpAndSettle();

    // The Column children are wrapped in ExcludeSemantics so only the
    // outer Semantics(label: '$label: $stationName') node is reachable.
    // A screen reader should hear the merged label as one announcement,
    // not two adjacent text nodes.
    expect(
      find.bySemanticsLabel('Pre-filled from: Total Castelnau'),
      findsOneWidget,
      reason:
          'The banner combines label + station name into a single '
          'Semantics container so screen readers announce them as one '
          'affordance rather than two disconnected texts.',
    );

    handle.dispose();
  });

  testWidgets('renders even when label or stationName is empty',
      (tester) async {
    await pumpBanner(tester, label: '', stationName: '');
    await tester.pumpAndSettle();

    // Defensive: an empty pre-fill payload must not crash the banner.
    expect(find.byType(FillUpStationPreFillBanner), findsOneWidget);
    expect(find.byIcon(Icons.place_outlined), findsOneWidget);
  });
}
