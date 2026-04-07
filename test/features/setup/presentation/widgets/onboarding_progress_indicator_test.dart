import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/setup/presentation/widgets/onboarding_progress_indicator.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('OnboardingProgressIndicator', () {
    testWidgets('renders correct number of dots', (tester) async {
      await pumpApp(
        tester,
        const OnboardingProgressIndicator(currentStep: 0, stepCount: 4),
      );

      final containers = find.byType(AnimatedContainer);
      expect(containers, findsNWidgets(4));
    });

    testWidgets('renders 3 dots for 3-step flow', (tester) async {
      await pumpApp(
        tester,
        const OnboardingProgressIndicator(currentStep: 1, stepCount: 3),
      );

      final containers = find.byType(AnimatedContainer);
      expect(containers, findsNWidgets(3));
    });

    testWidgets('active dot is wider than inactive', (tester) async {
      await pumpApp(
        tester,
        const OnboardingProgressIndicator(currentStep: 1, stepCount: 3),
      );
      await tester.pumpAndSettle();

      final renderBoxes = <Size>[];
      for (final element in find.byType(AnimatedContainer).evaluate()) {
        final renderBox = element.renderObject as RenderBox;
        renderBoxes.add(renderBox.size);
      }

      // Active dot at index 1 should be 24px wide, others 8px
      expect(renderBoxes[0].width, 8.0);
      expect(renderBoxes[1].width, 24.0);
      expect(renderBoxes[2].width, 8.0);
    });

    testWidgets('first step active has correct widths', (tester) async {
      await pumpApp(
        tester,
        const OnboardingProgressIndicator(currentStep: 0, stepCount: 4),
      );
      await tester.pumpAndSettle();

      final renderBoxes = <Size>[];
      for (final element in find.byType(AnimatedContainer).evaluate()) {
        final renderBox = element.renderObject as RenderBox;
        renderBoxes.add(renderBox.size);
      }

      expect(renderBoxes[0].width, 24.0); // active
      expect(renderBoxes[1].width, 8.0);
      expect(renderBoxes[2].width, 8.0);
      expect(renderBoxes[3].width, 8.0);
    });

    testWidgets('last step active has correct widths', (tester) async {
      await pumpApp(
        tester,
        const OnboardingProgressIndicator(currentStep: 3, stepCount: 4),
      );
      await tester.pumpAndSettle();

      final renderBoxes = <Size>[];
      for (final element in find.byType(AnimatedContainer).evaluate()) {
        final renderBox = element.renderObject as RenderBox;
        renderBoxes.add(renderBox.size);
      }

      expect(renderBoxes[0].width, 8.0);
      expect(renderBoxes[1].width, 8.0);
      expect(renderBoxes[2].width, 8.0);
      expect(renderBoxes[3].width, 24.0); // active
    });

    testWidgets('all dots have consistent height of 8px', (tester) async {
      await pumpApp(
        tester,
        const OnboardingProgressIndicator(currentStep: 2, stepCount: 4),
      );
      await tester.pumpAndSettle();

      for (final element in find.byType(AnimatedContainer).evaluate()) {
        final renderBox = element.renderObject as RenderBox;
        expect(renderBox.size.height, 8.0);
      }
    });
  });
}
