import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/pump_display_reticle.dart';

/// Tests for the #1868 pump-display capture reticle overlay.
void main() {
  testWidgets('renders a centred wide framed box', (tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: PumpDisplayReticle(),
    ));

    expect(find.byType(PumpDisplayReticle), findsOneWidget);

    // 86% of the width — leaves a margin so the frame reads as a target.
    final fsb = tester.widget<FractionallySizedBox>(
      find.descendant(
        of: find.byType(PumpDisplayReticle),
        matching: find.byType(FractionallySizedBox),
      ),
    );
    expect(fsb.widthFactor, 0.86);

    // A wide three-number readout shape.
    final aspect = tester.widget<AspectRatio>(
      find.descendant(
        of: find.byType(PumpDisplayReticle),
        matching: find.byType(AspectRatio),
      ),
    );
    expect(aspect.aspectRatio, closeTo(16 / 5, 1e-9));

    // The frame has a visible border.
    final decoration = tester
        .widget<DecoratedBox>(
          find.descendant(
            of: find.byType(PumpDisplayReticle),
            matching: find.byType(DecoratedBox),
          ),
        )
        .decoration as BoxDecoration;
    expect(decoration.border, isNotNull);
  });

  testWidgets('is decorative — ignores pointer events', (tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: PumpDisplayReticle(),
    ));
    // Wrapped in IgnorePointer so taps fall through to the capture
    // button beneath the overlay.
    expect(
      find.descendant(
        of: find.byType(PumpDisplayReticle),
        matching: find.byType(IgnorePointer),
      ),
      findsOneWidget,
    );
  });
}
