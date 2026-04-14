import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/setup/presentation/widgets/onboarding_navigation_buttons.dart';

void main() {
  group('OnboardingNavigationButtons', () {
    Future<void> pumpButtons(
      WidgetTester tester, {
      required int currentStep,
      bool isLoading = false,
      bool isLastStep = false,
      bool isSkippable = false,
      VoidCallback? onBack,
      VoidCallback? onNext,
      VoidCallback? onSkip,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OnboardingNavigationButtons(
              currentStep: currentStep,
              isLoading: isLoading,
              isLastStep: isLastStep,
              isSkippable: isSkippable,
              onBack: onBack ?? () {},
              onNext: onNext ?? () {},
              onSkip: onSkip ?? () {},
            ),
          ),
        ),
      );
    }

    testWidgets('hides Back button on first step', (tester) async {
      await pumpButtons(tester, currentStep: 0);
      expect(find.text('Back'), findsNothing);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('shows Back button on later steps', (tester) async {
      await pumpButtons(tester, currentStep: 2);
      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('hides Skip button when step is not skippable',
        (tester) async {
      await pumpButtons(tester, currentStep: 1, isSkippable: false);
      expect(find.text('Skip'), findsNothing);
    });

    testWidgets('shows Skip button when step is skippable', (tester) async {
      await pumpButtons(tester, currentStep: 1, isSkippable: true);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('shows "Get started" + check icon on the last step',
        (tester) async {
      await pumpButtons(tester, currentStep: 3, isLastStep: true);
      expect(find.text('Get started'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsNothing);
    });

    testWidgets('shows "Next" + arrow icon on intermediate steps',
        (tester) async {
      await pumpButtons(tester, currentStep: 1, isLastStep: false);
      expect(find.text('Next'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('shows spinner instead of icon while loading', (tester) async {
      await pumpButtons(tester, currentStep: 1, isLoading: true);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsNothing);
    });

    testWidgets('disables every button while loading', (tester) async {
      var nextPressed = false;
      var skipPressed = false;
      var backPressed = false;
      await pumpButtons(
        tester,
        currentStep: 2,
        isLoading: true,
        isSkippable: true,
        onBack: () => backPressed = true,
        onNext: () => nextPressed = true,
        onSkip: () => skipPressed = true,
      );
      await tester.tap(find.text('Back'));
      await tester.tap(find.text('Skip'));
      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(backPressed, isFalse);
      expect(skipPressed, isFalse);
      expect(nextPressed, isFalse);
    });

    testWidgets('forwards onBack/onNext/onSkip when idle', (tester) async {
      var backPressed = false;
      var nextPressed = false;
      var skipPressed = false;
      await pumpButtons(
        tester,
        currentStep: 2,
        isSkippable: true,
        onBack: () => backPressed = true,
        onNext: () => nextPressed = true,
        onSkip: () => skipPressed = true,
      );
      await tester.tap(find.text('Back'));
      await tester.pump();
      expect(backPressed, isTrue);

      await tester.tap(find.text('Skip'));
      await tester.pump();
      expect(skipPressed, isTrue);

      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(nextPressed, isTrue);
    });
  });
}
