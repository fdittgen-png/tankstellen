import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consent/providers/gdpr_consent_form_provider.dart';

void main() {
  group('GdprConsentFormState', () {
    test('default constructor leaves all five flags false', () {
      const state = GdprConsentFormState();
      expect(state.locationConsent, isFalse);
      expect(state.errorReportingConsent, isFalse);
      expect(state.cloudSyncConsent, isFalse);
      expect(state.communityWaitTimeConsent, isFalse);
      expect(state.vinOnlineDecodeConsent, isFalse);
    });

    group('copyWith', () {
      test('returns identical-value state when no params are passed', () {
        const original = GdprConsentFormState(
          locationConsent: true,
          errorReportingConsent: true,
          cloudSyncConsent: true,
          communityWaitTimeConsent: true,
        );
        final copy = original.copyWith();
        expect(copy.locationConsent, isTrue);
        expect(copy.errorReportingConsent, isTrue);
        expect(copy.cloudSyncConsent, isTrue);
        expect(copy.communityWaitTimeConsent, isTrue);
      });

      test('overrides only communityWaitTimeConsent when supplied', () {
        const original = GdprConsentFormState();
        final copy = original.copyWith(communityWaitTimeConsent: true);
        expect(copy.locationConsent, isFalse);
        expect(copy.errorReportingConsent, isFalse);
        expect(copy.cloudSyncConsent, isFalse);
        expect(copy.communityWaitTimeConsent, isTrue);
      });

      test('overrides only locationConsent when that param is supplied', () {
        const original = GdprConsentFormState();
        final copy = original.copyWith(locationConsent: true);
        expect(copy.locationConsent, isTrue);
        expect(copy.errorReportingConsent, isFalse);
        expect(copy.cloudSyncConsent, isFalse);
      });

      test('overrides only errorReportingConsent when that param is supplied',
          () {
        const original = GdprConsentFormState();
        final copy = original.copyWith(errorReportingConsent: true);
        expect(copy.locationConsent, isFalse);
        expect(copy.errorReportingConsent, isTrue);
        expect(copy.cloudSyncConsent, isFalse);
      });

      test('overrides only cloudSyncConsent when that param is supplied', () {
        const original = GdprConsentFormState();
        final copy = original.copyWith(cloudSyncConsent: true);
        expect(copy.locationConsent, isFalse);
        expect(copy.errorReportingConsent, isFalse);
        expect(copy.cloudSyncConsent, isTrue);
      });

      test('omitted params keep the existing value (true stays true)', () {
        const original = GdprConsentFormState(
          locationConsent: true,
          errorReportingConsent: true,
          cloudSyncConsent: true,
        );
        final copy = original.copyWith(locationConsent: false);
        expect(copy.locationConsent, isFalse);
        expect(copy.errorReportingConsent, isTrue);
        expect(copy.cloudSyncConsent, isTrue);
      });
    });
  });

  group('GdprConsentFormController', () {
    test('build() returns the default state with all flags false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(gdprConsentFormControllerProvider);

      expect(state.locationConsent, isFalse);
      expect(state.errorReportingConsent, isFalse);
      expect(state.cloudSyncConsent, isFalse);
      expect(state.communityWaitTimeConsent, isFalse);
    });

    test('setCommunityWaitTime(true) flips communityWaitTimeConsent only', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(gdprConsentFormControllerProvider.notifier);

      notifier.setCommunityWaitTime(true);

      final state = container.read(gdprConsentFormControllerProvider);
      expect(state.locationConsent, isFalse);
      expect(state.errorReportingConsent, isFalse);
      expect(state.cloudSyncConsent, isFalse);
      expect(state.communityWaitTimeConsent, isTrue);
    });

    test('setCommunityWaitTime leaves the other three flags intact', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(gdprConsentFormControllerProvider.notifier);

      notifier.setLocation(true);
      notifier.setErrorReporting(true);
      notifier.setCloudSync(true);

      notifier.setCommunityWaitTime(true);

      final state = container.read(gdprConsentFormControllerProvider);
      expect(state.locationConsent, isTrue);
      expect(state.errorReportingConsent, isTrue);
      expect(state.cloudSyncConsent, isTrue);
      expect(state.communityWaitTimeConsent, isTrue);
    });

    test('setLocation(true) flips locationConsent only', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(gdprConsentFormControllerProvider.notifier);

      notifier.setLocation(true);

      final state = container.read(gdprConsentFormControllerProvider);
      expect(state.locationConsent, isTrue);
      expect(state.errorReportingConsent, isFalse);
      expect(state.cloudSyncConsent, isFalse);
    });

    test('setLocation(false) leaves errorReporting + cloudSync intact', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(gdprConsentFormControllerProvider.notifier);

      // Pre-arm the other two flags so we can verify setLocation does not
      // disturb them.
      notifier.setErrorReporting(true);
      notifier.setCloudSync(true);

      notifier.setLocation(false);

      final state = container.read(gdprConsentFormControllerProvider);
      expect(state.locationConsent, isFalse);
      expect(state.errorReportingConsent, isTrue);
      expect(state.cloudSyncConsent, isTrue);
    });

    test('setErrorReporting(true) flips errorReportingConsent only', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(gdprConsentFormControllerProvider.notifier);

      notifier.setErrorReporting(true);

      final state = container.read(gdprConsentFormControllerProvider);
      expect(state.locationConsent, isFalse);
      expect(state.errorReportingConsent, isTrue);
      expect(state.cloudSyncConsent, isFalse);
    });

    test('setErrorReporting(false) leaves location + cloudSync intact', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(gdprConsentFormControllerProvider.notifier);

      notifier.setLocation(true);
      notifier.setCloudSync(true);
      notifier.setErrorReporting(true);

      notifier.setErrorReporting(false);

      final state = container.read(gdprConsentFormControllerProvider);
      expect(state.locationConsent, isTrue);
      expect(state.errorReportingConsent, isFalse);
      expect(state.cloudSyncConsent, isTrue);
    });

    test('setCloudSync(true) flips cloudSyncConsent only', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(gdprConsentFormControllerProvider.notifier);

      notifier.setCloudSync(true);

      final state = container.read(gdprConsentFormControllerProvider);
      expect(state.locationConsent, isFalse);
      expect(state.errorReportingConsent, isFalse);
      expect(state.cloudSyncConsent, isTrue);
    });

    test('setCloudSync(false) leaves location + errorReporting intact', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(gdprConsentFormControllerProvider.notifier);

      notifier.setLocation(true);
      notifier.setErrorReporting(true);
      notifier.setCloudSync(true);

      notifier.setCloudSync(false);

      final state = container.read(gdprConsentFormControllerProvider);
      expect(state.locationConsent, isTrue);
      expect(state.errorReportingConsent, isTrue);
      expect(state.cloudSyncConsent, isFalse);
    });

    test('calling all three setters with true yields all flags true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(gdprConsentFormControllerProvider.notifier);

      notifier.setLocation(true);
      notifier.setErrorReporting(true);
      notifier.setCloudSync(true);

      final state = container.read(gdprConsentFormControllerProvider);
      expect(state.locationConsent, isTrue);
      expect(state.errorReportingConsent, isTrue);
      expect(state.cloudSyncConsent, isTrue);
    });

    test('setVinOnlineDecode(true) flips vinOnlineDecodeConsent only (#1399)',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(gdprConsentFormControllerProvider.notifier);

      notifier.setVinOnlineDecode(true);

      final state = container.read(gdprConsentFormControllerProvider);
      expect(state.locationConsent, isFalse);
      expect(state.errorReportingConsent, isFalse);
      expect(state.cloudSyncConsent, isFalse);
      expect(state.communityWaitTimeConsent, isFalse);
      expect(state.vinOnlineDecodeConsent, isTrue);
    });

    test('setVinOnlineDecode leaves the other four flags intact (#1399)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(gdprConsentFormControllerProvider.notifier);

      notifier.setLocation(true);
      notifier.setErrorReporting(true);
      notifier.setCloudSync(true);
      notifier.setCommunityWaitTime(true);

      notifier.setVinOnlineDecode(true);

      final state = container.read(gdprConsentFormControllerProvider);
      expect(state.locationConsent, isTrue);
      expect(state.errorReportingConsent, isTrue);
      expect(state.cloudSyncConsent, isTrue);
      expect(state.communityWaitTimeConsent, isTrue);
      expect(state.vinOnlineDecodeConsent, isTrue);
    });
  });
}
