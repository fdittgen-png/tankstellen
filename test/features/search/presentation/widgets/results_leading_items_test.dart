// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4363 — the leading slots' index arithmetic, which is exactly the
/// shape of bug the class exists to prevent: a `count` and a builder
/// that disagree by one, and the last station of the list vanishes.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/help_banner.dart';
import 'package:tankstellen/features/search/presentation/widgets/results/decision_header.dart';
import 'package:tankstellen/features/search/presentation/widgets/results/refuel_comparison_card.dart';
import 'package:tankstellen/features/search/presentation/widgets/results/results_leading_items.dart';

void main() {
  test('the comparison leads, the decision follows, then the help banner',
      () {
    const leading = ResultsLeadingItems(showDecision: true, showHelp: true);

    expect(leading.count, 3);
    expect(leading.itemAt(0, const []), isA<RefuelComparisonCard>());
    expect(leading.itemAt(1, const []), isA<DecisionHeader>());
    expect(leading.itemAt(2, const []), isA<HelpBanner>());
    expect(leading.itemAt(3, const []), isNull,
        reason: 'the first station row starts exactly at count');
  });

  test('the landscape radar pane carries none of them', () {
    const leading = ResultsLeadingItems(showDecision: false, showHelp: false);

    expect(leading.count, 0);
    expect(leading.itemAt(0, const []), isNull);
  });

  test('the help banner alone still starts at index 0', () {
    const leading = ResultsLeadingItems(showDecision: false, showHelp: true);

    expect(leading.count, 1);
    expect(leading.itemAt(0, const []), isA<HelpBanner>());
    expect(leading.itemAt(1, const []), isNull);
  });
}
