import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/setup/providers/onboarding_wizard_provider.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vin_data.dart';

void main() {
  group('OnboardingWizardState', () {
    test('default constructor produces documented defaults', () {
      final state = OnboardingWizardState();
      expect(state.currentStep, 0);
      expect(state.isLoading, isFalse);
      expect(state.homeZipCode, isNull);
      expect(state.defaultSearchRadius, 10.0);
      expect(state.preferredFuelType, FuelType.e10);
      expect(state.landingScreen, LandingScreen.nearest);
      expect(state.obd2VinData, isNull);
      expect(state.obd2VinReadFailed, isFalse);
    });

    test('preferredFuelType: null falls back to FuelType.e10', () {
      final state = OnboardingWizardState(preferredFuelType: null);
      expect(state.preferredFuelType, FuelType.e10);
    });

    test('preferredFuelType honors explicit non-default value', () {
      final state = OnboardingWizardState(preferredFuelType: FuelType.diesel);
      expect(state.preferredFuelType, FuelType.diesel);
    });

    test('copyWith with no args preserves every field', () {
      const vin = VinData(vin: 'WVWZZZ1JZXW000001');
      final original = OnboardingWizardState(
        currentStep: 4,
        isLoading: true,
        homeZipCode: '34000',
        defaultSearchRadius: 25.0,
        preferredFuelType: FuelType.diesel,
        landingScreen: LandingScreen.map,
        obd2VinData: vin,
        obd2VinReadFailed: true,
      );

      final copy = original.copyWith();

      expect(copy.currentStep, original.currentStep);
      expect(copy.isLoading, original.isLoading);
      expect(copy.homeZipCode, original.homeZipCode);
      expect(copy.defaultSearchRadius, original.defaultSearchRadius);
      expect(copy.preferredFuelType, original.preferredFuelType);
      expect(copy.landingScreen, original.landingScreen);
      expect(copy.obd2VinData, original.obd2VinData);
      expect(copy.obd2VinReadFailed, original.obd2VinReadFailed);
    });

    test('copyWith(currentStep: 5) overrides only currentStep', () {
      final original = OnboardingWizardState();
      final copy = original.copyWith(currentStep: 5);

      expect(copy.currentStep, 5);
      // Every other field stays equal to the original defaults.
      expect(copy.isLoading, original.isLoading);
      expect(copy.homeZipCode, original.homeZipCode);
      expect(copy.defaultSearchRadius, original.defaultSearchRadius);
      expect(copy.preferredFuelType, original.preferredFuelType);
      expect(copy.landingScreen, original.landingScreen);
      expect(copy.obd2VinData, original.obd2VinData);
      expect(copy.obd2VinReadFailed, original.obd2VinReadFailed);
    });

    test('copyWith propagates isLoading override', () {
      final state = OnboardingWizardState().copyWith(isLoading: true);
      expect(state.isLoading, isTrue);
      expect(state.currentStep, 0);
    });

    test('copyWith propagates homeZipCode override', () {
      final state = OnboardingWizardState().copyWith(homeZipCode: '75001');
      expect(state.homeZipCode, '75001');
      expect(state.defaultSearchRadius, 10.0);
    });

    test('copyWith propagates defaultSearchRadius override', () {
      final state = OnboardingWizardState().copyWith(defaultSearchRadius: 50.0);
      expect(state.defaultSearchRadius, 50.0);
      expect(state.preferredFuelType, FuelType.e10);
    });

    test('copyWith propagates preferredFuelType override', () {
      final state =
          OnboardingWizardState().copyWith(preferredFuelType: FuelType.electric);
      expect(state.preferredFuelType, FuelType.electric);
      expect(state.landingScreen, LandingScreen.nearest);
    });

    test('copyWith propagates landingScreen override', () {
      final state = OnboardingWizardState()
          .copyWith(landingScreen: LandingScreen.favorites);
      expect(state.landingScreen, LandingScreen.favorites);
      expect(state.currentStep, 0);
    });

    test('copyWith propagates obd2VinData override', () {
      const vin = VinData(
        vin: 'WVWZZZ1JZXW000002',
        make: 'Volkswagen',
        model: 'Golf',
        source: VinDataSource.vpic,
      );
      final state = OnboardingWizardState().copyWith(obd2VinData: vin);
      expect(state.obd2VinData, vin);
      expect(state.obd2VinReadFailed, isFalse);
    });

    test('copyWith propagates obd2VinReadFailed override', () {
      final state = OnboardingWizardState().copyWith(obd2VinReadFailed: true);
      expect(state.obd2VinReadFailed, isTrue);
      expect(state.obd2VinData, isNull);
    });
  });

  group('OnboardingWizardController', () {
    late ProviderContainer container;
    late OnboardingWizardController controller;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
      controller =
          container.read(onboardingWizardControllerProvider.notifier);
    });

    OnboardingWizardState read() =>
        container.read(onboardingWizardControllerProvider);

    test('build() exposes default state', () {
      final state = read();
      expect(state.currentStep, 0);
      expect(state.isLoading, isFalse);
      expect(state.homeZipCode, isNull);
      expect(state.defaultSearchRadius, 10.0);
      expect(state.preferredFuelType, FuelType.e10);
      expect(state.landingScreen, LandingScreen.nearest);
      expect(state.obd2VinData, isNull);
      expect(state.obd2VinReadFailed, isFalse);
    });

    test('setStep mutates currentStep', () {
      controller.setStep(3);
      expect(read().currentStep, 3);
    });

    test('setLoading mutates isLoading', () {
      controller.setLoading(true);
      expect(read().isLoading, isTrue);
    });

    test('setLoading does not touch currentStep', () {
      controller.setStep(1);
      controller.setLoading(true);
      final state = read();
      expect(state.currentStep, 1);
      expect(state.isLoading, isTrue);
    });

    test('setHomeZipCode mutates homeZipCode', () {
      controller.setHomeZipCode('34000');
      expect(read().homeZipCode, '34000');
    });

    test('setDefaultSearchRadius mutates defaultSearchRadius', () {
      controller.setDefaultSearchRadius(25.0);
      expect(read().defaultSearchRadius, 25.0);
    });

    test('setPreferredFuelType mutates preferredFuelType', () {
      controller.setPreferredFuelType(FuelType.diesel);
      expect(read().preferredFuelType, FuelType.diesel);
    });

    test('setLandingScreen mutates landingScreen (non-default value)', () {
      // Default is LandingScreen.nearest — pick map (non-default).
      controller.setLandingScreen(LandingScreen.map);
      expect(read().landingScreen, LandingScreen.map);
    });

    test('setObd2VinData stores the supplied VinData', () {
      const vin = VinData(
        vin: 'WVWZZZ1JZXW000003',
        make: 'Volkswagen',
        model: 'Polo',
        source: VinDataSource.vpic,
      );
      controller.setObd2VinData(vin);
      expect(read().obd2VinData, vin);
    });

    test('setObd2VinData resets obd2VinReadFailed to false', () {
      // Arrange: simulate a previous failed VIN read.
      controller.setObd2VinReadFailed();
      expect(read().obd2VinReadFailed, isTrue);

      // Act: a successful retry now provides VinData.
      const vin = VinData(
        vin: 'WVWZZZ1JZXW000004',
        source: VinDataSource.vpic,
      );
      controller.setObd2VinData(vin);

      // Assert: failed flag is cleared.
      final state = read();
      expect(state.obd2VinData, vin);
      expect(state.obd2VinReadFailed, isFalse);
    });

    test('setObd2VinReadFailed sets obd2VinReadFailed to true', () {
      controller.setObd2VinReadFailed();
      expect(read().obd2VinReadFailed, isTrue);
    });

    test('setters are independent — mutating one preserves the others', () {
      controller.setStep(2);
      controller.setHomeZipCode('75001');
      controller.setPreferredFuelType(FuelType.diesel);
      controller.setLandingScreen(LandingScreen.cheapest);

      final state = read();
      expect(state.currentStep, 2);
      expect(state.homeZipCode, '75001');
      expect(state.preferredFuelType, FuelType.diesel);
      expect(state.landingScreen, LandingScreen.cheapest);
      // Untouched fields keep defaults.
      expect(state.isLoading, isFalse);
      expect(state.defaultSearchRadius, 10.0);
      expect(state.obd2VinData, isNull);
      expect(state.obd2VinReadFailed, isFalse);
    });

    test('controller is keepAlive — same instance across reads', () {
      final firstNotifier =
          container.read(onboardingWizardControllerProvider.notifier);
      firstNotifier.setStep(7);
      final secondNotifier =
          container.read(onboardingWizardControllerProvider.notifier);
      // keepAlive: true means the same controller instance is reused, so
      // the step we just set must still be visible.
      expect(secondNotifier, same(firstNotifier));
      expect(read().currentStep, 7);
    });
  });
}
