import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/setup/providers/onboarding_wizard_provider.dart';

void main() {
  ProviderContainer makeContainer() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  test('defaults to step 0, not loading', () {
    final c = makeContainer();
    final s = c.read(onboardingWizardControllerProvider);
    expect(s.currentStep, 0);
    expect(s.isLoading, isFalse);
  });

  test('setStep updates current step', () {
    final c = makeContainer();
    c.read(onboardingWizardControllerProvider.notifier).setStep(2);
    expect(c.read(onboardingWizardControllerProvider).currentStep, 2);
  });

  test('setLoading toggles loading without touching step', () {
    final c = makeContainer();
    final ctrl = c.read(onboardingWizardControllerProvider.notifier);
    ctrl.setStep(1);
    ctrl.setLoading(true);
    final s = c.read(onboardingWizardControllerProvider);
    expect(s.currentStep, 1);
    expect(s.isLoading, isTrue);
  });
}
