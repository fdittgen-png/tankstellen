// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/presentation/widgets/results/summary_chip.dart';

import '../../../../helpers/pump_app.dart';

/// #4094 (epic #4087) — colour only where it means something.
///
/// Four tonal pills in a row, above a list of filled cards, above a
/// filled navigation bar, is how the screen ran out of hierarchy to
/// spend: every element was individually reasonable and the problem was
/// cumulative. A fill has to mean something, which it can only do if
/// most things do not have one.
void main() {
  Future<BoxDecoration> decorationOf(
    WidgetTester tester, {
    required bool emphasized,
  }) async {
    await pumpApp(
      tester,
      SummaryChip(
        icon: const Icon(Icons.schedule, size: 12),
        label: '10 km',
        emphasized: emphasized,
      ),
    );
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(SummaryChip),
        matching: find.byType(Container),
      ).first,
    );
    return container.decoration! as BoxDecoration;
  }

  testWidgets('an ordinary segment is TEXT on the band, not a surface',
      (tester) async {
    final decoration = await decorationOf(tester, emphasized: false);
    expect(decoration.color, Colors.transparent);
    expect(decoration.border, isNull,
        reason: 'nor is it an outlined pill — that trades a fill for a '
            'border and keeps the boundary');
  });

  testWidgets('the emphasized segment keeps its fill — that IS the point',
      (tester) async {
    final decoration = await decorationOf(tester, emphasized: true);
    final scheme = Theme.of(
      tester.element(find.byType(SummaryChip)),
    ).colorScheme;
    // Stale prices are an attention state. A fill means something here
    // precisely because nothing beside it has one.
    expect(decoration.color, scheme.tertiaryContainer);
  });

  testWidgets('the label still reads against the band it now sits on',
      (tester) async {
    await pumpApp(
      tester,
      const SummaryChip(
        icon: Icon(Icons.schedule, size: 12),
        label: '10 km',
      ),
    );
    final ctx = tester.element(find.byType(SummaryChip));
    final text = tester.widget<Text>(find.text('10 km'));
    // onSurfaceVariant, not onSecondaryContainer: the container it was
    // named for is gone, and a foreground chosen for a surface that no
    // longer exists is how contrast bugs are born.
    expect(text.style?.color, Theme.of(ctx).colorScheme.onSurfaceVariant);
  });
}
