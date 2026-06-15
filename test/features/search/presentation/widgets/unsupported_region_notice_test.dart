// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/location_coverage_provider.dart';
import 'package:tankstellen/features/search/presentation/widgets/unsupported_region_notice.dart';

import '../../../../helpers/pump_app.dart';

/// #3360 — the coverage banner shows the RIGHT message for the right reason,
/// and only when there's something to say + not dismissed.
void main() {
  Finder notice() => find.byKey(const Key('unsupported_region_notice'));

  testWidgets('hidden when coverage is ok / unknown', (tester) async {
    for (final s
        in [LocationCoverageStatus.ok, LocationCoverageStatus.unknown]) {
      await pumpApp(
        tester,
        const UnsupportedRegionNotice(),
        overrides: [locationCoverageProvider.overrideWithValue(s)],
      );
      expect(notice(), findsNothing, reason: 'no banner for $s');
    }
  });

  testWidgets('unsupported → "not available in your region" message',
      (tester) async {
    await pumpApp(
      tester,
      const UnsupportedRegionNotice(),
      overrides: [
        locationCoverageProvider
            .overrideWithValue(LocationCoverageStatus.unsupported),
      ],
    );
    expect(notice(), findsOneWidget);
    expect(find.text('Not available in your region yet'), findsOneWidget);
  });

  testWidgets('needsProfile → "set your country" message', (tester) async {
    await pumpApp(
      tester,
      const UnsupportedRegionNotice(),
      overrides: [
        locationCoverageProvider
            .overrideWithValue(LocationCoverageStatus.needsProfile),
      ],
    );
    expect(notice(), findsOneWidget);
    expect(find.text('Set your country'), findsOneWidget);
  });

  testWidgets('dismiss hides it for the session', (tester) async {
    await pumpApp(
      tester,
      const UnsupportedRegionNotice(),
      overrides: [
        locationCoverageProvider
            .overrideWithValue(LocationCoverageStatus.unsupported),
      ],
    );
    expect(notice(), findsOneWidget);
    await tester.tap(find.byKey(const Key('unsupported_region_dismiss')));
    await tester.pumpAndSettle();
    expect(notice(), findsNothing);
  });
}
